---

description: "Actionable, dependency-ordered task list for HU 22.3: Competition Tabs Cloud Persistence and Synchronization"
---

# Tasks: Cloud Persistence and Synchronization for Competition Standings, Teams, and Information Tabs

**Input**: Design documents from `/specs/051-competition-tabs-cloud-sync/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/data-model.md), [competition_tabs_cloud_sync_contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/contracts/competition_tabs_cloud_sync_contract.md)

**Tests**: Included per Project Constitution Principle III (Automated Tests & Quality Gate).

**Organization**: Tasks are grouped by user story (US1–US4) to enable independent implementation and verification of each increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story mapping (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Exact file paths included in every task description

---

## Phase 1: Setup (Shared Verification Baseline)

**Purpose**: Verify existing test baseline and confirm no pending localization or schema blockers before modifying code.

- [X] T001 Run existing tournament widget tests (`competition_detail_screen_test.dart`, `competition_info_tab_view_test.dart`, `competition_teams_tab_view_test.dart`, `competition_standings_tab_view_test.dart`) to capture baseline status before changes

---

## Phase 2: Foundational (Parallel Cold-Start Hydration Architecture)

**Purpose**: Establish the shared parallel cloud hydration lifecycle in `CompetitionDetailScreen` that feeds all four tabs ("Fixture", "Clasificación", "Equipos", "Información") on cold start and manual pull-to-refresh (FR-004, SC-005).

**⚠️ CRITICAL**: Complete this phase before wiring tab-specific pull-to-refresh callbacks in US1–US3.

- [X] T002 Add `initState()` parallel cloud hydration (`_hydrateCompetitionData()` guarded by `_isHydrating`, calling `loadCatalog()`, `loadTeams()`, `loadTournamentMatches(widget.tournamentId)`, `loadVenues()` via `Future.wait`, followed by `standingsAndRankingsControllerProvider(widget.tournamentId).notifier.loadCompetitiveSnapshot()` and refreshing season honor roll state for finished tournaments) and pass `onRefresh: _hydrateCompetitionData` to all four tab views in `lib/presentation/tournaments/competition_detail_screen.dart`
- [X] T003 [P] Add optional `Future<void> Function()? onRefresh` callback parameter and wrap scrollable body in `RefreshIndicator` with `AlwaysScrollableScrollPhysics()` in `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart`

**Checkpoint**: `CompetitionDetailScreen` now hydrates all cloud data in parallel on cold start while preserving instant local cache rendering.

---

## Phase 3: User Story 1 - Cloud Synchronization of Competition Information, Rules, and Audit History (Priority: P1) 🎯 MVP

**Goal**: Ensure 100% of competition metadata, `rules_config` JSONB, linked `venueIds`, status, and chronological `rule_audit_entries` persist losslessly to Supabase with normalized UUIDv5 keys, and render accurately in the "Información" tab on cold start and pull-to-refresh (FR-001, FR-002, FR-004, FR-010, SC-001).

**Independent Test**: Save/edit a competition with custom scoring rules, tiebreakers, linked venues, status, and rule audit entries; clear local cache; reload via `HybridTournamentsRepository` and render `CompetitionInfoTabView` to verify all fields and audit entries match identically.

### Implementation for User Story 1

- [X] T004 [US1] Normalize `tournament.id` via `HybridRepositorySupport.ensureUuid(tournament.id, 'tournament')` and each entry in `tournament.venueIds` via `ensureUuid(v, 'venue')` prior to both local and remote persistence, and verify lossless `rules_config` / `rule_audit_entries` round-trip deserialization with safe backward-compatible defaults in `lib/infrastructure/repositories/hybrid_tournaments_repository.dart`
- [X] T005 [P] [US1] Add optional `Future<void> Function()? onRefresh` parameter, wrap content/empty state in `RefreshIndicator` with `AlwaysScrollableScrollPhysics()`, and resolve `primaryVenue` using `tournament.venueIds` first (before falling back to match venue or first catalog venue) in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart`

### Tests for User Story 1

- [X] T006 [P] [US1] Create unit/repository tests covering UUIDv5 normalization on `saveTournament`, lossless `rules_config` JSONB round-trip, backward-compatible defaults for missing rule fields, chronological deduplicated `rule_audit_entries`, and offline outbox queueing in `test/infrastructure/repositories/hybrid_tournaments_repository_test.dart`
- [X] T007 [P] [US1] Extend widget tests to verify `tournament.venueIds`-first venue resolution, pull-to-refresh `onRefresh` callback invocation, and read-only RBAC visibility in `test/presentation/tournaments/competition_info_tab_view_test.dart`

**Checkpoint**: User Story 1 is independently functional and tested — competition information, rules, venues, and audit history sync losslessly and hydrate cleanly.

---

