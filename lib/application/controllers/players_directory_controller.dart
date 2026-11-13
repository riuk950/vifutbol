import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

export 'package:vifutbol/domain/entities/player_directory_item.dart';

/// State representation for the Players Directory screen.
class PlayersDirectoryState {
  final List<PlayerDirectoryItem> allPlayers;
  final String searchQuery;
  final UiViewState<List<PlayerDirectoryItem>> viewState;

  const PlayersDirectoryState({
    required this.allPlayers,
    required this.searchQuery,
    required this.viewState,
  });

  factory PlayersDirectoryState.initial({
    List<PlayerDirectoryItem> initialPlayers = const [],
  }) {
    final sorted = List<PlayerDirectoryItem>.from(initialPlayers)
      ..sort(
        (a, b) => a.player.fullName.toLowerCase().compareTo(
          b.player.fullName.toLowerCase(),
        ),
      );

    return PlayersDirectoryState(
      allPlayers: sorted,
      searchQuery: '',
      viewState: sorted.isEmpty
          ? const UiEmptyState<List<PlayerDirectoryItem>>()
          : UiContentState<List<PlayerDirectoryItem>>(sorted),
    );
  }

  /// Filtered players matching multi-field search query, sorted alphabetically A-Z.
  List<PlayerDirectoryItem> get filteredPlayers {
    final trimmedQuery = searchQuery.trim();
    final items = List<PlayerDirectoryItem>.from(allPlayers);

    items.sort(
      (a, b) => a.player.fullName.toLowerCase().compareTo(
        b.player.fullName.toLowerCase(),
      ),
    );

    if (trimmedQuery.isEmpty) return items;

    return items.where((item) {
      final p = item.player;
      return matchesSearchQuery(p.fullName, trimmedQuery) ||
          p.shirtNumber.toString() == trimmedQuery ||
          matchesSearchQuery(item.teamName, trimmedQuery) ||
          matchesSearchQuery(item.teamShortCode, trimmedQuery) ||
          matchesSearchQuery(p.position.name, trimmedQuery) ||
          _matchesPositionSpanish(p.position, trimmedQuery);
    }).toList();
  }

  static bool _matchesPositionSpanish(PlayerPosition position, String query) {
    final normalized = normalizeSearchText(query);
    final List<String> keywords;
    switch (position) {
      case PlayerPosition.goalkeeper:
        keywords = const ['portero', 'arquero', 'goalkeeper'];
      case PlayerPosition.defender:
        keywords = const ['defensa', 'zaguero', 'defender'];
      case PlayerPosition.midfielder:
        keywords = const [
          'centrocampista',
          'mediocampista',
          'volante',
          'medio',
          'midfielder',
        ];
      case PlayerPosition.forward:
        keywords = const ['delantero', 'atacante', 'forward'];
    }
    return keywords.any(
      (k) => k.startsWith(normalized) || normalized.contains(k),
    );
  }

  PlayersDirectoryState copyWith({
    List<PlayerDirectoryItem>? allPlayers,
    String? searchQuery,
    UiViewState<List<PlayerDirectoryItem>>? viewState,
  }) {
    return PlayersDirectoryState(
      allPlayers: allPlayers ?? this.allPlayers,
      searchQuery: searchQuery ?? this.searchQuery,
      viewState: viewState ?? this.viewState,
    );
  }
}

/// StateNotifier controlling player loading, refresh, and search for the Players Directory.
class PlayersDirectoryController extends StateNotifier<PlayersDirectoryState> {
  PlayersDirectoryController({
    this.teamsRepository,
    List<PlayerDirectoryItem> initialPlayers = const [],
  }) : super(PlayersDirectoryState.initial(initialPlayers: initialPlayers));

  final TeamsRepository? teamsRepository;

  /// Loads players from [TeamsRepository] (Supabase cloud or local Hive cache).
  Future<void> loadPlayers() async {
    if (teamsRepository == null) return;

    if (state.allPlayers.isEmpty) {
      state = state.copyWith(
        viewState: const UiLoadingState<List<PlayerDirectoryItem>>(),
      );
    }

    try {
      final players = await teamsRepository!.loadAllPlayers();
      updateData(players: players);
    } catch (e) {
      if (state.allPlayers.isEmpty) {
        state = state.copyWith(
          viewState: UiErrorState<List<PlayerDirectoryItem>>(
            DataLoadFailure(e.toString(), e),
          ),
        );
      }
    }
  }

  /// Triggers a pull-to-refresh reload from the cloud.
  /// Returns `true` if reload succeeded, or `false` on failure (e.g. offline).
  Future<bool> refreshPlayers() async {
    if (teamsRepository == null) return true;

    try {
      final players = await teamsRepository!.loadAllPlayers();
      updateData(players: players);
      return true;
    } catch (_) {
      // Preserve existing data on failure and signal caller
      return false;
    }
  }

  /// Updates the real-time search query.
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clears the search query.
  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  /// Updates the directory players list.
  void updateData({required List<PlayerDirectoryItem> players}) {
    final sorted = List<PlayerDirectoryItem>.from(players)
      ..sort(
        (a, b) => a.player.fullName.toLowerCase().compareTo(
          b.player.fullName.toLowerCase(),
        ),
      );

    state = state.copyWith(
      allPlayers: sorted,
      viewState: sorted.isEmpty
          ? const UiEmptyState<List<PlayerDirectoryItem>>()
          : UiContentState<List<PlayerDirectoryItem>>(sorted),
    );
  }
}
