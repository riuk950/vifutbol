/// Operational match periods controlled by the official referee.
enum MatchPeriod {
  notStarted,
  firstHalf,
  halfTime,
  secondHalf,
  fullTime,
  closed;

  String get code => name;

  static MatchPeriod fromCode(String? code) {
    return MatchPeriod.values.firstWhere(
      (value) => value.name == code,
      orElse: () => MatchPeriod.notStarted,
    );
  }

  bool get isRunning =>
      this == MatchPeriod.firstHalf || this == MatchPeriod.secondHalf;

  bool get isOpenForEvents =>
      this != MatchPeriod.notStarted && this != MatchPeriod.closed;

  bool get isClosed => this == MatchPeriod.closed;
}

/// Official event types recorded in the match report timeline.
enum MatchEventType {
  goal,
  yellowCard,
  secondYellowRedCard,
  directRedCard,
  substitution,
  periodTransition;

  String get code => name;

  static MatchEventType fromCode(String? code) {
    return MatchEventType.values.firstWhere(
      (value) => value.name == code,
      orElse: () => MatchEventType.goal,
    );
  }

  bool get isCard =>
      this == MatchEventType.yellowCard ||
      this == MatchEventType.secondYellowRedCard ||
      this == MatchEventType.directRedCard;

  bool get isExpulsion =>
      this == MatchEventType.secondYellowRedCard ||
      this == MatchEventType.directRedCard;
}
