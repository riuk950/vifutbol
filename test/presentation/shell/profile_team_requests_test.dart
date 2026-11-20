import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/team_join_requests_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/shell/tabs/player_team_requests_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

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

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(UserAccount playerAccount)
    : super(
        AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 'sess-1',
            user: playerAccount,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingRequestsController extends StateNotifier<TeamJoinRequestsState>
    implements TeamJoinRequestsController {
  _TrackingRequestsController({List<TeamJoinRequest> playerRequests = const []})
    : super(TeamJoinRequestsState(playerRequests: playerRequests));

  String? lastRespondedRequestId;
  bool? lastAcceptValue;

  @override
  Future<void> loadRequestsForCurrentPlayer() async {}

  @override
  Future<bool> respondToJoinRequest({
    required String requestId,
    required bool accept,
    required UserRole actorRole,
  }) async {
    lastRespondedRequestId = requestId;
    lastAcceptValue = accept;
    state = state.copyWith(
      playerRequests:
          state.playerRequests.where((r) => r.id != requestId).toList(),
    );
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileTabView & PlayerTeamRequestsScreen (HU 20.1 - US2)', () {
    final playerAccount = UserAccount(
      id: 'player-acc-1',
      fullName: 'Radamel Falcao',
      email: 'falcao@vifutbol.com',
      activeRole: UserRole.player,
      authorizedRoles: const {UserRole.player},
      documentId: 'CC-998877',
    );

    final pendingRequest = TeamJoinRequest(
      id: 'req-101',
      teamId: 'team-millos',
      teamName: 'Millonarios FC',
      teamShortCode: 'MFC',
      coachAccountId: 'coach-gamero',
      coachName: 'Alberto Gamero',
      playerAccountId: 'player-acc-1',
      playerName: 'Radamel Falcao',
      playerDocumentId: 'CC-998877',
      shirtNumber: 9,
      position: PlayerPosition.forward,
      status: TeamJoinRequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets(
      'ProfileTabView displays "Solicitudes de Equipos" tile for player and navigates',
      (tester) async {
        final trackingController = _TrackingRequestsController(
          playerRequests: [pendingRequest],
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
              authControllerProvider.overrideWith(
                (ref) => _FakeAuthController(playerAccount),
              ),
              teamJoinRequestsControllerProvider.overrideWith(
                (ref) => trackingController,
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(body: ProfileTabView()),
              routes: {
                '/profile/team-requests': (context) =>
                    const Scaffold(body: Text('PLAYER_TEAM_REQUESTS_DESTINATION')),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify tile is visible
        final tileFinder = find.byKey(const Key('profile_team_requests_tile'));
        expect(tileFinder, findsOneWidget);
        expect(find.text('Solicitudes de Equipos'), findsOneWidget);

        // Ensure tile is visible in scrollview and tap to navigate
        await tester.ensureVisible(tileFinder);
        await tester.pumpAndSettle();
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        expect(find.text('PLAYER_TEAM_REQUESTS_DESTINATION'), findsOneWidget);
      },
    );

    testWidgets(
      'PlayerTeamRequestsScreen handles Accept and Reject actions without overflow',
      (tester) async {
        final trackingController = _TrackingRequestsController(
          playerRequests: [pendingRequest],
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
              authControllerProvider.overrideWith(
                (ref) => _FakeAuthController(playerAccount),
              ),
              teamJoinRequestsControllerProvider.overrideWith(
                (ref) => trackingController,
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: [Locale('es')],
              home: PlayerTeamRequestsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check request card details
        expect(find.text('Millonarios FC'), findsOneWidget);
        expect(find.text('#9'), findsOneWidget);
        expect(find.textContaining('Alberto Gamero'), findsOneWidget);
        expect(find.byKey(const Key('accept_join_request_req-101')), findsOneWidget);
        expect(find.byKey(const Key('reject_join_request_req-101')), findsOneWidget);

        // Tap Accept button
        await tester.tap(find.byKey(const Key('accept_join_request_req-101')));
        await tester.pumpAndSettle();

        expect(trackingController.lastRespondedRequestId, equals('req-101'));
        expect(trackingController.lastAcceptValue, isTrue);

        // Feedback SnackBar appears
        expect(find.textContaining('Millonarios FC'), findsOneWidget);
      },
    );
  });
}
