import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// State representation for the global Teams Directory screen.
class TeamsDirectoryState {
  final List<TeamDirectoryItem> allTeams;
  final String searchQuery;
  final UiViewState<List<TeamDirectoryItem>> viewState;

  const TeamsDirectoryState({
    required this.allTeams,
    required this.searchQuery,
    required this.viewState,
  });

  factory TeamsDirectoryState.initial({
    List<TeamDirectoryItem> initialTeams = const [],
  }) {
    final sorted = _sortAlphabetically(initialTeams);
    return TeamsDirectoryState(
      allTeams: sorted,
      searchQuery: '',
      viewState: sorted.isEmpty
          ? const UiEmptyState<List<TeamDirectoryItem>>()
          : UiContentState<List<TeamDirectoryItem>>(sorted),
    );
  }

  static List<TeamDirectoryItem> _sortAlphabetically(
    List<TeamDirectoryItem> teams,
  ) {
    return [...teams]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Filtered teams matching the search query, ordered alphabetically A-Z.
  List<TeamDirectoryItem> get filteredTeams {
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isEmpty) return allTeams;

    return allTeams.where((team) {
      return matchesSearchQuery(team.name, trimmedQuery) ||
          matchesSearchQuery(team.shortCode, trimmedQuery) ||
          matchesSearchQuery(team.categoryLabel ?? '', trimmedQuery);
    }).toList();
  }

  TeamsDirectoryState copyWith({
    List<TeamDirectoryItem>? allTeams,
    String? searchQuery,
    UiViewState<List<TeamDirectoryItem>>? viewState,
  }) {
    return TeamsDirectoryState(
      allTeams: allTeams ?? this.allTeams,
      searchQuery: searchQuery ?? this.searchQuery,
      viewState: viewState ?? this.viewState,
    );
  }
}

/// State notifier managing dynamic cloud/local loading, pull-to-refresh,
/// and reactive search for the global Teams Directory.
class TeamsDirectoryController extends StateNotifier<TeamsDirectoryState> {
  final TeamsRepository? teamsRepository;

  TeamsDirectoryController({
    this.teamsRepository,
    List<TeamDirectoryItem> initialTeams = const [],
  }) : super(TeamsDirectoryState.initial(initialTeams: initialTeams));

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  /// Initial load of unique clubs from the repository (remote-first + Hive cache).
  Future<void> loadTeams() async {
    final repo = teamsRepository;
    if (repo == null) return;

    state = state.copyWith(viewState: const UiLoadingState());

    try {
      final teams = await repo.loadAllTeams();
      final sorted = TeamsDirectoryState._sortAlphabetically(teams);
      state = state.copyWith(
        allTeams: sorted,
        viewState: sorted.isEmpty
            ? const UiEmptyState<List<TeamDirectoryItem>>()
            : UiContentState<List<TeamDirectoryItem>>(sorted),
      );
    } catch (e) {
      if (state.allTeams.isNotEmpty) {
        state = state.copyWith(
          viewState: UiContentState<List<TeamDirectoryItem>>(state.allTeams),
        );
      } else {
        state = state.copyWith(
          viewState: UiErrorState<List<TeamDirectoryItem>>(
            DataLoadFailure(e.toString(), e),
          ),
        );
      }
    }
  }

  /// Manual pull-to-refresh. Returns `true` if refresh succeeded, or `false`
  /// if it failed (preserving existing cached teams in state).
  Future<bool> refreshTeams() async {
    final repo = teamsRepository;
    if (repo == null) return false;

    try {
      final teams = await repo.loadAllTeams();
      final sorted = TeamsDirectoryState._sortAlphabetically(teams);
      state = state.copyWith(
        allTeams: sorted,
        viewState: sorted.isEmpty
            ? const UiEmptyState<List<TeamDirectoryItem>>()
            : UiContentState<List<TeamDirectoryItem>>(sorted),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateData({List<TeamDirectoryItem>? teams}) {
    final updatedTeams = TeamsDirectoryState._sortAlphabetically(
      teams ?? state.allTeams,
    );

    state = state.copyWith(
      allTeams: updatedTeams,
      viewState: updatedTeams.isEmpty
          ? const UiEmptyState<List<TeamDirectoryItem>>()
          : UiContentState<List<TeamDirectoryItem>>(updatedTeams),
    );
  }
}
