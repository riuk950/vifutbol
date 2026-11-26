import 'team_enums.dart';
import 'tournament_enums.dart';

/// Represents a single team's calculated standing row within a league or group table.
class StandingsRow {
  const StandingsRow({
    required this.position,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    this.crestShape = TeamCrestShape.shield,
    this.primaryColorHex = 0xFF00E676,
    this.crestUrl,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.yellowCards = 0,
    this.secondYellowRedCards = 0,
    this.directRedCards = 0,
    this.fairPlayPenaltyPoints = 0,
    this.isQualified = false,
    this.isTiedOnAllCriteria = false,
  }) : assert(position >= 1, 'position must be >= 1'),
       assert(played >= 0, 'played must be >= 0'),
       assert(won >= 0, 'won must be >= 0'),
       assert(drawn >= 0, 'drawn must be >= 0'),
       assert(lost >= 0, 'lost must be >= 0'),
       assert(goalsFor >= 0, 'goalsFor must be >= 0'),
       assert(goalsAgainst >= 0, 'goalsAgainst must be >= 0'),
       assert(
         fairPlayPenaltyPoints <= 0,
         'fairPlayPenaltyPoints must be <= 0 (0 or negative penalty points)',
       );

  final int position;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final String? crestUrl;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int yellowCards;
  final int secondYellowRedCards;
  final int directRedCards;
  final int fairPlayPenaltyPoints;
  final bool isQualified;
  final bool isTiedOnAllCriteria;

  int get totalRedCards => secondYellowRedCards + directRedCards;

  StandingsRow copyWith({
    int? position,
    String? teamId,
    String? teamName,
    String? teamShortCode,
    TeamCrestShape? crestShape,
    int? primaryColorHex,
    String? crestUrl,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? points,
    int? yellowCards,
    int? secondYellowRedCards,
    int? directRedCards,
    int? fairPlayPenaltyPoints,
    bool? isQualified,
    bool? isTiedOnAllCriteria,
  }) {
    return StandingsRow(
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      crestShape: crestShape ?? this.crestShape,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      crestUrl: crestUrl ?? this.crestUrl,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      points: points ?? this.points,
      yellowCards: yellowCards ?? this.yellowCards,
      secondYellowRedCards: secondYellowRedCards ?? this.secondYellowRedCards,
      directRedCards: directRedCards ?? this.directRedCards,
      fairPlayPenaltyPoints:
          fairPlayPenaltyPoints ?? this.fairPlayPenaltyPoints,
      isQualified: isQualified ?? this.isQualified,
      isTiedOnAllCriteria: isTiedOnAllCriteria ?? this.isTiedOnAllCriteria,
    );
  }
}

/// Aggregate representing a deterministic standings table for a league or tournament group.
class StandingsTable {
  StandingsTable({
    required this.tournamentId,
    this.groupName,
    required List<StandingsRow> rows,
    required List<TiebreakerCriterion> appliedTiebreakers,
    required this.completedMatchesCount,
    DateTime? updatedAt,
  }) : rows = List.unmodifiable(rows),
       appliedTiebreakers = List.unmodifiable(appliedTiebreakers),
       updatedAt = updatedAt ?? DateTime.now();

  final String tournamentId;
  final String? groupName;
  final List<StandingsRow> rows;
  final List<TiebreakerCriterion> appliedTiebreakers;
  final int completedMatchesCount;
  final DateTime updatedAt;
}
