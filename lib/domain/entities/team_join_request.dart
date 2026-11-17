import 'team_enums.dart';

/// Status of a team join request sent by a coach to a registered player.
enum TeamJoinRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

/// Represents an invitation/request sent by a coach for a registered player to join a team roster.
class TeamJoinRequest {
  final String id;
  final String teamId;
  final String? tournamentTeamId;
  final String? tournamentId;
  final String teamName;
  final String teamShortCode;
  final String coachAccountId;
  final String coachName;
  final String playerAccountId;
  final String playerName;
  final String playerDocumentId;
  final int shirtNumber;
  final PlayerPosition position;
  final TeamJoinRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    this.tournamentTeamId,
    this.tournamentId,
    required this.teamName,
    required this.teamShortCode,
    required this.coachAccountId,
    required this.coachName,
    required this.playerAccountId,
    required this.playerName,
    required this.playerDocumentId,
    required this.shirtNumber,
    required this.position,
    this.status = TeamJoinRequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == TeamJoinRequestStatus.pending;
  bool get isAccepted => status == TeamJoinRequestStatus.accepted;
  bool get isRejected => status == TeamJoinRequestStatus.rejected;
  bool get isCancelled => status == TeamJoinRequestStatus.cancelled;

  TeamJoinRequest copyWith({
    String? id,
    String? teamId,
    String? tournamentTeamId,
    String? tournamentId,
    String? teamName,
    String? teamShortCode,
    String? coachAccountId,
    String? coachName,
    String? playerAccountId,
    String? playerName,
    String? playerDocumentId,
    int? shirtNumber,
    PlayerPosition? position,
    TeamJoinRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamJoinRequest(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      tournamentId: tournamentId ?? this.tournamentId,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      coachAccountId: coachAccountId ?? this.coachAccountId,
      coachName: coachName ?? this.coachName,
      playerAccountId: playerAccountId ?? this.playerAccountId,
      playerName: playerName ?? this.playerName,
      playerDocumentId: playerDocumentId ?? this.playerDocumentId,
      shirtNumber: shirtNumber ?? this.shirtNumber,
      position: position ?? this.position,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'tournamentTeamId': tournamentTeamId,
      'tournamentId': tournamentId,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'coachAccountId': coachAccountId,
      'coachName': coachName,
      'playerAccountId': playerAccountId,
      'playerName': playerName,
      'playerDocumentId': playerDocumentId,
      'shirtNumber': shirtNumber,
      'position': position.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    return TeamJoinRequest(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      tournamentTeamId: json['tournamentTeamId'] as String?,
      tournamentId: json['tournamentId'] as String?,
      teamName: json['teamName'] as String? ?? '',
      teamShortCode: json['teamShortCode'] as String? ?? '',
      coachAccountId: json['coachAccountId'] as String? ?? '',
      coachName: json['coachName'] as String? ?? '',
      playerAccountId: json['playerAccountId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      playerDocumentId: json['playerDocumentId'] as String? ?? '',
      shirtNumber: (json['shirtNumber'] as num).toInt(),
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.forward,
      ),
      status: TeamJoinRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeamJoinRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
