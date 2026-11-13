---

description: "Actionable, dependency-ordered task list for HU 19.2: Teams Directory - Tournament Filter Chips Removal and Dynamic Supabase Cloud Loading"
---

# Tasks: Directorio de Equipos: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.2)

**Input**: Design documents from `/Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/data-model.md), [teams-directory-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/contracts/teams-directory-contracts.md), [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/quickstart.md)

**Tests**: Included per story in accordance with Project Constitution Principle III (`Pruebas Automatizadas`) and [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/plan.md).

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Parallelizable task (independent files, no unmet prerequisite dependencies).
- **[US1]..[US3]**: User story traceability matching `spec.md`. Setup, Foundational, and Polish tasks intentionally omit story labels.

---

## Phase 1: Setup (Localization & Domain Contracts)

**Purpose**: Define the localized UI strings and pure domain entity/repository contract before modifying infrastructure or presentation layers.

- [X] T001 Add localized Spanish strings (`teamsDirectoryOfflineRefreshWarning`, `teamsDirectoryNoTournamentAssigned`, `teamsDirectoryMultipleTournaments`) to `lib/l10n/app_es.arb` and regenerate localization classes via `flutter gen-l10n`
- [X] T002 [P] Create pure domain entity `TeamDirectoryItem` (`id`, `name`, `shortCode`, `crestShape`, `primaryColorHex`, `secondaryColorHex`, `categoryLabel`, `tournamentCount`, `playerCount`, `eligibilityStatus`, `coachId`, `updatedAt`) in `lib/domain/entities/team_directory_item.dart`
- [X] T003 Add `Future<List<TeamDirectoryItem>> loadAllTeams()` contract method to `TeamsRepository` in `lib/domain/repositories/teams_repository.dart` (depends on T002)

---

## Phase 2: Foundational (Infrastructure & Repository Implementations)

**Purpose**: Implement data access in `LocalTeamsRepository` and `HybridTeamsRepository` querying `vifutboldev.teams` and persisting directory items in Hive. **CRITICAL**: Complete before starting controller or presentation updates.

- [X] T004 [P] Implement `loadAllTeams()` and `cacheDirectoryTeams(List<TeamDirectoryItem> teams)` in `lib/infrastructure/repositories/local_teams_repository.dart` persisting consolidated `TeamDirectoryItem` entries in Hive and sorting alphabetically A-Z by `name` (depends on T003)
- [X] T005 [P] Add `fetchAllTeams()` to `TeamsRemoteDataSource` and implement in `PostgrestTeamsRemoteDataSource` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` querying `vifutboldev.teams` with relational joins to `tournament_teams`, `tournaments`, and `players` for unique club consolidation (depends on T002)
- [X] T006 Implement `loadAllTeams()` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` with remote-first Supabase fetch, Hive cache hydration via `cacheDirectoryTeams()`, and seamless fallback to `LocalTeamsRepository.loadAllTeams()` (depends on T004, T005)
- [X] T007 [P] Update existing `TeamsRepository` test doubles/mocks across `test/` (`directories_responsive_widget_test.dart`, `manage_teams_eligibility_use_case_test.dart`, `teams_controller_test.dart`, `players_directory_screen_test.dart`) implementing `loadAllTeams()` (depends on T003)
- [X] T008 [P] Write unit tests in `test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart` verifying unique club fetch from `vifutboldev.teams` (0, 1, and multiple tournaments), Hive cache update, and offline fallback for `loadAllTeams()` (depends on T006)

**Checkpoint**: Infrastructure data layer ready — `TeamsRepository.loadAllTeams()` tested and available for Riverpod controllers.

---

## Phase 3: User Story 1 - Remoción de Filter Chips Horizontales y Vista Centralizada (Priority: P1) 🎯 MVP

**Goal**: Remove horizontal tournament `ChoiceChip`s and the tournament scroll container from `TeamsDirectoryScreen`, allocating the upper area exclusively to the reactive search bar.

**Independent Test**: Render `TeamsDirectoryScreen` and verify that `Key('teams_tournament_selector')` and `ChoiceChip`s no longer exist in the widget tree, while `Key('teams_search_bar')` remains in the header.

- [X] T009 [US1] Remove horizontal tournament selector (`SingleChildScrollView` with `Key('teams_tournament_selector')` and `ChoiceChip`s) from `lib/presentation/directories/teams_directory_screen.dart`
- [X] T010 [P] [US1] Update widget tests in `test/presentation/teams_directory_screen_test.dart` asserting that `teams_tournament_selector` and tournament `ChoiceChip`s are completely removed

**Checkpoint**: User Story 1 (P1 MVP UI cleanup) is independently functional and verified in tests.

---

## Phase 4: User Story 2 - Carga Dinámica de Equipos desde la Nube con Caché Local y Pull-to-Refresh (Priority: P1) 🎯 MVP

**Goal**: Connect the Teams Directory to `TeamsRepository.loadAllTeams()`, populating unique clubs dynamically from `vifutboldev.teams`, caching in Hive, providing a `RefreshIndicator` with graceful offline SnackBar degradation, and ensuring safe navigation to `TeamDetailScreen` for clubs without tournaments.

**Independent Test**: Load the teams directory online and verify clubs from `vifutboldev.teams` (including un-enrolled clubs) populate the list with name, crest, category/status, and player count; verify offline cache rendering and Pull-to-Refresh offline SnackBar; tap an un-enrolled club and verify `TeamDetailScreen` opens cleanly.

- [X] T011 [US2] Update `TeamsDirectoryController` in `lib/application/controllers/teams_directory_controller.dart` to inject `TeamsRepository`, use `TeamDirectoryItem`, implement `loadTeams()`, and implement `Future<bool> refreshTeams()` (depends on T006)
- [X] T012 [P] [US2] Update `teamsDirectoryControllerProvider` in `lib/application/providers/directory_providers.dart` to bind `teamsRepositoryProvider` and trigger automatic `loadTeams()` initialization (depends on T011)
- [X] T013 [US2] Wrap list view and empty state in `RefreshIndicator` in `lib/presentation/directories/teams_directory_screen.dart`, rendering club name, crest, category label (`teamsDirectoryNoTournamentAssigned` / `teamsDirectoryMultipleTournaments`), and player count, and displaying `SnackBar` with `teamsDirectoryOfflineRefreshWarning` when `refreshTeams()` returns `false` (depends on T001, T009, T011)
- [X] T014 [P] [US2] Ensure `TeamDetailScreen` in `lib/presentation/teams/team_detail_screen.dart` accepts optional fallback club metadata from `TeamDirectoryItem` (or resolves from `teamsDirectoryControllerProvider`) so clubs without tournament enrollments open with basic summary and empty roster/matches states instead of not-found error (depends on T002, T013)
- [X] T015 [P] [US2] Write unit tests in `test/unit/application/teams_directory_controller_test.dart` verifying dynamic loading from repository, successful refresh, and offline error resilience (depends on T011)
- [X] T016 [P] [US2] Update widget tests in `test/presentation/teams_directory_screen_test.dart` verifying `RefreshIndicator` triggering, offline `SnackBar` presentation, and safe tap navigation for un-enrolled clubs (depends on T013, T014)

**Checkpoint**: User Story 2 (P1 MVP cloud loading + offline cache + Pull-to-Refresh + safe detail navigation) is independently functional and verified.

---

## Phase 5: User Story 3 - Búsqueda Instantánea de Clubes y Ordenamiento Alfabético (Priority: P2)

**Goal**: Provide instant multi-field search (club name, short code, category label) with 300 ms debounce, accent/case insensitivity, default A-Z alphabetical sorting, and clean state without obsolete tournament filter fields.

**Independent Test**: Enter queries with accents or uppercase letters in `Key('teams_search_bar')` and verify instant filtering; verify clubs appear sorted alphabetically by `name` when no query is present.

- [X] T017 [US3] Refactor `TeamsDirectoryState` in `lib/application/controllers/teams_directory_controller.dart` removing `availableTournaments`, `selectedTournamentId`, `clearTournamentFilter`, and `selectTournamentFilter()`, and enforce default A-Z sorting by `name` (depends on T011)
- [X] T018 [P] [US3] Verify `KickPulseSearchBar` with 300 ms debounce and `filteredTeams` multi-field matching (`name`, `shortCode`, `categoryLabel`) in `lib/presentation/directories/teams_directory_screen.dart` and `lib/application/controllers/teams_directory_controller.dart` (depends on T017)
- [X] T019 [P] [US3] Update unit tests in `test/unit/application/teams_directory_controller_test.dart` verifying multi-field accent/case-insensitive search and default A-Z sorting (depends on T017)
- [X] T020 [P] [US3] Verify responsive and role-visibility widget tests in `test/presentation/directories_responsive_widget_test.dart` and `test/presentation/teams_directory_screen_test.dart` preserving `Key('create_team_from_directory_button')` for authorized roles (depends on T013, T017)

**Checkpoint**: All user stories (US1, US2, US3) are fully functional and covered by automated tests.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate code quality, zero static analysis issues, formatting, and end-to-end execution.

- [X] T021 Run `flutter analyze` and resolve all warnings and lint errors across `lib/` and `test/`
- [X] T022 [P] Run `dart format lib/ test/` to enforce consistent code formatting
- [X] T023 Run full target test suite (`flutter test test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart test/unit/application/teams_directory_controller_test.dart test/presentation/teams_directory_screen_test.dart test/presentation/directories_responsive_widget_test.dart`) verifying 100% pass rate
- [X] T024 Execute validation scenarios following [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/quickstart.md) on Android emulator or test suite

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Can start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T002`, `T003`). Blocks Phase 4 & Phase 5.
- **Phase 3 (User Story 1)**: Can run immediately in parallel with Phase 2 on presentation file (`teams_directory_screen.dart`).
- **Phase 4 (User Story 2)**: Depends on Phase 2 (`T006`) and Phase 3 (`T009`).
- **Phase 5 (User Story 3)**: Depends on Phase 4 (`T011`).
- **Phase 6 (Polish)**: Depends on completion of Phases 1 through 5.

