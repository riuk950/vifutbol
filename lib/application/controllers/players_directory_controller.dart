import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';

/// Presentation projection representing an enrolled player in the directory.
class PlayerDirectoryItem {
  final RegisteredPlayer player;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final String tournamentId;
  final String tournamentName;

  const PlayerDirectoryItem({
    required this.player,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.tournamentId,
    required this.tournamentName,
  });

  /// Converts this directory item into a [PlayerPerformanceProfile] for performance modals.
  PlayerPerformanceProfile toPerformanceProfile() {
    return PlayerPerformanceProfile(
      playerId: player.id,
      tournamentId: tournamentId,
      fullName: player.fullName,
      shirtNumber: player.shirtNumber,
      position: player.position,
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      isSuspended: !player.isEligible,
    );
  }
}

/// State representation for the Players Directory screen.
class PlayersDirectoryState {
  final List<PlayerDirectoryItem> allPlayers;
  final List<ChampionshipTournament> availableTournaments;
  final String? selectedTournamentId;
  final String searchQuery;
  final UiViewState<List<PlayerDirectoryItem>> viewState;

  const PlayersDirectoryState({
    required this.allPlayers,
    required this.availableTournaments,
    required this.selectedTournamentId,
    required this.searchQuery,
    required this.viewState,
  });

  factory PlayersDirectoryState.initial({
    List<PlayerDirectoryItem> initialPlayers = const [],
    List<ChampionshipTournament> availableTournaments = const [],
    String? selectedTournamentId,
  }) {
    return PlayersDirectoryState(
      allPlayers: initialPlayers,
      availableTournaments: availableTournaments,
      selectedTournamentId: selectedTournamentId,
      searchQuery: '',
      viewState: initialPlayers.isEmpty
          ? const UiEmptyState<List<PlayerDirectoryItem>>()
          : UiContentState<List<PlayerDirectoryItem>>(initialPlayers),
    );
  }

  /// Filtered players matching tournament filter and multi-field search query.
  List<PlayerDirectoryItem> get filteredPlayers {
    var items = allPlayers;
    if (selectedTournamentId != null) {
      items = items
          .where((p) => p.tournamentId == selectedTournamentId)
          .toList();
    }

    final trimmedQuery = searchQuery.trim();
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
    List<ChampionshipTournament>? availableTournaments,
    String? selectedTournamentId,
    bool clearTournamentSelection = false,
    String? searchQuery,
    UiViewState<List<PlayerDirectoryItem>>? viewState,
  }) {
    return PlayersDirectoryState(
      allPlayers: allPlayers ?? this.allPlayers,
      availableTournaments: availableTournaments ?? this.availableTournaments,
      selectedTournamentId: clearTournamentSelection
          ? null
          : (selectedTournamentId ?? this.selectedTournamentId),
      searchQuery: searchQuery ?? this.searchQuery,
      viewState: viewState ?? this.viewState,
    );
  }
}

/// StateNotifier controlling player filtering and search state for the Players Directory.
class PlayersDirectoryController extends StateNotifier<PlayersDirectoryState> {
  PlayersDirectoryController({
    List<PlayerDirectoryItem> initialPlayers = const [],
    List<ChampionshipTournament> availableTournaments = const [],
    String? initialTournamentId,
  }) : super(
         PlayersDirectoryState.initial(
           initialPlayers: initialPlayers,
           availableTournaments: availableTournaments,
           selectedTournamentId: initialTournamentId,
         ),
       );

  /// Updates the real-time search query.
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clears the search query.
  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  /// Sets or clears the active tournament filter.
  void selectTournament(String? tournamentId) {
    state = state.copyWith(
      selectedTournamentId: tournamentId,
      clearTournamentSelection: tournamentId == null,
    );
  }

  /// Updates the raw players and tournaments data.
  void updateData({
    required List<PlayerDirectoryItem> players,
    required List<ChampionshipTournament> tournaments,
  }) {
    state = state.copyWith(
      allPlayers: players,
      availableTournaments: tournaments,
      viewState: players.isEmpty
          ? const UiEmptyState<List<PlayerDirectoryItem>>()
          : UiContentState<List<PlayerDirectoryItem>>(players),
    );
  }
}
