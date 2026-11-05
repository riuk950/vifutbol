# Contract: Live Matches Stream Contract

**Feature**: Feed de Noticias, Marcadores en Tiempo Real y Alertas para Aficionados (HU 9.1)  
**Location**: `lib/domain/repositories/tournament_matches_repository.dart`

---

## Extension to `TournamentMatchesRepository`

```dart
abstract class TournamentMatchesRepository {
  // Existing methods:
  Future<List<ChampionshipMatch>> loadMatchesForTournament(String tournamentId);
  Future<ChampionshipMatch> saveMatch(ChampionshipMatch match);
  Future<List<ChampionshipMatch>> saveMatchesBatch(List<ChampionshipMatch> matches);
  Future<List<MatchReferee>> loadOfficialReferees();

  // Added reactive stream method:
  /// Streams matches for a tournament, emitting immediately upon subscription
  /// and whenever matches in the tournament are created, modified, or updated in status/score.
  Stream<List<ChampionshipMatch>> watchMatchesForTournament(String tournamentId);
}
```

## Guarantees:
1. **Low Latency**: Emits new state within 100 ms of local persistence (`saveMatch`, `saveMatchesBatch`).
2. **Resource Cleanup**: Subscribing callers (e.g. `MatchesCatalogController`) can cancel the stream subscription without leaks or remaining broadcast listeners.
3. **Filtering by Status**: Emits all matches; the controller or view segments live matches using `match.status == MatchStatus.inProgress`.
