# Tasks: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Input**: Design documents from `/specs/007-fixture-generation-assignment/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/data-model.md), [fixture-scheduling-contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/contracts/fixture-scheduling-contract.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description.

---

## Phase 1: Setup (Shared Localization & Seed Data)

**Purpose**: Prepare Spanish localization strings for fixture generation, round navigation, match scheduling, and collision warnings (`FR-007`), and configure official referee and match seeds in `AppEnvironment.development` (`FR-002`).

- [x] T001 Add Spanish localization strings for matchday tabs, round chips (`"Jornada {number}"`), status filters (`"Todos"`, `"Pendiente"`, `"Programado"`, `"Finalizado"`), fixture generation button and confirmation dialog, match scheduling dialog (`"Programar Partido"`, date, time, venue, pitch, referee), and collision error messages (`"Conflicto de Cancha"`, `"Conflicto de Árbitro"`, `"Conflicto de Equipo"`) in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations*.dart`
- [x] T002 [P] Prepare official referee seed records (`'ref-seed-1'` `"Nicolás Gallo"` FIFA, `'ref-seed-2'` `"Wilmar Roldán"` FIFA, `'ref-seed-3'` `"Andrés Rojas"` Nacional) and default seed matches for `tourn-seed-torneo-relampago-2026` in `lib/infrastructure/repositories/local_tournament_matches_repository.dart`

---

## Phase 2: Foundational (Core Domain Entities, Failures & Repository Contract)

**Purpose**: Core domain models, collision models, error codes, and repository abstractions that MUST be complete before user story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 [P] Create domain enumerations `MatchStatus` (`pendingSchedule`, `scheduled`, `inProgress`, `completed`, `cancelled`) and `ScheduleCollisionType` (`pitchConflict`, `refereeConflict`, `teamConflict`) in `lib/domain/entities/match_enums.dart`
- [x] T004 [P] Create `MatchReferee` entity (`id` non-empty, `fullName` `>= 3` chars, `certificationLevel` non-empty, `isActive` default true) with JSON serialization in `lib/domain/entities/match_referee.dart`
- [x] T005 [P] Create `ChampionshipMatch` entity (`id`, `tournamentId`, `roundNumber >= 1`, `roundName`, `homeTeamId`, `awayTeamId != homeTeamId`, `scheduledStartTime`, `scheduledEndTime`, `venueId`, `pitchId`, `pitchName`, `refereeId`, `refereeName`, `status`, `updatedAt`) with `isScheduled`, `overlapsWith(DateTime start, DateTime end)`, and JSON serialization in `lib/domain/entities/championship_match.dart`
- [x] T006 [P] Create `ScheduleCollisionResult` entity (`hasCollision`, `collisionType`, `conflictingMatchId`, `conflictingEntityName`, `message`) in `lib/domain/entities/schedule_collision_result.dart`
- [x] T007 [P] Create `MatchesCatalogState` immutable state (`matches`, `referees`, `selectedRound`, `statusFilter`, `teamFilter`, `isLoading`, `isSaving`, `errorMessage`) in `lib/domain/entities/matches_catalog_state.dart`
- [x] T008 [P] Extend `lib/domain/failures/app_failure.dart` with `FixtureScheduleErrorCode` (`unauthorizedRole`, `insufficientTeams`, `tournamentClosed`, `invalidScheduleTimes`, `pitchScheduleCollision`, `refereeScheduleCollision`, `teamScheduleCollision`) and `FixtureScheduleValidationFailure`
- [x] T009 [P] Define `TournamentMatchesRepository` abstract interface (`loadMatchesForTournament`, `saveMatch`, `saveMatchesBatch`, `loadOfficialReferees`) in `lib/domain/repositories/tournament_matches_repository.dart`
- [x] T010 Implement `LocalTournamentMatchesRepository` with JSON storage keys `'vifutbol.matches.v1'` and `'vifutbol.referees.v1'`, batch persistence, and seed referees/matches in `lib/infrastructure/repositories/local_tournament_matches_repository.dart`
- [x] T011 [P] Write unit tests for `ChampionshipMatch` interval logic (`overlapsWith`), `MatchReferee`, and `LocalTournamentMatchesRepository` in `test/unit/domain/championship_match_entities_test.dart` and `test/unit/infrastructure/local_tournament_matches_repository_test.dart`

**Checkpoint**: Foundation ready — user story implementation can begin.

---

## Phase 3: User Story 1 - Generación de Fixture y Distribución de Jornadas (Priority: P1) 🎯 MVP

**Goal**: Allow the `Organizador` to generate the complete round-robin fixture for eligible teams, creating all pairings with status `pendingSchedule` grouped by rounds, and navigate between rounds via horizontal chips in `MatchdayTabView` (`FR-001`, `FR-005`).

**Independent Test**: As `Organizador`, select a tournament with 4 eligible teams in `MatchdayTabView`, tap `"Generar Fixture"`, and verify that 3 rounds of 2 matches each are generated with status `"Pendiente de Programación"`, and tapping each round chip displays only the matches for that round.

### Implementation & Tests for User Story 1

- [x] T012 [US1] Implement `RoundRobinGenerator` domain service in `lib/domain/services/round_robin_generator.dart` supporting even and odd team counts (with bye team), round pairing rotation, home/away alternation (`leagueRounds`), and knockout bracket generation (`TournamentFormat.knockout` / `KnockoutRound`)
- [x] T013 [P] [US1] Write unit tests for `RoundRobinGenerator` validating pair generation for 4, 5 (bye), and 8 teams, round counts, knockout brackets, and team recurrence in `test/unit/domain/round_robin_generator_test.dart`
- [x] T014 [US1] Implement `FixtureSchedulingUseCase.generateRoundRobinFixture` enforcing organizer authorization (`RoleCapability.manageTournaments`), minimum 2 eligible teams (`TeamEligibilityStatus.eligible`), blocking regeneration if matches are already `inProgress` or `completed`, and batch persistence in `lib/application/use_cases/fixture_scheduling_use_case.dart`
- [x] T015 [US1] Implement `MatchesCatalogController` (`StateNotifier<MatchesCatalogState>`) with `loadTournamentMatches`, `selectRound`, `setStatusFilter`, `setTeamFilter`, and Riverpod providers in `lib/application/controllers/matches_catalog_controller.dart` and `lib/application/providers/matches_catalog_providers.dart`
- [x] T016 [US1] Refactor `MatchdayTabView` in `lib/presentation/shell/tabs/matchday_tab_view.dart` and create `GenerateFixtureConfirmationDialog` in `lib/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart`, replacing the demo selector with horizontal round chips, status and team filters, empty fixture view with `"Generar Fixture"` action, and tournament matches list
- [x] T017 [US1] Create `MatchCard` widget displaying team badges, team names, match status pill (`"Pendiente de Programación"` vs `"Programado"`), round title, and organizer action button in `lib/presentation/matches/widgets/match_card.dart`

**Checkpoint**: User Story 1 (Deterministic fixture generation and round navigation) is functional and testable.

---

## Phase 4: User Story 2 - Programación de Encuentros, Asignación de Canchas y Designación de Árbitros (Priority: P2)

**Goal**: Allow the `Organizador` to assign date, time, venue, pitch, and official referee to a pending match, calculating match end time ($2 \times \text{halfDurationMinutes} + 15\text{ min}$) and transitioning status to `"Programado"` (`FR-002`, `FR-003`).

**Independent Test**: Select a pending match in `MatchdayTabView`, tap `"Programar"`, choose date, time, pitch, and official referee in `ScheduleMatchDialog`, save, and verify the match card updates to `"Programado"` displaying scheduled date/time, pitch name, and referee name.

### Implementation & Tests for User Story 2

- [x] T018 [US2] Enhance `FixtureSchedulingUseCase` with `scheduleMatch` calculating match end time from tournament half duration ($2 \times \text{halfDurationMinutes} + 15\text{ min}$) and updating match status to `MatchStatus.scheduled` in `lib/application/use_cases/fixture_scheduling_use_case.dart`
- [x] T019 [US2] Enhance `MatchesCatalogController` with `scheduleMatch` action, error handling, and state refresh in `lib/application/controllers/matches_catalog_controller.dart`
- [x] T020 [US2] Create `ScheduleMatchDialog` modal with date picker, time picker, sports venue / pitch selector (reading from `venuesRepositoryProvider`), and official referee selector (reading from `loadOfficialReferees`) in `lib/presentation/matches/widgets/schedule_match_dialog.dart` and trigger it from `MatchCard`

**Checkpoint**: User Stories 1 and 2 are complete and verified.

---

## Phase 5: User Story 3 - Detección y Bloqueo de Conflictos Horarios en Recursos Físicos y Humanos (Priority: P3)

**Goal**: Prevent scheduling overlaps in $[T_{start}, T_{end}]$ for the same pitch, same referee, or either competing team, displaying an explicit error dialog with conflict details (`FR-004`).

**Independent Test**: Schedule match A on pitch 1 from 14:00 to 15:15 with referee "Wilmar Roldán". Then attempt to schedule match B on pitch 1 from 14:30 to 15:45 (or with referee "Wilmar Roldán"). Verify the system blocks the operation and displays a specific collision warning dialog.

### Implementation & Tests for User Story 3

- [x] T021 [US3] Implement `detectCollisions` in `FixtureSchedulingUseCase` detecting pitch overlaps (`pitchScheduleCollision`), referee overlaps (`refereeScheduleCollision`), and team overlaps (`teamScheduleCollision`) in $[T_{start}, T_{end}]$ in `lib/application/use_cases/fixture_scheduling_use_case.dart`
- [x] T022 [P] [US3] Write unit tests for `FixtureSchedulingUseCase` and `MatchesCatalogController` covering fixture generation, match scheduling, and all collision types (pitch, referee, team) in `test/unit/application/fixture_scheduling_use_case_test.dart` and `test/unit/application/matches_catalog_controller_test.dart`
- [x] T023 [US3] Write comprehensive widget tests verifying all 3 Gherkin scenarios (fixture generation with round chips, successful match scheduling to `"Programado"`, and schedule collision blocking alert) in `test/widget/matchday_fixture_widget_test.dart`

**Checkpoint**: All 3 user stories (`US1`, `US2`, `US3`) are fully functional, integrated, and verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute full static analysis, code formatting, and test suite verification to satisfy Constitution quality gates.

- [x] T024 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`, and `flutter test --coverage` across the entire workspace to ensure 0 static analysis issues and 100% passing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. Serves as MVP.
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (scheduling requires generated matches).
- **User Story 3 (Phase 5)**: Depends on User Story 2 completion (collision checking validates candidate match against existing scheduled matches).
- **Polish (Phase 6)**: Depends on all user stories being implemented and tested.

### Parallel Opportunities

- Within Phase 1: `T002` can run in parallel with `T001`.
- Within Phase 2: `T003`, `T004`, `T005`, `T006`, `T007`, `T008`, `T009` define independent domain entities/contracts and can be written in parallel. `T011` tests domain entities in parallel with infrastructure setup.
- Within Phase 3: `T013` (generator tests) can be written in parallel with `T012`.
- Within Phase 5: `T022` (use case unit tests) can run in parallel with `T021`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1 (Localization & Seeds)
2. Complete Phase 2 (Entities, Repository & Tests)
3. Complete Phase 3 (Round-Robin Generator, Use Case, `MatchdayTabView` & `MatchCard`)
4. **VALIDATE**: Generate fixture and navigate rounds in `MatchdayTabView`.

### Incremental Delivery
1. Phase 1 + Phase 2 → Foundational layer ready.
2. User Story 1 → Deterministic fixture generation and round navigation functional.
3. User Story 2 → Scheduling with pitch and referee designation functional.
4. User Story 3 → Conflict prevention (pitch, referee, teams) and end-to-end widget tests complete.
5. Phase 6 → Full quality gate verification (`flutter analyze`, `dart format`, `flutter test`).
