import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/referee_panel_content.dart';

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

class FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  FakeAuthController({required AuthSession session})
    : super(AuthFlowState(status: AuthStatus.authenticated, session: session));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createRefereePanelApp({
  List<ChampionshipMatch>? matches,
  String currentUserId = 'ref-101',
}) {
  final user = UserAccount(
    id: currentUserId,
    email: 'referee@vifutbol.com',
    fullName: 'Árbitro Oficial',
    activeRole: UserRole.referee,
  );
  final session = AuthSession(
    sessionId: 'session-1',
    user: user,
    sessionToken: 'token-1',
    authenticatedAt: DateTime.now(),
  );

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
      activeUserRoleProvider.overrideWith((ref) => UserRole.referee),
      authControllerProvider.overrideWith(
        (ref) => FakeAuthController(session: session),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: matches ?? []),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: const PanelScreen(),
    ),
  );
}

void main() {
  group('RefereePanelContent Widget Tests (US3 - P3)', () {
    testWidgets(
      'renders Referee AppBar title and lists assigned matches with Digital Report action',
      (tester) async {
        final assignedMatch = ChampionshipMatch(
          id: 'match-ref-1',
          tournamentId: 't-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          refereeId: 'ref-101',
          refereeName: 'Árbitro Oficial',
          pitchName: 'Cancha Sintética Principal',
          status: MatchStatus.inProgress,
        );

        await tester.pumpWidget(
          createRefereePanelApp(matches: [assignedMatch]),
        );
        await tester.pumpAndSettle();

        // Verify AppBar title
        expect(find.text('Panel Arbitral'), findsOneWidget);
        expect(find.byType(RefereePanelContent), findsOneWidget);

        // Verify Assigned Match Item
        expect(
          find.byKey(const Key('referee_assigned_matches_list')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('referee_match_item_match-ref-1')),
          findsOneWidget,
        );
        expect(find.text('TEAM-A vs TEAM-B'), findsOneWidget);
        expect(find.text('Cancha Sintética Principal'), findsOneWidget);

        // Verify Action Button
        final reportButton = find.byKey(
          const Key('referee_open_match_report_match-ref-1'),
        );
        expect(reportButton, findsOneWidget);
        expect(find.text('Acta Digital'), findsOneWidget);

        // Tap "Acta Digital" opens DigitalMatchReportScreen
        await tester.tap(reportButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DigitalMatchReportScreen), findsOneWidget);
      },
    );

    testWidgets('renders empty state when referee has no assigned matches', (
      tester,
    ) async {
      final unassignedMatch = ChampionshipMatch(
        id: 'match-other-1',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        refereeId: 'other-ref-999',
        status: MatchStatus.scheduled,
      );

      await tester.pumpWidget(
        createRefereePanelApp(matches: [unassignedMatch]),
      );
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(
        find.byKey(const Key('referee_empty_matches_state')),
        findsOneWidget,
      );
      expect(find.text('Sin partidos asignados'), findsOneWidget);
      expect(
        find.text('Actualmente no tienes partidos designados para dirigir.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('referee_assigned_matches_list')),
        findsNothing,
      );
    });
  });
}
