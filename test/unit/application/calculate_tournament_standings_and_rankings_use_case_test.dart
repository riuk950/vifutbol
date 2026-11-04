import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart';
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
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

class _InMemoryStorage implements LocalStorageRepository {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('CalculateTournamentStandingsAndRankingsUseCase Unit Tests', () {
    late _InMemoryStorage storage;
    late EnvironmentConfig config;
    late LocalTournamentsRepository tournamentsRepo;
    late LocalTeamsRepository teamsRepo;
    late LocalTournamentMatchesRepository matchesRepo;
    late LocalMatchReportsRepository reportsRepo;
    late LocalLineupsTrackingRepository lineupsRepo;
    late ManageDigitalMatchReportUseCase reportUseCase;
    late CalculateTournamentStandingsAndRankingsUseCase standingsUseCase;

    final baseDate = DateTime(2026, 11, 4, 15, 0);

    setUp(() {
      storage = _InMemoryStorage();
      config = EnvironmentConfig.production();
      tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );
      teamsRepo = LocalTeamsRepository(storage: storage, config: config);
      matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: config,
      );
      reportsRepo = LocalMatchReportsRepository(
        storage: storage,
        config: config,
      );
      lineupsRepo = LocalLineupsTrackingRepository(
        storage: storage,
        config: config,
      );

      reportUseCase = ManageDigitalMatchReportUseCase(
        matchReportsRepository: reportsRepo,
        tournamentMatchesRepository: matchesRepo,
        lineupsTrackingRepository: lineupsRepo,
        tournamentsRepository: tournamentsRepo,
        teamsRepository: teamsRepo,
      );

      standingsUseCase = CalculateTournamentStandingsAndRankingsUseCase(
        tournamentsRepository: tournamentsRepo,
        teamsRepository: teamsRepo,
        tournamentMatchesRepository: matchesRepo,
        matchReportsRepository: reportsRepo,
        lineupsTrackingRepository: lineupsRepo,
        localStorageRepository: storage,
      );
    });

    test(
      'Closing an official match report updates league standings, scorers, assists, and Fair Play deterministically',
      () async {
        final tournament = ChampionshipTournament(
          id: 't-league-100',
          name: 'Liga Oficial Test',
          category: 'Libre',
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 30)),
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          updatedAt: baseDate,
        );
        await tournamentsRepo.saveTournament(tournament);

        const pHomeScorer = RegisteredPlayer(
          id: 'p-h1',
          fullName: 'Luis Díaz',
          documentId: '101',
          shirtNumber: 7,
          position: PlayerPosition.forward,
          isEligible: true,
        );
        const pHomeAssist = RegisteredPlayer(
          id: 'p-h2',
          fullName: 'Juan Cuadrado',
          documentId: '102',
          shirtNumber: 11,
          position: PlayerPosition.midfielder,
          isEligible: true,
        );
        const pAwayPlayer = RegisteredPlayer(
          id: 'p-a1',
          fullName: 'Enner Valencia',
          documentId: '201',
          shirtNumber: 13,
          position: PlayerPosition.forward,
          isEligible: true,
        );

        final homeTeam = TournamentTeam(
          id: 'team-home',
          tournamentId: tournament.id,
          name: 'Equipo Local',
          shortCode: 'LOC',
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: const [pHomeScorer, pHomeAssist],
        );
        final awayTeam = TournamentTeam(
          id: 'team-away',
          tournamentId: tournament.id,
          name: 'Equipo Visitante',
          shortCode: 'VIS',
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: const [pAwayPlayer],
        );
        await teamsRepo.saveTeam(homeTeam);
        await teamsRepo.saveTeam(awayTeam);

        final match = ChampionshipMatch(
          id: 'm-100',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: homeTeam.id,
          awayTeamId: awayTeam.id,
          status: MatchStatus.scheduled,
        );
        await matchesRepo.saveMatch(match);