### Parallel Opportunities

- `T001` and `T002` in Phase 1 can run in parallel.
- `T004`, `T005`, and `T007` in Phase 2 can run in parallel once `T002`/`T003` are ready.
- `T009` (US1 UI cleanup) can run in parallel with foundational repository work.
- `T012`, `T014`, `T015` in Phase 4 can run in parallel once `T011` is complete.
- `T018`, `T019`, `T020` in Phase 5 can run in parallel once `T017` is complete.

---

## Implementation Strategy

### MVP Scope (User Story 1 & User Story 2)
1. Complete Phase 1 (Setup: localization strings and `TeamDirectoryItem` domain contract).
2. Complete Phase 2 (Foundational: `loadAllTeams()` in `LocalTeamsRepository` and `HybridTeamsRepository`).
3. Complete Phase 3 (User Story 1: remove chips from `TeamsDirectoryScreen`).
4. Complete Phase 4 (User Story 2: connect controller to cloud + Hive cache + Pull-to-Refresh + safe detail view).
5. **Validate MVP**: Verify cloud reading from `vifutboldev.teams` and offline caching with chips removed.

### Incremental Delivery (User Story 3 & Polish)
1. Complete Phase 5 (User Story 3: clean state, A-Z ordering, multi-field search).
2. Complete Phase 6 (Polish: `flutter analyze`, `dart format`, test suites).
3. Ready for review, commit, and Notion closure.
