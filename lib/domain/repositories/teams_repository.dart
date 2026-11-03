import '../entities/tournament_team.dart';

/// Contract for teams data persistence and retrieval.
abstract interface class TeamsRepository {
  /// Loads all stored teams across tournaments.
  Future<List<TournamentTeam>> loadTeams();

  /// Loads all teams belonging to a specific tournament.
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId);

  /// Persists or updates a team in storage.
  Future<TournamentTeam> saveTeam(TournamentTeam team);
}
