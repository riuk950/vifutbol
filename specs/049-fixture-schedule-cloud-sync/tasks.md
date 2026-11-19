# Tasks: Fixture Generation, Match Scheduling Cloud Synchronization, and Daily Matches Visibility

**Input**: Design documents from `/specs/049-fixture-schedule-cloud-sync/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/matches_cloud_sync_contract.md`, `quickstart.md`

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and HU 22.1 DoD.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`, `US4`)
- Exact repository file paths are included in every task description.

---

## Phase 1: Setup (Shared Localization & Verification Baseline)

**Purpose**: Add required Spanish localization keys for regeneration confirmation and optional scheduling placeholders (`"Por definir"`) so all subsequent UI tasks comply with Constitution Principle VI.

- [X] T001 Add Spanish localization keys (`fixtureRegenerateConfirmTitle`, `fixtureRegenerateConfirmMessage`, `fixtureRegenerateConfirmAction`, `matchLogisticsTbdLabel`, `scheduleMatchOptionalHint`) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core hybrid persistence, deterministic UUID alignment, and multi-tournament catalog loading that MUST be complete before any user story can be verified end-to-end.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Add `Future<void> replaceForTournament(String tournamentId, List<ChampionshipMatch> matches)` to `TournamentMatchesRemoteDataSource` and implement stale-ID pruning + idempotent batch `upsert(..., onConflict: 'id')` in `PostgrestTournamentMatchesRemoteDataSource` in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`
- [X] T004 Normalize generated match IDs to deterministic UUIDv5 via `HybridRepositorySupport.ensureUuid(m.id, 'match')` before local persistence and remote sync inside `HybridTournamentMatchesRepository` (`saveMatch`, `saveMatchesBatch`, `replaceMatchesForTournament`) and update `replaceMatchesForTournament` + `replayOutboxItem` (`SyncOutboxOperation.replaceBatch`) to invoke `remote.replaceForTournament(tournamentId, matches)` in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`
- [X] T005 Add `Future<void> loadAllMatches({bool silent = false})` to `MatchesCatalogController`, update `loadTournamentMatches(String tournamentId)` to merge tournament-scoped matches into `state.matches` without discarding other tournaments' matches, and add `if (state.isSaving) return false;` guards in `generateFixture` and `scheduleMatch` in `lib/application/controllers/matches_catalog_controller.dart`

**Checkpoint**: Foundation ready — hybrid remote pruning, canonical UUIDs, and cross-tournament catalog hydration are in place.

---

## Phase 3: User Story 1 - Cloud Persistence and Synchronization of Generated Competition Fixture (Priority: P1) 🎯 MVP

**Goal**: Ensure generating or regenerating a competition fixture persists all matches locally and syncs them atomically/idempotently as a batch to `vifutboldev.matches`, blocking regeneration when any match is `inProgress`/`completed` and requiring organizer confirmation when replacing an existing unstarted fixture (`FR-001`, `FR-002`, `FR-002a`, `FR-011`, `FR-012`).

**Independent Test**: Organizer with >= 2 eligible teams generates a fixture online, confirms all matches persist in `vifutboldev.matches` with matching UUIDs, regenerates after confirmation with zero orphaned remote rows, and verifies regeneration is blocked if any match is `inProgress` or `completed`.

### Tests for User Story 1

- [X] T006 [P] [US1] Create unit tests verifying `HybridTournamentMatchesRepository.replaceMatchesForTournament` prunes stale remote IDs, upserts canonical UUIDv5 matches idempotently, and leaves zero duplicates in `test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart`
- [X] T007 [P] [US1] Add unit tests verifying `MatchesCatalogController.generateFixture` blocks concurrent duplicate taps (`isSaving` guard) and preserves other tournaments' matches in `test/unit/application/matches_catalog_controller_test.dart`

### Implementation for User Story 1

- [X] T008 [US1] Update fixture generation action in `lib/presentation/tournaments/competition_detail_screen.dart` to show a Spanish confirmation dialog (`l10n.fixtureRegenerateConfirmTitle` / `l10n.fixtureRegenerateConfirmMessage`) when the competition already has unstarted matches, disable repeated taps while `isSaving` is true, and trigger `dailyMatchesFeedControllerProvider.notifier.refreshFromCloud()` on success
- [X] T009 [US1] Add widget tests covering fixture regeneration confirmation dialog and duplicate-tap protection in `test/presentation/tournaments/competition_fixture_widget_test.dart`

**Checkpoint**: User Story 1 is independently testable — fixture generation and guarded regeneration sync cleanly to `vifutboldev.matches`.

---

## Phase 4: User Story 2 - Cloud Synchronization of Individual Match Scheduling (Priority: P1)

**Goal**: Allow organizers to schedule or reschedule any match with mandatory date & start time (not in the past) and optional `venue`, `pitch`, and `referee`, persisting immediately locally and to `vifutboldev.matches` (`status = 'scheduled'`, UTC `scheduled_at`/`scheduled_end_at`, nullable logistics columns) with collision safety and `"Por definir"` UI fallbacks (`FR-003`, `FR-004`, `FR-005`, `FR-007`, `FR-012`, `FR-013`).

**Independent Test**: Organizer opens `ScheduleMatchDialog`, schedules a match with date/time only (no venue/pitch/referee) and another with full logistics, confirms both persist to `vifutboldev.matches`, and verifies `"Por definir"` fallback labels render cleanly when optional fields are null.

### Tests for User Story 2

- [X] T010 [P] [US2] Update unit tests in `test/unit/application/fixture_scheduling_use_case_test.dart` to verify scheduling succeeds with nullable `venue`, `pitch`, and `referee`, skips pitch/referee collision checks when null while still enforcing team overlap checks, and rejects past dates or non-organizer roles
- [X] T011 [P] [US2] Add unit test in `test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart` verifying `saveMatch` upserts `scheduled_at`, `scheduled_end_at`, `venue_id`, `pitch_id`, `pitch_name`, `referee_id`, `referee_name`, and `status = 'scheduled'` accurately for both full and null-optional logistics

### Implementation for User Story 2

- [X] T012 [US2] Update `FixtureSchedulingUseCase.scheduleMatch` and `detectCollisions` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to accept nullable `SportsVenue? venue`, `VenuePitch? pitch`, and `MatchReferee? referee`, enforcing mandatory non-past `scheduledStartTime`, computing `scheduledEndTime = scheduledStartTime + (halfDurationMinutes * 2 + 15) min`, and checking pitch/referee collisions only when non-null
- [X] T013 [US2] Update `MatchesCatalogController.scheduleMatch` in `lib/application/controllers/matches_catalog_controller.dart` to accept nullable `SportsVenue? venue`, `VenuePitch? pitch`, and `MatchReferee? referee` and forward them to `FixtureSchedulingUseCase.scheduleMatch`
- [X] T014 [US2] Update `ScheduleMatchDialog` in `lib/presentation/matches/widgets/schedule_match_dialog.dart` so only date and start time are validated as mandatory (making venue, pitch, and referee optional with clearable selection), disable the submit button while submitting (`_isSubmitting` / `catalogState.isSaving`), and call `dailyMatchesFeedControllerProvider.notifier.refreshFromCloud()` on success
- [X] T015 [P] [US2] Update match card logistics display in `lib/presentation/matches/widgets/match_card.dart` (and `lib/presentation/matches/widgets/match_center_card.dart` if applicable) to display `l10n.matchLogisticsTbdLabel` (`"Por definir"`) when venue/pitch or referee is null
- [X] T016 [US2] Update widget tests in `test/presentation/matches/schedule_match_dialog_test.dart` to verify scheduling with date/time only, scheduling with full logistics, and duplicate-tap prevention

**Checkpoint**: User Stories 1 and 2 work independently — both batch fixtures and individual schedules (with optional logistics) sync cleanly to `vifutboldev.matches`.

---

## Phase 5: User Story 3 - Automatic Visibility of Scheduled Matches in the Matches Screen (Priority: P1)

**Goal**: Surface all cloud-synchronized scheduled matches (`scheduledStartTime != null`) in `MatchdayTabView` filtered by calendar date for all 5 user roles, excluding unscheduled matches (`scheduledStartTime == null`), using immediate local cache rendering + automatic cloud refresh on tab entry/return, date change, and pull-to-refresh (`FR-008`, `FR-009`, `FR-010`).

**Independent Test**: Schedule a match for a target date, open `MatchdayTabView` (as any role), select that date, verify the match appears immediately from cache and refreshes from cloud with accurate competition, teams, start time, venue/pitch, and status, and verify unscheduled matches never appear in `MatchdayTabView`.

### Tests for User Story 3

- [X] T017 [P] [US3] Update unit tests in `test/application/controllers/daily_matches_feed_controller_test.dart` to verify reactive recomputation when `matchesCatalogControllerProvider` or `tournamentsControllerProvider` updates, `refreshFromCloud()` triggers parallel catalog + matches hydration, date selection refreshes feed, and unscheduled matches (`scheduledStartTime == null`) are excluded
- [X] T018 [P] [US3] Update widget tests in `test/presentation/shell/tabs/matchday_tab_view_test.dart` to verify `MatchdayTabView` triggers `refreshFromCloud()` on init, on quick-tab/date selection, and on pull-to-refresh, renders scheduled cloud matches with `"Por definir"` when logistics are unassigned, and displays empty state on dates with no scheduled matches

### Implementation for User Story 3

- [X] T019 [US3] Update `DailyMatchesFeedController` in `lib/application/controllers/daily_matches_feed_controller.dart` to subscribe reactively via `ref.listen` to `matchesCatalogControllerProvider` and `tournamentsControllerProvider`, add `Future<void> refreshFromCloud({bool showLoading = false})` (cache-first immediate `_computeFeed()`, then parallel `loadCatalog()`, `loadTeams()`, and `loadAllMatches(silent: true)`), and invoke background `refreshFromCloud()` in `selectQuickTab` and `selectCustomDate`
- [X] T020 [US3] Update `MatchdayTabView` in `lib/presentation/shell/tabs/matchday_tab_view.dart` (and calendar date selection callback in `lib/presentation/shell/app_shell_screen.dart` if needed) to invoke `await ref.read(dailyMatchesFeedControllerProvider.notifier).refreshFromCloud()` on init, tab activation, and `RefreshIndicator.onRefresh`

**Checkpoint**: User Stories 1, 2, and 3 work end-to-end — scheduled matches appear automatically in `MatchdayTabView` from Supabase DEV across all 5 roles.

---

## Phase 6: User Story 4 - Offline Fixture Generation, Scheduling, and Automatic Recovery (Priority: P2)

**Goal**: Guarantee that fixture generation (`replaceBatch`) and individual match scheduling (`upsert`) performed offline are saved locally, queued in `SyncOutboxQueue`, reflected in the AppBar sync status indicator, and replayed cleanly in FIFO order by `SupabaseCloudSyncService` upon reconnect with zero duplicate rows (`FR-006`, `FR-007`).

**Independent Test**: Simulate disconnected connectivity, execute `replaceMatchesForTournament` and `saveMatch`, verify both enqueue in `SyncOutboxQueue` and persist locally, then restore connectivity and run `SupabaseCloudSyncService.flushOutbox`, confirming `remote.replaceForTournament` and `remote.upsertMatch` replay in order with zero duplicates on repeated retries.

### Tests for User Story 4

- [X] T021 [P] [US4] Add offline-queueing and FIFO outbox replay tests (including mid-sync failure retry idempotency) for both `replaceMatchesForTournament` (`replaceBatch`) and `saveMatch` (`upsert`) in `test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart`

### Implementation for User Story 4

- [X] T022 [US4] Audit and verify `HybridTournamentMatchesRepository.replayOutboxItem` in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart` and its registration in `lib/application/providers/matches_catalog_providers.dart` so replaying `replaceBatch` invokes `remote.replaceForTournament` and triggers post-sync feed refresh cleanly when connectivity returns

