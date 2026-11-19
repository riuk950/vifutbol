# Internal Contracts: Competition Tabs Cloud Persistence & Synchronization

**Feature**: `051-competition-tabs-cloud-sync` (HU 22.3)  
**Date**: 2026-11-19

---

## 1. `HybridTournamentsRepository` Contract

**File**: `lib/infrastructure/repositories/hybrid_tournaments_repository.dart`

### Methods & Guarantees
1. `Future<ChampionshipTournament> saveTournament(ChampionshipTournament tournament)`
   - **Pre-write normalization**: Normalizes `tournament.id` via `HybridRepositorySupport.ensureUuid(tournament.id, 'tournament')` and each entry in `tournament.venueIds` via `ensureUuid(v, 'venue')` before writing to `local` AND `remote`.
   - **Local-first**: Always persists normalized tournament + `ruleAuditTrail` to `LocalTournamentsRepository` first.
   - **Remote sync**:
     - If online: Upserts into `vifutboldev.tournaments` (including `rules_config` JSONB, `venue_ids`, `status`, `format`) and upserts `ruleAuditTrail` into `vifutboldev.rule_audit_entries` using deterministic IDs (no duplicates).
     - If offline or remote error: Enqueues `SyncOutboxItem(entityType: SyncEntityType.tournament, operation: SyncOperationType.upsert, entityId: normalized.id, payload: normalized.toJson())` and updates top-bar `SyncStatus` to pending.
2. `Future<List<ChampionshipTournament>> loadTournaments()`
   - If online: Fetches all rows from `vifutboldev.tournaments` + `vifutboldev.rule_audit_entries`, deserializes `rules_config` losslessly with backward-compatible defaults, updates local cache, and returns fresh list.
   - If offline / transient failure: Returns cached local tournaments without throwing or wiping cache.

---

## 2. `HybridTeamsRepository` & `PostgrestTeamsRemoteDataSource` Contract

**File**: `lib/infrastructure/repositories/hybrid_teams_repository.dart`

### Methods & Guarantees
1. `Future<TournamentTeam> saveTeam(TournamentTeam team)`
   - Normalizes `team.id` (`ensureUuid(team.id, 'tournament_team')`) and `team.tournamentId` (`ensureUuid(team.tournamentId, 'tournament')`) prior to local and remote persistence.
   - Persists `groupName`, `eligibilityStatus`, and roster locally and upserts to `vifutboldev.tournament_teams` when online (or enqueues `SyncEntityType.team` outbox item when offline).
2. `Future<void> replaceForTournament(String tournamentId, List<TournamentTeam> teams)` (in `PostgrestTeamsRemoteDataSource`)
   - Normalizes `safeTournamentId = ensureUuid(tournamentId, 'tournament')` and incoming enrollment IDs `keepIds = teams.map((t) => ensureUuid(t.id, 'tournament_team')).toSet()`.
   - Queries existing `id` rows in `vifutboldev.tournament_teams` where `tournament_id = safeTournamentId`.
   - Computes `staleIds = existingIds.difference(keepIds)`.
   - If `staleIds.isNotEmpty`, executes `.delete().eq('tournament_id', safeTournamentId).inFilter('id', staleIds.toList())`.
   - Upserts all incoming `teams` into `vifutboldev.tournament_teams`.
3. `Future<List<TournamentTeam>> replaceTeamsForTournament(String tournamentId, List<TournamentTeam> teams)` (in `HybridTeamsRepository`)
   - Normalizes all incoming teams + `tournamentId`, replaces locally, and calls `remote.replaceForTournament(safeTournamentId, normalizedTeams)` when online (or enqueues `SyncEntityType.team` `replaceForTournament` outbox payload when offline).

---

## 3. `SupabaseCloudSyncService` Dependency-Ordered Flush Contract

**File**: `lib/infrastructure/sync/supabase_cloud_sync_service.dart`

### Ordering Specification
```dart
static int dependencyPriority(SyncEntityType type) => switch (type) {
  SyncEntityType.venue => 0,
  SyncEntityType.tournament => 1,
  SyncEntityType.team || SyncEntityType.teamJoinRequest => 2,
  SyncEntityType.match => 3,
  SyncEntityType.matchReport ||
  SyncEntityType.lineupTracking ||
  SyncEntityType.matchAlert => 4,
  SyncEntityType.seasonHonorRoll ||
  SyncEntityType.tournamentNews ||
  SyncEntityType.fanFavorite => 5,
};
```
- Before iterating in `_executeFlush()`, `pendingItems` MUST be sorted by:
  1. `dependencyPriority(a.entityType).compareTo(dependencyPriority(b.entityType))`
  2. Tie-breaker: `a.createdAt.compareTo(b.createdAt)` (strict FIFO within same tier).
- Exposed as a `@visibleForTesting` / static helper so unit tests can assert ordering deterministically and integration flush tests can verify exact dispatch sequence across mixed offline mutations.

---

## 4. `CompetitionDetailScreen` Parallel Cloud Hydration & Tab Refresh Contract

**Files**:
- `lib/presentation/tournaments/competition_detail_screen.dart`
- `lib/presentation/tournaments/widgets/competition_info_tab_view.dart`
- `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart`
- `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart`
- `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart`

### Hydration Lifecycle (`_CompetitionDetailScreenState`)
1. **`initState()`**: Schedules `Future.microtask(_hydrateCompetitionData)` so cached local state renders instantaneously on frame 1 while cloud hydration runs in parallel.
2. **`Future<void> _hydrateCompetitionData()`**:
   - Guarded by `_isHydrating` flag to prevent overlapping concurrent hydration bursts.
   - Executes in parallel via `Future.wait`:
     - `ref.read(tournamentsControllerProvider.notifier).loadCatalog()`
     - `ref.read(teamsControllerProvider.notifier).loadTeams()`
     - `ref.read(matchesCatalogControllerProvider.notifier).loadTournamentMatches(widget.tournamentId)`
     - `ref.read(venuesControllerProvider.notifier).loadVenues()`
   - Immediately after the parallel batch resolves (if `mounted`), recomputes deterministic standings & honor roll:
     - `await ref.read(standingsAndRankingsControllerProvider(widget.tournamentId).notifier).loadCompetitiveSnapshot()`
   - Never clears or destroys cached data if an offline/network error occurs; errors are surfaced non-destructively in Spanish.
3. **Pull-to-Refresh (`onRefresh` callback)**:
   - `CompetitionInfoTabView`, `CompetitionTeamsTabView`, `CompetitionStandingsTabView`, and `CompetitionFixtureTabView` accept an optional `Future<void> Function()? onRefresh` (defaulting to controller refresh if omitted) and wrap their scrollable body in `RefreshIndicator` with `AlwaysScrollableScrollPhysics()` so empty/short views can also be pulled to refresh.
4. **Venue Resolution in `CompetitionInfoTabView`**:
   - Resolves linked venue from `tournament.venueIds` first (matching against `venuesCatalog.venues`), falling back to `matchWithVenue?.venueId`, then `venuesCatalog.venues.firstOrNull`.
5. **Duplicate-Tap Guards (`FR-008`)**:
   - `CompetitionTeamsTabView` disables/guards `moveTeamToGroup`, `removeTeamFromCompetition`, and eligibility toggle while `teamsCatalog.isSaving` is `true`, preventing concurrent duplicate writes.
