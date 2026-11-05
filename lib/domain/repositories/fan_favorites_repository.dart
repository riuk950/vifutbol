import '../entities/fan_favorite_team.dart';

abstract class FanFavoritesRepository {
  /// Loads all favorite teams saved by the user for a specific tournament.
  Future<List<FanFavoriteTeam>> loadFavoriteTeams(
    String userId,
    String tournamentId,
  );

  /// Streams favorite teams for reactive UI badges.
  Stream<List<FanFavoriteTeam>> watchFavoriteTeams(
    String userId,
    String tournamentId,
  );

  /// Adds or updates a team in the user's favorites list.
  Future<void> saveFavoriteTeam(FanFavoriteTeam favorite);

  /// Removes a team from favorites.
  Future<void> removeFavoriteTeam(
    String userId,
    String tournamentId,
    String teamId,
  );

  /// Toggles favorite status: adds if not present, removes if already present.
  /// Returns `true` if added, `false` if removed.
  Future<bool> toggleFavoriteTeam(FanFavoriteTeam favorite);
}
