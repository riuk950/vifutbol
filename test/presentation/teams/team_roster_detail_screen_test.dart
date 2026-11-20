import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/team_join_requests_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/teams/team_roster_detail_screen.dart';

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

class _FakeTournamentsController
    extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           viewState: UiSuccessState(tournaments),
           tournaments: tournaments,
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _TrackingTeamsController({
    List<TournamentTeam> teams = const [],
    String? selectedTeamId,
  }) : super(
         TeamsCatalogState(teams: teams, selectedTeamId: selectedTeamId),
       );

  bool approveCalled = false;

  @override
  Future<bool> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    approveCalled = true;
    final updatedTeams = state.teams.map((t) {
      if (t.id == teamId) {
        return t.copyWith(
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: t.players.map((p) => p.copyWith(isEligible: true)).toList(),
        );
      }
      return t;
    }).toList();

    state = state.copyWith(teams: updatedTeams);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequestsController extends StateNotifier<TeamJoinRequestsState>
    implements TeamJoinRequestsController {
  _FakeRequestsController() : super(const TeamJoinRequestsState());

  @override
  Future<void> loadRequestsForTeam(String teamId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TeamRosterDetailScreen Quota and Eligibility Tests (HU 20.1 - US3)', () {
    final tournament = ChampionshipTournament(
      id: 'tour-cup-1',
      name: 'Copa Élite 2026',
      category: 'Libre',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 60)),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      updatedAt: DateTime.now(),
    );

    testWidgets(
      'Displays "No elegible / Faltan jugadores" indicator and disables button when players < 11',
      (tester) async {
        final eightPlayers = List.generate(
          8,
          (i) => RegisteredPlayer(
            id: 'p-$i',
            fullName: 'Player $i',
            documentId: 'DOC-$i',
            shirtNumber: i + 1,
            position: PlayerPosition.midfielder,
          ),
        );

        final incompleteTeam = TournamentTeam(
          id: 'team-incomplete',
          tournamentId: 'tour-cup-1',
          name: 'Deportivo Incompleto',
          shortCode: 'INC',
          coachId: 'coach-1',
          players: eightPlayers,
        );

        final controller = _TrackingTeamsController(
          teams: [incompleteTeam],
          selectedTeamId: 'team-incomplete',
        );

        await tester.pumpWidget(
          ProviderScope(
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
              activeUserRoleProvider.overrideWith((ref) => UserRole.coach),
              tournamentsControllerProvider.overrideWith(
                (ref) => _FakeTournamentsController(tournaments: [tournament]),
              ),
              teamsControllerProvider.overrideWith((ref) => controller),
              teamJoinRequestsControllerProvider.overrideWith(
                (ref) => _FakeRequestsController(),
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const TeamRosterDetailScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify indicators
        expect(find.text('No elegible / Faltan jugadores'), findsOneWidget);
        expect(find.text('8/11 jugadores mínimos'), findsOneWidget);

        // Verify approve button is disabled
        final approveButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('approve_team_eligibility_button')),
        );
        expect(approveButton.onPressed, isNull);
      },
    );

    testWidgets(
      'Enables "Habilitar para Competiciones" when players >= 11 and transitions team to eligible on tap',
      (tester) async {
        final elevenPlayers = List.generate(
          11,
          (i) => RegisteredPlayer(
            id: 'p-$i',
            fullName: 'Player $i',
            documentId: 'DOC-$i',
            shirtNumber: i + 1,
            position: PlayerPosition.forward,
          ),
        );

        final readyTeam = TournamentTeam(
          id: 'team-ready',
          tournamentId: 'tour-cup-1',
          name: 'Deportivo Completo',
          shortCode: 'COM',
          coachId: 'coach-1',
          players: elevenPlayers,
          eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        );

        final controller = _TrackingTeamsController(
          teams: [readyTeam],
          selectedTeamId: 'team-ready',
        );

        await tester.pumpWidget(
          ProviderScope(
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
              activeUserRoleProvider.overrideWith((ref) => UserRole.coach),
              tournamentsControllerProvider.overrideWith(
                (ref) => _FakeTournamentsController(tournaments: [tournament]),
              ),
              teamsControllerProvider.overrideWith((ref) => controller),
              teamJoinRequestsControllerProvider.overrideWith(
                (ref) => _FakeRequestsController(),
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const TeamRosterDetailScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify quota progress indicates ready squad
        expect(find.text('No elegible / Faltan jugadores'), findsNothing);

        final approveButtonFinder = find.byKey(
          const Key('approve_team_eligibility_button'),
        );
        expect(approveButtonFinder, findsOneWidget);

        final approveButton = tester.widget<ElevatedButton>(approveButtonFinder);
        expect(approveButton.onPressed, isNotNull);

        // Tap the button
        await tester.tap(approveButtonFinder);
        await tester.pumpAndSettle();

        expect(controller.approveCalled, isTrue);
        expect(find.text('Habilitado'), findsOneWidget);
      },
    );
  });
}
