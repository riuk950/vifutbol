/// Represents an individual player's entry in the top scorers or top assists ranking.
class PlayerRankingEntry {
  const PlayerRankingEntry({
    required this.rank,
    required this.playerId,
    required this.playerName,
    required this.shirtNumber,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.goals,
    required this.assists,
    required this.matchesPlayed,
    this.yellowCards = 0,
    this.redCards = 0,
  }) : assert(rank >= 1, 'rank must be >= 1'),
       assert(goals >= 0, 'goals must be >= 0'),
       assert(assists >= 0, 'assists must be >= 0'),
       assert(matchesPlayed >= 0, 'matchesPlayed must be >= 0');

  final int rank;
  final String playerId;
  final String playerName;
  final int shirtNumber;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int yellowCards;
  final int redCards;

  PlayerRankingEntry copyWith({int? rank}) {
    return PlayerRankingEntry(
      rank: rank ?? this.rank,
      playerId: playerId,
      playerName: playerName,
      shirtNumber: shirtNumber,
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      goals: goals,
      assists: assists,
      matchesPlayed: matchesPlayed,
      yellowCards: yellowCards,
      redCards: redCards,
    );
  }
}

/// Represents a team's collective Fair Play disciplinary record.
/// Penalty weighting: -1 per yellow card, -3 per second-yellow red card, -3 per direct red card.
class TeamFairPlayRow {
  const TeamFairPlayRow({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.yellowCards,
    required this.secondYellowRedCards,
    required this.directRedCards,
    required this.penaltyPoints,
  }) : assert(rank >= 1, 'rank must be >= 1'),
       assert(yellowCards >= 0, 'yellowCards must be >= 0'),
       assert(secondYellowRedCards >= 0, 'secondYellowRedCards must be >= 0'),
       assert(directRedCards >= 0, 'directRedCards must be >= 0'),
       assert(penaltyPoints <= 0, 'penaltyPoints must be <= 0');

  final int rank;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final int yellowCards;
  final int secondYellowRedCards;
  final int directRedCards;
  final int penaltyPoints;

  int get totalRedCards => secondYellowRedCards + directRedCards;

  TeamFairPlayRow copyWith({int? rank}) {
    return TeamFairPlayRow(
      rank: rank ?? this.rank,
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      yellowCards: yellowCards,
      secondYellowRedCards: secondYellowRedCards,
      directRedCards: directRedCards,
      penaltyPoints: penaltyPoints,
    );
  }
}

/// Bundle containing all deterministic sports rankings for a tournament.
class TournamentRankingsBundle {
  TournamentRankingsBundle({
    required this.tournamentId,
    required List<PlayerRankingEntry> topScorers,
    required List<PlayerRankingEntry> topAssists,
    required List<TeamFairPlayRow> teamFairPlay,
  }) : topScorers = List.unmodifiable(topScorers),
       topAssists = List.unmodifiable(topAssists),
       teamFairPlay = List.unmodifiable(teamFairPlay);

  final String tournamentId;
  final List<PlayerRankingEntry> topScorers;
  final List<PlayerRankingEntry> topAssists;
  final List<TeamFairPlayRow> teamFairPlay;
}
