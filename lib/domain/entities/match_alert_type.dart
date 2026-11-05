/// Categorization of live and scheduled match alerts.
enum MatchAlertType {
  matchUpcoming,
  matchStarted,
  goalScored,
  matchEnded,
  newsPublished;

  String get storageKey => name;

  static MatchAlertType fromString(String value) {
    return MatchAlertType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => MatchAlertType.matchUpcoming,
    );
  }
}
