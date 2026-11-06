import 'package:vifutbol/domain/entities/championship_match.dart';

/// Grouping of matches for a specific tournament round/matchday.
class MatchdayFixtureGroup {
  final int roundNumber;
  final String roundName;
  final List<ChampionshipMatch> matches;

  const MatchdayFixtureGroup({
    required this.roundNumber,
    required this.roundName,
    required this.matches,
  });
}

/// Pure deterministic grouping function that organizes a tournament's matches by round.
List<MatchdayFixtureGroup> groupMatchesByRoundNumber(
  List<ChampionshipMatch> matches,
) {
  if (matches.isEmpty) return const [];

  final Map<int, List<ChampionshipMatch>> roundMap = {};
  final Map<int, String> roundNameMap = {};

  for (final match in matches) {
    roundMap.putIfAbsent(match.roundNumber, () => []).add(match);
    roundNameMap.putIfAbsent(match.roundNumber, () => match.roundName);
  }

  final sortedRounds = roundMap.keys.toList()..sort();

  return sortedRounds.map((roundNumber) {
    final roundMatches = List<ChampionshipMatch>.from(roundMap[roundNumber]!);
    // Sort matches: scheduled matches by start time, pending matches at the end
    roundMatches.sort((a, b) {
      if (a.scheduledStartTime != null && b.scheduledStartTime != null) {
        return a.scheduledStartTime!.compareTo(b.scheduledStartTime!);
      }
      if (a.scheduledStartTime != null) return -1;
      if (b.scheduledStartTime != null) return 1;
      return a.id.compareTo(b.id);
    });

    return MatchdayFixtureGroup(
      roundNumber: roundNumber,
      roundName: roundNameMap[roundNumber] ?? 'Jornada $roundNumber',
      matches: roundMatches,
    );
  }).toList();
}
