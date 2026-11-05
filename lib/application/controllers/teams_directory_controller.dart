import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';

/// State representation for the Teams Directory screen.
class TeamsDirectoryState {
  final List<TournamentTeam> allTeams;
  final List<ChampionshipTournament> availableTournaments;
  final String? selectedTournamentId;
  final String searchQuery;
  final UiViewState<List<TournamentTeam>> viewState;

  const TeamsDirectoryState({
    required this.allTeams,
    required this.availableTournaments,
    required this.selectedTournamentId,
    required this.searchQuery,
    required this.viewState,
  });

  factory TeamsDirectoryState.initial({
    List<TournamentTeam> initialTeams = const [],
    List<ChampionshipTournament> availableTournaments = const [],
    String? selectedTournamentId,
  }) {
    return TeamsDirectoryState(
      allTeams: initialTeams,
      availableTournaments: availableTournaments,
      selectedTournamentId: selectedTournamentId,
      searchQuery: '',
      viewState: initialTeams.isEmpty
          ? const UiEmptyState<List<TournamentTeam>>()
          : UiContentState<List<TournamentTeam>>(initialTeams),
    );
  }

  /// Filtered teams matching both the tournament filter and the search query.
  List<TournamentTeam> get filteredTeams {
    var teams = allTeams;
    if (selectedTournamentId != null) {
      teams = teams
          .where((team) => team.tournamentId == selectedTournamentId)
          .toList();
    }

    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isEmpty) return teams;

    return teams.where((team) {
      return matchesSearchQuery(team.name, trimmedQuery) ||
          matchesSearchQuery(team.shortCode, trimmedQuery);
    }).toList();
  }

  TeamsDirectoryState copyWith({
    List<TournamentTeam>? allTeams,
    List<ChampionshipTournament>? availableTournaments,
    String? selectedTournamentId,
    bool clearTournamentFilter = false,
    String? searchQuery,
    UiViewState<List<TournamentTeam>>? viewState,
  }) {
    return TeamsDirectoryState(
      allTeams: allTeams ?? this.allTeams,
      availableTournaments: availableTournaments ?? this.availableTournaments,
      selectedTournamentId: clearTournamentFilter
          ? null
          : (selectedTournamentId ?? this.selectedTournamentId),
      searchQuery: searchQuery ?? this.searchQuery,
      viewState: viewState ?? this.viewState,
    );
  }
}

/// State notifier managing filtering, tournament selection, and search for the Teams Directory.
class TeamsDirectoryController extends StateNotifier<TeamsDirectoryState> {
  TeamsDirectoryController({
    List<TournamentTeam> initialTeams = const [],
    List<ChampionshipTournament> availableTournaments = const [],
    String? selectedTournamentId,
  }) : super(
         TeamsDirectoryState.initial(
           initialTeams: initialTeams,
           availableTournaments: availableTournaments,
           selectedTournamentId: selectedTournamentId,
         ),
       );

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  void selectTournamentFilter(String? tournamentId) {
    if (tournamentId == null) {
      state = state.copyWith(clearTournamentFilter: true);
    } else {
      state = state.copyWith(selectedTournamentId: tournamentId);
    }
  }

  void updateData({
    List<TournamentTeam>? teams,
    List<ChampionshipTournament>? tournaments,
  }) {
    final updatedTeams = teams ?? state.allTeams;
    final updatedTournaments = tournaments ?? state.availableTournaments;

    state = state.copyWith(
      allTeams: updatedTeams,
      availableTournaments: updatedTournaments,
      viewState: updatedTeams.isEmpty
          ? const UiEmptyState<List<TournamentTeam>>()
          : UiContentState<List<TournamentTeam>>(updatedTeams),
    );
  }
}
