import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_bell_action.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';

class _InMemoryStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      const LocalStorageStatus(isPersistent: false, storageNamespace: 'test');

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async => _data[key] = value;
}

class _FakeNotificationService implements NotificationService {
  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> dispatchAlert(MatchLiveAlert alert) async {}
}

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockAuthUseCase extends Mock implements AuthenticateUserUseCase {}

class _MockMatchesRepo extends Mock implements TournamentMatchesRepository {}

class _MockReportsRepo extends Mock implements MatchReportsRepository {}

class _MockTeamsRepo extends Mock implements TeamsRepository {}

class _MockLineupsRepo extends Mock implements LineupsTrackingRepository {}

class _MockTournamentsRepo extends Mock implements TournamentsRepository {}

class _TestAuthController extends AuthController {
  _TestAuthController(AuthFlowState initialState)
    : super(
        authRepository: _MockAuthRepo(),
        authenticateUserUseCase: _MockAuthUseCase(),
      ) {
    state = initialState;
  }
}

void main() {
  late LocalMatchAlertsRepository alertsRepo;
  late _MockMatchesRepo matchesRepo;
  late _MockReportsRepo reportsRepo;
  late _MockTeamsRepo teamsRepo;
  late _MockLineupsRepo lineupsRepo;
  late _MockTournamentsRepo tournamentsRepo;

  final now = DateTime(2026, 11, 25, 16, 0);

  setUpAll(() {
    registerFallbackValue(
      ChampionshipMatch(
        id: 'fb',
        tournamentId: 't-fb',
        roundNumber: 1,
        roundName: 'J1',
        homeTeamId: 'h',
        awayTeamId: 'a',
        updatedAt: now,
      ),
    );
  });

  setUp(() {
    alertsRepo = LocalMatchAlertsRepository(storage: _InMemoryStorage());
    matchesRepo = _MockMatchesRepo();
    reportsRepo = _MockReportsRepo();
    teamsRepo = _MockTeamsRepo();
    lineupsRepo = _MockLineupsRepo();
    tournamentsRepo = _MockTournamentsRepo();

    when(() => matchesRepo.loadOfficialReferees()).thenAnswer(
      (_) async => const <MatchReferee>[],
    );
    when(() => matchesRepo.loadAllMatches()).thenAnswer(
      (_) async => const <ChampionshipMatch>[],
    );
    when(() => teamsRepo.loadTeams()).thenAnswer(
      (_) async => const <TournamentTeam>[],
    );
    when(() => teamsRepo.loadTeamsForTournament(any())).thenAnswer(
      (_) async => [
        TournamentTeam(
          id: 'h-1',
          tournamentId: 't-1',
          name: 'Local FC',
          shortCode: 'LFC',
          updatedAt: now,
        ),
        TournamentTeam(
          id: 'a-1',
          tournamentId: 't-1',
          name: 'Visitante FC',
          shortCode: 'VFC',
          updatedAt: now,
        ),
      ],
    );
    when(() => reportsRepo.loadOrCreateReport(any())).thenAnswer(
      (inv) async {
        final m = inv.positionalArguments.first as ChampionshipMatch;
        return DigitalMatchReport(
          matchId: m.id,
          tournamentId: m.tournamentId,
          homeTeamId: m.homeTeamId,
          awayTeamId: m.awayTeamId,
        );
      },
    );
    when(() => reportsRepo.loadPendingSyncQueue(any())).thenAnswer(
      (_) async => const [],
    );
    when(() => lineupsRepo.loadConvocationForTeam(any(), any())).thenAnswer(
      (inv) async => MatchLineupConvocation(
        id: 'c-${inv.positionalArguments[1]}',
        tournamentId: 't-1',
        teamId: inv.positionalArguments[1] as String,
        updatedAt: now,
      ),
    );
    when(() => tournamentsRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => tournamentsRepo.loadTournaments()).thenAnswer(
      (_) async => const <ChampionshipTournament>[],
    );
  });

  Widget wrapBell({required String userId}) {
    final authCtrl = _TestAuthController(
      AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-1',
          user: UserAccount(
            id: userId,
            fullName: 'Árbitro Test',
            email: 'ref@vifutbol.com',
            activeRole: UserRole.referee,
            authorizedRoles: {UserRole.referee},
            onboardingCompleted: true,
          ),
          sessionToken: 'tok-1',
          authenticatedAt: now,
        ),
      ),
    );
    final matchesCtrl = MatchesCatalogController(
      matchesRepository: matchesRepo,
      fixtureSchedulingUseCase: FixtureSchedulingUseCase(
        matchesRepository: matchesRepo,
      ),
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => authCtrl),
        matchAlertsRepositoryProvider.overrideWithValue(alertsRepo),
        notificationServiceProvider.overrideWithValue(
          _FakeNotificationService(),
        ),
        matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
        tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
        matchReportsRepositoryProvider.overrideWithValue(reportsRepo),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [FanAlertsBellAction(userId: userId)],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets(
    'shows unread badge, opens tray with assignment details, marks read and opens DigitalMatchReportScreen',
    (tester) async {
      final assignedMatch = ChampionshipMatch(
        id: 'm-assigned',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'h-1',
        awayTeamId: 'a-1',
        refereeId: 'user-ref-1',
        status: MatchStatus.scheduled,
        updatedAt: now,
      );
      when(() => matchesRepo.loadMatchesForTournament('t-1')).thenAnswer(
        (_) async => [assignedMatch],
      );

      await alertsRepo.saveAlert(
        MatchLiveAlert(
          id: 'alert-1',
          matchId: 'm-assigned',
          tournamentId: 't-1',
          type: MatchAlertType.refereeMatchAssigned,
          title: 'Nuevo partido asignado',
          message: 'Local FC vs Visitante FC · Copa Apertura · 26/11 3:00 PM',
          timestamp: now,
          recipientUserId: 'user-ref-1',
        ),
      );

      await tester.pumpWidget(wrapBell(userId: 'user-ref-1'));
      await tester.pumpAndSettle();

      // Badge shows 1
      expect(find.text('1'), findsOneWidget);

      // Open tray
      await tester.tap(find.byKey(const Key('fan_alerts_bell_button')));
      await tester.pumpAndSettle();

      expect(find.text('Asignación arbitral'), findsOneWidget);
      expect(find.text('Nuevo partido asignado'), findsOneWidget);
      expect(
        find.text('Local FC vs Visitante FC · Copa Apertura · 26/11 3:00 PM'),
        findsOneWidget,
      );

      // Tap alert -> marks read and navigates to DigitalMatchReportScreen
      await tester.tap(find.byKey(const Key('alert_tile_alert-1')));
      await tester.pumpAndSettle();

      expect(find.byType(DigitalMatchReportScreen), findsOneWidget);

      // Navigate back and verify badge decremented to 0 (hidden)
      Navigator.of(
        tester.element(find.byType(DigitalMatchReportScreen)),
      ).pop();
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNothing);
    },
  );

  testWidgets(
    'caps badge at 99+ and falls back to PanelScreen when assigned match is unavailable',
    (tester) async {
      when(() => matchesRepo.loadMatchesForTournament('t-missing')).thenAnswer(
        (_) async => const <ChampionshipMatch>[],
      );

      for (var i = 0; i < 101; i++) {
        await alertsRepo.saveAlert(
          MatchLiveAlert(
            id: 'alert-$i',
            matchId: 'm-missing-$i',
            tournamentId: 't-missing',
            type: MatchAlertType.refereeMatchAssigned,
            title: 'Nuevo partido asignado',
            message: 'Equipo A vs Equipo B #$i',
            timestamp: now.add(Duration(seconds: i)),
            recipientUserId: 'user-ref-many',
          ),
        );
      }

      await tester.pumpWidget(wrapBell(userId: 'user-ref-many'));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fan_alerts_bell_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('alert_tile_alert-100')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelScreen), findsOneWidget);
    },
  );
}
