import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/digital_match_report_controller.dart';
import 'package:vifutbol/application/use_cases/manage_digital_match_report_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

class MockLocalStorageRepository implements LocalStorageRepository {
  final Map<String, dynamic> _memory = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return const LocalStorageStatus(
      isPersistent: true,
      storageNamespace: 'test',
    );
  }

  @override
  Future<String?> readString(String key) async => _memory[key] as String?;

  @override
  Future<void> writeString(String key, String value) async {
    _memory[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _memory.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('ManageDigitalMatchReportUseCase & Controller Tests', () {
    late MockLocalStorageRepository storage;
    late EnvironmentConfig config;
    late LocalMatchReportsRepository matchReportsRepo;
    late LocalTournamentMatchesRepository matchesRepo;
    late LocalTeamsRepository teamsRepo;
    late LocalLineupsTrackingRepository lineupsRepo;
    late LocalTournamentsRepository tournamentsRepo;
    late ManageDigitalMatchReportUseCase useCase;

    late ChampionshipTournament tournament;
    late ChampionshipMatch match;
    late TournamentTeam homeTeam;
    late TournamentTeam awayTeam;

    late RegisteredPlayer pHome1;
    late RegisteredPlayer pHome2;
    late RegisteredPlayer pHome3;
    late RegisteredPlayer pAway1;
    late RegisteredPlayer pAway2;

    setUp(() async {
      storage = MockLocalStorageRepository();
      config = EnvironmentConfig.development();

      matchReportsRepo = LocalMatchReportsRepository(
        storage: storage,
        config: config,
      );
      matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: config,
      );
      teamsRepo = LocalTeamsRepository(storage: storage, config: config);
      lineupsRepo = LocalLineupsTrackingRepository(
        storage: storage,
        config: config,
      );
      tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );

      useCase = ManageDigitalMatchReportUseCase(
        matchReportsRepository: matchReportsRepo,
        tournamentMatchesRepository: matchesRepo,
        lineupsTrackingRepository: lineupsRepo,
        tournamentsRepository: tournamentsRepo,
      );

      // Seed tournament
      tournament = ChampionshipTournament(
        id: 'tournament-test-1',
        name: 'Torneo Apertura 2026',
        category: 'Libre',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        format: TournamentFormat.league,
        updatedAt: DateTime.now(),
      );
      await tournamentsRepo.saveTournament(tournament);

      // Seed players
      pHome1 = const RegisteredPlayer(
        id: 'p-home-1',
        fullName: 'Carlos Valderrama',
        shirtNumber: 10,
        documentId: 'CC-101',
        position: PlayerPosition.midfielder,
        isEligible: true,
      );
      pHome2 = const RegisteredPlayer(
        id: 'p-home-2',
        fullName: 'Faustino Asprilla',
        shirtNumber: 11,
        documentId: 'CC-102',
        position: PlayerPosition.forward,
        isEligible: true,
      );
      pHome3 = const RegisteredPlayer(
        id: 'p-home-3',
        fullName: 'Freddy Rincón',
        shirtNumber: 19,
        documentId: 'CC-103',
        position: PlayerPosition.midfielder,
        isEligible: true,
      );
      pAway1 = const RegisteredPlayer(
        id: 'p-away-1',
        fullName: 'Dávinson Sánchez',
        shirtNumber: 5,
        documentId: 'CC-201',
        position: PlayerPosition.defender,
        isEligible: true,
      );
      pAway2 = const RegisteredPlayer(
        id: 'p-away-2',
        fullName: 'James Rodríguez',
        shirtNumber: 10,
        documentId: 'CC-202',
        position: PlayerPosition.midfielder,
        isEligible: true,
      );

      homeTeam = TournamentTeam(
        id: 'team-atn',
        tournamentId: tournament.id,
        name: 'Atlético Nacional',
        shortCode: 'ATN',
        primaryColorHex: 0xFF008000,
        players: [pHome1, pHome2, pHome3],
        updatedAt: DateTime.now(),
      );
      awayTeam = TournamentTeam(
        id: 'team-rsc',
        tournamentId: tournament.id,
        name: 'Real Santa Cruz',
        shortCode: 'RSC',
        primaryColorHex: 0xFFFFFFFF,
        players: [pAway1, pAway2],
        updatedAt: DateTime.now(),
      );

      await teamsRepo.saveTeam(homeTeam);
      await teamsRepo.saveTeam(awayTeam);

      match = ChampionshipMatch(
        id: 'match-1',
        tournamentId: tournament.id,
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        status: MatchStatus.scheduled,
        updatedAt: DateTime.now(),
      );
      await matchesRepo.saveMatch(match);
    });

    test(
      'referee starts match into firstHalf and transitions through halfTime and secondHalf',
      () async {
        final initialReport = await useCase.loadOrCreateReport(match);
        expect(initialReport.currentPeriod, MatchPeriod.notStarted);

        // Start match
        final firstHalfReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: initialReport,
          targetPeriod: MatchPeriod.firstHalf,
          activeRole: UserRole.referee,
        );
        expect(firstHalfReport.currentPeriod, MatchPeriod.firstHalf);
        expect(firstHalfReport.periodStartedAt, isNotNull);

        // Transition to half-time
        final halfTimeReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: firstHalfReport,
          targetPeriod: MatchPeriod.halfTime,
          activeRole: UserRole.referee,
        );
        expect(halfTimeReport.currentPeriod, MatchPeriod.halfTime);
        expect(
          halfTimeReport.elapsedSecondsBeforeCurrentPeriod,
          greaterThanOrEqualTo(0),
        );

        // Transition to second-half
        final secondHalfReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: halfTimeReport,
          targetPeriod: MatchPeriod.secondHalf,
          activeRole: UserRole.referee,
        );
        expect(secondHalfReport.currentPeriod, MatchPeriod.secondHalf);
      },
    );

    test('recording a goal increments team score and timeline', () async {
      final initialReport = await useCase.loadOrCreateReport(match);
      final firstHalfReport = await useCase.transitionMatchPeriod(
        match: match,
        currentReport: initialReport,
        targetPeriod: MatchPeriod.firstHalf,
        activeRole: UserRole.referee,
      );

      final reportWithGoal = await useCase.recordGoalEvent(
        match: match,
        currentReport: firstHalfReport,
        teamId: homeTeam.id,
        scorer: pHome2,
        assistant: pHome1,
        minute: 23,
        activeRole: UserRole.referee,
      );

      expect(reportWithGoal.homeScore, 1);
      expect(reportWithGoal.awayScore, 0);
      expect(
        reportWithGoal.events
            .where((e) => e.type == MatchEventType.goal)
            .length,
        1,
      );
      final event = reportWithGoal.events.firstWhere(
        (e) => e.type == MatchEventType.goal,
      );
      expect(event.primaryPlayerId, 'p-home-2');
      expect(event.secondaryPlayerId, 'p-home-1');
      expect(event.minute, 23);
    });

    test(
      'rule: second yellow card automatically expels player and adds secondYellowRedCard event',
      () async {
        final initialReport = await useCase.loadOrCreateReport(match);
        final firstHalfReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: initialReport,
          targetPeriod: MatchPeriod.firstHalf,
          activeRole: UserRole.referee,
        );

        // First yellow card to Dávinson Sánchez #5
        final reportYellow1 = await useCase.recordDisciplinaryCard(
          match: match,
          currentReport: firstHalfReport,
          teamId: awayTeam.id,
          player: pAway1,
          isDirectRed: false,
          minute: 15,
          activeRole: UserRole.referee,
        );

        expect(reportYellow1.yellowCardCountForPlayer('p-away-1'), 1);
        expect(reportYellow1.isPlayerExpelled('p-away-1'), isFalse);

        // Second yellow card to Dávinson Sánchez #5 at minute 38
        final reportYellow2 = await useCase.recordDisciplinaryCard(
          match: match,
          currentReport: reportYellow1,
          teamId: awayTeam.id,
          player: pAway1,
          isDirectRed: false,
          minute: 38,
          activeRole: UserRole.referee,
        );

        // Should now have second yellow + automatic secondYellowRedCard
        expect(reportYellow2.yellowCardCountForPlayer('p-away-1'), 2);
        expect(reportYellow2.isPlayerExpelled('p-away-1'), isTrue);
        expect(reportYellow2.expelledPlayerIds, contains('p-away-1'));

        final redEvent = reportYellow2.events.firstWhere(
          (e) => e.type == MatchEventType.secondYellowRedCard,
        );
        expect(redEvent.primaryPlayerId, 'p-away-1');
        expect(redEvent.minute, 38);

        // Attempting to register another event with expelled player should fail
        expect(
          () => useCase.recordGoalEvent(
            match: match,
            currentReport: reportYellow2,
            teamId: awayTeam.id,
            scorer: pAway1,
            minute: 40,
            activeRole: UserRole.referee,
          ),
          throwsA(
            isA<MatchReportValidationFailure>().having(
              (f) => f.code,
              'code',
              MatchReportErrorCode.playerAlreadyExpelled,
            ),
          ),
        );
      },
    );

    test(
      'undo live event removes both yellow card and linked secondYellowRedCard',
      () async {
        final initialReport = await useCase.loadOrCreateReport(match);
        final firstHalfReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: initialReport,
          targetPeriod: MatchPeriod.firstHalf,
          activeRole: UserRole.referee,
        );

        final reportYellow1 = await useCase.recordDisciplinaryCard(
          match: match,
          currentReport: firstHalfReport,
          teamId: awayTeam.id,
          player: pAway1,
          isDirectRed: false,
          minute: 15,
          activeRole: UserRole.referee,
          now: DateTime(2026, 1, 1, 10, 15),
        );

        final reportYellow2 = await useCase.recordDisciplinaryCard(
          match: match,
          currentReport: reportYellow1,
          teamId: awayTeam.id,
          player: pAway1,
          isDirectRed: false,
          minute: 38,
          activeRole: UserRole.referee,
          now: DateTime(2026, 1, 1, 10, 38),
        );

        final secondYellow = reportYellow2.events.firstWhere(
          (e) => e.type == MatchEventType.yellowCard && e.minute == 38,
        );

        // Undo second yellow card
        final restoredReport = await useCase.removeMatchEvent(
          match: match,
          currentReport: reportYellow2,
          eventId: secondYellow.id,
          activeRole: UserRole.referee,
        );

        expect(restoredReport.yellowCardCountForPlayer('p-away-1'), 1);
        expect(restoredReport.isPlayerExpelled('p-away-1'), isFalse);
      },
    );

    test(
      'closing match report locks report, sets match completed and propagates stats',
      () async {
        final initialReport = await useCase.loadOrCreateReport(match);
        final firstHalfReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: initialReport,
          targetPeriod: MatchPeriod.firstHalf,
          activeRole: UserRole.referee,
        );

        final reportWithGoal = await useCase.recordGoalEvent(
          match: match,
          currentReport: firstHalfReport,
          teamId: homeTeam.id,
          scorer: pHome2,
          minute: 23,
          activeRole: UserRole.referee,
        );

        final fullTimeReport = await useCase.transitionMatchPeriod(
          match: match,
          currentReport: reportWithGoal,
          targetPeriod: MatchPeriod.fullTime,
          activeRole: UserRole.referee,
        );

        // Close official match report
        final closedReport = await useCase.closeOfficialMatchReport(
          match: match,
          currentReport: fullTimeReport,
          activeRole: UserRole.referee,
          userId: 'ref-user-1',
        );

        expect(closedReport.isClosed, isTrue);
        expect(closedReport.currentPeriod, MatchPeriod.closed);

        // Match in repository is now completed with scores
        final updatedMatches = await matchesRepo.loadMatchesForTournament(
          tournament.id,
        );
        final updatedMatch = updatedMatches.firstWhere((m) => m.id == match.id);
        expect(updatedMatch.status, MatchStatus.completed);
        expect(updatedMatch.homeScore, 1);
        expect(updatedMatch.awayScore, 0);

        // Any further modifications fail
        expect(
          () => useCase.recordGoalEvent(
            match: updatedMatch,
            currentReport: closedReport,
            teamId: homeTeam.id,
            scorer: pHome1,
            minute: 90,
            activeRole: UserRole.referee,
          ),
          throwsA(
            isA<MatchReportValidationFailure>().having(
              (f) => f.code,
              'code',
              MatchReportErrorCode.reportAlreadyClosed,
            ),
          ),
        );
      },
    );

    test(
      'unauthorized non-referee role cannot record events or close report',
      () async {
        final initialReport = await useCase.loadOrCreateReport(match);

        expect(
          () => useCase.transitionMatchPeriod(
            match: match,
            currentReport: initialReport,
            targetPeriod: MatchPeriod.firstHalf,
            activeRole: UserRole.player,
          ),
          throwsA(
            isA<MatchReportValidationFailure>().having(
              (f) => f.code,
              'code',
              MatchReportErrorCode.unauthorizedRole,
            ),
          ),
        );

        expect(
          () => useCase.recordGoalEvent(
            match: match,
            currentReport: initialReport,
            teamId: homeTeam.id,
            scorer: pHome1,
            minute: 10,
            activeRole: UserRole.fan,
          ),
          throwsA(
            isA<MatchReportValidationFailure>().having(
              (f) => f.code,
              'code',
              MatchReportErrorCode.unauthorizedRole,
            ),
          ),
        );
      },
    );

    test(
      'DigitalMatchReportController loads match, toggles offline mode, and synchronizes',
      () async {
        final controller = DigitalMatchReportController(
          useCase: useCase,
          teamsRepository: teamsRepo,
          lineupsTrackingRepository: lineupsRepo,
          matchReportsRepository: matchReportsRepo,
          matchesRepository: matchesRepo,
        );

        await controller.loadReportForMatch(match);

        expect(controller.state.match?.id, match.id);
        expect(controller.state.homeTeam?.id, homeTeam.id);
        expect(controller.state.awayTeam?.id, awayTeam.id);
        expect(controller.state.report?.isClosed, isFalse);
        expect(controller.state.isOfflineMode, isFalse);

        // Toggle offline mode
        controller.setOfflineMode(true);
        expect(controller.state.isOfflineMode, isTrue);

        // Transition to first half
        await controller.transitionPeriod(
          MatchPeriod.firstHalf,
          activeRole: UserRole.referee,
        );
        expect(controller.state.report?.currentPeriod, MatchPeriod.firstHalf);

        // Record goal offline
        await controller.recordGoal(
          activeRole: UserRole.referee,
          teamId: homeTeam.id,
          scorer: pHome2,
          minute: 12,
        );

        // 1 period transition event + 1 goal event = 2 queued events
        expect(controller.state.report?.homeScore, 1);
        expect(controller.state.pendingSyncEventsCount, 2);

        // Reconnect and synchronize
        await controller.synchronizeOfflineQueue();
        expect(controller.state.pendingSyncEventsCount, 0);
        expect(
          controller.state.report?.events.every((e) => e.isSynced),
          isTrue,
        );
      },
    );
  });
}
