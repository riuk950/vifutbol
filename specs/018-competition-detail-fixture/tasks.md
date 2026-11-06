# Tasks: Pantalla de Detalle de Competición con Pestañas y Partidos por Jornadas (Fixture Completo)

**Input**: Design documents from `specs/018-competition-detail-fixture/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-competition-detail-contracts.md`, `quickstart.md`

**Organization**: Tasks are structured by user story to guarantee independent testability and incremental delivery.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies).
- **[Story]**: Associated user story (e.g. `[US1]`, `[US2]`, `[US3]`, `[US4]`).
- Includes exact file paths for each task.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization keys, code generation, and domain/presentation data aggregates.

- [X] T001 Define Spanish localization keys for competition detail tabs, fixture empty state, pending status, round headers, and rules in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n`
- [X] T003 [P] Create presentation model `MatchdayFixtureGroup` and pure grouping function `groupMatchesByRoundNumber` in `lib/presentation/tournaments/models/matchday_fixture_group.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core navigation and screen container required by all user stories.

**⚠️ CRITICAL**: Must be completed before user story implementation.

- [X] T004 Define and register `/competitions/:id` route in `lib/presentation/navigation/app_router.dart` mapping to `CompetitionDetailScreen(tournamentId: id)`
- [X] T005 [P] Update `CompetitionsDirectoryScreen` in `lib/presentation/directories/competitions_directory_screen.dart` to navigate to `/competitions/${tournament.id}` on tournament tap
- [X] T006 Implement base `CompetitionDetailScreen` in `lib/presentation/tournaments/competition_detail_screen.dart` with AppBar (title, category, status badge, back button) and fixed 3-tab `TabBar` structure

**Checkpoint**: Foundation ready — Navigation to `/competitions/:id` and screen container operational.

---

## Phase 3: User Story 1 - Navegación y Fixture Completo por Jornadas (Priority: P1) 🎯 MVP

**Goal**: Deliver the full tournament fixture in the default "Partidos" tab grouped chronologically by round with prominent headers in a continuous scroll view.

**Independent Test**: Can be tested independently by navigating to `/competitions/:id` for a tournament with scheduled matches, verifying the AppBar title/category/badge, verifying "Partidos" is active by default, and validating that round headers ("Jornada 1", "Jornada 2", etc.) and match items are displayed.

### Implementation for User Story 1

- [X] T007 [US1] Implement `CompetitionFixtureTabView` in `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart` rendering continuous vertical scroll list with round headers (`Key('fixture_round_header_${roundNumber}')`) and match cards
- [X] T008 [P] [US1] Implement widget tests in `test/presentation/tournaments/competition_fixture_widget_test.dart` verifying round grouping, chronological ordering, and full fixture rendering

**Checkpoint**: User Story 1 complete — Competition fixture browsing operational as independent MVP.

---

## Phase 4: User Story 2 - Estructura de Pestañas Horizontales Fijas (Priority: P2)

**Goal**: Deliver a 3-tab navigation bar ("Partidos", "Clasificación" e "Información") immediately below the AppBar with tab switching and state preservation.

**Independent Test**: Can be tested independently by opening `CompetitionDetailScreen`, switching between "Partidos", "Clasificación", and "Información", verifying tab indicator highlight and content changes.

### Implementation for User Story 2

- [X] T009 [US2] Implement `CompetitionStandingsTabView` (connecting with `standingsAndRankingsControllerProvider(tournamentId)`) and `CompetitionInfoTabView` (informational rules placeholder) under `lib/presentation/tournaments/widgets/`
- [X] T010 [P] [US2] Implement widget tests in `test/presentation/tournaments/competition_detail_screen_test.dart` verifying TabBar navigation, active tab highlight, and switching between all 3 tabs

**Checkpoint**: User Story 2 complete — 3-tab navigation and tab content integration operational.

---

## Phase 5: User Story 3 - Tarjetas de Partido y Apertura Modal de Match Center (Priority: P3)

**Goal**: Present match cards with status, scores, date/venue or pending badges, and open the Match Center modal on tap.

**Independent Test**: Can be tested independently by tapping a match card in the fixture and verifying that the modal sheet opens with complete match details, events, and lineups.

### Implementation for User Story 3

- [X] T011 [US3] Integrate `MatchCenterCard` in `CompetitionFixtureTabView` with status/score/date/pitch and trigger modal bottom sheet on tap displaying match details
- [X] T012 [P] [US3] Implement widget tests in `test/presentation/tournaments/competition_fixture_widget_test.dart` verifying match card details (scores, venues, pending badges) and modal sheet opening on tap

**Checkpoint**: User Story 3 complete — Interactive match inspection operational.

---

## Phase 6: User Story 4 - Estado Vacío Informativo para Competiciones Sin Fixture (Priority: P4)

**Goal**: Present an informative, friendly empty state (`KickPulseStateView`) in the "Partidos" tab when a tournament has no generated matches.

**Independent Test**: Can be tested independently by launching `CompetitionDetailScreen` for a tournament with 0 matches, verifying the empty state message and icon without errors.

### Implementation for User Story 4

- [X] T013 [US4] Integrate `KickPulseStateView` empty state in `CompetitionFixtureTabView` (`Key('fixture_empty_matches_state')`) with calendar preparation message when a tournament has 0 matches
- [X] T014 [P] [US4] Implement widget tests in `test/presentation/tournaments/competition_fixture_widget_test.dart` verifying empty state appearance and behavior when tournament has no matches

**Checkpoint**: User Story 4 complete — Resilient empty state operational for newly registered tournaments.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Responsive validation, accessibility (`320x640` @ `130%` text scaling), and global quality gate execution.

- [X] T015 [P] Implement compact viewport (`320x640` logical pixels) and `130%` text scaling tests in `test/presentation/directories_responsive_widget_test.dart` for `CompetitionDetailScreen` verifying zero `RenderFlex` overflows
- [X] T016 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and all tournament widget tests validating scenarios in `specs/018-competition-detail-fixture/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T003`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T004`–`T006`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T007`–`T008`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T009`–`T010`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T011`–`T012`)**: Depends on Phase 3 completion (`CompetitionFixtureTabView`).
- **Phase 6: User Story 4 (`T013`–`T014`)**: Depends on Phase 3 completion (`CompetitionFixtureTabView`).
- **Phase 7: Polish (`T015`–`T016`)**: Depends on completion of all desired user stories.

---

## Parallel Opportunities

- `T003` (presentation models) can run in parallel with `T001`–`T002`.
- `T005` (directory navigation update) can run in parallel with `T004` (route definition).
- `T008` (US1 widget tests) can run in parallel with `T007` once contracts are set.
- `T010` (US2 widget tests) can run in parallel with `T009`.
- `T012` (US3 widget tests) can run in parallel with `T011`.
- `T014` (US4 widget tests) can run in parallel with `T013`.
- `T015` (responsive tests) can run in parallel with `T016`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T003`)
2. Complete Phase 2: Foundational (`T004`–`T006`)
3. Complete Phase 3: User Story 1 (`T007`–`T008`)
4. **STOP and VALIDATE**: Verify navigation and fixture browsing independently.
5. Deliver/demo MVP increment.

### Incremental Delivery

1. Setup + Foundational → Navigation infrastructure ready.
2. User Story 1 (P1) → Full fixture browsing by rounds (MVP!).
3. User Story 2 (P2) → 3-tab navigation with standings and rules tabs.
4. User Story 3 (P3) → Interactive match cards and modal sheet.
5. User Story 4 (P4) → Informative empty state for new tournaments.
6. Polish → 320x640 @ 130% text scaling validation, analyzer, and formatter.
