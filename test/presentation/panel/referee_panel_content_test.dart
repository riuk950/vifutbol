import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/referee_panel_content.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthUseCase extends Mock implements AuthenticateUserUseCase {}

class _MockMatchesRepo extends Mock implements TournamentMatchesRepository {}

class _MockTournamentsRepo extends Mock implements TournamentsRepository {}

class _MockTeamsRepo extends Mock implements TeamsRepository {}

class _MockReportsRepo extends Mock implements MatchReportsRepository {}

class _MockLineupsRepo extends Mock implements LineupsTrackingRepository {}

class _TestAuthController extends AuthController {
  _TestAuthController(AuthFlowState initialState)
    : super(
        authRepository: _MockAuthRepository(),
        authenticateUserUseCase: _MockAuthUseCase(),
      ) {
    state = initialState;
  }
}

void main() {
  late _MockMatchesRepo matchesRepo;
  late _MockTournamentsRepo tournamentsRepo;
  late _MockTeamsRepo teamsRepo;
  late _MockReportsRepo reportsRepo;
  late _MockLineupsRepo lineupsRepo;

  final now = DateTime(2026, 11, 25, 15, 0);

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
    matchesRepo = _MockMatchesRepo();
    tournamentsRepo = _MockTournamentsRepo();
    teamsRepo = _MockTeamsRepo();
    reportsRepo = _MockReportsRepo();
    lineupsRepo = _MockLineupsRepo();

    when(() => matchesRepo.loadOfficialReferees()).thenAnswer(
      (_) async => const <MatchReferee>[],
    );
    when(() => tournamentsRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => tournamentsRepo.loadTournaments()).thenAnswer(
      (_) async => [
        ChampionshipTournament(
          id: 't-1',
          name: 'Copa Metropolitana',
          category: 'Libre',
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          rules: const TournamentRulesConfig(),
          organizerId: 'org-1',
          updatedAt: now,
        ),
      ],
    );
    when(() => teamsRepo.loadTeams()).thenAnswer(
      (_) async => [
        TournamentTeam(
          id: 'team-h',
          tournamentId: 't-1',
          name: 'Atlético Norte',
          shortCode: 'ATN',
          updatedAt: now,
        ),
        TournamentTeam(
          id: 'team-a',
          tournamentId: 't-1',
          name: 'Deportivo Sur',
          shortCode: 'DPS',
          updatedAt: now,
        ),
      ],
    );
    when(() => teamsRepo.loadTeamsForTournament(any())).thenAnswer(
      (_) async => [
        TournamentTeam(
          id: 'team-h',
          tournamentId: 't-1',
          name: 'Atlético Norte',
          shortCode: 'ATN',
          updatedAt: now,
        ),
        TournamentTeam(
          id: 'team-a',
          tournamentId: 't-1',
          name: 'Deportivo Sur',
          shortCode: 'DPS',
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
        id: 'conv-${inv.positionalArguments[1]}',
        tournamentId: inv.positionalArguments[0] as String,
        teamId: inv.positionalArguments[1] as String,
        updatedAt: now,
      ),
    );
  });

  Widget wrapPanel({required UserAccount user}) {
    final authCtrl = _TestAuthController(
      AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-1',
          user: user,
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
    final tournamentsCtrl = TournamentsController(
      tournamentsRepository: tournamentsRepo,
      manageTournamentsUseCase: ManageTournamentsUseCase(tournamentsRepo),
    );
    final teamsCtrl = TeamsController(
      teamsRepository: teamsRepo,
      manageTeamsEligibilityUseCase: ManageTeamsEligibilityUseCase(
        teamsRepo,
        matchesRepo,
      ),
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => authCtrl),
        matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
        tournamentsControllerProvider.overrideWith((_) => tournamentsCtrl),
        teamsControllerProvider.overrideWith((_) => teamsCtrl),
        matchReportsRepositoryProvider.overrideWithValue(reportsRepo),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
        tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RefereePanelContent()),
      ),
    );
  }

  testWidgets(
    'loads multi-tournament assigned matches via linkedRefereeId with real team names, operational sort, filters, and opens DigitalMatchReportScreen',
    (tester) async {
      final assignedScheduled = ChampionshipMatch(
        id: 'm-sched',
        tournamentId: 't-1',
        roundNumber: 2,
        roundName: 'Jornada 2',
        homeTeamId: 'team-h',
        awayTeamId: 'team-a',
        refereeId: 'linked-ref-1',
        pitchName: 'Cancha Sintética El Poblado',
        scheduledStartTime: DateTime.utc(2026, 11, 26, 20, 0),
        status: MatchStatus.scheduled,
        updatedAt: now,
      );
      final assignedLive = ChampionshipMatch(
        id: 'm-live',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-a',
        awayTeamId: 'team-h',
        refereeId: 'user-ref-1',
        pitchName: 'Estadio Central',
        scheduledStartTime: DateTime.utc(2026, 11, 25, 19, 0),
        status: MatchStatus.inProgress,
        homeScore: 2,
        awayScore: 1,
        updatedAt: now,
      );
      final otherRefereeMatch = ChampionshipMatch(
        id: 'm-other',
        tournamentId: 't-1',
        roundNumber: 3,
        roundName: 'Jornada 3',
        homeTeamId: 'team-h',
        awayTeamId: 'team-a',
        refereeId: 'someone-else',
        status: MatchStatus.scheduled,
        updatedAt: now,
      );

      when(() => matchesRepo.loadAllMatches()).thenAnswer(
        (_) async => [assignedScheduled, otherRefereeMatch, assignedLive],
      );

      final user = UserAccount(
        id: 'user-ref-1',
        fullName: 'Árbitro Central',
        email: 'ref@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        roleProfile: const RoleProfileData(linkedRefereeId: 'linked-ref-1'),
      );

      await tester.pumpWidget(wrapPanel(user: user));
      await tester.pumpAndSettle();

      // Excludes other referee
      expect(find.byKey(const Key('referee_match_item_m-other')), findsNothing);
      expect(
        find.byKey(const Key('referee_match_item_m-live')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('referee_match_item_m-sched')),
        findsOneWidget,
      );

      // Real team names & tournament shown (no raw IDs)
      expect(find.text('Deportivo Sur vs Atlético Norte'), findsOneWidget);
      expect(find.text('Atlético Norte vs Deportivo Sur'), findsOneWidget);
      expect(find.text('Copa Metropolitana · Jornada 1'), findsOneWidget);
      expect(find.text('2 - 1'), findsOneWidget);

      // Operational order: inProgress above scheduled
      final liveY =
          tester.getTopLeft(find.byKey(const Key('referee_match_item_m-live'))).dy;
      final schedY = tester
          .getTopLeft(find.byKey(const Key('referee_match_item_m-sched')))
          .dy;
      expect(liveY, lessThan(schedY));

      // Filter chip "Programados" hides inProgress
      await tester.tap(find.byKey(const Key('referee_filter_scheduled')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('referee_match_item_m-live')), findsNothing);
      expect(
        find.byKey(const Key('referee_match_item_m-sched')),
        findsOneWidget,
      );

      // Filter chip "Finalizados" shows empty filter state
      await tester.tap(find.byKey(const Key('referee_filter_completed')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('referee_empty_matches_state')),
        findsOneWidget,
      );

      // Reset to Todos and open report
      await tester.tap(find.byKey(const Key('referee_filter_all')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('referee_open_match_report_m-sched')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DigitalMatchReportScreen), findsOneWidget);
    },
  );
}
