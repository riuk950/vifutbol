/// Role-specific profile attributes persisted in cloud satellite tables or
/// linked `players` / `match_referees` records.
class RoleProfileData {
  final String? clubName;
  final String? licenseLevel;
  final String? organizationName;
  final String? baseCity;
  final String? city;
  final String? preferences;
  final String? certificationLevel;
  final String? linkedPlayerId;
  final String? linkedRefereeId;

  const RoleProfileData({
    this.clubName,
    this.licenseLevel,
    this.organizationName,
    this.baseCity,
    this.city,
    this.preferences,
    this.certificationLevel,
    this.linkedPlayerId,
    this.linkedRefereeId,
  });

  RoleProfileData copyWith({
    String? clubName,
    String? licenseLevel,
    String? organizationName,
    String? baseCity,
    String? city,
    String? preferences,
    String? certificationLevel,
    String? linkedPlayerId,
    String? linkedRefereeId,
  }) {
    return RoleProfileData(
      clubName: clubName ?? this.clubName,
      licenseLevel: licenseLevel ?? this.licenseLevel,
      organizationName: organizationName ?? this.organizationName,
      baseCity: baseCity ?? this.baseCity,
      city: city ?? this.city,
      preferences: preferences ?? this.preferences,
      certificationLevel: certificationLevel ?? this.certificationLevel,
      linkedPlayerId: linkedPlayerId ?? this.linkedPlayerId,
      linkedRefereeId: linkedRefereeId ?? this.linkedRefereeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (clubName != null) 'clubName': clubName,
      if (licenseLevel != null) 'licenseLevel': licenseLevel,
      if (organizationName != null) 'organizationName': organizationName,
      if (baseCity != null) 'baseCity': baseCity,
      if (city != null) 'city': city,
      if (preferences != null) 'preferences': preferences,
      if (certificationLevel != null) 'certificationLevel': certificationLevel,
      if (linkedPlayerId != null) 'linkedPlayerId': linkedPlayerId,
      if (linkedRefereeId != null) 'linkedRefereeId': linkedRefereeId,
    };
  }

  factory RoleProfileData.fromJson(Map<String, dynamic> json) {
    String? readStr(String camel, String snake) {
      final raw = json[camel] ?? json[snake];
      if (raw is! String) return null;
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return RoleProfileData(
      clubName: readStr('clubName', 'club_name'),
      licenseLevel: readStr('licenseLevel', 'license_level'),
      organizationName: readStr('organizationName', 'organization_name'),
      baseCity: readStr('baseCity', 'base_city'),
      city: readStr('city', 'city'),
      preferences: readStr('preferences', 'preferences'),
      certificationLevel: readStr('certificationLevel', 'certification_level'),
      linkedPlayerId: readStr('linkedPlayerId', 'linked_player_id'),
      linkedRefereeId: readStr('linkedRefereeId', 'linked_referee_id'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleProfileData &&
          runtimeType == other.runtimeType &&
          clubName == other.clubName &&
          licenseLevel == other.licenseLevel &&
          organizationName == other.organizationName &&
          baseCity == other.baseCity &&
          city == other.city &&
          preferences == other.preferences &&
          certificationLevel == other.certificationLevel &&
          linkedPlayerId == other.linkedPlayerId &&
          linkedRefereeId == other.linkedRefereeId;

  @override
  int get hashCode => Object.hash(
        clubName,
        licenseLevel,
        organizationName,
        baseCity,
        city,
        preferences,
        certificationLevel,
        linkedPlayerId,
        linkedRefereeId,
      );
}
