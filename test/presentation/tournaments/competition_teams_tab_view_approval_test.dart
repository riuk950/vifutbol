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
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_teams_tab_view.dart';

import '../../test_helpers/teams_eligibility_test_helper.dart';

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

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController(ChampionshipTournament tournament)
    : super(
        TournamentsCatalogState(
          viewState: UiSuccessState<List<ChampionshipTournament>>([tournament]),
          tournaments: [tournament],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController(List<TournamentTeam> teams)
    : super(TeamsCatalogState(teams: teams));

  bool approveCalled = false;

  @override
  Future<bool> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    approveCalled = true;
    final updated = state.teams.map((t) {
      if (t.id == teamId) {
        return t.copyWith(eligibilityStatus: TeamEligibilityStatus.eligible);
      }
      return t;
    }).toList();
    state = state.copyWith(teams: updated);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required ChampionshipTournament tournament,
  required List<TournamentTeam> teams,
  _FakeTeamsController? teamsController,
}) {
  final fakeTeams = teamsController ?? _FakeTeamsController(teams);
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
      tournamentsControllerProvider.overrideWith(
        (ref) => _FakeTournamentsController(tournament),
      ),
      teamsControllerProvider.overrideWith((ref) => fakeTeams),
      activeUserRoleProvider.overrideWithValue(UserRole.organizer),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: CompetitionTeamsTabView(tournamentId: tournament.id),
      ),
    ),
  );
}

void main() {
  group('CompetitionTeamsTabView Team Approval Widget Tests (HU 16.3 / US1)', () {
    testWidgets(
      'shows warning dialog when tapping Habilitar Equipo on team with < 11 players',
      (tester) async {
        final tournament = createTestTournament(minPlayers: 11);
        final team9 = createTestTeam(
          id: 'team-9',
          tournamentId: tournament.id,
          name: 'Incomplete FC',
          shortCode: 'INC',
          playerCount: 9,
          status: TeamEligibilityStatus.pendingVerification,
        );

        final controller = _FakeTeamsController([team9]);

        await tester.pumpWidget(
          _buildTestApp(
            tournament: tournament,
            teams: [team9],
            teamsController: controller,
          ),
        );
        await tester.pumpAndSettle();

        final approveBtn = find.byKey(
          Key('competition_team_action_approve_${team9.id}'),
        );
        expect(approveBtn, findsOneWidget);

        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_team_insufficient_quota_dialog')),
          findsOneWidget,
        );
        expect(
          find.text(
            'El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: 9)',
          ),
          findsOneWidget,
        );

        final confirmBtn = find.byKey(
          const Key('competition_team_dialog_confirm_button'),
        );
        expect(confirmBtn, findsOneWidget);

        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_team_insufficient_quota_dialog')),
          findsNothing,
        );
        expect(controller.approveCalled, isFalse);
      },
    );

    testWidgets(
      'successfully approves team with >= 11 players and updates status',
      (tester) async {
        final tournament = createTestTournament(minPlayers: 11);
        final team11 = createTestTeam(
          id: 'team-11',
          tournamentId: tournament.id,
          name: 'Complete FC',
          shortCode: 'COM',
          playerCount: 11,
          status: TeamEligibilityStatus.pendingVerification,
        );

        final controller = _FakeTeamsController([team11]);

        await tester.pumpWidget(
          _buildTestApp(
            tournament: tournament,
            teams: [team11],
            teamsController: controller,
          ),
        );
        await tester.pumpAndSettle();

        final approveBtn = find.byKey(
          Key('competition_team_action_approve_${team11.id}'),
        );
        expect(approveBtn, findsOneWidget);

        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        expect(controller.approveCalled, isTrue);
        expect(
          find.byKey(const Key('competition_team_insufficient_quota_dialog')),
          findsNothing,
        );
        expect(
          find.text(
            'El equipo ha sido habilitado oficialmente para el campeonato',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
