import 'match_report_enums.dart';

/// Represents an immutable official incident recorded in the match timeline.
class MatchEvent {
  MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.minute,
    required this.teamId,
    this.primaryPlayerId,
    this.primaryPlayerName,
    this.primaryPlayerShirtNumber,
    this.secondaryPlayerId,
    this.secondaryPlayerName,
    this.secondaryPlayerShirtNumber,
    this.linkedParentEventId,
    this.description,
    this.isSynced = true,
    DateTime? createdAt,
  }) : assert(id.isNotEmpty, 'Event id cannot be empty'),
       assert(matchId.isNotEmpty, 'Match id cannot be empty'),
       assert(teamId.isNotEmpty, 'Team id cannot be empty'),
       assert(minute >= 1 && minute <= 130, 'Minute must be between 1 and 130'),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String matchId;
  final MatchEventType type;
  final int minute;
  final String teamId;
  final String? primaryPlayerId;
  final String? primaryPlayerName;
  final int? primaryPlayerShirtNumber;
  final String? secondaryPlayerId;
  final String? secondaryPlayerName;
  final int? secondaryPlayerShirtNumber;
  final String? linkedParentEventId;
  final String? description;
  final bool isSynced;
  final DateTime createdAt;

  MatchEvent copyWith({
    String? id,
    String? matchId,
    MatchEventType? type,
    int? minute,
    String? teamId,
    String? primaryPlayerId,
    String? primaryPlayerName,
    int? primaryPlayerShirtNumber,
    String? secondaryPlayerId,
    String? secondaryPlayerName,
    int? secondaryPlayerShirtNumber,
    String? linkedParentEventId,
    String? description,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return MatchEvent(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      type: type ?? this.type,
      minute: minute ?? this.minute,
      teamId: teamId ?? this.teamId,
      primaryPlayerId: primaryPlayerId ?? this.primaryPlayerId,
      primaryPlayerName: primaryPlayerName ?? this.primaryPlayerName,
      primaryPlayerShirtNumber:
          primaryPlayerShirtNumber ?? this.primaryPlayerShirtNumber,
      secondaryPlayerId: secondaryPlayerId ?? this.secondaryPlayerId,
      secondaryPlayerName: secondaryPlayerName ?? this.secondaryPlayerName,
      secondaryPlayerShirtNumber:
          secondaryPlayerShirtNumber ?? this.secondaryPlayerShirtNumber,
      linkedParentEventId: linkedParentEventId ?? this.linkedParentEventId,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'type': type.name,
      'minute': minute,
      'teamId': teamId,
      'primaryPlayerId': primaryPlayerId,
      'primaryPlayerName': primaryPlayerName,
      'primaryPlayerShirtNumber': primaryPlayerShirtNumber,
      'secondaryPlayerId': secondaryPlayerId,
      'secondaryPlayerName': secondaryPlayerName,
      'secondaryPlayerShirtNumber': secondaryPlayerShirtNumber,
      'linkedParentEventId': linkedParentEventId,
      'description': description,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      type: MatchEventType.fromCode(json['type'] as String?),
      minute: (json['minute'] as num?)?.toInt() ?? 1,
      teamId: json['teamId'] as String? ?? '',
      primaryPlayerId: json['primaryPlayerId'] as String?,
      primaryPlayerName: json['primaryPlayerName'] as String?,
      primaryPlayerShirtNumber: (json['primaryPlayerShirtNumber'] as num?)
          ?.toInt(),
      secondaryPlayerId: json['secondaryPlayerId'] as String?,
      secondaryPlayerName: json['secondaryPlayerName'] as String?,
      secondaryPlayerShirtNumber: (json['secondaryPlayerShirtNumber'] as num?)
          ?.toInt(),
      linkedParentEventId: json['linkedParentEventId'] as String?,
      description: json['description'] as String?,
      isSynced: json['isSynced'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchEvent &&
        other.id == id &&
        other.matchId == matchId &&
        other.type == type &&
        other.minute == minute &&
        other.teamId == teamId &&
        other.primaryPlayerId == primaryPlayerId &&
        other.secondaryPlayerId == secondaryPlayerId &&
        other.linkedParentEventId == linkedParentEventId &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    type,
    minute,
    teamId,
    primaryPlayerId,
    secondaryPlayerId,
    isSynced,
  );
}
