import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/use_cases/manage_digital_match_report_use_case.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

class _MockMatchReportsRepository extends Mock
    implements MatchReportsRepository {}

class _MockTournamentMatchesRepository extends Mock
    implements TournamentMatchesRepository {}

class _MockLineupsTrackingRepository extends Mock
    implements LineupsTrackingRepository {}

class _MockTournamentsRepository extends Mock implements TournamentsRepository {}

void main() {
  late _MockMatchReportsRepository reportsRepo;
  late _MockTournamentMatchesRepository matchesRepo;
  late _MockLineupsTrackingRepository lineupsRepo;
  late _MockTournamentsRepository tournamentsRepo;
  late ManageDigitalMatchReportUseCase useCase;

  final now = DateTime(2026, 11, 25, 16, 0);
  final match = ChampionshipMatch(
    id: 'match-1',
    tournamentId: 't-1',
    roundNumber: 1,
    roundName: 'Jornada 1',
    homeTeamId: 'home-1',
    awayTeamId: 'away-1',
    refereeId: 'ref-profile-1',
    status: MatchStatus.scheduled,
    updatedAt: now,
  );

  const scorer = RegisteredPlayer(
    id: 'p-1',
    fullName: 'Juan Pérez',
    documentId: '1010',
    position: PlayerPosition.forward,
    shirtNumber: 9,
    isEligible: true,
  );

  setUpAll(() {
    registerFallbackValue(match);
    registerFallbackValue(
      DigitalMatchReport(
        matchId: 'match-1',
        tournamentId: 't-1',
        homeTeamId: 'home-1',
        awayTeamId: 'away-1',
      ),
    );
    registerFallbackValue(<MatchEvent>[]);
    registerFallbackValue(
      PlayerInternalTracking(
        playerId: 'p-1',
        teamId: 'home-1',
        tournamentId: 't-1',
      ),
    );
  });

  setUp(() {
    reportsRepo = _MockMatchReportsRepository();
    matchesRepo = _MockTournamentMatchesRepository();
    lineupsRepo = _MockLineupsTrackingRepository();
    tournamentsRepo = _MockTournamentsRepository();
    useCase = ManageDigitalMatchReportUseCase(
      matchReportsRepository: reportsRepo,
      tournamentMatchesRepository: matchesRepo,
      lineupsTrackingRepository: lineupsRepo,
      tournamentsRepository: tournamentsRepo,
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
    when(
      () => lineupsRepo.loadTrackingForTeam(any(), any(), any()),
    ).thenAnswer((_) async => const <PlayerInternalTracking>[]);
    when(() => lineupsRepo.savePlayerTracking(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as PlayerInternalTracking,
    );
  });

  group('ManageDigitalMatchReportUseCase - HU 26.1', () {
    test('runs full lifecycle: start, goal, observations, close, and blocks edits after closure', () async {
      final initial = DigitalMatchReport(
        matchId: match.id,
        tournamentId: match.tournamentId,
        homeTeamId: match.homeTeamId,
        awayTeamId: match.awayTeamId,
      );

      final started = await useCase.transitionMatchPeriod(
        activeRole: UserRole.referee,
        match: match,
        currentReport: initial,
        targetPeriod: MatchPeriod.firstHalf,
        actorUserId: 'user-1',
        actorRefereeId: 'ref-profile-1',
        now: now,
      );
      expect(started.currentPeriod, MatchPeriod.firstHalf);
      verify(
        () => matchesRepo.saveMatch(
          any(
            that: isA<ChampionshipMatch>().having(
              (m) => m.status,
              'status',
              MatchStatus.inProgress,
            ),
          ),
        ),
      ).called(1);

      final withGoal = await useCase.recordGoalEvent(
        activeRole: UserRole.referee,
        match: match.copyWith(status: MatchStatus.inProgress),
        currentReport: started,
        teamId: 'home-1',
        scorer: scorer,
        minute: 12,
        actorUserId: 'user-1',
        actorRefereeId: 'ref-profile-1',
        now: now.add(const Duration(minutes: 12)),
      );
      expect(withGoal.homeScore, 1);

      final withObs = await useCase.updateRefereeObservations(
        activeRole: UserRole.referee,
        match: match.copyWith(status: MatchStatus.inProgress),
        currentReport: withGoal,
        observations: 'Cancha en excelente estado',
        actorUserId: 'user-1',
        actorRefereeId: 'ref-profile-1',
        now: now.add(const Duration(minutes: 45)),
      );
      expect(withObs.refereeObservations, 'Cancha en excelente estado');

      final closed = await useCase.closeOfficialMatchReport(
        activeRole: UserRole.referee,
        userId: 'user-1',
        actorRefereeId: 'ref-profile-1',
        match: match.copyWith(status: MatchStatus.inProgress),
        currentReport: withObs,
        now: now.add(const Duration(minutes: 90)),
      );
      expect(closed.isClosed, isTrue);
      expect(closed.currentPeriod, MatchPeriod.closed);
      expect(closed.refereeObservations, 'Cancha en excelente estado');

      await expectLater(
        () => useCase.updateRefereeObservations(
          activeRole: UserRole.referee,
          match: match.copyWith(status: MatchStatus.completed),
          currentReport: closed,
          observations: 'Intento post cierre',
          actorUserId: 'user-1',
          actorRefereeId: 'ref-profile-1',
        ),
        throwsA(
          isA<MatchReportValidationFailure>().having(
            (e) => e.code,
            'code',
            MatchReportErrorCode.reportAlreadyClosed,
          ),
        ),
      );
    });

    test('enforces assigned referee ownership and allows organizer override', () async {
      final report = DigitalMatchReport(
        matchId: match.id,
        tournamentId: match.tournamentId,
        homeTeamId: match.homeTeamId,
        awayTeamId: match.awayTeamId,
      );

      await expectLater(
        () => useCase.transitionMatchPeriod(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          targetPeriod: MatchPeriod.firstHalf,
          actorUserId: 'other-user',
          actorRefereeId: 'other-ref',
        ),
        throwsA(
          isA<MatchReportValidationFailure>().having(
            (e) => e.code,
            'code',
            MatchReportErrorCode.unauthorizedRole,
          ),
        ),
      );

      final orgStarted = await useCase.transitionMatchPeriod(
        activeRole: UserRole.organizer,
        match: match,
        currentReport: report,
        targetPeriod: MatchPeriod.firstHalf,
        actorUserId: 'org-user',
      );
      expect(orgStarted.currentPeriod, MatchPeriod.firstHalf);
    });
  });
}
