import 'match_alert_type.dart';

/// Represents a live match event or announcement notification generated for a user.
class MatchLiveAlert {
  final String id;
  final String matchId;
  final String tournamentId;
  final MatchAlertType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? recipientUserId;

  MatchLiveAlert({
    required this.id,
    required this.matchId,
    required this.tournamentId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.recipientUserId,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Alert ID cannot be empty');
    }
    if (matchId.trim().isEmpty) {
      throw ArgumentError.value(matchId, 'matchId', 'Match ID cannot be empty');
    }
    if (tournamentId.trim().isEmpty) {
      throw ArgumentError.value(
        tournamentId,
        'tournamentId',
        'Tournament ID cannot be empty',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title cannot be empty');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError.value(message, 'message', 'Message cannot be empty');
    }
  }

  MatchLiveAlert copyWith({
    bool? isRead,
    String? title,
    String? message,
    String? recipientUserId,
  }) {
    return MatchLiveAlert(
      id: id,
      matchId: matchId,
      tournamentId: tournamentId,
      type: type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      recipientUserId: recipientUserId ?? this.recipientUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'tournamentId': tournamentId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'recipientUserId': recipientUserId,
    };
  }

  factory MatchLiveAlert.fromJson(Map<String, dynamic> json) {
    return MatchLiveAlert(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      tournamentId: json['tournamentId'] as String,
      type: MatchAlertType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      recipientUserId:
          (json['recipientUserId'] ?? json['recipient_user_id']) as String?,
    );
  }
}