**Checkpoint**: All 4 user stories (online & offline) are complete and independently verified.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final static analysis, full regression test pass, and live verification against Supabase DEV (`quickstart.md`).

- [X] T023 Run `flutter analyze` across the entire repository and resolve any warnings or errors to achieve zero issues
- [X] T024 Run all affected unit and widget tests (`test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart`, `test/unit/application/fixture_scheduling_use_case_test.dart`, `test/unit/application/matches_catalog_controller_test.dart`, `test/application/controllers/daily_matches_feed_controller_test.dart`, `test/presentation/matches/schedule_match_dialog_test.dart`, `test/presentation/tournaments/competition_fixture_widget_test.dart`, `test/presentation/shell/tabs/matchday_tab_view_test.dart`) and confirm 100% pass rate
- [X] T025 Validate end-to-end fixture batch upsert, stale row pruning, and scheduled match readback against Supabase DEV (`vifutboldev.matches`) following `specs/049-fixture-schedule-cloud-sync/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — can start immediately (`T001` → `T002`).
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T003` → `T004`, `T005` can run in parallel with `T003`/`T004`). **BLOCKS** all user stories.
- **Phase 3 (US1 — P1)**: Depends on Phase 2 (`T006`–`T009`).
- **Phase 4 (US2 — P1)**: Depends on Phase 2 (`T010`–`T016`). Can run in parallel with US1 except `T013` touches `matches_catalog_controller.dart` (after `T005`).
- **Phase 5 (US3 — P1)**: Depends on Phase 2 (`T005`) and benefits from US2 (`T015` for `"Por definir"` cards) (`T017`–`T020`).
- **Phase 6 (US4 — P2)**: Depends on Phase 2 (`T003`, `T004`) (`T021`–`T022`).
- **Phase 7 (Polish)**: Depends on all desired user stories being complete (`T023`–`T025`).

