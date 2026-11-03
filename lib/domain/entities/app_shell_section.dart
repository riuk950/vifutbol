/// Sections available in the bottom navigation bar of the App Shell.
enum AppShellSection { matchday, standings, venues, profile }

/// Domain state representation of the App Shell container.
class AppShellState {
  final AppShellSection activeSection;

  const AppShellState({this.activeSection = AppShellSection.matchday});

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
