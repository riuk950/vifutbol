import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/standings_calculator_service.dart';

void main() {
  group('StandingsCalculatorService Unit Tests', () {
    const calculator = StandingsCalculatorService();
    final baseDate = DateTime(2026, 11, 1);

    ChampionshipTournament buildTournament({
      TournamentFormat format = TournamentFormat.league,
      TournamentRulesConfig rules = const TournamentRulesConfig(),
    }) {
      return ChampionshipTournament(
        id: 't-league-1',
        name: 'Liga Oficial ViFutbol',
        category: 'Libre',
        startDate: baseDate,
        endDate: baseDate.add(const Duration(days: 60)),
        format: format,
        status: TournamentStatus.inProgress,
        rules: rules,
        updatedAt: baseDate,
      );
    }

    TournamentTeam buildTeam(String id, String name, String code) {
      return TournamentTeam(
        id: id,
        tournamentId: 't-league-1',
        name: name,
        shortCode: code,
        eligibilityStatus: TeamEligibilityStatus.eligible,
        updatedAt: baseDate,
      );
    }

    test(
      'US1 Scenario 1: Calculates PJ, PG, PE, PP, GF, GC, DG, PTS from completed matches and ignores non-completed matches',
      () {
        final tournament = buildTournament();
        final homeTeam = buildTeam('team-1', 'Equipo Local', 'LOC');
        final awayTeam = buildTeam('team-2', 'Equipo Visitante', 'VIS');

        final matches = [
          ChampionshipMatch(
            id: 'm-1',
            tournamentId: 't-league-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-1',
            awayTeamId: 'team-2',
            status: MatchStatus.completed,
            homeScore: 2,
            awayScore: 1,
          ),
          // In-progress match must be ignored (FR-001)
          ChampionshipMatch(
            id: 'm-2',
            tournamentId: 't-league-1',
            roundNumber: 2,
            roundName: 'Jornada 2',
            homeTeamId: 'team-2',
            awayTeamId: 'team-1',
            status: MatchStatus.inProgress,
            homeScore: 4,
            awayScore: 0,
          ),
        ];

        final table = calculator.calculateTable(
          tournament: tournament,
          teams: [homeTeam, awayTeam],
          matches: matches,
          closedReports: const [],
        );

        expect(table.completedMatchesCount, 1);
        expect(table.rows.length, 2);

        final first = table.rows[0];
        expect(first.position, 1);
        expect(first.teamId, 'team-1');
        expect(first.played, 1);
        expect(first.won, 1);
        expect(first.drawn, 0);
        expect(first.lost, 0);
        expect(first.goalsFor, 2);
        expect(first.goalsAgainst, 1);
        expect(first.goalDifference, 1);
        expect(first.points, 3);

        final second = table.rows[1];
        expect(second.position, 2);
        expect(second.teamId, 'team-2');
        expect(second.played, 1);
        expect(second.won, 0);
        expect(second.drawn, 0);
        expect(second.lost, 1);
        expect(second.goalsFor, 1);
        expect(second.goalsAgainst, 2);
        expect(second.goalDifference, -1);
        expect(second.points, 0);
      },
    );

    test(
      'US1 Scenario 2a & 2b: Resolves ties by Goal Difference first, then Goals For',
      () {
        final tournament = buildTournament();
        final teamA = buildTeam('team-a', 'Equipo A', 'EQA');
        final teamB = buildTeam('team-b', 'Equipo B', 'EQB');
        final teamC = buildTeam('team-c', 'Equipo C', 'EQC');

        // Both Team A and Team B beat Team C, earning 3 points each:
        // Case 1: Team A has DG +3 (3-0), Team B has DG +2 (2-0) -> Team A first
        final matchesCase1 = [
          ChampionshipMatch(
            id: 'm-1',
            tournamentId: 't-league-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-c',
            status: MatchStatus.completed,
            homeScore: 3,
            awayScore: 0,
          ),
          ChampionshipMatch(
            id: 'm-2',
            tournamentId: 't-league-1',
            roundNumber: 2,
            roundName: 'Jornada 2',
            homeTeamId: 'team-b',
            awayTeamId: 'team-c',
            status: MatchStatus.completed,
            homeScore: 2,
            awayScore: 0,
          ),
        ];

        final table1 = calculator.calculateTable(
          tournament: tournament,
          teams: [teamB, teamA, teamC],
          matches: matchesCase1,
          closedReports: const [],
        );

        expect(table1.rows[0].teamId, 'team-a');
        expect(table1.rows[1].teamId, 'team-b');

        // Case 2: Identical DG (+2 vs +2), but Team B has more Goals For (4-2 vs 2-0) -> Team B first
        final matchesCase2 = [
          ChampionshipMatch(
            id: 'm-1',
            tournamentId: 't-league-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-c',
            status: MatchStatus.completed,
            homeScore: 2,
            awayScore: 0,
          ),
          ChampionshipMatch(
            id: 'm-2',
            tournamentId: 't-league-1',
            roundNumber: 2,
            roundName: 'Jornada 2',
            homeTeamId: 'team-b',
            awayTeamId: 'team-c',
            status: MatchStatus.completed,
            homeScore: 4,
            awayScore: 2,
          ),
        ];

        final table2 = calculator.calculateTable(
          tournament: tournament,
          teams: [teamA, teamB, teamC],
          matches: matchesCase2,
          closedReports: const [],
        );

        expect(table2.rows[0].teamId, 'team-b');
        expect(table2.rows[1].teamId, 'team-a');
      },
    );

    test(
      'US1 Scenario 2c & Clarification: Resolves tie via Head-to-Head when mutual winner exists, or skips immediately to Fair Play (-1/-3/-3) when mutual match was drawn or unplayed',
      () {
        final tournament = buildTournament();
        final teamA = buildTeam('team-a', 'Equipo A', 'EQA');
        final teamB = buildTeam('team-b', 'Equipo B', 'EQB');

        // Team A and Team B played a 1-1 draw (identical PTS=1, DG=0, GF=1, H2H=drawn).
        // Therefore, headToHead is skipped immediately and Fair Play breaks the tie!
        final match = ChampionshipMatch(
          id: 'm-ab',
          tournamentId: 't-league-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.completed,
          homeScore: 1,
          awayScore: 1,
        );

        // Team A has 1 direct red card (-3) and 1 yellow card (-1) = -4 penalty points
        // Team B has 2 yellow cards (-2) = -2 penalty points -> Team B ranks higher!
        final closedReport = DigitalMatchReport(
          matchId: 'm-ab',
          tournamentId: 't-league-1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          homeScore: 1,
          awayScore: 1,
          currentPeriod: MatchPeriod.closed,
          closedAt: baseDate,
          events: [
            MatchEvent(
              id: 'ev-1',
              matchId: 'm-ab',
              type: MatchEventType.directRedCard,
              minute: 30,
              teamId: 'team-a',
              primaryPlayerId: 'p-a1',
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-2',
              matchId: 'm-ab',
              type: MatchEventType.yellowCard,
              minute: 40,
              teamId: 'team-a',
              primaryPlayerId: 'p-a2',
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-3',
              matchId: 'm-ab',
              type: MatchEventType.yellowCard,
              minute: 50,
              teamId: 'team-b',
              primaryPlayerId: 'p-b1',
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-4',
              matchId: 'm-ab',
              type: MatchEventType.yellowCard,
              minute: 60,
              teamId: 'team-b',
              primaryPlayerId: 'p-b2',
              createdAt: baseDate,
            ),
          ],
        );

        final table = calculator.calculateTable(
          tournament: tournament,
          teams: [teamA, teamB],
          matches: [match],
          closedReports: [closedReport],
        );

        expect(table.rows[0].teamId, 'team-b');
        expect(table.rows[0].fairPlayPenaltyPoints, -2);
        expect(table.rows[1].teamId, 'team-a');
        expect(table.rows[1].fairPlayPenaltyPoints, -4);
      },
    );

    test(
      'FR-003 Head-to-Head winner breaks tie when points, DG, and GF are equal',
      () {
        final tournament = buildTournament();
        final teamA = buildTeam('team-a', 'Equipo A', 'EQA');
        final teamB = buildTeam('team-b', 'Equipo B', 'EQB');
        final teamC = buildTeam('team-c', 'Equipo C', 'EQC');

        // Team B beat Team A 1-0; Team A beat Team C 1-0; Team C beat Team B 1-0.
        // All 3 have 3 pts, DG=0, GF=1. Between A and B, B won the head-to-head match 1-0.
        final matches = [
          ChampionshipMatch(
            id: 'm-1',
            tournamentId: 't-league-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-b',
            awayTeamId: 'team-a',
            status: MatchStatus.completed,
            homeScore: 1,
            awayScore: 0,
          ),
          ChampionshipMatch(
            id: 'm-2',
            tournamentId: 't-league-1',
            roundNumber: 2,
            roundName: 'Jornada 2',
            homeTeamId: 'team-a',
            awayTeamId: 'team-c',
            status: MatchStatus.completed,
            homeScore: 1,
            awayScore: 0,
          ),
          ChampionshipMatch(
            id: 'm-3',
            tournamentId: 't-league-1',
            roundNumber: 3,
            roundName: 'Jornada 3',
            homeTeamId: 'team-c',
            awayTeamId: 'team-b',
            status: MatchStatus.completed,
            homeScore: 1,
            awayScore: 0,
          ),
        ];

        final table = calculator.calculateTable(
          tournament: tournament,
          teams: [teamA, teamB, teamC],
          matches: matches,
          closedReports: const [],
        );
        final idxA = table.rows.indexWhere((r) => r.teamId == 'team-a');
        final idxB = table.rows.indexWhere((r) => r.teamId == 'team-b');
        expect(idxB, lessThan(idxA));
      },
    );

    test(
      'FR-004 Group stage calculation produces independent tables per group',
      () {
        final tournament = buildTournament(
          format: TournamentFormat.mixedGroupsAndKnockout,
          rules: const TournamentRulesConfig(
            groupStageConfig: GroupStageConfig(
              groupCount: 2,
              advancingPerGroup: 1,
            ),
          ),
        );
        final teams = [
          buildTeam('t-1', 'Alfa', 'ALF'),
          buildTeam('t-2', 'Beta', 'BET'),
          buildTeam('t-3', 'Gamma', 'GAM'),
          buildTeam('t-4', 'Delta', 'DEL'),
        ];

        final groupTables = calculator.calculateGroupStageTables(
          tournament: tournament,
          teams: teams,
          matches: const [],
          closedReports: const [],
        );

        expect(groupTables.length, 2);
        expect(groupTables[0].groupName, 'Grupo A');
        expect(groupTables[0].rows.length, 2);
        expect(groupTables[0].rows.first.isQualified, isTrue);
        expect(groupTables[0].rows.last.isQualified, isFalse);
        expect(groupTables[1].groupName, 'Grupo B');
        expect(groupTables[1].rows.length, 2);
      },
    );

    test(
      'HU 15.4: Group stage calculation respects explicit team.groupName assignments and resolves effective groups',
      () {
        final tournament = buildTournament(
          format: TournamentFormat.mixedGroupsAndKnockout,
          rules: const TournamentRulesConfig(
            groupStageConfig: GroupStageConfig(
              groupCount: 2,
              advancingPerGroup: 1,
            ),
          ),
        );
        // Explicitly put t-1 and t-2 into Grupo B, and t-3 into Grupo A, t-4 unassigned
        final teams = [
          buildTeam('t-1', 'Alfa', 'ALF').copyWith(groupName: 'Grupo B'),
          buildTeam('t-2', 'Beta', 'BET').copyWith(groupName: 'Grupo B'),
          buildTeam('t-3', 'Gamma', 'GAM').copyWith(groupName: 'Grupo A'),
          buildTeam('t-4', 'Delta', 'DEL'), // unassigned -> fallback to Grupo A
        ];

        final groupTables = calculator.calculateGroupStageTables(
          tournament: tournament,
          teams: teams,
          matches: const [],
          closedReports: const [],
        );

        expect(groupTables.length, 2);
        final groupA = groupTables.firstWhere((g) => g.groupName == 'Grupo A');
        final groupB = groupTables.firstWhere((g) => g.groupName == 'Grupo B');

        expect(groupA.rows.map((r) => r.teamId), containsAll(['t-3', 't-4']));
        expect(groupB.rows.map((r) => r.teamId), containsAll(['t-1', 't-2']));

        // Verify helper resolveEffectiveGroupName
        expect(
          StandingsCalculatorService.resolveEffectiveGroupName(
            team: teams[0],
            allTournamentTeams: teams,
            groupCount: 2,
          ),
          'Grupo B',
        );
        expect(
          StandingsCalculatorService.resolveEffectiveGroupName(
            team: teams[2],
            allTournamentTeams: teams,
            groupCount: 2,
          ),
          'Grupo A',
        );
      },
    );
  });
}
