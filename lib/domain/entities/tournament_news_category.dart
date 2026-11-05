/// Categories for official tournament announcements and bulletins.
enum TournamentNewsCategory {
  general,
  disciplinary,
  rescheduling;

  String get storageKey => name;

  static TournamentNewsCategory fromString(String value) {
    return TournamentNewsCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => TournamentNewsCategory.general,
    );
  }
}
