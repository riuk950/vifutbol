/// Represents a fan's favorite team bookmark and alert subscription.
class FanFavoriteTeam {
  final String userId;
  final String tournamentId;
  final String teamId;
  final String teamName;
  final bool notificationsEnabled;
  final DateTime createdAt;

  FanFavoriteTeam({
    required this.userId,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.notificationsEnabled = true,
    required this.createdAt,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty');
    }
    if (tournamentId.trim().isEmpty) {
      throw ArgumentError.value(
        tournamentId,
        'tournamentId',
        'Tournament ID cannot be empty',
      );
    }
    if (teamId.trim().isEmpty) {
      throw ArgumentError.value(teamId, 'teamId', 'Team ID cannot be empty');
    }
    if (teamName.trim().isEmpty) {
      throw ArgumentError.value(
        teamName,
        'teamName',
        'Team Name cannot be empty',
      );
    }
  }

  FanFavoriteTeam copyWith({bool? notificationsEnabled, String? teamName}) {
    return FanFavoriteTeam(
      userId: userId,
      tournamentId: tournamentId,
      teamId: teamId,
      teamName: teamName ?? this.teamName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FanFavoriteTeam.fromJson(Map<String, dynamic> json) {
    return FanFavoriteTeam(
      userId: json['userId'] as String,
      tournamentId: json['tournamentId'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
