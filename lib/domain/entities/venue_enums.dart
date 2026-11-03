/// Types of playing surfaces for pitches.
enum PitchSurfaceType {
  syntheticGrass,
  naturalGrass,
  dirtOrSand,
  hardCourt;

  String toJson() => name;

  static PitchSurfaceType fromJson(String value) {
    return PitchSurfaceType.values.firstWhere(
      (element) => element.name == value,
      orElse: () => PitchSurfaceType.syntheticGrass,
    );
  }
}

/// Match formats and pitch dimensions.
enum PitchFormat {
  football5,
  football7,
  football8,
  football11;

  String toJson() => name;

  static PitchFormat fromJson(String value) {
    return PitchFormat.values.firstWhere(
      (element) => element.name == value,
      orElse: () => PitchFormat.football7,
    );
  }
}

/// Operational and maintenance status for venues and individual pitches.
enum VenueOperationalStatus {
  active,
  maintenance;

  String toJson() => name;

  static VenueOperationalStatus fromJson(String value) {
    return VenueOperationalStatus.values.firstWhere(
      (element) => element.name == value,
      orElse: () => VenueOperationalStatus.active,
    );
  }
}
