import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/directories/teams_directory_screen.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  bool get isUsingFallbackMemory => false;

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }
}

class FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class FakeTournamentsRepository implements TournamentsRepository {
  final List<ChampionshipTournament> tournaments;

  FakeTournamentsRepository(this.tournaments);

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async => tournaments;

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async => tournament;

  @override
  Future<void> deleteTournament(String tournamentId) async {}

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(dynamic draft) async {}

  @override
  Future<void> clearDraft() async {}
}

class FakeTeamsRepository implements TeamsRepository {
  final List<TournamentTeam> teams;
  bool shouldFailLoadAllTeams = false;

  FakeTeamsRepository(this.teams);

  @override
  Future<List<TournamentTeam>> loadTeams() async => teams;

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    return teams.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async => team;

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> updatedTeams,
  ) async {}

  @override
  Future<void> deleteTeam(String teamId) async {
    teams.removeWhere((t) => t.id == teamId);
  }

  @override
  Future<List<PlayerDirectoryItem>> loadAllPlayers() async {
    final List<PlayerDirectoryItem> items = [];
    for (final team in teams) {
      for (final p in team.players) {
        items.add(
          PlayerDirectoryItem(
            player: p,
            teamId: team.id,
            teamName: team.name,
            teamShortCode: team.shortCode,
            tournamentId: team.tournamentId,
            tournamentName: '',
          ),
        );
      }
    }
    items.sort(
      (a, b) => a.player.fullName.toLowerCase().compareTo(
        b.player.fullName.toLowerCase(),
      ),
    );
    return items;
  }

  @override
  Future<List<TeamDirectoryItem>> loadAllTeams() async {
    if (shouldFailLoadAllTeams) {
      throw Exception('Offline');
    }
    return teams
        .map(
          (t) => TeamDirectoryItem(
            id: t.id,
            name: t.name,
            shortCode: t.shortCode,
            crestShape: t.crestShape,
            primaryColorHex: t.primaryColorHex,
            secondaryColorHex: t.secondaryColorHex,
            categoryLabel: t.groupName,
            tournamentCount: t.tournamentId.trim().isEmpty ? 0 : 1,
            playerCount: t.players.length,
            eligibilityStatus: t.eligibilityStatus,
            coachId: t.coachId,
            updatedAt: t.updatedAt,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

Widget createTeamsTestApp({
  required List<ChampionshipTournament> tournaments,
  required List<TournamentTeam> teams,
  FakeTeamsRepository? customRepository,
  UserRole role = UserRole.fan,
}) {
  final repo = customRepository ?? FakeTeamsRepository(teams);
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
      localStorageRepositoryProvider.overrideWithValue(
        FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        FakeConnectivityRepository(),
      ),
      activeUserRoleProvider.overrideWith((ref) => role),
      teamsRepositoryProvider.overrideWithValue(repo),
      tournamentsControllerProvider.overrideWith((ref) {
        return TournamentsController(
          tournamentsRepository: FakeTournamentsRepository(tournaments),
          manageTournamentsUseCase: ref.watch(manageTournamentsUseCaseProvider),
        );
      }),
      teamsControllerProvider.overrideWith((ref) {
        return TeamsController(
          teamsRepository: repo,
          manageTeamsEligibilityUseCase: ref.watch(
            manageTeamsEligibilityUseCaseProvider,
          ),
        );
      }),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: const TeamsDirectoryScreen(),
    ),
  );
}

void main() {
  final tournament1 = ChampionshipTournament(
    id: 't-1',
    name: 'Liga Premier Apertura',
    category: 'Libre Masculino',
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 6, 30),
    updatedAt: DateTime(2026, 3, 1),
  );

  final tournament2 = ChampionshipTournament(
    id: 't-2',
    name: 'Copa Élite Verano',
    category: 'Sub-20',
    format: TournamentFormat.knockoutCup,
    status: TournamentStatus.openRegistration,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 7, 1),
  );

  final team1 = TournamentTeam(
    id: 'team-1',
    tournamentId: 't-1',
    name: 'Tigres FC',
    shortCode: 'TIG',
  );

  final team2 = TournamentTeam(
    id: 'team-2',
    tournamentId: 't-1',
    name: 'Águilas Doradas',
    shortCode: 'AGU',
  );

  final team3 = TournamentTeam(
    id: 'team-3',
    tournamentId: 't-2',
    name: 'Atlético Halcones',
    shortCode: 'HAL',
  );

  group('TeamsDirectoryScreen Widget Tests', () {
    testWidgets(
      'renders teams and confirms tournament filter chips are completely removed',
      (tester) async {
        await tester.pumpWidget(
          createTeamsTestApp(
            tournaments: [tournament1, tournament2],
            teams: [team1, team2, team3],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        // All 3 teams displayed initially
        expect(find.byKey(const Key('team_item_team-1')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-2')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-3')), findsOneWidget);

        // Search bar present, tournament selector and ChoiceChips completely removed
        expect(find.byKey(const Key('teams_search_bar')), findsOneWidget);
        expect(
          find.byKey(const Key('teams_tournament_selector')),
          findsNothing,
        );
        expect(find.byType(ChoiceChip), findsNothing);
      },
    );

    testWidgets(
      'pull-to-refresh offline preserves cached teams and shows SnackBar warning',
      (tester) async {
        final repo = FakeTeamsRepository([team1, team2]);
        await tester.pumpWidget(
          createTeamsTestApp(
            tournaments: [tournament1],
            teams: [team1, team2],
            customRepository: repo,
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_item_team-1')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-2')), findsOneWidget);

        // Simulate offline failure on pull-to-refresh
        repo.shouldFailLoadAllTeams = true;
        await tester.fling(
          find.byKey(const Key('teams_directory_list')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_item_team-1')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-2')), findsOneWidget);
        expect(
          find.text(
            'Sin conexión a internet. Mostrando equipos locales disponibles.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'un-enrolled club displays fallback label and opens TeamDetailScreen safely',
      (tester) async {
        final unEnrolledTeam = TournamentTeam(
          id: 'team-free',
          tournamentId: '',
          name: 'Club Independiente',
          shortCode: 'IND',
        );
        await tester.pumpWidget(
          createTeamsTestApp(
            tournaments: const [],
            teams: [unEnrolledTeam],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_item_team-free')), findsOneWidget);
        expect(
          find.text('Sin torneo asignado • 0 jugadores inscritos'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('team_item_team-free')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_detail_screen')), findsOneWidget);
        expect(
          find.byKey(const Key('team_detail_not_found_state')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'real-time search with accent-insensitivity filters correctly',
      (tester) async {
        await tester.pumpWidget(
          createTeamsTestApp(
            tournaments: [tournament1, tournament2],
            teams: [team1, team2, team3],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        // Search 'aguilas' should match 'Águilas Doradas'
        await tester.enterText(
          find.byKey(const Key('teams_search_bar')),
          'aguilas',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_item_team-1')), findsNothing);
        expect(find.byKey(const Key('team_item_team-2')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-3')), findsNothing);

        // Clear search
        await tester.tap(find.byKey(const Key('search_bar_clear_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_item_team-1')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-2')), findsOneWidget);
        expect(find.byKey(const Key('team_item_team-3')), findsOneWidget);
      },
    );

    testWidgets('displays empty state when search matches nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTeamsTestApp(
          tournaments: [tournament1, tournament2],
          teams: [team1, team2, team3],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('teams_search_bar')),
        'Equipo Fantasma',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teams_empty_state')), findsOneWidget);
      expect(
        find.text('No se encontraron equipos con ese criterio.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping team opens TeamDetailScreen', (tester) async {
      await tester.pumpWidget(
        createTeamsTestApp(
          tournaments: [tournament1],
          teams: [team1],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('team_item_team-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_detail_screen')), findsOneWidget);
    });

    testWidgets(
      'renders create team button exclusively for coach, hides for organizer, referee, player and fan',
      (tester) async {
        for (final role in UserRole.values) {
          await tester.pumpWidget(
            createTeamsTestApp(
              tournaments: [tournament1],
              teams: [team1],
              role: role,
            ),
          );
          await tester.pumpAndSettle();

          final finder = find.byKey(
            const Key('create_team_from_directory_button'),
          );
          if (role == UserRole.coach) {
            expect(
              finder,
              findsOneWidget,
              reason: 'Coach must see create team button',
            );
          } else {
            expect(
              finder,
              findsNothing,
              reason: '${role.name} must NOT see create team button',
            );
          }
        }
      },
    );
  });
}
