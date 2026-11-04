import 'championship_match.dart';
import 'match_enums.dart';
import 'match_referee.dart';

class MatchesCatalogState {
  const MatchesCatalogState({
    this.matches = const [],
    this.referees = const [],
    this.selectedRound = 1,
    this.statusFilter,
    this.teamFilter,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<ChampionshipMatch> matches;
  final List<MatchReferee> referees;
  final int selectedRound;
  final MatchStatus? statusFilter;
  final String? teamFilter;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  List<int> get availableRounds {
    if (matches.isEmpty) return const [];
    final rounds = matches.map((m) => m.roundNumber).toSet().toList()..sort();
    return rounds;
  }

  List<ChampionshipMatch> get filteredMatches {
    return matches.where((match) {
      if (availableRounds.isNotEmpty && match.roundNumber != selectedRound) {
        return false;
      }
      if (statusFilter != null && match.status != statusFilter) {
        return false;
      }
      if (teamFilter != null &&
          teamFilter!.isNotEmpty &&
          match.homeTeamId != teamFilter &&
          match.awayTeamId != teamFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  MatchesCatalogState copyWith({
    List<ChampionshipMatch>? matches,
    List<MatchReferee>? referees,
    int? selectedRound,
    MatchStatus? Function()? statusFilter,
    String? Function()? teamFilter,
    bool? isLoading,
    bool? isSaving,
    String? Function()? errorMessage,
  }) {
    return MatchesCatalogState(
      matches: matches ?? this.matches,
      referees: referees ?? this.referees,
      selectedRound: selectedRound ?? this.selectedRound,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      teamFilter: teamFilter != null ? teamFilter() : this.teamFilter,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchesCatalogState &&
        other.matches == matches &&
        other.referees == referees &&
        other.selectedRound == selectedRound &&
        other.statusFilter == statusFilter &&
        other.teamFilter == teamFilter &&
        other.isLoading == isLoading &&
        other.isSaving == isSaving &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    matches,
    referees,
    selectedRound,
    statusFilter,
    teamFilter,
    isLoading,
    isSaving,
    errorMessage,
  );
}