### Parallel Opportunities

```bash
# Within Phase 3 (US1) — Tests in parallel:
T006: test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart
T007: test/unit/application/matches_catalog_controller_test.dart

# Within Phase 4 (US2) — Tests & independent UI widget in parallel:
T010: test/unit/application/fixture_scheduling_use_case_test.dart
T011: test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart
T015: lib/presentation/matches/widgets/match_card.dart

# Within Phase 5 (US3) — Tests in parallel:
T017: test/application/controllers/daily_matches_feed_controller_test.dart
T018: test/presentation/shell/tabs/matchday_tab_view_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2 + User Story 3)

1. Complete **Phase 1 (Setup)** + **Phase 2 (Foundational)** → Core hybrid pruning, canonical UUIDs, and `loadAllMatches()` ready.
2. Complete **Phase 3 (US1)** → Fixture batch sync & guarded regeneration verified.
3. Complete **Phase 4 (US2)** → Individual match scheduling with optional logistics synced to `vifutboldev.matches`.
4. Complete **Phase 5 (US3)** → Scheduled matches visible automatically in `MatchdayTabView` across all 5 roles.
5. Complete **Phase 6 (US4)** → Offline outbox replay verified idempotently.
6. Complete **Phase 7 (Polish)** → `flutter analyze`, full test suite, and live DEV validation.
