# Tasks: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador (HU 16.1)

**Input**: Design documents from `/specs/028-organizer-competitions-crud/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-organizer-competitions-contracts.md`, `quickstart.md`
**Tests**: Automated tests included per Constitution Principle III (Pruebas Automatizadas como Puerta de Calidad).
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Exact file paths included in every task description

---

## Phase 1: Setup & Localization (Shared Infrastructure)

**Purpose**: Setup localization strings and dependencies required by all user stories

- [x] T001 Define and register all localization strings in `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb`, and generate localizations via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, repository contracts, and base providers that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 [P] Update domain entity `ChampionshipTournament` in `lib/domain/entities/championship_tournament.dart` to support optional `organizerId` with default in `fromJson` and `copyWith`
- [x] T003 [P] Add unit tests for `ChampionshipTournament.organizerId` serialization and fallback in `test/domain/championship_tournament_organizer_test.dart`
- [x] T004 Update `TournamentsRepository` contract in `lib/domain/repositories/tournaments_repository.dart` to add `Future<void> deleteTournament(String tournamentId);`
- [x] T005 Implement `deleteTournament` and update seed tournaments with `organizerId: 'org-seed-1'` in `lib/infrastructure/repositories/local_tournaments_repository.dart`
- [x] T006 [P] Add repository tests for `deleteTournament` and seed persistence in `test/infrastructure/repositories/local_tournaments_repository_crud_test.dart`
- [x] T007 Add `organizerTournamentsProvider` filtering by active user session `organizerId` in `lib/application/providers/tournaments_providers.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel or sequentially.

---

## Phase 3: User Story 1 - Visualización y Filtrado de Competiciones del Organizador (Priority: P1) 🎯 MVP

**Goal**: Enable organizers to view their exclusive list of championships with status badges, category, teams count, quick create action, or an empty state when none exist.

**Independent Test**: Log in as an organizer with tournaments to verify cards are rendered with badges; log in without tournaments to verify empty state and the "+ Nueva Competición" action.

### Tests for User Story 1
- [x] T008 [P] [US1] Widget test for `OrganizerCompetitionsSection` empty state and list rendering in `test/presentation/panel/organizer_competitions_section_test.dart`

### Implementation for User Story 1
- [x] T009 [US1] Implement `OrganizerCompetitionsSection` widget with tournament cards, status badges, empty state, and create action in `lib/presentation/panel/widgets/organizer_competitions_section.dart`
- [x] T010 [US1] Embed `OrganizerCompetitionsSection` inside `OrganizerPanelContent` in `lib/presentation/panel/widgets/organizer_panel_content.dart`

**Checkpoint**: User Story 1 functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Edición de Metadatos de la Competición (Priority: P2)

**Goal**: Allow organizers to edit name, category, format, scoring system, and rules from a pre-filled dialog, recalculating standings if the tournament is already in progress.

**Independent Test**: Open edit dialog from a tournament card, update metadata, save, and verify instant reflection in UI and state.

### Tests for User Story 2
- [x] T011 [P] [US2] Unit test for tournament metadata updates and validation in `TournamentsController` in `test/application/controllers/tournaments_controller_update_test.dart`
- [x] T012 [P] [US2] Widget test for `CompetitionEditDialog` form validation and submission in `test/presentation/panel/competition_edit_dialog_test.dart`

### Implementation for User Story 2
- [x] T013 [US2] Implement `updateTournamentMetadata` method in `TournamentsController` in `lib/application/controllers/tournaments_controller.dart`
- [x] T014 [US2] Implement `CompetitionEditDialog` in `lib/presentation/panel/widgets/competition_edit_dialog.dart` and wire it to "Editar metadatos" option in `OrganizerCompetitionsSection`

**Checkpoint**: User Stories 1 AND 2 functional and independently testable.

---

## Phase 5: User Story 3 - Transición Controlada del Ciclo de Vida del Campeonato (Priority: P3)

**Goal**: Implement strict unidirectional lifecycle progression (`openRegistration` → `inProgress` → `finished`), validating $\ge 2$ teams and generated fixture before starting, with quick actions to complete missing requirements.

**Independent Test**: Attempt transition without fixture/teams to verify blocking modal and quick action shortcuts ("Inscribir Equipos", "Generar Fixture"); verify successful transition once prerequisites are met; verify prevention of backwards state transitions.

### Tests for User Story 3
- [x] T015 [P] [US3] Unit test for lifecycle transition validations and rule enforcement in `TournamentsController` in `test/application/controllers/tournaments_controller_lifecycle_test.dart`
- [x] T016 [P] [US3] Widget test for `CompetitionLifecycleDialog` and quick action buttons in `test/presentation/panel/competition_lifecycle_dialog_test.dart`

### Implementation for User Story 3
- [x] T017 [US3] Implement `transitionTournamentStatus` method in `TournamentsController` in `lib/application/controllers/tournaments_controller.dart`
- [x] T018 [US3] Implement `CompetitionLifecycleDialog` in `lib/presentation/panel/widgets/competition_lifecycle_dialog.dart` with quick action buttons and connect to card menu in `OrganizerCompetitionsSection`

**Checkpoint**: User Stories 1, 2, and 3 functional and independently testable.

---

## Phase 6: User Story 4 - Eliminación Restringida y Segura de Competición (Priority: P4)

**Goal**: Allow safe deletion of tournaments only in `openRegistration` without played matches, cascade-deleting scheduled matches, resetting active selection, and blocking deletion for active/finished tournaments.

**Independent Test**: Verify deletion is blocked if status is `inProgress` or has played matches; verify confirmation dialog and successful deletion for eligible tournaments, resetting `selectedTournamentProvider` seamlessly.

### Tests for User Story 4
- [x] T019 [P] [US4] Unit test for deletion rules, active selection reset, and cascade deletion in `test/application/controllers/tournaments_controller_delete_test.dart`
- [x] T020 [P] [US4] Widget test for `CompetitionDeleteDialog` (blocking mode and confirmation mode) in `test/presentation/panel/competition_delete_dialog_test.dart`

### Implementation for User Story 4
- [x] T021 [US4] Implement `deleteTournament` method with cascade deletion and active selection fallback in `TournamentsController` in `lib/application/controllers/tournaments_controller.dart`
- [x] T022 [US4] Implement `CompetitionDeleteDialog` in `lib/presentation/panel/widgets/competition_delete_dialog.dart` and connect to card menu in `OrganizerCompetitionsSection`

**Checkpoint**: All user stories functional and independently testable.

---

## Phase 7: Polish & Quality Gates

**Purpose**: Cross-cutting validation, responsive testing, static analysis, and regression checks

- [x] T023 [P] Add responsive layout test at 320x640 with 130% text scaling in `test/presentation/panel/organizer_competitions_responsive_test.dart`
- [x] T024 Run `flutter analyze` and verify 0 errors and 0 warnings across the codebase
- [x] T025 Run full automated test suite to ensure zero regressions across all modules

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: Can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1; blocks all user stories.
- **US1 (Phase 3)**: Depends on Phase 2; serves as MVP.
- **US2 (Phase 4)**: Depends on Phase 2 and US1 card menu integration.
- **US3 (Phase 5)**: Depends on Phase 2 and US1 card menu integration.
- **US4 (Phase 6)**: Depends on Phase 2 and US1 card menu integration.
- **Polish (Phase 7)**: Depends on Phases 1-6 completion.

### Parallel Opportunities
- Within Phase 2: T002, T003, and T006 can run in parallel.
- Tests within each User Story (T008, T011, T012, T015, T016, T019, T020) can run in parallel with entity/UI preparation.
- US2, US3, and US4 controller methods and dialogs can be developed in parallel once Phase 3 (US1) is completed.

---

## Implementation Strategy (MVP First)

1. **Step 1**: Complete Phase 1 (Localization) and Phase 2 (Foundational Entities, Repositories, Providers).
2. **Step 2**: Implement Phase 3 (US1 - Competitions Section & Cards). **Deliver MVP**.
3. **Step 3**: Incrementally implement Phase 4 (US2 - Metadata Editing).
4. **Step 4**: Incrementally implement Phase 5 (US3 - Lifecycle Transitions & Quick Actions).
5. **Step 5**: Incrementally implement Phase 6 (US4 - Restricted Deletion & Cascade).
6. **Step 6**: Execute Phase 7 (Responsive verification, static analysis, test suite).
