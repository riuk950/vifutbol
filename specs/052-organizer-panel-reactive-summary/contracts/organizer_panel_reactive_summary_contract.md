# Internal Contracts: Reactive Organizer Panel Summary

**Feature**: `052-organizer-panel-reactive-summary` (HU 22.4)  
**Date**: 2026-11-19

---

## 1. `computeOrganizerPanelMetrics` Contract

**File**: `lib/application/providers/tournaments_providers.dart`

```dart
OrganizerPanelData computeOrganizerPanelMetrics({
  required List<ChampionshipTournament> organizerTournaments,
  required List<ChampionshipMatch> allMatches,
})
```

### Guarantees
1. Returns `OrganizerPanelData(0, 0, 0)` when `organizerTournaments` is empty.
2. `activeTournaments` includes ONLY `TournamentStatus.openRegistration` and `TournamentStatus.inProgress` (strictly excludes `TournamentStatus.finished`).
3. `pendingScheduleMatchesCount` counts ONLY matches whose `tournamentId` is in `activeTournamentIds` AND `(m.status == MatchStatus.pendingSchedule || (m.status == MatchStatus.scheduled && m.scheduledStartTime == null))`.
4. `unseededTournamentsCount` counts ONLY `activeTournaments` with zero matches in `allMatches`.

---

## 2. `OrganizerPanelContent` Lifecycle & Hydration Contract

**File**: `lib/presentation/panel/widgets/organizer_panel_content.dart`

### Guarantees
1. Stateful `ConsumerStatefulWidget` with `_isHydrating` concurrency guard.
2. `initState()` schedules `Future.microtask(_hydrateOrganizerData)` to hydrate `tournamentsControllerProvider.notifier.loadCatalog()`, `teamsControllerProvider.notifier.loadTeams()`, and `matchesCatalogControllerProvider.notifier.loadAllMatches(silent: true)` in parallel.
3. Each controller call is isolated in a safe wrapper so isolated widget tests with partial fake controllers or transient network failures never crash or wipe cached state.
4. `build()` registers `ref.listen<String?>(authControllerProvider.select((s) => s.session?.user.id), (prev, next) { ... })` to trigger `_hydrateOrganizerData()` when the signed-in user changes.
5. Wraps the scrollable body in `RefreshIndicator(onRefresh: _hydrateOrganizerData, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), ...))`.

---

## 3. `cloudSyncBootstrapProvider` Post-Sync Refresh Contract

**File**: `lib/application/providers/sync_bootstrap_provider.dart`

### Guarantees
1. Registers a single `afterSyncCallback` on `supabaseCloudSyncServiceProvider` when remote cloud sync is enabled.
2. When `item.entityType` is:
   - `SyncOutboxEntityType.tournament`: triggers `ref.read(tournamentsControllerProvider.notifier).loadCatalog()`
   - `SyncOutboxEntityType.team`: triggers `ref.read(teamsControllerProvider.notifier).loadTeams()`
   - `SyncOutboxEntityType.match`: triggers `ref.read(matchesCatalogControllerProvider.notifier).loadAllMatches(silent: true)`
3. Errors during post-sync refresh are caught non-destructively so outbox flushing is never disrupted.

---

## 4. `OrganizerCompetitionsSection` Live Team Count Contract

**File**: `lib/presentation/panel/widgets/organizer_competitions_section.dart`

### Guarantees
1. Watches `teamsControllerProvider` in `build()` alongside `organizerTournamentsProvider`.
2. Renders a live team count badge (`Key('organizer_competition_teams_badge_${tournament.id}')`) displaying `l10n.competitionTeamsHeaderCount(enrolledTeamsCount)` on each competition card, updating immediately when teams are enrolled or withdrawn.
