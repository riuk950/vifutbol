import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/knockout_bracket_service.dart';
import 'package:vifutbol/domain/services/round_robin_generator.dart';

void main() {
  group('KnockoutBracketService Unit Tests', () {
    const service = KnockoutBracketService();
    final baseDate = DateTime(2026, 11, 4);

    ChampionshipTournament buildCupTournament({
      KnockoutRound startingRound = KnockoutRound.quarterFinals,
    }) {
      return ChampionshipTournament(
        id: 't-cup-1',
        name: 'Copa Eliminatoria Nocturna',
        category: 'Libre',
        startDate: baseDate,
        endDate: baseDate.add(const Duration(days: 30)),
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.inProgress,
        rules: TournamentRulesConfig(
          knockoutConfig: KnockoutStageConfig(
            startingRound: startingRound,
            directPenaltyShootoutOnDraw: true,
          ),
        ),
        updatedAt: baseDate,
      );
    }

    List<TournamentTeam> buildTeams(int count) {
      return List<TournamentTeam>.generate(count, (i) {
        final idx = i + 1;
        return TournamentTeam(
          id: 'team-$idx',
          tournamentId: 't-cup-1',
          name: 'Equipo $idx',
          shortCode: 'EQ$idx',
          eligibilityStatus: TeamEligibilityStatus.eligible,
          updatedAt: baseDate,
        );
      });
    }

    test(
      'US2 Scenario 1: Regulation winner in Quarter-Finals automatically advances to Semi-Final 1 slot',
      () {
        final tournament = buildCupTournament(
          startingRound: KnockoutRound.quarterFinals,
        );
        final teams = buildTeams(8);
        final initialMatches = RoundRobinGenerator.generateKnockoutFixture(
          tournamentId: tournament.id,
          teamIds: teams.map((t) => t.id).toList(),
          startingRound: KnockoutRound.quarterFinals,
        );

        // Complete Quarter-Final 1 (team-1 3 - 1 team-2) and Quarter-Final 2 (team-3 2 - 0 team-4)
        final completedMatches = [
          initialMatches[0].copyWith(
            status: MatchStatus.completed,
            homeScore: 3,
            awayScore: 1,
          ),
          initialMatches[1].copyWith(
            status: MatchStatus.completed,
            homeScore: 2,
            awayScore: 0,
          ),
          initialMatches[2],
          initialMatches[3],
        ];

        final bracket = service.buildBracket(
          tournament: tournament,
          teams: teams,
          matches: completedMatches,
          reports: const [],
        );

        // QuarterFinals -> SemiFinals -> FinalMatch (3 rounds)
        expect(bracket.rounds.length, 3);
        expect(bracket.rounds[0].round, KnockoutRound.quarterFinals);
        expect(bracket.rounds[1].round, KnockoutRound.semiFinals);
        expect(bracket.rounds[2].round, KnockoutRound.finalMatch);

        // Check Quarter-Final 1 winner
        final qf1 = bracket.rounds[0].ties[0];
        expect(qf1.isCompleted, isTrue);
        expect(qf1.winnerTeamId, 'team-1');
        expect(qf1.winnerTeamName, 'Equipo 1');

        // Check Semi-Final 1 automatically has team-1 (home) vs team-3 (away)
        final sf1 = bracket.rounds[1].ties[0];
        expect(sf1.homeTeamId, 'team-1');
        expect(sf1.homeTeamName, 'Equipo 1');
        expect(sf1.awayTeamId, 'team-3');
        expect(sf1.awayTeamName, 'Equipo 3');

        // Semi-Final 2 still has "Por definir" since QF3 & QF4 are not completed
        final sf2 = bracket.rounds[1].ties[1];
        expect(sf2.homeTeamId, isNull);
        expect(sf2.homeTeamName, 'Por definir');

        // Also verify computeUpdatedMatchesWithAdvancement creates the new ChampionshipMatch for Semi-Final 1
        final nextRoundMatches = service.computeUpdatedMatchesWithAdvancement(
          tournament: tournament,
          teams: teams,
          currentMatches: completedMatches,
          reports: const [],
          now: baseDate,
        );
        expect(nextRoundMatches.length, 1);
        expect(nextRoundMatches.first.roundName, 'Semifinales');
        expect(nextRoundMatches.first.homeTeamId, 'team-1');
        expect(nextRoundMatches.first.awayTeamId, 'team-3');
      },
    );

    test(
      'US2 Scenario 2: Tied knockout match decided by penalty shootout (1 - 1, Penales 5 - 4) advances penalty winner to next round',
      () {
        final tournament = buildCupTournament(
          startingRound: KnockoutRound.semiFinals,
        );
        final teams = buildTeams(4);
        final initialMatches = RoundRobinGenerator.generateKnockoutFixture(
          tournamentId: tournament.id,
          teamIds: teams.map((t) => t.id).toList(),
          startingRound: KnockoutRound.semiFinals,
        );

        // Semi-Final 1 ends 1 - 1 in regulation, team-2 wins 5 - 4 on penalties
        final sf1Completed = initialMatches[0].copyWith(
          status: MatchStatus.completed,
          homeScore: 1,
          awayScore: 1,
          homePenaltyScore: 4,
          awayPenaltyScore: 5,
        );
        final closedReport = DigitalMatchReport(
          matchId: sf1Completed.id,
          tournamentId: tournament.id,
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 1,
          awayScore: 1,
          homePenaltyScore: 4,
          awayPenaltyScore: 5,
          currentPeriod: MatchPeriod.closed,
          closedAt: baseDate,
        );

        final bracket = service.buildBracket(
          tournament: tournament,
          teams: teams,
          matches: [sf1Completed, initialMatches[1]],
          reports: [closedReport],
        );

        final sf1Node = bracket.rounds[0].ties[0];
        expect(sf1Node.isCompleted, isTrue);
        expect(sf1Node.isDecidedByPenalties, isTrue);
        expect(sf1Node.winnerTeamId, 'team-2');

        // Final match now has team-2 seeded in home slot
        final finalNode = bracket.rounds[1].ties[0];
        expect(finalNode.homeTeamId, 'team-2');
        expect(finalNode.homeTeamName, 'Equipo 2');
        expect(finalNode.awayTeamId, isNull);
        expect(finalNode.awayTeamName, 'Por definir');
      },
    );
  });
}
