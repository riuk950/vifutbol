/// Sections available in the bottom navigation bar of the App Shell.
enum AppShellSection {
  matches,
  explore,
  news,
  profile;

  /// Compatibility alias for [matches].
  static const AppShellSection matchday = AppShellSection.matches;

  /// Compatibility alias for [explore].
  static const AppShellSection standings = AppShellSection.explore;

  /// Compatibility alias for [news].
  static const AppShellSection venues = AppShellSection.news;
}

/// Domain state representation of the App Shell container.
class AppShellState {
  final AppShellSection activeSection;

  const AppShellState({this.activeSection = AppShellSection.matches});

  AppShellState copyWith({AppShellSection? activeSection}) {
    return AppShellState(activeSection: activeSection ?? this.activeSection);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppShellState &&
          runtimeType == other.runtimeType &&
          activeSection == other.activeSection;

  @override
  int get hashCode => activeSection.hashCode;
}