## Phase 4: User Story 2 - Cloud Synchronization of Competition Teams, Group Assignments, and Eligibility Status (Priority: P1)

**Goal**: Ensure enrolling teams, moving teams between groups, toggling eligibility (`pendingVerification` / `eligible`), and withdrawing teams synchronize cleanly to `vifutboldev.tournament_teams` with remote pruning of withdrawn enrollments and duplicate-tap protection in the "Equipos" tab (FR-003, FR-008, FR-009, FR-010, SC-002).

**Independent Test**: Enroll teams, move a team to a new group, toggle eligibility, and withdraw a team; verify `PostgrestTeamsRemoteDataSource.replaceForTournament` deletes stale remote enrollment IDs and `CompetitionTeamsTabView` blocks concurrent duplicate taps while supporting pull-to-refresh.

### Implementation for User Story 2

- [X] T008 [US2] Normalize `team.id` (`ensureUuid(team.id, 'tournament_team')`) and `team.tournamentId` (`ensureUuid(team.tournamentId, 'tournament')`) prior to local & remote writes in `HybridTeamsRepository.saveTeam` and `replaceTeamsForTournament`, and implement remote pruning of stale enrollment IDs in `PostgrestTeamsRemoteDataSource.replaceForTournament` (query existing IDs for `safeTournamentId`, delete `existingIds.difference(keepIds)`, then upsert remaining enrollments) in `lib/infrastructure/repositories/hybrid_teams_repository.dart`
- [X] T009 [P] [US2] Add optional `Future<void> Function()? onRefresh` parameter with `RefreshIndicator` (`AlwaysScrollableScrollPhysics()`) and add duplicate-tap concurrency guards (`teamsCatalog.isSaving`) on group move (`moveTeamToGroup`), team withdrawal (`removeTeamFromCompetition`), and eligibility toggle actions in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart`, and verify tournament edit save action also guards against concurrent duplicate submissions while `isSaving == true`

### Tests for User Story 2

- [X] T010 [P] [US2] Create unit/repository tests verifying UUIDv5 normalization, enrollment/group/eligibility upsert persistence, remote pruning of withdrawn team enrollments in `replaceForTournament`, and offline fallback queueing in `test/infrastructure/repositories/hybrid_teams_repository_test.dart`
- [X] T011 [P] [US2] Extend widget tests verifying pull-to-refresh callback execution, duplicate-tap prevention while `isSaving == true`, and Organizer-only mutation controls in `test/presentation/tournaments/competition_teams_tab_view_test.dart`

**Checkpoint**: User Story 2 is independently functional and tested — team enrollments, groups, eligibility, and withdrawals stay 100% consistent with zero orphaned cloud records.

---

## Phase 5: User Story 3 - Deterministic Cloud-Backed Standings and Knockout Bracket Consistency (Priority: P1)

**Goal**: Ensure the "Clasificación" tab computes standings (`PJ, PG, PE, PP, GF, GC, DG, PTS`) and knockout brackets deterministically from cloud-hydrated rules, teams, matches, and official match reports, preserves cached snapshot data on transient offline errors, and syncs season closure / honor roll records across devices (FR-004, FR-005, FR-006, FR-010, SC-003).

**Independent Test**: Hydrate a competition with synchronized rules, enrolled teams, and completed matches; verify `StandingsAndRankingsController.loadCompetitiveSnapshot()` produces identical tables and retains cached snapshot data when a subsequent refresh fails offline, and verify `CompetitionStandingsTabView` triggers full competition hydration on pull-to-refresh.

### Implementation for User Story 3

- [X] T012 [US3] Update `StandingsAndRankingsController.loadCompetitiveSnapshot()` to preserve existing `state.snapshot` non-destructively when a refresh throws a transient/offline error while exposing a clear error state for retry in `lib/application/controllers/standings_and_rankings_controller.dart`
- [X] T013 [P] [US3] Add optional `Future<void> Function()? onRefresh` parameter and wrap standings/bracket/rankings/empty views in `RefreshIndicator` with `AlwaysScrollableScrollPhysics()` (defaulting to `controller.loadCompetitiveSnapshot()` when `onRefresh` is omitted) in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart`

### Tests for User Story 3

- [X] T014 [P] [US3] Extend widget/controller tests verifying deterministic standings refresh on pull-to-refresh, preservation of cached standings snapshot on transient offline error, cold-start hydration triggering `loadCompetitiveSnapshot()`, and season honor roll hydration/sync for finished competitions (FR-006) in `test/presentation/tournaments/competition_standings_tab_view_test.dart` and `test/presentation/tournaments/competition_detail_screen_test.dart`

**Checkpoint**: User Story 3 is independently functional and tested — standings and knockout brackets remain 100% deterministic across devices and resilient offline.

---

## Phase 6: User Story 4 - Offline Resilience and Dependency-Ordered Cloud Recovery (Priority: P2)

