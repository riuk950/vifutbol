# Tasks: Pestaña de Clasificación y Resultados de Equipos en el Detalle de Competición (HU 13.2)

**Input**: Design documents from `specs/019-competition-detail-standings/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-competition-standings-contracts.md`, `quickstart.md`  

**Organization**: Tasks are structured by user story to guarantee independent testability, clear priority ordering, and incremental delivery.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies).
- **[Story]**: Associated user story (e.g. `[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`).
- Includes exact file paths for each task.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Spanish localization keys, code generation, and competitive subview foundations.

- [X] T001 Define Spanish localization keys for competition standings subviews and empty states (`competitionStandingsSubviewsTitle`, `competitionStandingsEmptyTitle`, `competitionStandingsEmptyDescription`, `competitionBracketsEmptyTitle`, `competitionBracketsEmptyDescription`, `competitionRankingsEmptyTitle`, `competitionRankingsEmptyDescription`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core subview selector and format adaptation infrastructure.

**⚠️ CRITICAL**: Must be completed before user story implementation.

- [X] T003 Refactor `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` to watch `tournamentsControllerProvider` to resolve the current `TournamentFormat`
- [X] T004 Implement subview selector chips row (`Key('competition_standings_subview_selector')`) in `CompetitionStandingsTabView` adapting visible chips (`Posiciones`, `Llaves`, `Estadísticas`) based on `tournament.format` and delegating to `controller.selectViewMode()`

**Checkpoint**: Foundation ready — Subview selector container operational and format-aware.

---

## Phase 3: User Story 1 - Visualización de Tabla de Posiciones para Torneo Tipo Liga (Priority: P1) 🎯 MVP

**Goal**: Deliver the official standings table for league tournaments (`league`) with tabular figures and tie-breaker sorting.

**Independent Test**: Navigate to `/competitions/:id` for a league tournament with match results, select the "Clasificación" tab, and verify that `StandingsTableCard` displays all columns (`#`, crest, name, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`) with `FontFeature.tabularFigures()`.

### Implementation for User Story 1

- [X] T005 [US1] Implement league standings view in `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` rendering `StandingsTableCard(mainTable: snapshot.mainStandingsTable, onTeamSelected: null)` when `activeViewMode == CompetitiveViewMode.standings`
- [X] T006 [P] [US1] Implement widget tests in `test/presentation/tournaments/competition_standings_tab_view_test.dart` verifying league standings rendering, tabular typography, and points ordering

**Checkpoint**: User Story 1 complete — Official league standings table operational as independent MVP.

---

## Phase 4: User Story 2 - Cuadro de Llaves Eliminatorias (Bracket) para Torneo de Copa (Priority: P2)

**Goal**: Deliver the visual knockout bracket for cup tournaments (`knockoutCup`) showing rounds, matches, and qualified teams.

**Independent Test**: Navigate to `/competitions/:id` for a cup tournament, select "Clasificación", and verify that `KnockoutBracketCard` renders the playoff tree with rounds and teams.

### Implementation for User Story 2

- [X] T007 [US2] Implement cup knockout bracket view in `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` rendering `KnockoutBracketCard(bracket: snapshot.knockoutBracket!)` when `activeViewMode == CompetitiveViewMode.brackets`
- [X] T008 [P] [US2] Implement widget tests in `test/presentation/tournaments/competition_standings_tab_view_test.dart` verifying knockout bracket rendering for `knockoutCup` tournaments

**Checkpoint**: User Story 2 complete — Visual knockout bracket operational.

---

## Phase 5: User Story 3 - Alternancia entre Grupos y Llaves en Torneos Mixtos (Priority: P3)

**Goal**: Deliver multi-subview switching for mixed tournaments (`mixedGroupsAndKnockout`), defaulting to "Posiciones" (Fase de Grupos) and enabling group-by-group consultation.

**Independent Test**: Open a mixed tournament in `/competitions/:id`, verify that "Posiciones" is active by default with group tabs, switch to "Llaves", and verify the knockout bracket appears smoothly.

### Implementation for User Story 3

- [X] T009 [US3] Implement mixed format handling in `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` supporting `[Posiciones, Llaves, Estadísticas]`, defaulting to `CompetitiveViewMode.standings`, and passing `groupTables` to `StandingsTableCard`
- [X] T010 [P] [US3] Implement widget tests in `test/presentation/tournaments/competition_standings_tab_view_test.dart` verifying mixed tournament subviews switching and group table tabs

**Checkpoint**: User Story 3 complete — Mixed tournament multi-stage navigation operational.

---

## Phase 6: User Story 4 - Estadísticas Adicionales y Ranking de Goleadores (Priority: P4)

**Goal**: Present the comprehensive tournament rankings (`TournamentRankingsCard`) with top scorers, disciplinary records (yellow/red cards), and clean sheets.

**Independent Test**: In the "Clasificación" tab, tap the "Estadísticas" chip, and verify that `TournamentRankingsCard` renders the scorers, fair play, and goalkeeper rankings.

### Implementation for User Story 4

- [X] T011 [US4] Implement "Estadísticas" subview in `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` rendering `TournamentRankingsCard(rankings: snapshot.rankings)` when `activeViewMode == CompetitiveViewMode.rankings`
- [X] T012 [P] [US4] Implement widget tests in `test/presentation/tournaments/competition_standings_tab_view_test.dart` verifying rankings card rendering (scorers, cards, clean sheets) on "Estadísticas" chip selection

**Checkpoint**: User Story 4 complete — Complete individual and disciplinary rankings operational.

---

## Phase 7: User Story 5 - Estados Vacíos y Resiliencia sin Partidos Jugados (Priority: P5)

**Goal**: Present contextualized informative empty states (`KickPulseStateView`) when a tournament has no standings, bracket, or statistics generated yet, keeping subview chips accessible.

**Independent Test**: Open a newly created tournament in "Clasificación", verify the empty standings message, switch to "Estadísticas", and verify the contextual empty statistics message.

### Implementation for User Story 5

- [X] T013 [US5] Implement contextual `KickPulseStateView` empty states in `CompetitionStandingsTabView` in `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` for standings (`competition_detail_standings_empty_state`), brackets (`competition_detail_brackets_empty_state`), and rankings (`competition_detail_rankings_empty_state`) while keeping subview chips visible
- [X] T014 [P] [US5] Implement widget tests in `test/presentation/tournaments/competition_standings_tab_view_test.dart` verifying contextual empty states and loading indicator without app crash

**Checkpoint**: User Story 5 complete — Resilient empty and loading state management operational.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Responsive validation, accessibility (`320x640` @ `130%` text scaling), and global quality gate execution.

- [X] T015 [P] Run responsive layout and rendering tests at $320 \times 640\text{ px}$ with $130\%$ text scaling in `test/presentation/directories_responsive_widget_test.dart` and `test/presentation/tournaments/competition_detail_screen_test.dart` verifying 0 `RenderFlex` overflows on `CompetitionDetailScreen` in the "Clasificación" tab
- [X] T016 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and all tournament widget tests validating scenarios in `specs/019-competition-detail-standings/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T002`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T003`–`T004`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T005`–`T006`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T007`–`T008`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T009`–`T010`)**: Depends on Phase 3 and Phase 4 completion.
- **Phase 6: User Story 4 (`T011`–`T012`)**: Depends on Phase 2 completion.
- **Phase 7: User Story 5 (`T013`–`T014`)**: Depends on Phase 2 completion.
- **Phase 8: Polish (`T015`–`T016`)**: Depends on completion of all user stories.

---

## Parallel Opportunities

- `T006` (US1 widget tests) can run in parallel with `T005` once contracts are set.
- `T008` (US2 widget tests) can run in parallel with `T007`.
- `T010` (US3 widget tests) can run in parallel with `T009`.
- `T012` (US4 widget tests) can run in parallel with `T011`.
- `T014` (US5 widget tests) can run in parallel with `T013`.
- `T015` (responsive tests) can run in parallel with `T016`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T004`)
3. Complete Phase 3: User Story 1 (`T005`–`T006`)
4. **STOP and VALIDATE**: Verify official league standings table independently.
5. Deliver MVP increment.

### Incremental Delivery

1. Setup + Foundational → Subview navigation ready.
2. User Story 1 (P1) → Official league standings table (MVP!).
3. User Story 2 (P2) → Cup knockout bracket view.
4. User Story 3 (P3) → Mixed format group & bracket switching.
5. User Story 4 (P4) → Individual & disciplinary rankings.
6. User Story 5 (P5) → Contextual empty states for unplayed tournaments.
7. Polish → 320x640 @ 130% text scaling validation, static analyzer, and formatter.
