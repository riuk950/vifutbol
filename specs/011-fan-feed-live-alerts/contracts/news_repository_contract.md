# Contract: Tournament News Repository

**Feature**: Feed de Noticias, Marcadores en Tiempo Real y Alertas para Aficionados (HU 9.1)  
**Location**: `lib/domain/repositories/tournament_news_repository.dart`

---

## Abstract Interface

```dart
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
```

## Behavior and Guarantees
- Emits in descending order of `publishedAt` (pinned items first if `isPinned == true`).
- Guarantees thread-safe / atomic updates to local storage cache.
- The stream returned by `watchNewsForTournament` must be a broadcast stream or multicast, cleanly cancelling without leaking listeners upon caller cancellation.
