import 'team_enums.dart';

/// Performance and disciplinary tracking breakdown for a single match participation.
class PlayerMatchParticipation {
  const PlayerMatchParticipation({
    required this.matchId,
    required this.roundNumber,
    required this.roundName,
    required this.scheduledAt,
    required this.opponentTeamId,
    required this.opponentTeamName,
    required this.opponentShortCode,
    required this.isHome,
    required this.teamScore,
    required this.opponentScore,
    required this.wasStarter,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  }) : assert(matchId != '', 'matchId cannot be empty'),
       assert(teamScore >= 0, 'teamScore cannot be negative'),
       assert(opponentScore >= 0, 'opponentScore cannot be negative'),
       assert(goals >= 0, 'goals cannot be negative'),
       assert(assists >= 0, 'assists cannot be negative'),
       assert(yellowCards >= 0, 'yellowCards cannot be negative'),
       assert(redCards >= 0, 'redCards cannot be negative');

  final String matchId;
  final int roundNumber;
  final String roundName;
  final DateTime scheduledAt;
  final String opponentTeamId;
  final String opponentTeamName;
  final String opponentShortCode;
  final bool isHome;
  final int teamScore;
  final int opponentScore;
  final bool wasStarter;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'roundNumber': roundNumber,
      'roundName': roundName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'opponentTeamId': opponentTeamId,
      'opponentTeamName': opponentTeamName,
      'opponentShortCode': opponentShortCode,
      'isHome': isHome,
      'teamScore': teamScore,
      'opponentScore': opponentScore,
      'wasStarter': wasStarter,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
    };
  }

  factory PlayerMatchParticipation.fromJson(Map<String, dynamic> json) {
    return PlayerMatchParticipation(
      matchId: json['matchId'] as String? ?? '',
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      roundName: json['roundName'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      opponentTeamId: json['opponentTeamId'] as String? ?? '',
      opponentTeamName: json['opponentTeamName'] as String? ?? '',
      opponentShortCode: json['opponentShortCode'] as String? ?? '',
      isHome: json['isHome'] as bool? ?? true,
      teamScore: (json['teamScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      wasStarter: json['wasStarter'] as bool? ?? false,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerMatchParticipation &&
        other.matchId == matchId &&
        other.roundNumber == roundNumber &&
        other.wasStarter == wasStarter &&
        other.goals == goals &&
        other.assists == assists &&
        other.yellowCards == yellowCards &&
        other.redCards == redCards;
  }

  @override
  int get hashCode => Object.hash(
    matchId,
    roundNumber,
    wasStarter,
    goals,
    assists,
    yellowCards,
    redCards,
  );
}

/// Official consolidated performance profile of a registered player in a championship.
class PlayerPerformanceProfile {
  const PlayerPerformanceProfile({
    required this.playerId,
    required this.tournamentId,
    required this.fullName,
    required this.shirtNumber,
    required this.position,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    this.matchesPlayed = 0,
    this.startsCount = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.isSuspended = false,
    this.matchParticipations = const <PlayerMatchParticipation>[],
  }) : assert(playerId != '', 'playerId cannot be empty'),
       assert(tournamentId != '', 'tournamentId cannot be empty'),
       assert(fullName != '', 'fullName cannot be empty'),
       assert(matchesPlayed >= 0, 'matchesPlayed cannot be negative'),
       assert(startsCount >= 0, 'startsCount cannot be negative'),
       assert(goals >= 0, 'goals cannot be negative'),
       assert(assists >= 0, 'assists cannot be negative'),
       assert(yellowCards >= 0, 'yellowCards cannot be negative'),
       assert(redCards >= 0, 'redCards cannot be negative');

  final String playerId;
  final String tournamentId;
  final String fullName;
  final int shirtNumber;
  final PlayerPosition position;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final int matchesPlayed;
  final int startsCount;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final bool isSuspended;
  final List<PlayerMatchParticipation> matchParticipations;

  /// Safe calculation of goal average per match with zero-division protection (`FR-003`).
  double get goalsPerMatchAverage =>
      matchesPlayed > 0 ? goals / matchesPlayed : 0.0;

  /// Formatted goal average rounded to 2 decimal places (e.g. `0.50`, `0.00`).
  String get formattedGoalsAverage => goalsPerMatchAverage.toStringAsFixed(2);

  /// Whether the player has played in any official match or recorded participations.
  bool get hasParticipations =>
      matchesPlayed > 0 || matchParticipations.isNotEmpty;

  PlayerPerformanceProfile copyWith({
    String? playerId,
    String? tournamentId,
    String? fullName,
    int? shirtNumber,
    PlayerPosition? position,
    String? teamId,
    String? teamName,
    String? teamShortCode,
    int? matchesPlayed,
    int? startsCount,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    bool? isSuspended,
    List<PlayerMatchParticipation>? matchParticipations,
  }) {
    return PlayerPerformanceProfile(
      playerId: playerId ?? this.playerId,
      tournamentId: tournamentId ?? this.tournamentId,
      fullName: fullName ?? this.fullName,
      shirtNumber: shirtNumber ?? this.shirtNumber,
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      startsCount: startsCount ?? this.startsCount,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      isSuspended: isSuspended ?? this.isSuspended,
      matchParticipations: matchParticipations ?? this.matchParticipations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'tournamentId': tournamentId,
      'fullName': fullName,
      'shirtNumber': shirtNumber,
      'position': position.name,
      'teamId': teamId,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'matchesPlayed': matchesPlayed,
      'startsCount': startsCount,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'isSuspended': isSuspended,
      'matchParticipations': matchParticipations
          .map((p) => p.toJson())
          .toList(),
    };
  }

  factory PlayerPerformanceProfile.fromJson(Map<String, dynamic> json) {
    final rawParticipations = json['matchParticipations'] as List<dynamic>?;
    final parsedParticipations = rawParticipations != null
        ? rawParticipations
              .whereType<Map<String, dynamic>>()
              .map(PlayerMatchParticipation.fromJson)
              .toList()
        : const <PlayerMatchParticipation>[];

    return PlayerPerformanceProfile(
      playerId: json['playerId'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      shirtNumber: (json['shirtNumber'] as num?)?.toInt() ?? 0,
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.midfielder,
      ),
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      teamShortCode: json['teamShortCode'] as String? ?? '',
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      startsCount: (json['startsCount'] as num?)?.toInt() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      isSuspended: json['isSuspended'] as bool? ?? false,
      matchParticipations: parsedParticipations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerPerformanceProfile &&
        other.playerId == playerId &&
        other.tournamentId == tournamentId &&
        other.matchesPlayed == matchesPlayed &&
        other.startsCount == startsCount &&
        other.goals == goals &&
        other.assists == assists &&
        other.yellowCards == yellowCards &&
        other.redCards == redCards &&
        other.isSuspended == isSuspended;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    tournamentId,
    matchesPlayed,
    startsCount,
    goals,
    assists,
    yellowCards,
    redCards,
    isSuspended,
  );
}
