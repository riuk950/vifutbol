// lib/domain/entities/role_profile_data.dart

import 'package:vifutbol/domain/entities/team_enums.dart';

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

  // HU 21.1 Player Personal & Tactical Fields
  final String? firstName;
  final String? secondName;
  final String? firstSurname;
  final String? secondSurname;
  final String? sex;
  final DateTime? birthDate;
  final String? bloodType;
  final String? department;
  final String? municipality;
  final PlayerPosition? primaryPosition;
  final List<String> secondaryPositions;

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
    this.firstName,
    this.secondName,
    this.firstSurname,
    this.secondSurname,
    this.sex,
    this.birthDate,
    this.bloodType,
    this.department,
    this.municipality,
    this.primaryPosition,
    this.secondaryPositions = const [],
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
    String? firstName,
    String? secondName,
    String? firstSurname,
    String? secondSurname,
    String? sex,
    DateTime? birthDate,
    String? bloodType,
    String? department,
    String? municipality,
    PlayerPosition? primaryPosition,
    List<String>? secondaryPositions,
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
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      firstSurname: firstSurname ?? this.firstSurname,
      secondSurname: secondSurname ?? this.secondSurname,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      department: department ?? this.department,
      municipality: municipality ?? this.municipality,
      primaryPosition: primaryPosition ?? this.primaryPosition,
      secondaryPositions: secondaryPositions ?? this.secondaryPositions,
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
      if (firstName != null) 'firstName': firstName,
      if (secondName != null) 'secondName': secondName,
      if (firstSurname != null) 'firstSurname': firstSurname,
      if (secondSurname != null) 'secondSurname': secondSurname,
      if (sex != null) 'sex': sex,
      if (birthDate != null)
        'birthDate':
            '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
      if (bloodType != null) 'bloodType': bloodType,
      if (department != null) 'department': department,
      if (municipality != null) 'municipality': municipality,
      if (primaryPosition != null) 'primaryPosition': primaryPosition!.name,
      if (secondaryPositions.isNotEmpty)
        'secondaryPositions': secondaryPositions,
    };
  }

  factory RoleProfileData.fromJson(Map<String, dynamic> json) {
    String? readStr(String camel, String snake) {
      final raw = json[camel] ?? json[snake];
      if (raw is! String) return null;
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    DateTime? readDate(String camel, String snake) {
      final raw = json[camel] ?? json[snake];
      if (raw is DateTime) return raw;
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isNotEmpty) {
          return DateTime.tryParse(trimmed);
        }
      }
      return null;
    }

    PlayerPosition? readPosition(String camel, String snake, String alt) {
      final raw = json[camel] ?? json[snake] ?? json[alt];
      if (raw is! String) return null;
      final normalized = raw.trim().toLowerCase();
      for (final p in PlayerPosition.values) {
        if (p.name.toLowerCase() == normalized) return p;
      }
      return null;
    }

    List<String> readList(String camel, String snake) {
      final raw = json[camel] ?? json[snake];
      if (raw is List) {
        return raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const [];
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
      firstName: readStr('firstName', 'first_name'),
      secondName: readStr('secondName', 'second_name'),
      firstSurname: readStr('firstSurname', 'first_surname'),
      secondSurname: readStr('secondSurname', 'second_surname'),
      sex: readStr('sex', 'sex'),
      birthDate: readDate('birthDate', 'birth_date'),
      bloodType: readStr('bloodType', 'blood_type'),
      department: readStr('department', 'department'),
      municipality: readStr('municipality', 'municipality'),
      primaryPosition: readPosition('primaryPosition', 'primary_position', 'position'),
      secondaryPositions: readList('secondaryPositions', 'secondary_positions'),
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
          linkedRefereeId == other.linkedRefereeId &&
          firstName == other.firstName &&
          secondName == other.secondName &&
          firstSurname == other.firstSurname &&
          secondSurname == other.secondSurname &&
          sex == other.sex &&
          birthDate == other.birthDate &&
          bloodType == other.bloodType &&
          department == other.department &&
          municipality == other.municipality &&
          primaryPosition == other.primaryPosition &&
          _listEquals(secondaryPositions, other.secondaryPositions);

  @override
  int get hashCode => Object.hashAll([
        clubName,
        licenseLevel,
        organizationName,
        baseCity,
        city,
        preferences,
        certificationLevel,
        linkedPlayerId,
        linkedRefereeId,
        firstName,
        secondName,
        firstSurname,
        secondSurname,
        sex,
        birthDate,
        bloodType,
        department,
        municipality,
        primaryPosition,
        Object.hashAll(secondaryPositions),
      ]);

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
