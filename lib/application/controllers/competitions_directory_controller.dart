import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';

/// State representation for the Competitions Directory screen.
class CompetitionsDirectoryState {
  final List<ChampionshipTournament> allTournaments;
  final String searchQuery;
  final UiViewState<List<ChampionshipTournament>> viewState;

  const CompetitionsDirectoryState({
    required this.allTournaments,
    required this.searchQuery,
    required this.viewState,
  });

  factory CompetitionsDirectoryState.initial({
    List<ChampionshipTournament> initialTournaments = const [],
  }) {
    return CompetitionsDirectoryState(
      allTournaments: initialTournaments,
      searchQuery: '',
      viewState: initialTournaments.isEmpty
          ? const UiEmptyState<List<ChampionshipTournament>>()
          : UiContentState<List<ChampionshipTournament>>(initialTournaments),
    );
  }

  /// Filtered tournaments matching the active search query across name and category.
  List<ChampionshipTournament> get filteredTournaments {
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isEmpty) return allTournaments;

    return allTournaments.where((tournament) {
      return matchesSearchQuery(tournament.name, trimmedQuery) ||
          matchesSearchQuery(tournament.category, trimmedQuery);
    }).toList();
  }

  CompetitionsDirectoryState copyWith({
    List<ChampionshipTournament>? allTournaments,
    String? searchQuery,
    UiViewState<List<ChampionshipTournament>>? viewState,
  }) {
    return CompetitionsDirectoryState(
      allTournaments: allTournaments ?? this.allTournaments,
      searchQuery: searchQuery ?? this.searchQuery,
      viewState: viewState ?? this.viewState,
    );
  }
}

/// State notifier managing real-time filtering and search for the Competitions Directory.
class CompetitionsDirectoryController
    extends StateNotifier<CompetitionsDirectoryState> {
  CompetitionsDirectoryController({
    List<ChampionshipTournament> initialTournaments = const [],
  }) : super(
         CompetitionsDirectoryState.initial(
           initialTournaments: initialTournaments,
         ),
       );

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  void updateTournaments(List<ChampionshipTournament> tournaments) {
    state = state.copyWith(
      allTournaments: tournaments,
      viewState: tournaments.isEmpty
          ? const UiEmptyState<List<ChampionshipTournament>>()
          : UiContentState<List<ChampionshipTournament>>(tournaments),
    );
  }
}
