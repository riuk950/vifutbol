import 'match_enums.dart';
import 'tournament_enums.dart';

/// Represents a single head-to-head elimination pairing within a knockout round.
class KnockoutMatchTieNode {
  const KnockoutMatchTieNode({
    required this.nodeId,
    required this.round,
    required this.tieIndex,
    this.matchId,
    this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamShortCode,
    this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamShortCode,
    this.homeScore,
    this.awayScore,
    this.homePenaltyScore,
    this.awayPenaltyScore,
    this.status = MatchStatus.pendingSchedule,
    this.winnerTeamId,
    this.winnerTeamName,
    this.nextRoundNodeId,
  }) : assert(tieIndex >= 0, 'tieIndex must be >= 0');

  final String nodeId;
  final KnockoutRound round;
  final int tieIndex;
  final String? matchId;
  final String? homeTeamId;
  final String homeTeamName;
  final String? homeTeamShortCode;
  final String? awayTeamId;
  final String awayTeamName;
  final String? awayTeamShortCode;
  final int? homeScore;
  final int? awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;
  final MatchStatus status;
  final String? winnerTeamId;
  final String? winnerTeamName;
  final String? nextRoundNodeId;

  bool get isCompleted =>
      status == MatchStatus.completed && winnerTeamId != null;

  bool get isDecidedByPenalties =>
      homeScore != null &&
      awayScore != null &&
      homeScore == awayScore &&
      homePenaltyScore != null &&
      awayPenaltyScore != null &&
      homePenaltyScore != awayPenaltyScore;

  bool get hasBothTeamsAssigned =>
      homeTeamId != null &&
      homeTeamId!.isNotEmpty &&
      awayTeamId != null &&
      awayTeamId!.isNotEmpty;
}

/// Represents a chronological round of ties in a knockout bracket.
class KnockoutBracketRound {
  KnockoutBracketRound({
    required this.round,
    required this.roundTitle,
    required List<KnockoutMatchTieNode> ties,
  }) : ties = List.unmodifiable(ties);

  final KnockoutRound round;
  final String roundTitle;
  final List<KnockoutMatchTieNode> ties;
}

/// Aggregate modeling the full knockout elimination bracket tree from starting round to final.
class KnockoutBracket {
  KnockoutBracket({
    required this.tournamentId,
    required List<KnockoutBracketRound> rounds,
    this.championTeamId,
    this.championTeamName,
  }) : rounds = List.unmodifiable(rounds);

  final String tournamentId;
  final List<KnockoutBracketRound> rounds;
  final String? championTeamId;
  final String? championTeamName;
}
