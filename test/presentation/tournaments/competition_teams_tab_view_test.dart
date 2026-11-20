import 'package:material_ui/material_ui.dart';
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
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_teams_tab_view.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           viewState: UiSuccessState<List<ChampionshipTournament>>(tournaments),
           tournaments: tournaments,
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  AppFailure? forcedFailure;

  @override
  Future<bool> moveTeamToGroup({
    required String teamId,
    required String groupName,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    final updated = state.teams.map((t) {
      if (t.id == teamId) {
        return t.copyWith(groupName: groupName);
      }
      return t;
    }).toList();
    state = state.copyWith(teams: updated);
    return true;
  }

  @override
  Future<bool> removeTeamFromCompetition({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (forcedFailure != null) {
      state = state.copyWith(lastFailure: forcedFailure);
      return false;
    }
    final updated = state.teams.where((t) => t.id != teamId).toList();
    state = state.copyWith(
      teams: updated,
      clearSelectedTeamId: state.selectedTeamId == teamId,
    );
    return true;
  }

  @override
  void selectTeam(String? teamId) {
    if (teamId == null) {
      state = state.copyWith(clearSelectedTeamId: true);
    } else {
      state = state.copyWith(selectedTeamId: teamId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTeamsTabTestApp({
  required ChampionshipTournament tournament,
  List<TournamentTeam> teams = const [],
  UserRole role = UserRole.organizer,
  FakeTeamsController? teamsController,
}) {
  return ProviderScope(
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
      localStorageRepositoryProvider.overrideWithValue(
        _FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        _FakeConnectivityRepository(),
      ),
      activeUserRoleProvider.overrideWith((ref) => role),
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: [tournament]),
      ),
      teamsControllerProvider.overrideWith(
        (ref) => teamsController ?? FakeTeamsController(teams: teams),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: CompetitionTeamsTabView(tournamentId: tournament.id),
      ),
    ),
  );
}

void main() {
  final mixedTournament = ChampionshipTournament(
    id: 'tour-mixed',
    name: 'Copa Mixta 2026',
    category: 'Libre',
    status: TournamentStatus.inProgress,
    format: TournamentFormat.mixedGroupsAndKnockout,
    rules: const TournamentRulesConfig(
      groupStageConfig: GroupStageConfig(groupCount: 2),
    ),
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 11, 30),
    updatedAt: DateTime(2026, 3, 1),
  );

  final leagueTournament = ChampionshipTournament(
    id: 'tour-league',
    name: 'Liga Apertura 2026',
    category: 'Primera',
    status: TournamentStatus.inProgress,
    format: TournamentFormat.league,
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 11, 30),
    updatedAt: DateTime(2026, 2, 1),
  );

  group('CompetitionTeamsTabView', () {
    testWidgets('US2: renders empty state when no teams are enrolled', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTeamsTabTestApp(tournament: mixedTournament, teams: const []),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_teams_empty_state')),
        findsOneWidget,
      );
      expect(find.text('Sin equipos inscritos'), findsOneWidget);
    });

    testWidgets(
      'US2: renders simple alphabetical list in league format with team details',
      (tester) async {
        final teamB = TournamentTeam(
          id: 'team-b',
          tournamentId: leagueTournament.id,
          name: 'Boca del Río',
          shortCode: 'BOC',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        );
        final teamA = TournamentTeam(
          id: 'team-a',
          tournamentId: leagueTournament.id,
          name: 'Atlético Central',
          shortCode: 'ATC',
          eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        );

        await tester.pumpWidget(
          createTeamsTabTestApp(
            tournament: leagueTournament,
            teams: [teamB, teamA],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_teams_tab_view')),
          findsOneWidget,
        );
        expect(find.text('Equipos Inscritos (2)'), findsOneWidget);

        // Check cards render
        expect(
          find.byKey(const Key('competition_team_card_team-a')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_team_card_team-b')),
          findsOneWidget,
        );

        // Non-organizer / league does not show group move button
        expect(
          find.byKey(const Key('competition_team_move_group_team-a')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('competition_team_remove_team-a')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'US2: renders group section headers and group badges in mixedGroupsAndKnockout',
      (tester) async {
        final team1 = TournamentTeam(
          id: 'team-1',
          tournamentId: mixedTournament.id,
          name: 'Club Águilas',
          shortCode: 'AGU',
          groupName: 'Grupo A',
        );
        final team2 = TournamentTeam(
          id: 'team-2',
          tournamentId: mixedTournament.id,
          name: 'Club Halcones',
          shortCode: 'HAL',
          groupName: 'Grupo B',
        );

        await tester.pumpWidget(
          createTeamsTabTestApp(
            tournament: mixedTournament,
            teams: [team1, team2],
            role: UserRole.fan,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_team_group_header_Grupo A')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_team_group_header_Grupo B')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('competition_team_group_badge_team-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_team_group_badge_team-2')),
          findsOneWidget,
        );
      },
    );

    testWidgets('US3: Organizer can open group move dialog and relocate team', (
      tester,
    ) async {
      final team = TournamentTeam(
        id: 'team-mv',
        tournamentId: mixedTournament.id,
        name: 'Deportivo Naranja',
        shortCode: 'DNA',
        groupName: 'Grupo A',
      );
      final controller = FakeTeamsController(teams: [team]);

      await tester.pumpWidget(
        createTeamsTabTestApp(
          tournament: mixedTournament,
          teams: [team],
          role: UserRole.organizer,
          teamsController: controller,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Move group button visible
      final moveBtn = find.byKey(
        const Key('competition_team_move_group_team-mv'),
      );
      expect(moveBtn, findsOneWidget);

      // 2. Tap to open dialog
      await tester.tap(moveBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_move_group_dialog')),
        findsOneWidget,
      );

      // 3. Select Grupo B
      final groupBOption = find.byKey(
        const Key('competition_move_group_option_Grupo B'),
      );
      expect(groupBOption, findsOneWidget);
      await tester.tap(groupBOption);
      await tester.pumpAndSettle();

      // 4. Dialog is dismissed and team is updated to Grupo B
      expect(
        find.byKey(const Key('competition_move_group_dialog')),
        findsNothing,
      );
      expect(controller.state.teams.first.groupName, equals('Grupo B'));
    });

    testWidgets(
      'US3: Organizer can open remove confirmation dialog and remove team',
      (tester) async {
        final team = TournamentTeam(
          id: 'team-del',
          tournamentId: mixedTournament.id,
          name: 'Deportivo Descartable',
          shortCode: 'DDE',
        );
        final controller = FakeTeamsController(teams: [team]);

        await tester.pumpWidget(
          createTeamsTabTestApp(
            tournament: mixedTournament,
            teams: [team],
            role: UserRole.organizer,
            teamsController: controller,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Remove button visible
        final removeBtn = find.byKey(
          const Key('competition_team_remove_team-del'),
        );
        expect(removeBtn, findsOneWidget);

        // 2. Tap remove button
        await tester.tap(removeBtn);
        await tester.pumpAndSettle();

        // 3. Confirmation dialog visible
        expect(
          find.byKey(const Key('competition_remove_team_confirm_dialog')),
          findsOneWidget,
        );

        // 4. Confirm removal
        await tester.tap(
          find.byKey(const Key('competition_remove_team_confirm_button')),
        );
        await tester.pumpAndSettle();

        // 5. Dialog dismissed and team removed
        expect(
          find.byKey(const Key('competition_remove_team_confirm_dialog')),
          findsNothing,
        );
        expect(controller.state.teams.isEmpty, isTrue);
      },
    );

    testWidgets(
      'US3: When removal fails due to played matches, shows error SnackBar',
      (tester) async {
        final team = TournamentTeam(
          id: 'team-err',
          tournamentId: mixedTournament.id,
          name: 'Deportivo Bloqueado',
          shortCode: 'DBL',
        );
        final controller = FakeTeamsController(teams: [team])
          ..forcedFailure = const TeamEligibilityValidationFailure(
            TeamEligibilityErrorCode.teamHasPlayedMatches,
            'No se puede retirar un equipo que ya tiene partidos en curso o finalizados',
          );

        await tester.pumpWidget(
          createTeamsTabTestApp(
            tournament: mixedTournament,
            teams: [team],
            role: UserRole.organizer,
            teamsController: controller,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('competition_team_remove_team-err')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('competition_remove_team_confirm_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No se puede retirar un equipo que ya tiene partidos en curso o finalizados',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Polish (T019): renders without RenderFlex overflow at 320x640 with 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final team1 = TournamentTeam(
          id: 'team-1',
          tournamentId: mixedTournament.id,
          name: 'Deportivo Muy Largo de la Ciudad Deportiva',
          shortCode: 'DMLC',
          groupName: 'Grupo A',
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createTeamsTabTestApp(
              tournament: mixedTournament,
              teams: [team1],
              role: UserRole.organizer,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_teams_tab_view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_team_card_team-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HU 22.3: disables team mutation buttons while isSaving is true and supports pull-to-refresh',
      (tester) async {
        final team1 = TournamentTeam(
          id: 'team-guard',
          tournamentId: mixedTournament.id,
          name: 'Equipo Guard',
          shortCode: 'EGD',
          groupName: 'Grupo A',
        );
        final savingController = FakeTeamsController(teams: [team1]);
        savingController.state = savingController.state.copyWith(
          isSaving: true,
        );

        var refreshCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentsControllerProvider.overrideWith(
                (ref) =>
                    FakeTournamentsController(tournaments: [mixedTournament]),
              ),
              teamsControllerProvider.overrideWith((ref) => savingController),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: Scaffold(
                body: CompetitionTeamsTabView(
                  tournamentId: mixedTournament.id,
                  onRefresh: () async {
                    refreshCount++;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final moveButton = tester.widget<IconButton>(
          find.byKey(const Key('competition_team_move_group_team-guard')),
        );
        final removeButton = tester.widget<IconButton>(
          find.byKey(const Key('competition_team_remove_team-guard')),
        );
        expect(moveButton.onPressed, isNull);
        expect(removeButton.onPressed, isNull);

        await tester.fling(
          find.byKey(const Key('competition_teams_tab_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();
        expect(refreshCount, 1);
      },
    );
  });
}
