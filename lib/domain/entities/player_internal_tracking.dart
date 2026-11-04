import 'lineup_enums.dart';

/// Internal performance and disciplinary tracking metrics for a registered player.
class PlayerInternalTracking {
  final String playerId;
  final String teamId;
  final String tournamentId;
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int pendingSuspensionMatches;

  const PlayerInternalTracking({
    required this.playerId,
    required this.teamId,
    required this.tournamentId,
    this.matchesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.pendingSuspensionMatches = 0,
  }) : assert(playerId != '', 'playerId cannot be empty'),
       assert(teamId != '', 'teamId cannot be empty'),
       assert(tournamentId != '', 'tournamentId cannot be empty'),
       assert(matchesPlayed >= 0, 'matchesPlayed cannot be negative'),
       assert(goals >= 0, 'goals cannot be negative'),
       assert(assists >= 0, 'assists cannot be negative'),
       assert(yellowCards >= 0, 'yellowCards cannot be negative'),
       assert(redCards >= 0, 'redCards cannot be negative'),
       assert(
         pendingSuspensionMatches >= 0,
         'pendingSuspensionMatches cannot be negative',
       );

  /// Calculates effective match suspensions according to tournament rules.
  int effectiveSuspensionMatches(int yellowCardSuspensionLimit) {
    if (pendingSuspensionMatches > 0) {
      return pendingSuspensionMatches;
    }
    if (yellowCardSuspensionLimit > 0 &&
        yellowCards >= yellowCardSuspensionLimit) {
      return 1;
    }
    return 0;
  }

  /// Whether the player is prohibited from match selection due to an active suspension.
  bool isSuspended(int yellowCardSuspensionLimit) {
    return effectiveSuspensionMatches(yellowCardSuspensionLimit) > 0;
  }

  /// Whether the player is 1 yellow card away from suspension threshold.
  bool isAtYellowCardWarning(int yellowCardSuspensionLimit) {
    if (isSuspended(yellowCardSuspensionLimit)) return false;
    return yellowCardSuspensionLimit > 1 &&
        yellowCards == yellowCardSuspensionLimit - 1;
  }

  /// The active disciplinary state for this player.
  PlayerDisciplinaryState disciplinaryState(int yellowCardSuspensionLimit) {
    if (isSuspended(yellowCardSuspensionLimit)) {
      return PlayerDisciplinaryState.suspended;
    }
    if (isAtYellowCardWarning(yellowCardSuspensionLimit)) {
      return PlayerDisciplinaryState.warningAccumulation;
    }
    return PlayerDisciplinaryState.eligible;
  }

  PlayerInternalTracking copyWith({
    String? playerId,
    String? teamId,
    String? tournamentId,
    int? matchesPlayed,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? pendingSuspensionMatches,
  }) {
    return PlayerInternalTracking(
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      tournamentId: tournamentId ?? this.tournamentId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      pendingSuspensionMatches:
          pendingSuspensionMatches ?? this.pendingSuspensionMatches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'teamId': teamId,
      'tournamentId': tournamentId,
      'matchesPlayed': matchesPlayed,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'pendingSuspensionMatches': pendingSuspensionMatches,
    };
  }

  factory PlayerInternalTracking.fromJson(Map<String, dynamic> json) {
    return PlayerInternalTracking(
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      tournamentId: json['tournamentId'] as String,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      pendingSuspensionMatches:
          (json['pendingSuspensionMatches'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerInternalTracking &&
        other.playerId == playerId &&
        other.teamId == teamId &&
        other.tournamentId == tournamentId &&
        other.matchesPlayed == matchesPlayed &&
        other.goals == goals &&
        other.assists == assists &&
        other.yellowCards == yellowCards &&
        other.redCards == redCards &&
        other.pendingSuspensionMatches == pendingSuspensionMatches;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    teamId,
    tournamentId,
    matchesPlayed,
    goals,
    assists,
    yellowCards,
    redCards,
    pendingSuspensionMatches,
  );
}
