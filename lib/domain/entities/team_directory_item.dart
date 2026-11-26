import 'package:vifutbol/domain/entities/team_enums.dart';

/// Pure domain entity representing a unique club in the global Teams Directory.
class TeamDirectoryItem {
  final String id;
  final String name;
  final String shortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final int secondaryColorHex;
  final String? categoryLabel;
  final int tournamentCount;
  final int playerCount;
  final TeamEligibilityStatus eligibilityStatus;
  final String? coachId;
  final String? delegateName;
  final DateTime? foundedDate;
  final DateTime updatedAt;

  const TeamDirectoryItem({
    required this.id,
    required this.name,
    required this.shortCode,
    this.crestShape = TeamCrestShape.shield,
    this.primaryColorHex = 0xFF00E676,
    this.secondaryColorHex = 0xFF0A0E17,
    this.categoryLabel,
    this.tournamentCount = 0,
    this.playerCount = 0,
    this.eligibilityStatus = TeamEligibilityStatus.pendingVerification,
    this.coachId,
    this.delegateName,
    this.foundedDate,
    required this.updatedAt,
  });

  factory TeamDirectoryItem.fromJson(Map<String, dynamic> json) {
    final rawDelegate = json['delegateName'] as String?;
    final rawFounded = json['foundedDate'] as String?;
    return TeamDirectoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      shortCode: json['shortCode'] as String? ?? 'EQ',
      crestShape: TeamCrestShape.values.firstWhere(
        (s) => s.name == json['crestShape'],
        orElse: () => TeamCrestShape.shield,
      ),
      primaryColorHex: (json['primaryColorHex'] as num?)?.toInt() ?? 0xFF00E676,
      secondaryColorHex:
          (json['secondaryColorHex'] as num?)?.toInt() ?? 0xFF0A0E17,
      categoryLabel: json['categoryLabel'] as String?,
      tournamentCount: (json['tournamentCount'] as num?)?.toInt() ?? 0,
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      eligibilityStatus: TeamEligibilityStatus.fromJson(
        json['eligibilityStatus'] as String? ?? 'pendingVerification',
      ),
      coachId: json['coachId'] as String?,
      delegateName: (rawDelegate != null && rawDelegate.trim().isNotEmpty)
          ? rawDelegate.trim()
          : null,
      foundedDate: rawFounded != null ? DateTime.tryParse(rawFounded) : null,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortCode': shortCode,
    'crestShape': crestShape.name,
    'primaryColorHex': primaryColorHex,
    'secondaryColorHex': secondaryColorHex,
    'categoryLabel': categoryLabel,
    'tournamentCount': tournamentCount,
    'playerCount': playerCount,
    'eligibilityStatus': eligibilityStatus.name,
    'coachId': coachId,
    'delegateName': delegateName,
    'foundedDate': foundedDate != null
        ? '${foundedDate!.year.toString().padLeft(4, '0')}-${foundedDate!.month.toString().padLeft(2, '0')}-${foundedDate!.day.toString().padLeft(2, '0')}'
        : null,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamDirectoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          shortCode == other.shortCode &&
          crestShape == other.crestShape &&
          primaryColorHex == other.primaryColorHex &&
          secondaryColorHex == other.secondaryColorHex &&
          categoryLabel == other.categoryLabel &&
          tournamentCount == other.tournamentCount &&
          playerCount == other.playerCount &&
          eligibilityStatus == other.eligibilityStatus &&
          coachId == other.coachId &&
          delegateName == other.delegateName &&
          foundedDate == other.foundedDate &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortCode,
    crestShape,
    primaryColorHex,
    secondaryColorHex,
    categoryLabel,
    tournamentCount,
    playerCount,
    eligibilityStatus,
    coachId,
    delegateName,
    foundedDate,
    updatedAt,
  );
}
