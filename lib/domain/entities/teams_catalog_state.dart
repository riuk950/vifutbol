import '../failures/app_failure.dart';
import 'tournament_team.dart';

/// State representation of the teams catalog and active selection.
class TeamsCatalogState {
  final List<TournamentTeam> teams;
  final String? selectedTeamId;
  final bool isSaving;
  final AppFailure? lastFailure;

  const TeamsCatalogState({
    this.teams = const [],
    this.selectedTeamId,
    this.isSaving = false,
    this.lastFailure,
  });

  /// The currently selected team, if any.
  TournamentTeam? get selectedTeam {
    if (selectedTeamId == null) return null;
    try {
      return teams.firstWhere((t) => t.id == selectedTeamId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all teams associated with a specific tournament.
  List<TournamentTeam> teamsForTournament(String tournamentId) {
    return teams.where((t) => t.tournamentId == tournamentId).toList();
  }

  TeamsCatalogState copyWith({
    List<TournamentTeam>? teams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    bool? isSaving,
    AppFailure? lastFailure,
    bool clearLastFailure = false,
  }) {
    return TeamsCatalogState(
      teams: teams ?? this.teams,
      selectedTeamId: clearSelectedTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      isSaving: isSaving ?? this.isSaving,
      lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}