        var report = await reportUseCase.loadOrCreateReport(match);
        report = await reportUseCase.transitionMatchPeriod(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          targetPeriod: MatchPeriod.firstHalf,
          now: baseDate,
        );
        report = await reportUseCase.recordGoalEvent(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          teamId: homeTeam.id,
          scorer: pHomeScorer,
          assistant: pHomeAssist,
          minute: 15,
          now: baseDate.add(const Duration(minutes: 15)),
        );
        report = await reportUseCase.recordGoalEvent(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          teamId: homeTeam.id,
          scorer: pHomeScorer,
          minute: 40,
          now: baseDate.add(const Duration(minutes: 40)),
        );
        report = await reportUseCase.recordGoalEvent(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          teamId: awayTeam.id,
          scorer: pAwayPlayer,
          minute: 60,
          now: baseDate.add(const Duration(minutes: 60)),
        );
        report = await reportUseCase.recordDisciplinaryCard(
          activeRole: UserRole.referee,
          match: match,
          currentReport: report,
          teamId: awayTeam.id,
          player: pAwayPlayer,
          isDirectRed: false,
          minute: 70,
          now: baseDate.add(const Duration(minutes: 70)),
        );

        await reportUseCase.closeOfficialMatchReport(
          activeRole: UserRole.referee,
          userId: 'ref-1',
          match: match,
          currentReport: report,
          now: baseDate.add(const Duration(minutes: 90)),
        );

        final snapshot = await standingsUseCase.execute(tournament.id);
        final rows = snapshot.mainStandingsTable.rows;

        expect(rows.length, 2);
        expect(rows[0].teamId, homeTeam.id);
        expect(rows[0].played, 1);
        expect(rows[0].won, 1);
        expect(rows[0].goalsFor, 2);
        expect(rows[0].goalsAgainst, 1);
        expect(rows[0].goalDifference, 1);
        expect(rows[0].points, 3);

        expect(rows[1].teamId, awayTeam.id);
        expect(rows[1].points, 0);
        expect(rows[1].fairPlayPenaltyPoints, -1);

