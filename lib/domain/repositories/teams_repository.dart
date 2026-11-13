import '../entities/player_directory_item.dart';
import '../entities/team_directory_item.dart';
import '../entities/tournament_team.dart';

/// Contract for teams data persistence and retrieval.
abstract interface class TeamsRepository {
  /// Loads all stored teams across tournaments.
  Future<List<TournamentTeam>> loadTeams();

  /// Loads all teams belonging to a specific tournament.
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId);

  /// Persists or updates a team in storage.
  Future<TournamentTeam> saveTeam(TournamentTeam team);

  /// Replaces all teams belonging to [tournamentId] with [teams],
  /// preserving teams from other tournaments.
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  );

  /// Deletes a team by its [teamId] from storage.
  Future<void> deleteTeam(String teamId);

  /// Loads all registered players across all teams and tournaments,
  /// ordered alphabetically by full name.
  Future<List<PlayerDirectoryItem>> loadAllPlayers();

  /// Loads all unique clubs for the global Teams Directory,
  /// ordered alphabetically by club name.
  Future<List<TeamDirectoryItem>> loadAllTeams();
}
