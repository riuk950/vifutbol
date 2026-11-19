---

description: "Actionable, dependency-ordered task list for HU 22.4: Reactive Organizer Panel Summary with Cloud-Synchronized Data"
---

# Tasks: Reactive Organizer Panel Summary with Cloud-Synchronized Data

**Input**: Design documents from `/specs/052-organizer-panel-reactive-summary/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/data-model.md), [organizer_panel_reactive_summary_contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/contracts/organizer_panel_reactive_summary_contract.md)

**Tests**: Included per Project Constitution Principle III (Automated Tests & Quality Gate).

**Organization**: Tasks are grouped by user story (US1–US3) so each increment can be implemented and tested independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story mapping (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths included in every task description

---

## Phase 1: Setup (Shared Verification Baseline)

**Purpose**: Capture baseline pass status of existing organizer panel unit and widget tests before changes.

- [X] T001 Run existing organizer panel tests (`organizer_panel_metrics_test.dart`, `organizer_panel_widget_test.dart`, `organizer_competitions_addition_verification_test.dart`, `panel_screen_test.dart`) to capture baseline status

---

## Phase 2: User Story 1 - Immediate Summary Updates After Generating Fixtures and Scheduling Matches (Priority: P1) 🎯 MVP

**Goal**: Ensure `computeOrganizerPanelMetrics` and `organizerPanelMetricsProvider` calculate "Torneos Activos" (`openRegistration` + `inProgress`), "Partidos por Programar" (unscheduled `pendingSchedule` matches of active owned competitions), and "Torneos sin Fixture" (active owned competitions with 0 matches) accurately and react immediately when fixtures are generated/regenerated or matches are scheduled (FR-001, FR-002, FR-003, FR-004, SC-001).

**Independent Test**: Mutate `MatchesCatalogController` (generate fixture, schedule 2 matches, regenerate fixture) and assert `organizerPanelMetricsProvider` and `OrganizerPanelContent` counters update immediately without restarting the widget.

### Implementation for User Story 1

- [X] T002 [US1] Refine `computeOrganizerPanelMetrics` to scope `activeTournaments` strictly to `TournamentStatus.openRegistration` and `TournamentStatus.inProgress` (excluding `finished`) and restrict `pendingScheduleMatchesCount` to matches belonging to `activeTournamentIds` where `m.status == MatchStatus.pendingSchedule || (m.status == MatchStatus.scheduled && m.scheduledStartTime == null)` (excluding `completed`/`inProgress` matches and `finished` tournaments) in `lib/application/providers/tournaments_providers.dart`

### Tests for User Story 1

- [X] T003 [P] [US1] Extend unit tests verifying exact metric recalculation after generating a fixture ("Torneos sin Fixture" -1, "Partidos por Programar" +N), scheduling 2 of 6 matches ("Partidos por Programar" 6 → 4), regenerating a fixture, and excluding `finished` tournaments / `completed` matches in `test/unit/application/organizer_panel_metrics_test.dart`

**Checkpoint**: User Story 1 metric computation is exact and verified by unit tests.

---

## Phase 3: User Story 2 - Reactive Summary Updates on Competition Lifecycle and Team Changes (Priority: P1)

**Goal**: Ensure "Torneos Activos", "Torneos sin Fixture", and each card in "Mis Competiciones" update reactively on competition create/edit/status-change/delete AND show live enrolled team counts matching the competition detail view (FR-005, FR-007, SC-003).

**Independent Test**: Add/finish/delete competitions and enroll/withdraw teams in Riverpod controllers while `OrganizerPanelContent` is mounted, and assert top metric cards and per-competition team count badges update immediately.

### Implementation for User Story 2

- [X] T004 [US2] Watch `teamsControllerProvider` in `OrganizerCompetitionsSection` and render a live enrolled team count badge (`Key('organizer_competition_teams_badge_${tournament.id}')` using `l10n.competitionTeamsHeaderCount(enrolledTeamsCount)`) on each competition card in `lib/presentation/panel/widgets/organizer_competitions_section.dart`

### Tests for User Story 2

- [X] T005 [P] [US2] Extend unit tests verifying reactive recalculation after creating a tournament (+1 active, +1 unseeded), transitioning a tournament to `finished` (-1 active, excludes its pending matches), and deleting an open tournament in `test/unit/application/organizer_panel_metrics_test.dart`
- [X] T006 [P] [US2] Extend widget tests verifying live reactive updates in `OrganizerPanelContent` without widget rebuild/restart when tournaments are created/finished, fixtures are generated, matches are scheduled, and teams are enrolled/withdrawn (team badge parity) in `test/presentation/panel/organizer_panel_widget_test.dart`

**Checkpoint**: User Stories 1 and 2 deliver complete live in-memory reactivity across all summary cards and competition cards.

---

## Phase 4: User Story 3 - Automatic Cloud Hydration and Strict Organizer Isolation on Sign-In and Sync (Priority: P1)

**Goal**: Ensure `OrganizerPanelContent` automatically hydrates competitions, teams, and matches in parallel on cold start, on organizer account switch, on pull-to-refresh, and whenever `CloudSyncService` finishes syncing `tournament`/`team`/`match` items, always enforcing strict `organizerId == currentUserId` isolation and non-destructive offline cache preservation (FR-002, FR-006, FR-008, FR-009, SC-002, SC-004).

**Independent Test**: Mount `OrganizerPanelContent` with empty controller state and verify parallel hydration fires (`loadCatalog`, `loadTeams`, `loadAllMatches`), verify `RefreshIndicator` pull-to-refresh invokes hydration safely, verify `cloudSyncBootstrapProvider` refreshes controllers on `afterSyncCallback`, and verify multi-organizer isolation (`organizerId == currentUserId`).

### Implementation for User Story 3

- [X] T007 [US3] Convert `OrganizerPanelContent` to `ConsumerStatefulWidget`, add `_hydrateOrganizerData()` guarded by `_isHydrating` (calling `tournamentsControllerProvider.notifier.loadCatalog()`, `teamsControllerProvider.notifier.loadTeams()`, and `matchesCatalogControllerProvider.notifier.loadAllMatches(silent: true)` in parallel with safe error isolation) in `initState()`, add `ref.listen` on `authControllerProvider` user ID changes for account-switch re-hydration, and wrap the `SingleChildScrollView` in `RefreshIndicator` with `AlwaysScrollableScrollPhysics()` in `lib/presentation/panel/widgets/organizer_panel_content.dart`
- [X] T008 [P] [US3] Register a post-sync `OutboxSyncedCallback` on `supabaseCloudSyncServiceProvider` inside `cloudSyncBootstrapProvider` so syncing `tournament`, `team`, or `match` outbox items automatically triggers non-destructive refresh of `tournamentsControllerProvider`, `teamsControllerProvider`, or `matchesCatalogControllerProvider` in `lib/application/providers/sync_bootstrap_provider.dart`

### Tests for User Story 3

- [X] T009 [P] [US3] Extend widget tests verifying cold-start parallel cloud hydration (`loadCatalog`, `loadTeams`, `loadAllMatches`), pull-to-refresh invocation, and strict multi-organizer isolation (`organizerId == currentUserId`) in `test/presentation/panel/organizer_panel_widget_test.dart` and verify `test/presentation/panel/organizer_competitions_addition_verification_test.dart` & `test/presentation/panel/panel_screen_test.dart` pass cleanly

---

## Phase 5: Polish & Cross-Cutting Quality Gate

**Purpose**: Final static analysis and full targeted test suite verification per Constitution Principle III.

- [X] T010 Run `flutter analyze` across the entire repository and verify 0 errors, 0 warnings, and 0 lint issues
- [X] T011 Run full targeted test suite from `specs/052-organizer-panel-reactive-summary/quickstart.md` (`organizer_panel_metrics_test.dart`, `organizer_panel_widget_test.dart`, `organizer_competitions_addition_verification_test.dart`, `panel_screen_test.dart`) and verify 100% pass rate

---

## Dependencies & Execution Order

- **Phase 1 (`T001`)**: Baseline first.
- **Phase 2 (`T002`, `T003`)**, **Phase 3 (`T004`–`T006`)**, and **Phase 4 (`T007`–`T009`)**:
  - `T002` (`tournaments_providers.dart`), `T004` (`organizer_competitions_section.dart`), `T007` (`organizer_panel_content.dart`), and `T008` (`sync_bootstrap_provider.dart`) touch 4 distinct production files and can be implemented in parallel!
  - `T003` + `T005` both update `organizer_panel_metrics_test.dart` (execute together sequentially).
  - `T006` + `T009` both update `organizer_panel_widget_test.dart` (execute together sequentially after `T004` and `T007`).
- **Phase 5 (`T010`–`T011`)**: Final Quality Gate after all stories complete.

### Parallel Opportunities

```bash
# Parallel Production Implementation Batch (4 distinct files):
T002: lib/application/providers/tournaments_providers.dart
T004: lib/presentation/panel/widgets/organizer_competitions_section.dart
T007: lib/presentation/panel/widgets/organizer_panel_content.dart
T008: lib/application/providers/sync_bootstrap_provider.dart
```

---

## Implementation Strategy

- **MVP**: Phase 1 + Phase 2 (`T001`–`T003`) delivers exact reactive metric calculation.
- **Full Delivery**: All 11 tasks (`T001`–`T011`) are tightly scoped and deliver the complete HU 22.4 DoD in a single pass.
