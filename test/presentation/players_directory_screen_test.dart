import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
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
import 'package:vifutbol/presentation/directories/players_directory_screen.dart';
import 'package:vifutbol/presentation/standings/widgets/player_performance_profile_card.dart';

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
}

Widget createPlayersTestApp({
  required List<ChampionshipTournament> tournaments,
  required List<TournamentTeam> teams,
  UserRole role = UserRole.fan,
}) {
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
      tournamentsControllerProvider.overrideWith((ref) {
        return TournamentsController(
          tournamentsRepository: FakeTournamentsRepository(tournaments),
          manageTournamentsUseCase: ref.watch(manageTournamentsUseCaseProvider),
        );
      }),
      teamsRepositoryProvider.overrideWithValue(FakeTeamsRepository(teams)),
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
      home: const PlayersDirectoryScreen(),
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

  final player1 = const RegisteredPlayer(
    id: 'p-1',
    fullName: 'Carlos Gómez',
    documentId: 'DOC-101',
    shirtNumber: 10,
    position: PlayerPosition.forward,
    isEligible: true,
  );

  final player2 = const RegisteredPlayer(
    id: 'p-2',
    fullName: 'Andrés Álvarez',
    documentId: 'DOC-102',
    shirtNumber: 1,
    position: PlayerPosition.goalkeeper,
    isEligible: true,
  );

  final player3 = const RegisteredPlayer(
    id: 'p-3',
    fullName: 'Mateo Fernández',
    documentId: 'DOC-103',
    shirtNumber: 8,
    position: PlayerPosition.midfielder,
    isEligible: true,
  );

  final player4 = const RegisteredPlayer(
    id: 'p-4',
    fullName: 'Sebastián Peña',
    documentId: 'DOC-104',
    shirtNumber: 4,
    position: PlayerPosition.defender,
    isEligible: false,
  );

  final team1 = TournamentTeam(
    id: 'team-1',
    tournamentId: 't-1',
    name: 'Tigres FC',
    shortCode: 'TIG',
    players: [player1, player2],
  );

  final team2 = TournamentTeam(
    id: 'team-2',
    tournamentId: 't-1',
    name: 'Águilas Doradas',
    shortCode: 'AGU',
    players: [player3],
  );

  final team3 = TournamentTeam(
    id: 'team-3',
    tournamentId: 't-2',
    name: 'Halcones Sub-20',
    shortCode: 'HAL',
    players: [player4],
  );

  group('PlayersDirectoryScreen Widget Tests', () {
    testWidgets('renders all players and tournament filter chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPlayersTestApp(
          tournaments: [tournament1, tournament2],
          teams: [team1, team2, team3],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      // All 4 players displayed
      expect(find.byKey(const Key('player_item_p-1')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-2')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-3')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-4')), findsOneWidget);

      // Chips displayed
      expect(
        find.byKey(const Key('players_tournament_chip_all')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('players_tournament_chip_t-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('players_tournament_chip_t-2')),
        findsOneWidget,
      );
    });

    testWidgets(
      'filters players by tournament chip and restores with "Todos"',
      (tester) async {
        await tester.pumpWidget(
          createPlayersTestApp(
            tournaments: [tournament1, tournament2],
            teams: [team1, team2, team3],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        // Select t-2 chip (Copa Élite Verano)
        await tester.tap(find.byKey(const Key('players_tournament_chip_t-2')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('player_item_p-1')), findsNothing);
        expect(find.byKey(const Key('player_item_p-2')), findsNothing);
        expect(find.byKey(const Key('player_item_p-3')), findsNothing);
        expect(find.byKey(const Key('player_item_p-4')), findsOneWidget);

        // Select 'Todos' chip
        await tester.tap(find.byKey(const Key('players_tournament_chip_all')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('player_item_p-1')), findsOneWidget);
        expect(find.byKey(const Key('player_item_p-2')), findsOneWidget);
        expect(find.byKey(const Key('player_item_p-3')), findsOneWidget);
        expect(find.byKey(const Key('player_item_p-4')), findsOneWidget);
      },
    );

    testWidgets('multi-field search: player name, dorsal, position, team', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPlayersTestApp(
          tournaments: [tournament1, tournament2],
          teams: [team1, team2, team3],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Search player name without accent: 'alvarez' -> matches Andrés Álvarez
      await tester.enterText(
        find.byKey(const Key('players_search_bar')),
        'alvarez',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('player_item_p-1')), findsNothing);
      expect(find.byKey(const Key('player_item_p-2')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-3')), findsNothing);
      expect(find.byKey(const Key('player_item_p-4')), findsNothing);

      // 2. Clear and search by jersey number '10'
      await tester.tap(find.byKey(const Key('search_bar_clear_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('players_search_bar')), '10');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('player_item_p-1')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-2')), findsNothing);

      // 3. Clear and search by position: 'portero'
      await tester.tap(find.byKey(const Key('search_bar_clear_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('players_search_bar')),
        'portero',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('player_item_p-2')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-1')), findsNothing);

      // 4. Clear and search by team name: 'aguilas'
      await tester.tap(find.byKey(const Key('search_bar_clear_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('players_search_bar')),
        'aguilas',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('player_item_p-3')), findsOneWidget);
      expect(find.byKey(const Key('player_item_p-1')), findsNothing);
    });

    testWidgets('shows empty state when search matches no players', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPlayersTestApp(
          tournaments: [tournament1, tournament2],
          teams: [team1, team2, team3],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('players_search_bar')),
        'Jugador Inexistente',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('players_empty_state')), findsOneWidget);
      expect(
        find.text('No se encontraron jugadores con ese criterio.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping player item opens PlayerPerformanceProfileCard', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPlayersTestApp(
          tournaments: [tournament1],
          teams: [team1],
          role: UserRole.fan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('player_item_p-1')));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPerformanceProfileCard), findsOneWidget);
    });

    testWidgets(
      'renders register player button exclusively for coach, hides for organizer, referee, player and fan',
      (tester) async {
        for (final role in UserRole.values) {
          await tester.pumpWidget(
            createPlayersTestApp(
              tournaments: [tournament1],
              teams: [team1],
              role: role,
            ),
          );
          await tester.pumpAndSettle();

          final finder = find.byKey(
            const Key('register_player_from_directory_button'),
          );
          if (role == UserRole.coach) {
            expect(finder, findsOneWidget, reason: 'Coach must see register player button');
          } else {
            expect(
              finder,
              findsNothing,
              reason: '${role.name} must NOT see register player button',
            );
          }
        }
      },
    );
  });
}
