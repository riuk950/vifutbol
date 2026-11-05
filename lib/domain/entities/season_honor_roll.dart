/// Official honor roll entity generated upon closing a tournament season.
class SeasonHonorRoll {
  const SeasonHonorRoll({
    required this.tournamentId,
    required this.tournamentName,
    required this.closedAt,
    required this.championTeamId,
    required this.championTeamName,
    required this.championShortCode,
    required this.runnerUpTeamId,
    required this.runnerUpTeamName,
    required this.runnerUpShortCode,
    this.topScorerPlayerId,
    this.topScorerPlayerName,
    this.topScorerTeamName,
    this.topScorerGoals = 0,
    required this.bestDefenseTeamId,
    required this.bestDefenseTeamName,
    required this.bestDefenseShortCode,
    required this.bestDefenseGoalsAgainst,
  }) : assert(tournamentId.length > 0, 'tournamentId must not be empty'),
       assert(championTeamId.length > 0, 'championTeamId must not be empty'),
       assert(runnerUpTeamId.length > 0, 'runnerUpTeamId must not be empty'),
       assert(
         bestDefenseTeamId.length > 0,
         'bestDefenseTeamId must not be empty',
       ),
       assert(
         championTeamId != runnerUpTeamId,
         'Champion and Runner-Up must be different teams',
       ),
       assert(topScorerGoals >= 0, 'topScorerGoals must be >= 0'),
       assert(
         bestDefenseGoalsAgainst >= 0,
         'bestDefenseGoalsAgainst must be >= 0',
       );

  final String tournamentId;
  final String tournamentName;
  final DateTime closedAt;

  final String championTeamId;
  final String championTeamName;
  final String championShortCode;

  final String runnerUpTeamId;
  final String runnerUpTeamName;
  final String runnerUpShortCode;

  final String? topScorerPlayerId;
  final String? topScorerPlayerName;
  final String? topScorerTeamName;
  final int topScorerGoals;

  final String bestDefenseTeamId;
  final String bestDefenseTeamName;
  final String bestDefenseShortCode;
  final int bestDefenseGoalsAgainst;

  /// Returns true if an individual top scorer was determined with at least 1 goal.
  bool get hasTopScorer => topScorerPlayerId != null && topScorerGoals > 0;

  SeasonHonorRoll copyWith({
    String? tournamentId,
    String? tournamentName,
    DateTime? closedAt,
    String? championTeamId,
    String? championTeamName,
    String? championShortCode,
    String? runnerUpTeamId,
    String? runnerUpTeamName,
    String? runnerUpShortCode,
    String? topScorerPlayerId,
    String? topScorerPlayerName,
    String? topScorerTeamName,
    int? topScorerGoals,
    String? bestDefenseTeamId,
    String? bestDefenseTeamName,
    String? bestDefenseShortCode,
    int? bestDefenseGoalsAgainst,
  }) {
    return SeasonHonorRoll(
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      closedAt: closedAt ?? this.closedAt,
      championTeamId: championTeamId ?? this.championTeamId,
      championTeamName: championTeamName ?? this.championTeamName,
      championShortCode: championShortCode ?? this.championShortCode,
      runnerUpTeamId: runnerUpTeamId ?? this.runnerUpTeamId,
      runnerUpTeamName: runnerUpTeamName ?? this.runnerUpTeamName,
      runnerUpShortCode: runnerUpShortCode ?? this.runnerUpShortCode,
      topScorerPlayerId: topScorerPlayerId ?? this.topScorerPlayerId,
      topScorerPlayerName: topScorerPlayerName ?? this.topScorerPlayerName,
      topScorerTeamName: topScorerTeamName ?? this.topScorerTeamName,
      topScorerGoals: topScorerGoals ?? this.topScorerGoals,
      bestDefenseTeamId: bestDefenseTeamId ?? this.bestDefenseTeamId,
      bestDefenseTeamName: bestDefenseTeamName ?? this.bestDefenseTeamName,
      bestDefenseShortCode: bestDefenseShortCode ?? this.bestDefenseShortCode,
      bestDefenseGoalsAgainst:
          bestDefenseGoalsAgainst ?? this.bestDefenseGoalsAgainst,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'closedAt': closedAt.toIso8601String(),
      'championTeamId': championTeamId,
      'championTeamName': championTeamName,
      'championShortCode': championShortCode,
      'runnerUpTeamId': runnerUpTeamId,
      'runnerUpTeamName': runnerUpTeamName,
      'runnerUpShortCode': runnerUpShortCode,
      'topScorerPlayerId': topScorerPlayerId,
      'topScorerPlayerName': topScorerPlayerName,
      'topScorerTeamName': topScorerTeamName,
      'topScorerGoals': topScorerGoals,
      'bestDefenseTeamId': bestDefenseTeamId,
      'bestDefenseTeamName': bestDefenseTeamName,
      'bestDefenseShortCode': bestDefenseShortCode,
      'bestDefenseGoalsAgainst': bestDefenseGoalsAgainst,
    };
  }

  factory SeasonHonorRoll.fromJson(Map<String, dynamic> json) {
    return SeasonHonorRoll(
      tournamentId: json['tournamentId'] as String? ?? '',
      tournamentName: json['tournamentName'] as String? ?? '',
      closedAt:
          DateTime.tryParse(json['closedAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      championTeamId: json['championTeamId'] as String? ?? '',
      championTeamName: json['championTeamName'] as String? ?? '',
      championShortCode: json['championShortCode'] as String? ?? '',
      runnerUpTeamId: json['runnerUpTeamId'] as String? ?? '',
      runnerUpTeamName: json['runnerUpTeamName'] as String? ?? '',
      runnerUpShortCode: json['runnerUpShortCode'] as String? ?? '',
      topScorerPlayerId: json['topScorerPlayerId'] as String?,
      topScorerPlayerName: json['topScorerPlayerName'] as String?,
      topScorerTeamName: json['topScorerTeamName'] as String?,
      topScorerGoals: (json['topScorerGoals'] as num?)?.toInt() ?? 0,
      bestDefenseTeamId: json['bestDefenseTeamId'] as String? ?? '',
      bestDefenseTeamName: json['bestDefenseTeamName'] as String? ?? '',
      bestDefenseShortCode: json['bestDefenseShortCode'] as String? ?? '',
      bestDefenseGoalsAgainst:
          (json['bestDefenseGoalsAgainst'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonHonorRoll &&
        other.tournamentId == tournamentId &&
        other.tournamentName == tournamentName &&
        other.closedAt == closedAt &&
        other.championTeamId == championTeamId &&
        other.championTeamName == championTeamName &&
        other.championShortCode == championShortCode &&
        other.runnerUpTeamId == runnerUpTeamId &&
        other.runnerUpTeamName == runnerUpTeamName &&
        other.runnerUpShortCode == runnerUpShortCode &&
        other.topScorerPlayerId == topScorerPlayerId &&
        other.topScorerPlayerName == topScorerPlayerName &&
        other.topScorerTeamName == topScorerTeamName &&
        other.topScorerGoals == topScorerGoals &&
        other.bestDefenseTeamId == bestDefenseTeamId &&
        other.bestDefenseTeamName == bestDefenseTeamName &&
        other.bestDefenseShortCode == bestDefenseShortCode &&
        other.bestDefenseGoalsAgainst == bestDefenseGoalsAgainst;
  }

  @override
  int get hashCode => Object.hash(
    tournamentId,
    tournamentName,
    closedAt,
    championTeamId,
    runnerUpTeamId,
    topScorerPlayerId,
    topScorerGoals,
    bestDefenseTeamId,
    bestDefenseGoalsAgainst,
  );
}
