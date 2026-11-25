import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
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

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthUseCase extends Mock implements AuthenticateUserUseCase {}

class _MockReportsRepo extends Mock implements MatchReportsRepository {}

class _MockTeamsRepo extends Mock implements TeamsRepository {}

class _MockLineupsRepo extends Mock implements LineupsTrackingRepository {}

class _MockMatchesRepo extends Mock implements TournamentMatchesRepository {}

class _MockTournamentsRepo extends Mock implements TournamentsRepository {}

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
  late _MockReportsRepo reportsRepo;
  late _MockTeamsRepo teamsRepo;
  late _MockLineupsRepo lineupsRepo;
  late _MockMatchesRepo matchesRepo;
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
    registerFallbackValue(
      DigitalMatchReport(
        matchId: 'fb',
        tournamentId: 't-fb',
        homeTeamId: 'h',
        awayTeamId: 'a',
      ),
    );
    registerFallbackValue(<MatchEvent>[]);
    registerFallbackValue(
      PlayerInternalTracking(playerId: 'p', teamId: 'h', tournamentId: 't'),
    );
  });

  setUp(() {
    reportsRepo = _MockReportsRepo();
    teamsRepo = _MockTeamsRepo();
    lineupsRepo = _MockLineupsRepo();
    matchesRepo = _MockMatchesRepo();
    tournamentsRepo = _MockTournamentsRepo();

    when(() => teamsRepo.loadTeamsForTournament(any())).thenAnswer(
      (_) async => [
        TournamentTeam(
          id: 'home-1',
          tournamentId: 't-1',
          name: 'Local FC',
          shortCode: 'LFC',
          updatedAt: now,
          players: const [
            RegisteredPlayer(
              id: 'p-1',
              fullName: 'Jugador Uno',
              documentId: '1001',
              position: PlayerPosition.forward,
              shirtNumber: 10,
              isEligible: true,
            ),
          ],
        ),
        TournamentTeam(
          id: 'away-1',
          tournamentId: 't-1',
          name: 'Visitante FC',
          shortCode: 'VFC',
          updatedAt: now,
          players: const [
            RegisteredPlayer(
              id: 'p-2',
              fullName: 'Jugador Dos',
              documentId: '1002',
              position: PlayerPosition.defender,
              shirtNumber: 4,
              isEligible: true,
            ),
          ],
        ),
      ],
    );

    when(() => reportsRepo.loadPendingSyncQueue(any())).thenAnswer(
      (_) async => const [],
    );
    when(() => matchesRepo.saveMatch(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as ChampionshipMatch,
    );
    when(
      () => reportsRepo.saveReport(
        any(),
        newlyCreatedEvents: any(named: 'newlyCreatedEvents'),
      ),
    ).thenAnswer(
      (inv) async => inv.positionalArguments.first as DigitalMatchReport,
    );
    when(() => tournamentsRepo.loadTournaments()).thenAnswer(
      (_) async => const <ChampionshipTournament>[],
    );
  });

  Widget wrapScreen({
    required ChampionshipMatch match,
    required UserAccount user,
  }) {
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
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => authCtrl),
        matchReportsRepositoryProvider.overrideWithValue(reportsRepo),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
        tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DigitalMatchReportScreen(initialMatch: match),
      ),
    );
  }

  testWidgets(
    'shows unconfirmed convocation banner, allows starting match and saving referee observations',
    (tester) async {
      final match = ChampionshipMatch(
        id: 'm-1',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'home-1',
        awayTeamId: 'away-1',
        refereeId: 'ref-linked-1',
        status: MatchStatus.scheduled,
        updatedAt: now,
      );
      when(() => lineupsRepo.loadConvocationForTeam(any(), any())).thenAnswer(
        (inv) async => MatchLineupConvocation(
          id: 'conv-${inv.positionalArguments[1]}',
          tournamentId: 't-1',
          teamId: inv.positionalArguments[1] as String,
          updatedAt: now,
        ),
      );
      when(() => reportsRepo.loadOrCreateReport(any())).thenAnswer(
        (_) async => DigitalMatchReport(
          matchId: 'm-1',
          tournamentId: 't-1',
          homeTeamId: 'home-1',
          awayTeamId: 'away-1',
        ),
      );

      final assignedReferee = UserAccount(
        id: 'u-ref-1',
        fullName: 'Árbitro Asignado',
        email: 'ref@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        roleProfile: const RoleProfileData(linkedRefereeId: 'ref-linked-1'),
      );

      await tester.pumpWidget(wrapScreen(match: match, user: assignedReferee));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('digital_match_report_unconfirmed_convocation_banner'),
        ),
        findsOneWidget,
      );

      // Start match (non-blocking even without confirmed convocation)
      await tester.tap(find.text('Iniciar Partido'));
      await tester.pumpAndSettle();
      expect(find.text('EN JUEGO'), findsOneWidget);

      // Save referee observations
      await tester.enterText(
        find.byKey(const Key('digital_match_report_observations_field')),
        'Iluminación adecuada y juego limpio',
      );
      await tester.tap(
        find.byKey(const Key('digital_match_report_save_observations_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Observaciones guardadas en el acta'), findsOneWidget);
    },
  );

  testWidgets(
    'shows unauthorized read-only banner when another referee opens an assigned match',
    (tester) async {
      final match = ChampionshipMatch(
        id: 'm-2',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'home-1',
        awayTeamId: 'away-1',
        refereeId: 'assigned-ref-99',
        status: MatchStatus.scheduled,
        updatedAt: now,
      );
      when(() => lineupsRepo.loadConvocationForTeam(any(), any())).thenAnswer(
        (inv) async => MatchLineupConvocation(
          id: 'conv-${inv.positionalArguments[1]}',
          tournamentId: 't-1',
          teamId: inv.positionalArguments[1] as String,
          updatedAt: now,
          starterPlayerIds: const ['p-1'],
        ),
      );
      when(() => reportsRepo.loadOrCreateReport(any())).thenAnswer(
        (_) async => DigitalMatchReport(
          matchId: 'm-2',
          tournamentId: 't-1',
          homeTeamId: 'home-1',
          awayTeamId: 'away-1',
          currentPeriod: MatchPeriod.closed,
          closedAt: null,
        ).copyWith(currentPeriod: MatchPeriod.notStarted),
      );

      final otherReferee = UserAccount(
        id: 'u-other',
        fullName: 'Otro Árbitro',
        email: 'other@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        roleProfile: const RoleProfileData(linkedRefereeId: 'other-ref-1'),
      );

      await tester.pumpWidget(wrapScreen(match: match, user: otherReferee));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('digital_match_report_unauthorized_banner')),
        findsOneWidget,
      );
      expect(find.text('Iniciar Partido'), findsNothing);
      expect(
        find.byKey(const Key('digital_match_report_observations_field')),
        findsNothing,
      );
    },
  );
}
