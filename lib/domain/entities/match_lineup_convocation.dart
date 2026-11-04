import 'lineup_enums.dart';

/// Convocation and lineup configuration for an upcoming match.
class MatchLineupConvocation {
  final String id;
  final String tournamentId;
  final String teamId;
  final String matchLabel;
  final List<String> starterPlayerIds;
  final List<String> substitutePlayerIds;
  final String? captainPlayerId;
  final ConvocationStatus status;
  final List<String> confirmedStarterPlayerIds;
  final List<String> confirmedSubstitutePlayerIds;
  final String? confirmedCaptainPlayerId;
  final DateTime? confirmedAt;
  final DateTime updatedAt;

  MatchLineupConvocation({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    this.matchLabel = 'Próximo Partido Oficial',
    List<String> starterPlayerIds = const [],
    List<String> substitutePlayerIds = const [],
    this.captainPlayerId,
    this.status = ConvocationStatus.draft,
    List<String> confirmedStarterPlayerIds = const [],
    List<String> confirmedSubstitutePlayerIds = const [],
    this.confirmedCaptainPlayerId,
    this.confirmedAt,
    DateTime? updatedAt,
  }) : starterPlayerIds = List.unmodifiable(starterPlayerIds),
       substitutePlayerIds = List.unmodifiable(substitutePlayerIds),
       confirmedStarterPlayerIds = List.unmodifiable(confirmedStarterPlayerIds),
       confirmedSubstitutePlayerIds = List.unmodifiable(
         confirmedSubstitutePlayerIds,
       ),
       updatedAt = updatedAt ?? DateTime.now();

  /// Checks if a player is selected as starter.
  bool isStarter(String playerId) => starterPlayerIds.contains(playerId);

  /// Checks if a player is selected as substitute.
  bool isSubstitute(String playerId) => substitutePlayerIds.contains(playerId);

  /// Checks if a player is designated as captain.
  bool isCaptain(String playerId) => captainPlayerId == playerId;

  /// Returns the current role for a player.
  PlayerConvocationRole roleForPlayer(String playerId) {
    if (isStarter(playerId)) return PlayerConvocationRole.starter;
    if (isSubstitute(playerId)) return PlayerConvocationRole.substitute;
    return PlayerConvocationRole.notConvoked;
  }

  /// True if the convocation has at least one confirmed snapshot synced for the referee report.
  bool get isSyncedWithRefereeReport =>
      confirmedAt != null && confirmedStarterPlayerIds.isNotEmpty;

  MatchLineupConvocation copyWith({
    String? id,
    String? tournamentId,
    String? teamId,
    String? matchLabel,
    List<String>? starterPlayerIds,
    List<String>? substitutePlayerIds,
    String? Function()? captainPlayerId,
    ConvocationStatus? status,
    List<String>? confirmedStarterPlayerIds,
    List<String>? confirmedSubstitutePlayerIds,
    String? Function()? confirmedCaptainPlayerId,
    DateTime? Function()? confirmedAt,
    DateTime? updatedAt,
  }) {
    return MatchLineupConvocation(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      matchLabel: matchLabel ?? this.matchLabel,
      starterPlayerIds: starterPlayerIds ?? this.starterPlayerIds,
      substitutePlayerIds: substitutePlayerIds ?? this.substitutePlayerIds,
      captainPlayerId: captainPlayerId != null
          ? captainPlayerId()
          : this.captainPlayerId,
      status: status ?? this.status,
      confirmedStarterPlayerIds:
          confirmedStarterPlayerIds ?? this.confirmedStarterPlayerIds,
      confirmedSubstitutePlayerIds:
          confirmedSubstitutePlayerIds ?? this.confirmedSubstitutePlayerIds,
      confirmedCaptainPlayerId: confirmedCaptainPlayerId != null
          ? confirmedCaptainPlayerId()
          : this.confirmedCaptainPlayerId,
      confirmedAt: confirmedAt != null ? confirmedAt() : this.confirmedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'teamId': teamId,
      'matchLabel': matchLabel,
      'starterPlayerIds': starterPlayerIds,
      'substitutePlayerIds': substitutePlayerIds,
      'captainPlayerId': captainPlayerId,
      'status': status.name,
      'confirmedStarterPlayerIds': confirmedStarterPlayerIds,
      'confirmedSubstitutePlayerIds': confirmedSubstitutePlayerIds,
      'confirmedCaptainPlayerId': confirmedCaptainPlayerId,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MatchLineupConvocation.fromJson(Map<String, dynamic> json) {
    return MatchLineupConvocation(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      teamId: json['teamId'] as String,
      matchLabel: json['matchLabel'] as String? ?? 'Próximo Partido Oficial',
      starterPlayerIds: (json['starterPlayerIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      substitutePlayerIds: (json['substitutePlayerIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      captainPlayerId: json['captainPlayerId'] as String?,
      status: ConvocationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConvocationStatus.draft,
      ),
      confirmedStarterPlayerIds:
          (json['confirmedStarterPlayerIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      confirmedSubstitutePlayerIds:
          (json['confirmedSubstitutePlayerIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      confirmedCaptainPlayerId: json['confirmedCaptainPlayerId'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchLineupConvocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
