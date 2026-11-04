import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/services/round_robin_generator.dart';

void main() {
  group('RoundRobinGenerator', () {
    test(
      'generates complete round-robin fixture for even team count (4 teams)',
      () {
        final teams = ['team-1', 'team-2', 'team-3', 'team-4'];
        final matches = RoundRobinGenerator.generateLeagueFixture(
          tournamentId: 'tourn-even',
          teamIds: teams,
          leagueRounds: 1,
        );

        // 4 teams -> 3 rounds (n - 1)
        // Total matches: 3 rounds * 2 matches/round = 6 matches
        expect(matches.length, 6);

        final rounds = matches.map((m) => m.roundNumber).toSet();
        expect(rounds, {1, 2, 3});

        // Verify each team plays exactly once per round
        for (final r in rounds) {
          final roundMatches = matches
              .where((m) => m.roundNumber == r)
              .toList();
          expect(roundMatches.length, 2);

          final roundTeams = <String>{};
          for (final m in roundMatches) {
            expect(roundTeams.contains(m.homeTeamId), isFalse);
            roundTeams.add(m.homeTeamId);
            expect(roundTeams.contains(m.awayTeamId), isFalse);
            roundTeams.add(m.awayTeamId);
          }
          expect(roundTeams.length, 4);
        }

        // Verify all matches have pendingSchedule status initially
        expect(
          matches.every((m) => m.status == MatchStatus.pendingSchedule),
          isTrue,
        );
      },
    );

    test(
      'generates balanced round-robin fixture for odd team count (5 teams) with bye',
      () {
        final teams = ['team-1', 'team-2', 'team-3', 'team-4', 'team-5'];
        final matches = RoundRobinGenerator.generateLeagueFixture(
          tournamentId: 'tourn-odd',
          teamIds: teams,
          leagueRounds: 1,
        );

        // 5 teams (+ 1 bye) -> 5 rounds
        // 2 matches per round = 10 matches total
        expect(matches.length, 10);

        final rounds = matches.map((m) => m.roundNumber).toSet();
        expect(rounds, {1, 2, 3, 4, 5});

        // Verify that in each round, exactly 4 teams play (1 rests)
        for (final r in rounds) {
          final roundMatches = matches
              .where((m) => m.roundNumber == r)
              .toList();
          expect(roundMatches.length, 2);

          final playingTeams = <String>{};
          for (final m in roundMatches) {
            playingTeams.add(m.homeTeamId);
            playingTeams.add(m.awayTeamId);
          }
          expect(playingTeams.length, 4);
          final restingTeam = teams.firstWhere(
            (t) => !playingTeams.contains(t),
          );
          expect(restingTeam, isNotNull);
        }
      },
    );

    test(
      'supports two-leg league (ida y vuelta) with alternating home/away',
      () {
        final teams = ['team-1', 'team-2', 'team-3', 'team-4'];
        final matches = RoundRobinGenerator.generateLeagueFixture(
          tournamentId: 'tourn-two-legs',
          teamIds: teams,
          leagueRounds: 2,
        );

        // 4 teams, 2 legs -> 6 rounds, 12 matches total
        expect(matches.length, 12);

        final firstLeg = matches.where((m) => m.roundNumber <= 3).toList();
        final secondLeg = matches.where((m) => m.roundNumber > 3).toList();

        expect(firstLeg.length, 6);
        expect(secondLeg.length, 6);

        // Check reciprocity
        for (final match1 in firstLeg) {
          final match2 = secondLeg.firstWhere(
            (m) =>
                m.homeTeamId == match1.awayTeamId &&
                m.awayTeamId == match1.homeTeamId,
          );
          expect(match2, isNotNull);
        }
      },
    );

    test('generates knockout bracket for cup tournaments', () {
      final teams = ['team-1', 'team-2', 'team-3', 'team-4'];
      final matches = RoundRobinGenerator.generateKnockoutFixture(
        tournamentId: 'cup-1',
        teamIds: teams,
      );

      // 4 teams -> 2 semifinal matches
      expect(matches.length, 2);
      expect(matches.first.roundName, 'Semifinales');
      expect(matches.first.homeTeamId, 'team-1');
      expect(matches.first.awayTeamId, 'team-2');
      expect(matches.last.homeTeamId, 'team-3');
      expect(matches.last.awayTeamId, 'team-4');
    });

    test('returns empty list when fewer than 2 teams provided', () {
      final matches = RoundRobinGenerator.generateLeagueFixture(
        tournamentId: 'empty-tourn',
        teamIds: ['lone-team'],
      );
      expect(matches, isEmpty);
    });
  });
}