**Goal**: Guarantee that queued offline mutations across venues, competitions, team enrollments, matches, match reports, and season honor rolls automatically replay in strict foreign-key dependency order (`venue → tournament → team/teamJoinRequest → match → matchReport/lineupTracking/matchAlert → seasonHonorRoll/tournamentNews/fanFavorite`, FIFO within each tier) upon reconnect with zero `23503` FK failures (FR-007, SC-004).

**Independent Test**: Enqueue offline outbox items in reverse/mixed order (`seasonHonorRoll`, `matchReport`, `match`, `team`, `tournament`, `venue`), run `SupabaseCloudSyncService.flushPending()`, and assert exact dispatch order matches strict FK tiers with FIFO tie-breaking by `createdAt`.

### Implementation for User Story 4

- [X] T015 [US4] Add `static int dependencyPriority(SyncEntityType type)` helper and sort `pendingItems` by `(dependencyPriority(entityType), createdAt)` before replaying in `_executeFlush()` in `lib/infrastructure/sync/supabase_cloud_sync_service.dart`

### Tests for User Story 4

- [X] T016 [P] [US4] Create unit tests verifying `dependencyPriority` tier ordering, FIFO tie-breaking within identical tiers, and full mixed-order outbox flush dispatch sequence (`venue → tournament → team → match → matchReport → seasonHonorRoll`) with zero FK order violations in `test/infrastructure/sync/supabase_cloud_sync_service_test.dart`

**Checkpoint**: User Story 4 is independently functional and tested — offline recovery is immune to out-of-order `23503` FK failures.

---

## Phase 7: Polish & Cross-Cutting Quality Gate

**Purpose**: Verify full test suite, static analysis, Spanish localization integrity, and quickstart validation across all stories.

- [X] T017 Run `flutter analyze` across the entire repository and verify 0 errors, 0 warnings, and 0 lint issues
- [X] T018 Run full targeted test suite from `specs/051-competition-tabs-cloud-sync/quickstart.md` (`hybrid_tournaments_repository_test.dart`, `hybrid_teams_repository_test.dart`, `supabase_cloud_sync_service_test.dart`, `competition_detail_screen_test.dart`, `competition_info_tab_view_test.dart`, `competition_teams_tab_view_test.dart`, `competition_standings_tab_view_test.dart`, `competition_fixture_widget_test.dart`) and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — run baseline immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS** tab pull-to-refresh wiring in US1–US3 (`T002` defines `_hydrateCompetitionData()`).
- **Phase 3 (US1 - P1)**, **Phase 4 (US2 - P1)**, **Phase 5 (US3 - P1)**, **Phase 6 (US4 - P2)**:
  - All repository/sync tasks (`T004`, `T008`, `T012`, `T015`) operate on distinct files and can execute in parallel once Phase 2 is complete.
  - All tab view updates (`T005`, `T009`, `T013`) operate on distinct files and can execute in parallel after `T002`.
- **Phase 7 (Polish & Quality Gate)**: Depends on Phases 3–6 completion.

### Parallel Opportunities

```bash
# Parallel Repository & Sync Layer Batch (distinct files):
T004: lib/infrastructure/repositories/hybrid_tournaments_repository.dart
T008: lib/infrastructure/repositories/hybrid_teams_repository.dart
T012: lib/application/controllers/standings_and_rankings_controller.dart
T015: lib/infrastructure/sync/supabase_cloud_sync_service.dart

# Parallel Tab View Batch (after T002):
T003: lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart
T005: lib/presentation/tournaments/widgets/competition_info_tab_view.dart
T009: lib/presentation/tournaments/widgets/competition_teams_tab_view.dart
T013: lib/presentation/tournaments/widgets/competition_standings_tab_view.dart

# Parallel Test Suite Creation Batch:
T006: test/infrastructure/repositories/hybrid_tournaments_repository_test.dart
T010: test/infrastructure/repositories/hybrid_teams_repository_test.dart
T016: test/infrastructure/sync/supabase_cloud_sync_service_test.dart
```

---

## Implementation Strategy

### MVP First (US1 + Foundational)
1. Complete Phase 1 (T001) + Phase 2 (T002–T003) → Cold-start parallel hydration active.
2. Complete Phase 3 (T004–T007) → Competition info, rules, venues, and audit history sync losslessly (MVP).

### Full Incremental Delivery
3. Complete Phase 4 (T008–T011) → Teams, groups, eligibility, and remote withdrawal pruning synced.
4. Complete Phase 5 (T012–T014) → Deterministic standings refresh and offline snapshot preservation verified.
5. Complete Phase 6 (T015–T016) → Strict dependency-ordered offline outbox replay verified.
6. Complete Phase 7 (T017–T018) → `flutter analyze` (0 issues) + 100% green test suite.
