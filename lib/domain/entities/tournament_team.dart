import 'registered_player.dart';
import 'team_enums.dart';

/// Aggregate root representing an enrolled team in a tournament.
class TournamentTeam {
  final String id;
  final String tournamentId;
  final String name;
  final String shortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final int secondaryColorHex;
  final TeamEligibilityStatus eligibilityStatus;
  final List<RegisteredPlayer> players;
  final String? groupName;
  final DateTime updatedAt;
  final String? coachId;
  final String? coachName;
  final String? categoryLabel;

  TournamentTeam({
    required this.id,
    this.tournamentId = '',
    required this.name,
    required this.shortCode,
    this.crestShape = TeamCrestShape.shield,
    this.primaryColorHex = 0xFF00E676,
    this.secondaryColorHex = 0xFF0A0E17,
    this.eligibilityStatus = TeamEligibilityStatus.pendingVerification,
    List<RegisteredPlayer> players = const [],
    this.groupName,
    DateTime? updatedAt,
    this.coachId = 'coach-seed-1',
    this.coachName,
    this.categoryLabel,
  }) : players = List.unmodifiable(
         [...players]..sort((a, b) => a.shirtNumber.compareTo(b.shirtNumber)),
       ),
       updatedAt = updatedAt ?? DateTime.now();

  /// Normalized team name for case-insensitive and trimmed uniqueness checks.
  String get normalizedName => name.trim().toLowerCase();

  /// True if the team is officially eligible for fixtures and match play.
  bool get isEligible => eligibilityStatus == TeamEligibilityStatus.eligible;

  /// True if current enrolled players satisfy the tournament's minimum requirement.
  bool meetsMinimumQuota(int minPlayers) => players.length >= minPlayers;

  /// True if team can enroll another player without exceeding the maximum squad size.
  bool hasAvailableSlot(int maxPlayers) => players.length < maxPlayers;

  TournamentTeam copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? shortCode,
    TeamCrestShape? crestShape,
    int? primaryColorHex,
    int? secondaryColorHex,
    TeamEligibilityStatus? eligibilityStatus,
    List<RegisteredPlayer>? players,
    String? groupName,
    bool clearGroupName = false,
    DateTime? updatedAt,
    String? coachId,
    String? coachName,
    bool clearCoachName = false,
    String? categoryLabel,
    bool clearCategoryLabel = false,
  }) {
    return TournamentTeam(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      crestShape: crestShape ?? this.crestShape,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      players: players ?? this.players,
      groupName: clearGroupName ? null : (groupName ?? this.groupName),
      updatedAt: updatedAt ?? this.updatedAt,
      coachId: coachId ?? this.coachId,
      coachName: clearCoachName ? null : (coachName ?? this.coachName),
      categoryLabel:
          clearCategoryLabel ? null : (categoryLabel ?? this.categoryLabel),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'name': name,
      'shortCode': shortCode,
      'crestShape': crestShape.name,
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
      'eligibilityStatus': eligibilityStatus.name,
      'players': players.map((p) => p.toJson()).toList(),
      'groupName': groupName,
      'updatedAt': updatedAt.toIso8601String(),
      'coachId': coachId,
      'coachName': coachName,
      'categoryLabel': categoryLabel,
    };
  }

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String? ?? '',
      name: json['name'] as String,
      shortCode: (json['shortCode'] as String? ?? 'TEAM').toUpperCase(),
      crestShape: TeamCrestShape.values.firstWhere(
        (e) => e.name == json['crestShape'],
        orElse: () => TeamCrestShape.shield,
      ),
      primaryColorHex: (json['primaryColorHex'] as num?)?.toInt() ?? 0xFF00E676,
      secondaryColorHex:
          (json['secondaryColorHex'] as num?)?.toInt() ?? 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.fromJson(
        json['eligibilityStatus'] as String? ?? '',
      ),
      players: (json['players'] as List<dynamic>? ?? [])
          .map(
            (item) => RegisteredPlayer.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      groupName: json['groupName'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      coachId: json['coachId'] as String? ?? 'coach-seed-1',
      coachName: json['coachName'] as String?,
      categoryLabel: json['categoryLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentTeam && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
