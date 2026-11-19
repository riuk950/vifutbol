# Interface Contracts: Matches Cloud Sync & Daily Feed

**Feature**: `049-fixture-schedule-cloud-sync` (HU 22.1)
**Date**: 2026-11-19

## 1. Remote Data Source Contract (`TournamentMatchesRemoteDataSource`)

File: `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`

```dart
abstract interface class TournamentMatchesRemoteDataSource {
  Future<List<ChampionshipMatch>> fetchAll();
  Future<List<ChampionshipMatch>> fetchForTournament(String tournamentId);
  Future<ChampionshipMatch> upsertMatch(ChampionshipMatch match);
  Future<List<ChampionshipMatch>> upsertBatch(List<ChampionshipMatch> matches);
  Future<void> replaceForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  );
  Future<List<MatchReferee>> fetchOfficialReferees();
}
```

### Semantics of `replaceForTournament(tournamentId, matches)`
1. Normalize `safeTournamentId = HybridRepositorySupport.ensureUuid(tournamentId, 'tournament')`.
2. Normalize each match's `id` via `HybridRepositorySupport.ensureUuid(m.id, 'match')`.
3. Fetch existing match IDs for `tournament_id = safeTournamentId` from `vifutboldev.matches` (select `id`).
4. Compute `staleIds = existingIds.where((id) => !incomingIds.contains(id))`.
5. If `staleIds.isNotEmpty`, delete them via `.from('matches').delete().inFilter('id', staleIds)`.
6. If `matches.isNotEmpty`, upsert all mapped rows via `.from('matches').upsert(rows, onConflict: 'id')`.

### Outbox Replay Contract (`HybridTournamentMatchesRepository.replayOutboxItem`)
- `SyncOutboxOperation.upsert` → calls `remote.upsertMatch(match)`.
- `SyncOutboxOperation.replaceBatch`:
  - If `payloadJson['tournamentId']` is present and non-empty → calls `remote.replaceForTournament(tournamentId, matches)`.
  - Otherwise → calls `remote.upsertBatch(matches)`.

## 2. Use Case Contract (`FixtureSchedulingUseCase.scheduleMatch`)

File: `lib/application/use_cases/fixture_scheduling_use_case.dart`

```dart
Future<ChampionshipMatch> scheduleMatch({
  required String matchId,
  required ChampionshipTournament tournament,
  required DateTime scheduledStartTime,
  SportsVenue? venue,
  VenuePitch? pitch,
  MatchReferee? referee,
  required UserRole userRole,
});
```

- Validates organizer capability (`RoleCapability.manageTournaments`).
- Validates tournament is not `finished`.
- Validates `scheduledStartTime` is not in the past (minute precision).
- Computes `scheduledEndTime = scheduledStartTime + (halfDurationMinutes * 2 + 15) min`.
- Runs `detectCollisions` with nullable `pitchId` and `refereeId` (always checks home/away team overlaps).
- Persists updated `ChampionshipMatch` with `status: MatchStatus.scheduled` via `matchesRepository.saveMatch(updatedMatch)`.

## 3. State & Feed Contracts

### `MatchesCatalogController`
- `Future<void> loadAllMatches({bool silent = false})`:
  - Loads all matches via `matchesRepository.loadAllMatches()` (cache-first + remote sync) and updates `state.matches` across all tournaments.
- `Future<void> loadTournamentMatches(String tournamentId)`:
  - Loads matches for `tournamentId` and **merges** them into `state.matches` (replacing only matches belonging to `tournamentId`, preserving other tournaments' matches so `DailyMatchesFeedController` never loses cross-tournament data).
- `Future<bool> generateFixture(...)` & `Future<bool> scheduleMatch(...)`:
  - Guarded against concurrent duplicate submissions (`if (state.isSaving) return false;`).

### `DailyMatchesFeedController`
- Subscribes via `ref.listen` to `matchesCatalogControllerProvider` and `tournamentsControllerProvider` to recompute `tournamentGroups` reactively whenever data updates.
- `Future<void> refreshFromCloud({bool showLoading = false})`:
  1. Immediately computes feed from current cached state (zero perceived blank flash when cached data exists).
  2. Triggers parallel refresh of `tournamentsControllerProvider.notifier.loadCatalog()`, `teamsControllerProvider.notifier.loadTeams()`, and `matchesCatalogControllerProvider.notifier.loadAllMatches(silent: true)`.
  3. Recomputes feed automatically upon completion and clears any transient loading flag.
- Called automatically on:
  - `MatchdayTabView` init / tab activation
  - `selectQuickTab(...)` and `selectCustomDate(...)`
  - `RefreshIndicator.onRefresh` (pull-to-refresh)
