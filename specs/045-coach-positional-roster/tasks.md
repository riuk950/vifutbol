# Tasks: Visualización de Plantilla Agrupada por Posición en el Panel Técnico (HU 20.2)

**Input**: Design documents from `/specs/045-coach-positional-roster/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/positional_roster_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III (`Pruebas Automatizadas como Puerta de Calidad`) and HU 20.2 Definition of Done.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Localization & Keys)

**Purpose**: Centralize all Spanish UI strings for the coach positional roster section in `lib/l10n/app_es.arb`

- [X] T001 Add Spanish localization keys (`coachRosterSectionTitle`, `coachRosterPositionHeader`, `coachRosterPositionGoalkeepers`, `coachRosterPositionDefenders`, `coachRosterPositionMidfielders`, `coachRosterPositionForwards`, `coachRosterPlayerEligible`, `coachRosterPlayerInactive`, `coachRosterEmptyPosition`, `coachRosterNoGoalkeeperAlert`) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Unit Verification of Positional Grouping & Sorting)

**Purpose**: Ensure the reused `TeamSquadRoster` domain/presentation model strictly satisfies HU 20.2 tactical ordering and dorsal sorting rules

- [X] T003 [P] Create unit tests verifying `TeamSquadRoster.fromCatalog` groups players into `goalkeepers`, `defenders`, `midfielders`, and `forwards` and sorts each group by `shirtNumber` ascending in `test/unit/presentation/team_squad_roster_test.dart`

**Checkpoint**: Positional grouping & dorsal sorting verified at unit level — UI implementation can now proceed

---

## Phase 3: User Story 1 & 2 - Nómina Agrupada por Líneas Tácticas, Detalle y Alerta (Priority: P1) 🎯 MVP

**Goal**: Render `CoachPositionalRosterSection` inside `CoachPanelContent` displaying the 4 tactical groups in strict order (`Porteros` -> `Defensas` -> `Mediocampistas` -> `Delanteros`) with dynamic count headers (`"Defensas (6)"`), shirt number badge, full name, `"Elegible"` / `"Inactivo / Sancionado"` badge, `"Sin jugadores en esta posición"` empty state, and tactical alert when `goalkeepers.isEmpty`.

**Independent Test**: Render `CoachPanelContent` as `UserRole.coach` with an assigned team containing mixed positions/eligibility and without a goalkeeper; verify all 4 groups, counts, dorsal order, player badges, empty state, and tactical alert render cleanly without overflow on 320px/360px screens.

### Tests for User Stories 1 & 2

- [X] T004 [P] [US1] [US2] Add widget tests in `test/presentation/panel/coach_positional_roster_test.dart` verifying strict 4-group tactical order (`Porteros`, `Defensas`, `Mediocampistas`, `Delanteros`), dynamic counts, ascending dorsal order, `"Elegible"` / `"Inactivo / Sancionado"` badges, `"Sin jugadores en esta posición"` empty state, and `coach_no_goalkeeper_tactical_alert` when no goalkeeper is present

### Implementation for User Stories 1 & 2

- [X] T005 [US1] [US2] Create `CoachPositionalRosterSection` widget consuming `TeamSquadRoster` with `KickPulseCard`, `KickPulseBadge`, tactile header counts, ascending dorsal items, subtle empty-position state, and missing-goalkeeper tactical alert in `lib/presentation/panel/widgets/coach_positional_roster_section.dart`
- [X] T006 [US1] [US2] Integrate `CoachPositionalRosterSection` into `CoachPanelContent` watching `teamSquadRosterProvider(team.id)` in `lib/presentation/panel/widgets/coach_panel_content.dart`

**Checkpoint**: User Stories 1 and 2 pass independently via `flutter test test/presentation/panel/coach_positional_roster_test.dart`

---

## Phase 4: User Story 3 - Actualización Reactiva de la Nómina Posicional (Priority: P2)

**Goal**: Ensure updates to the team roster in `teamsControllerProvider` reactively update the positional blocks, counts, and goalkeeper alert in `CoachPanelContent`.

**Independent Test**: Mutate `teamsControllerProvider` state (adding a goalkeeper or toggling player eligibility) while `CoachPanelContent` is mounted and verify immediate UI update.

### Tests for User Story 3

- [X] T007 [US3] Add reactive update widget test in `test/presentation/panel/coach_positional_roster_test.dart` verifying adding a goalkeeper to `teamsControllerProvider` removes `coach_no_goalkeeper_tactical_alert` and updates `"Porteros (0)"` to `"Porteros (1)"`

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, responsive verification, and regression checks

- [X] T008 Run `flutter analyze` and resolve any warnings or errors
- [X] T009 Run `flutter test test/unit/presentation/team_squad_roster_test.dart test/presentation/panel/coach_positional_roster_test.dart test/presentation/panel/coach_panel_widget_test.dart test/presentation/panel/coach_panel_responsive_test.dart test/presentation/panel/coach_panel_content_test.dart` and verify 100% pass rate

---

## Dependencies & Execution Order

- **Phase 1 (Setup)**: `T001` -> `T002`.
- **Phase 2 (Foundational)**: `T003` can run in parallel with Phase 1.
- **Phase 3 (US1 & US2)**: Depends on `T002` (`T004`, `T005` -> `T006`).
- **Phase 4 (US3)**: Depends on `T006` (`T007`).
- **Phase 5 (Polish)**: Depends on Phases 1–4 (`T008` -> `T009`).
