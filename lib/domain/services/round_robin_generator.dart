import '../entities/championship_match.dart';
import '../entities/match_enums.dart';
import '../entities/tournament_enums.dart';

class RoundRobinGenerator {
  static const String byeTeamSentinel = '__BYE__';

  /// Generates a complete round-robin fixture for league / group phase formats.
  static List<ChampionshipMatch> generateLeagueFixture({
    required String tournamentId,
    required List<String> teamIds,
    int leagueRounds = 1,
    DateTime? initialDate,
  }) {
    if (teamIds.length < 2) return const [];

    final teams = List<String>.from(teamIds);
    final hasBye = teams.length.isOdd;
    if (hasBye) {
      teams.add(byeTeamSentinel);
    }

    final n = teams.length;
    final roundsPerCycle = n - 1;
    final matchesPerRound = n ~/ 2;

    final generatedMatches = <ChampionshipMatch>[];
    int matchCounter = 1;

    // Fixed first team, remaining rotate
    final rotating = teams.sublist(1);

    for (
      int cycle = 0;
      cycle < (leagueRounds < 1 ? 1 : leagueRounds);
      cycle++
    ) {
      final isReturnCycle = cycle.isOdd;

      for (int r = 0; r < roundsPerCycle; r++) {
        final currentRoundNumber = cycle * roundsPerCycle + r + 1;
        final roundName = 'Jornada $currentRoundNumber';

        // Construct current round arrangement
        final currentRoundTeams = <String>[teams[0], ...rotating];

        for (int m = 0; m < matchesPerRound; m++) {
          final home = currentRoundTeams[m];
          final away = currentRoundTeams[n - 1 - m];

          // Skip bye matches
          if (home == byeTeamSentinel || away == byeTeamSentinel) {
            continue;
          }

          // Balance home/away
          String finalHome;
          String finalAway;

          if (m == 0 && r.isOdd) {
            finalHome = away;
            finalAway = home;
          } else {
            finalHome = home;
            finalAway = away;
          }

          if (isReturnCycle) {
            final temp = finalHome;
            finalHome = finalAway;
            finalAway = temp;
          }

          generatedMatches.add(
            ChampionshipMatch(
              id: 'match-$tournamentId-r$currentRoundNumber-$matchCounter',
              tournamentId: tournamentId,
              roundNumber: currentRoundNumber,
              roundName: roundName,
              homeTeamId: finalHome,
              awayTeamId: finalAway,
              status: MatchStatus.pendingSchedule,
            ),
          );
          matchCounter++;
        }

        // Rotate remaining teams: last moves to front
        final last = rotating.removeLast();
        rotating.insert(0, last);
      }
    }

    return generatedMatches;
  }

  /// Generates initial knockout bracket pairings for cup formats.
  static List<ChampionshipMatch> generateKnockoutFixture({
    required String tournamentId,
    required List<String> teamIds,
    KnockoutRound? startingRound,
  }) {
    if (teamIds.length < 2) return const [];

    final round = startingRound ?? _resolveInitialKnockoutRound(teamIds.length);
    final count = round.tieCount;
    final generatedMatches = <ChampionshipMatch>[];

    final roundLabel = _formatKnockoutRoundLabel(round);

    for (int i = 0; i < count; i++) {
      final homeIdx = i * 2;
      final awayIdx = i * 2 + 1;

      if (homeIdx >= teamIds.length || awayIdx >= teamIds.length) {
        break;
      }

      generatedMatches.add(
        ChampionshipMatch(
          id: 'match-$tournamentId-ko-${round.name}-${i + 1}',
          tournamentId: tournamentId,
          roundNumber: 1,
          roundName: roundLabel,
          homeTeamId: teamIds[homeIdx],
          awayTeamId: teamIds[awayIdx],
          status: MatchStatus.pendingSchedule,
        ),
      );
    }

    return generatedMatches;
  }

  static KnockoutRound _resolveInitialKnockoutRound(int teamCount) {
    if (teamCount <= 2) return KnockoutRound.finalMatch;
    if (teamCount <= 4) return KnockoutRound.semiFinals;
    if (teamCount <= 8) return KnockoutRound.quarterFinals;
    return KnockoutRound.roundOf16;
  }

  static String _formatKnockoutRoundLabel(KnockoutRound round) {
    return switch (round) {
      KnockoutRound.roundOf16 => 'Octavos de Final',
      KnockoutRound.quarterFinals => 'Cuartos de Final',
      KnockoutRound.semiFinals => 'Semifinales',
      KnockoutRound.finalMatch => 'Gran Final',
    };
  }
}
