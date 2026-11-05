import '../entities/tournament_news_item.dart';

abstract class TournamentNewsRepository {
  /// Loads all news items published for a given tournament, ordered chronologically (newest first).
  Future<List<TournamentNewsItem>> loadNewsForTournament(String tournamentId);

  /// Streams news items for a given tournament, emitting immediately and upon any update.
  Stream<List<TournamentNewsItem>> watchNewsForTournament(String tournamentId);

  /// Publishes a new official news item or updates an existing one.
  Future<TournamentNewsItem> saveNewsItem(TournamentNewsItem newsItem);

  /// Permanently deletes a news item by its unique ID.
  Future<void> deleteNewsItem(String newsItemId);
}