        expect(snapshot.rankings.topScorers.first.playerId, 'p-h1');
        expect(snapshot.rankings.topScorers.first.goals, 2);
        expect(snapshot.rankings.topAssists.first.playerId, 'p-h2');
        expect(snapshot.rankings.topAssists.first.assists, 1);
      },
    );

    test(
      'Closing a knockout cup match automatically advances winner to next round match in repository',
      () async {
        final tournament = ChampionshipTournament(
          id: 't-cup-200',
          name: 'Copa Eliminatoria Test',
          category: 'Libre',
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 15)),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.inProgress,
          rules: const TournamentRulesConfig(
            knockoutConfig: KnockoutStageConfig(
              startingRound: KnockoutRound.semiFinals,
              directPenaltyShootoutOnDraw: true,
            ),
          ),
          updatedAt: baseDate,
        );
        await tournamentsRepo.saveTournament(tournament);

        final teams = [
          TournamentTeam(
            id: 't-1',
            tournamentId: tournament.id,
            name: 'Equipo Alfa',
            shortCode: 'ALF',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
          TournamentTeam(
            id: 't-2',
            tournamentId: tournament.id,
            name: 'Equipo Beta',
            shortCode: 'BET',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
          TournamentTeam(
            id: 't-3',
            tournamentId: tournament.id,
            name: 'Equipo Gamma',
            shortCode: 'GAM',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
          TournamentTeam(
            id: 't-4',
            tournamentId: tournament.id,
            name: 'Equipo Delta',
            shortCode: 'DEL',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
        ];
        for (final t in teams) {
          await teamsRepo.saveTeam(t);
        }

        final sf1 = ChampionshipMatch(
          id: 'match-${tournament.id}-ko-semiFinals-1',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Semifinales',
          homeTeamId: 't-1',
          awayTeamId: 't-2',
          status: MatchStatus.inProgress,
          homeScore: 1,
          awayScore: 1,
        );
        final sf2 = ChampionshipMatch(
          id: 'match-${tournament.id}-ko-semiFinals-2',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Semifinales',
          homeTeamId: 't-3',
          awayTeamId: 't-4',
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 0,
        );
        await matchesRepo.saveMatchesBatch([sf1, sf2]);

        final reportSf1 = await reportUseCase.loadOrCreateReport(sf1);
        // Close SF1 with penalty shootout 5 - 4 in favor of t-2 (Equipo Beta)
        await reportUseCase.closeOfficialMatchReport(
          activeRole: UserRole.referee,
          userId: 'ref-1',
          match: sf1,
          currentReport: reportSf1.copyWith(homeScore: 1, awayScore: 1),
          homePenaltyScore: 4,
          awayPenaltyScore: 5,
          now: baseDate,
        );

        final snapshot = await standingsUseCase.execute(tournament.id);
        final bracket = snapshot.knockoutBracket!;
        expect(bracket.rounds.length, 2);
        // Final match now has t-2 (Beta) vs t-3 (Gamma)
        final finalTie = bracket.rounds[1].ties.first;
        expect(finalTie.homeTeamId, 't-2');
        expect(finalTie.awayTeamId, 't-3');
      },
    );

    test(
      'HU 8.2: Calculates playerProfilesById, teamDetailedStatsById, and persists offline profile cache',
      () async {
        final tournament = ChampionshipTournament(
          id: 't-stats-82',
          name: 'Torneo Estadísticas 2026',
          category: 'Libre',
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 30)),
          format: TournamentFormat.league,
          rules: const TournamentRulesConfig(yellowCardSuspensionLimit: 3),
          updatedAt: baseDate,
        );
        await tournamentsRepo.saveTournament(tournament);

        final p1 = const RegisteredPlayer(
          id: 'pl-1',
          fullName: 'Andrés Iniesta',
          documentId: 'DOC-1',
          shirtNumber: 8,
          position: PlayerPosition.midfielder,
          isEligible: true,
        );
        final p2 = const RegisteredPlayer(
          id: 'pl-2',
          fullName: 'Xavi Hernández',
          documentId: 'DOC-2',
          shirtNumber: 6,
          position: PlayerPosition.midfielder,
          isEligible: true,
        );

        final team = TournamentTeam(
          id: 'team-fc',
          tournamentId: tournament.id,
          name: 'Barca FC',
          shortCode: 'BAR',
          players: [p1, p2],
        );
        await teamsRepo.saveTeam(team);

        // Execute use case with current user id = pl-1
        final snapshot = await standingsUseCase.execute(
          tournament.id,
          currentUserId: 'pl-1',
        );

        expect(snapshot.playerProfilesById.containsKey('pl-1'), isTrue);
        expect(snapshot.playerProfilesById.containsKey('pl-2'), isTrue);
        expect(snapshot.teamDetailedStatsById.containsKey('team-fc'), isTrue);

        final profileP1 = snapshot.playerProfilesById['pl-1']!;
        expect(profileP1.matchesPlayed, 0);
        expect(profileP1.formattedGoalsAverage, '0.00');
        expect(profileP1.hasParticipations, isFalse);

        final teamStats = snapshot.teamDetailedStatsById['team-fc']!;
        expect(teamStats.recentForm, isEmpty);
        expect(teamStats.squadStats.length, 2);

        // Verify offline cache persisted
        final cachedJson = await storage.readString(
          CalculateTournamentStandingsAndRankingsUseCase
              .cachedProfileStorageKey,
        );
        expect(cachedJson, isNotNull);
        expect(cachedJson!.contains('Andrés Iniesta'), isTrue);

        // Query without currentUserId and verify cached profile loads from storage
        final snapshotCached = await standingsUseCase.execute(tournament.id);
        expect(snapshotCached.cachedMyPlayerProfile, isNotNull);
        expect(
          snapshotCached.cachedMyPlayerProfile!.fullName,
          'Andrés Iniesta',
        );
      },
    );
  });
}
