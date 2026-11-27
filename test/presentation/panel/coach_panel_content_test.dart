import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';

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

class _TrackingTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _TrackingTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  String? selectedTeamId;

  @override
  void selectTeam(String? teamId) {
    selectedTeamId = teamId;
    state = state.copyWith(selectedTeamId: teamId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController() : super(const MatchesCatalogState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CoachPanelContent Navigation to TeamRosterDetailScreen (HU 20.1 - US1)', () {
    testWidgets(
      'Tapping "Gestionar Planilla" selects active team and navigates to /tournaments/teams/detail',
      (tester) async {
        final trackingTeamsController = _TrackingTeamsController(
          teams: [
            TournamentTeam(
              id: 'team-coach-123',
              tournamentId: 't-1',
              name: 'Atlético Juvenil',
              shortCode: 'ATJ',
              coachId: 'coach-seed-1',
              players: const [
                RegisteredPlayer(
                  id: 'p-1',
                  fullName: 'Andrés Suárez',
                  shirtNumber: 9,
                  position: PlayerPosition.forward,
                  documentId: 'DOC-112233',
                  isEligible: true,
                ),
              ],
            ),
          ],
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
              teamsControllerProvider.overrideWith(
                (ref) => trackingTeamsController,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => _FakeMatchesCatalogController(),
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(body: CoachPanelContent()),
              routes: {
                '/tournaments/teams/detail': (context) => const Scaffold(
                  body: Text('TEAM_ROSTER_DETAIL_SCREEN_MOCK'),
                ),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify button exists
        final manageRosterButtonFinder = find.byKey(
          const Key('coach_action_manage_roster'),
        );
        expect(manageRosterButtonFinder, findsOneWidget);

        // Tap the button
        await tester.ensureVisible(manageRosterButtonFinder);
        await tester.tap(manageRosterButtonFinder);
        await tester.pumpAndSettle();

        // Verify that selectTeam was invoked with team id
        expect(trackingTeamsController.selectedTeamId, equals('team-coach-123'));

        // Verify that navigation occurred to /tournaments/teams/detail
        expect(find.text('TEAM_ROSTER_DETAIL_SCREEN_MOCK'), findsOneWidget);
      },
    );
  });
}
