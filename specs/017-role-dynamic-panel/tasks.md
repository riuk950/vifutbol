---

description: "Task list for HU 12.2: Pantalla de Panel Administrativo Dinámico por Rol (Organizador, Entrenador, Árbitro y Jugador)"
---

# Tasks: Pantalla de Panel Administrativo Dinámico por Rol (HU 12.2)

**Input**: Design documents from `/specs/017-role-dynamic-panel/`

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-panel-contracts.md](contracts/ui-panel-contracts.md), [quickstart.md](quickstart.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`, `US4`, `US5`) to enable independent implementation and testing of each increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Localization & Shared Presentation Models)

**Purpose**: Centralize new Spanish UI strings and define shared presentation aggregates before implementing UI components.

- [X] T001 Define all Spanish localization keys for titles, metric labels, actions, and empty states in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes in `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`
- [X] T003 [P] Create presentation data models (`OrganizerPanelData`, `CoachPanelData`, `RefereePanelData`, `PlayerPanelData`) in `lib/presentation/panel/models/panel_presentation_models.dart`

---

## Phase 2: Foundational (Scaffold Host & Role Enrutador)

**Purpose**: Core router and container infrastructure in `PanelScreen` that hosts the dynamic subpanels.

**⚠️ CRITICAL**: Complete this phase before implementing individual user stories.

- [X] T004 Refactor `PanelScreen` in `lib/presentation/panel/panel_screen.dart` to dynamically resolve AppBar title (`Key('panel_screen_title')`) and render role-specific subpanels based on `activeRole`
- [X] T005 [P] Create base scaffold stub widgets for `OrganizerPanelContent`, `CoachPanelContent`, `RefereePanelContent`, `PlayerPanelContent`, and `FanPanelRestrictedContent` under `lib/presentation/panel/widgets/`

**Checkpoint**: Foundation ready — `PanelScreen` dynamically routes to subwidgets based on `UserRole`.

---

## Phase 3: User Story 1 - Panel de Gestión para el Rol Organizador (Priority: P1) 🎯 MVP

**Goal**: Deliver a specialized management dashboard for `UserRole.organizer` with metrics (active tournaments, pending matches, unseeded tournaments) and quick actions (Generar Fixture, Programar Partido, Copia de Seguridad).

**Independent Test**: Can be tested independently by launching `PanelScreen` with `UserRole.organizer`, verifying AppBar title "Panel de Organización", validating that cards display active tournament metrics, and testing that action buttons respond properly with single-flight locks.

### Implementation for User Story 1

- [X] T006 [US1] Implement `OrganizerPanelContent` in `lib/presentation/panel/widgets/organizer_panel_content.dart` consuming `tournamentsControllerProvider` and `matchesCatalogControllerProvider` with metrics cards and quick action buttons
- [X] T007 [P] [US1] Implement widget tests for `OrganizerPanelContent` in `test/presentation/panel/organizer_panel_widget_test.dart` verifying AppBar title, metric cards, and quick actions

**Checkpoint**: User Story 1 complete — Organizer dashboard operational as independent MVP.

---

## Phase 4: User Story 2 - Panel Técnico para el Rol Entrenador (Priority: P2)

**Goal**: Deliver a technical squad dashboard for `UserRole.coach` with squad eligibility breakdown (total players, eligible vs suspended) and quick access to next match lineup.

**Independent Test**: Can be tested independently by launching `PanelScreen` with `UserRole.coach`, verifying AppBar title "Panel Técnico", checking squad eligibility count cards, and verifying the next match lineup action.

### Implementation for User Story 2

- [X] T008 [US2] Implement `CoachPanelContent` in `lib/presentation/panel/widgets/coach_panel_content.dart` displaying team summary, player eligibility counts, and lineup quick actions
- [X] T009 [P] [US2] Implement widget tests for `CoachPanelContent` in `test/presentation/panel/coach_panel_widget_test.dart` verifying AppBar title, squad breakdown, and lineup trigger

**Checkpoint**: User Story 2 complete — Coach dashboard operational independently.

---

## Phase 5: User Story 3 - Panel Arbitral para el Rol Árbitro (Priority: P3)

**Goal**: Deliver a referee dashboard for `UserRole.referee` listing assigned matches with a direct button to open the Digital Match Report, and an informative empty state when no matches are assigned.

**Independent Test**: Can be tested independently by launching `PanelScreen` with `UserRole.referee`, verifying AppBar title "Panel Arbitral", verifying the assigned matches list with "Acta Digital" buttons, and verifying the empty state when no matches match `refereeId`.

### Implementation for User Story 3

- [X] T010 [US3] Implement `RefereePanelContent` in `lib/presentation/panel/widgets/referee_panel_content.dart` filtering assigned matches with digital report action and empty state fallback
- [X] T011 [P] [US3] Implement widget tests for `RefereePanelContent` in `test/presentation/panel/referee_panel_widget_test.dart` verifying AppBar title, assigned match items, digital report action, and empty state

**Checkpoint**: User Story 3 complete — Referee dashboard operational independently.

---

## Phase 6: User Story 4 - Ficha Deportiva y Estadísticas para el Rol Jugador (Priority: P4)

**Goal**: Deliver a player profile dashboard for `UserRole.player` with eligibility badge (Habilitado / Sancionado), season statistics cards, and next club match.

**Independent Test**: Can be tested independently by launching `PanelScreen` with `UserRole.player`, verifying AppBar title "Ficha del Jugador", checking eligibility status badge, and checking statistical cards (goals, assists, cards, matches played).

### Implementation for User Story 4

- [X] T012 [US4] Implement `PlayerPanelContent` in `lib/presentation/panel/widgets/player_panel_content.dart` with eligibility badge, season performance cards, and next match summary
- [X] T013 [P] [US4] Implement widget tests for `PlayerPanelContent` in `test/presentation/panel/player_panel_widget_test.dart` verifying AppBar title, eligibility badge, and statistical aggregates

**Checkpoint**: User Story 4 complete — Player dashboard operational independently.

---

## Phase 7: User Story 5 - Restricción Informativa para Rol Aficionado (Priority: P5)

**Goal**: Deliver a dedicated informative restriction view for `UserRole.fan` explaining role exclusivity and providing a clean return button to `/matches`.

**Independent Test**: Can be tested independently by launching `PanelScreen` with `UserRole.fan`, verifying that administrative tools are hidden, the informative message is displayed, and tapping "Volver a Partidos" navigates to `/matches`.

### Implementation for User Story 5

- [X] T014 [US5] Implement `FanPanelRestrictedContent` in `lib/presentation/panel/widgets/fan_panel_restricted_content.dart` with illustrated explanation and "Volver a Partidos" button
- [X] T015 [P] [US5] Implement widget tests for `FanPanelRestrictedContent` in `test/presentation/panel/fan_panel_restricted_widget_test.dart` verifying restriction view and navigation to `/matches`

**Checkpoint**: User Story 5 complete — Fan role safely restricted with clean navigation exit.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Responsive validation, accessibility (`320x640` @ `130%` text scaling), and global quality gate execution.

- [X] T016 [P] Implement compact viewport (`320x640` logical pixels) and `130%` text scaling tests across all 5 subpanels in `test/presentation/directories_responsive_widget_test.dart` verifying zero `RenderFlex` overflows
- [X] T017 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and presentation tests to validate all scenarios in `specs/017-role-dynamic-panel/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T003`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T004`–`T005`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T006`–`T007`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T008`–`T009`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T010`–`T011`)**: Depends on Phase 2 completion.
- **Phase 6: User Story 4 (`T012`–`T013`)**: Depends on Phase 2 completion.
- **Phase 7: User Story 5 (`T014`–`T015`)**: Depends on Phase 2 completion.
- **Phase 8: Polish (`T016`–`T017`)**: Depends on completion of all desired user stories.

### Parallel Opportunities

- `T001` / `T002` and `T003` can proceed in parallel `[P]`.
- User story subwidgets and tests can be developed in parallel once Phase 2 completes.
- Within each story, tests and models marked `[P]` can proceed in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T003`).
2. Complete Phase 2: Foundational (`T004`–`T005`).
3. Complete Phase 3: User Story 1 (`T006`–`T007`).
4. **STOP and VALIDATE**: Test Organizer Panel independently.

### Incremental Delivery

1. Setup + Foundational ready.
2. Deliver US1 (Organizador) $\to$ Validate.
3. Deliver US2 (Entrenador) $\to$ Validate.
4. Deliver US3 (Árbitro) $\to$ Validate.
5. Deliver US4 (Jugador) $\to$ Validate.
6. Deliver US5 (Aficionado) $\to$ Validate.
7. Polish & Quality Gates (`T016`–`T017`).
