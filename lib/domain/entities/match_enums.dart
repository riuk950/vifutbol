enum MatchStatus {
  pendingSchedule,
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get code => name;

  static MatchStatus fromCode(String? code) {
    return MatchStatus.values.firstWhere(
      (value) => value.name == code,
      orElse: () => MatchStatus.pendingSchedule,
    );
  }
}

enum ScheduleCollisionType {
  pitchConflict,
  refereeConflict,
  teamConflict;

  String get code => name;

  static ScheduleCollisionType fromCode(String? code) {
    return ScheduleCollisionType.values.firstWhere(
      (value) => value.name == code,
      orElse: () => ScheduleCollisionType.pitchConflict,
    );
  }
}
