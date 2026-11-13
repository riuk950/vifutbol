---

description: "Actionable, dependency-ordered task list for HU 19.1: Players Directory - Tournament Filter Chips Removal and Dynamic Supabase Cloud Loading"
---

# Tasks: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Input**: Design documents from `/Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/data-model.md), [players-directory-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/contracts/players-directory-contracts.md), [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/quickstart.md)

**Tests**: Included per story in accordance with Project Constitution Principle III (`Pruebas Automatizadas`) and [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/plan.md).

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Parallelizable task (independent files, no unmet prerequisite dependencies).
- **[US1]..[US3]**: User story traceability matching `spec.md`. Setup, Foundational, and Polish tasks intentionally omit story labels.

---

## Phase 1: Setup (Contracts & Localization)

**Purpose**: Define the domain repository method contract and localized UI strings before modifying data layers or presentation components.

- [X] T001 Add localized Spanish strings for offline pull-to-refresh fallback notification (`playersDirectoryOfflineRefreshWarning`) to `lib/l10n/app_es.arb` and regenerate localization classes via `flutter gen-l10n`
- [X] T002 [P] Update domain contract in `lib/domain/repositories/teams_repository.dart` adding `Future<List<PlayerDirectoryItem>> loadAllPlayers()`

---

## Phase 2: Foundational (Infrastructure & Repository Implementations)

**Purpose**: Implement data access in `LocalTeamsRepository` and `HybridTeamsRepository` querying `vifutboldev.players` and persisting to Hive. **CRITICAL**: Complete before starting controller or presentation updates.

- [X] T003 [P] Implement `loadAllPlayers()` in `lib/infrastructure/repositories/local_teams_repository.dart` extracting players from cached teams in Hive and ordering alphabetically A-Z by `fullName`
- [X] T004 [P] Add `fetchAllPlayers()` to `TeamsRemoteDataSource` and implement in `PostgrestTeamsRemoteDataSource` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` querying `vifutboldev.players` with relational joins to `tournament_teams`, `teams`, and `tournaments`
- [X] T005 Implement `loadAllPlayers()` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` with remote-first Supabase fetch, Hive cache hydration, and seamless fallback to `LocalTeamsRepository.loadAllPlayers()` (depends on T002, T003, T004)
- [X] T006 [P] Write unit tests in `test/unit/infrastructure/sync/hybrid_teams_repository_players_test.dart` verifying remote cloud fetch, Hive cache update, and offline fallback for `loadAllPlayers()` (depends on T005)

**Checkpoint**: Infrastructure data layer ready - `TeamsRepository.loadAllPlayers()` tested and available for Riverpod controllers.

---

## Phase 3: User Story 1 - Remoción de Filter Chips Horizontales y Vista Centralizada (Priority: P1) 🎯 MVP

**Goal**: Remove horizontal tournament `ChoiceChip`s and the tournament scroll container from `PlayersDirectoryScreen`, allocating the upper area exclusively to the reactive search bar.

**Independent Test**: Render `PlayersDirectoryScreen` and verify that `Key('players_tournament_selector')` and `ChoiceChip`s no longer exist in the widget tree, while `Key('players_search_bar')` remains in the header.

- [X] T007 [US1] Remove horizontal tournament selector (`SingleChildScrollView` with `Key('players_tournament_selector')` and `ChoiceChip`s) from `lib/presentation/directories/players_directory_screen.dart`
- [X] T008 [P] [US1] Update widget tests in `test/presentation/players_directory_screen_test.dart` to assert that `players_tournament_selector` and tournament chips are no longer present

**Checkpoint**: User Story 1 (P1 MVP UI cleanup) is independently functional and verified in tests.

---

## Phase 4: User Story 2 - Carga Dinámica desde Supabase Cloud (`vifutboldev.players`) con Caché Hive y Pull-to-Refresh (Priority: P1) 🎯 MVP

**Goal**: Connect the players directory to `TeamsRepository.loadAllPlayers()`, populating players dynamically from Supabase Cloud DEV, caching in Hive, and providing a `RefreshIndicator` that degrades gracefully with an informative SnackBar when offline.

**Independent Test**: Load the players directory online and verify players from Supabase populate the list; enable airplane mode and verify the cached list renders without crash; execute Pull-to-Refresh offline and verify the list is preserved and a SnackBar warning appears.

- [X] T009 [US2] Update `PlayersDirectoryController` in `lib/application/controllers/players_directory_controller.dart` to inject `TeamsRepository`, implement `loadPlayers()`, and implement `refreshPlayers()` with boolean result indicating network status (depends on T005)
- [X] T010 [P] [US2] Update `playersDirectoryControllerProvider` in `lib/application/providers/directory_providers.dart` to bind `teamsRepositoryProvider` and trigger automatic initialization (depends on T009)
- [X] T011 [US2] Wrap list view in `RefreshIndicator` in `lib/presentation/directories/players_directory_screen.dart`, calling `directoryController.refreshPlayers()` and displaying `ScaffoldMessenger` SnackBar on offline failure (depends on T001, T007, T009)
- [X] T012 [P] [US2] Write unit tests in `test/unit/application/players_directory_controller_test.dart` verifying dynamic loading from repository, successful refresh, and offline error resilience (depends on T009)
- [X] T013 [P] [US2] Update widget tests in `test/presentation/players_directory_screen_test.dart` verifying `RefreshIndicator` triggering and offline SnackBar presentation (depends on T011)

**Checkpoint**: User Story 2 (P1 MVP cloud loading + offline cache + Pull-to-Refresh) is independently functional and verified.

---

## Phase 5: User Story 3 - Búsqueda Reactiva Multi-campo y Ordenamiento A-Z (Priority: P2)

**Goal**: Provide instant multi-field search (name, shirt number, team name, team short code, position) with 300 ms debounce, accent/case insensitivity, default A-Z alphabetical sorting, and clean state without tournament fields.

**Independent Test**: Enter queries with accents or uppercase letters in `Key('players_search_bar')` and verify instant filtering; verify players appear sorted alphabetically by `fullName` when no query is present.

- [X] T014 [US3] Refactor `PlayersDirectoryState` in `lib/application/controllers/players_directory_controller.dart` removing `availableTournaments`, `selectedTournamentId`, and `selectTournament()`, and enforce default A-Z sorting by `fullName`
- [X] T015 [P] [US3] Verify and connect `KickPulseSearchBar` with 300 ms debounce to `directoryController.updateSearchQuery` in `lib/presentation/directories/players_directory_screen.dart` (depends on T014)
- [X] T016 [P] [US3] Update unit tests in `test/unit/application/players_directory_controller_test.dart` testing multi-field search matching (full name, shirt number, team name, team code, position in Spanish/English) and default A-Z sorting (depends on T014)
- [X] T017 [P] [US3] Update role visibility widget tests in `test/presentation/directories/players_directory_role_visibility_test.dart` ensuring `Key('register_player_from_directory_button')` is preserved for authorized roles (depends on T014, T015)

**Checkpoint**: All user stories (US1, US2, US3) are fully functional and covered by automated tests.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate code quality, zero static analysis issues, formatting, and end-to-end execution.

- [X] T018 Run `flutter analyze` and resolve all warnings and lint errors across `lib/` and `test/`
- [X] T019 [P] Run `dart format lib/ test/` to enforce consistent code formatting
- [X] T020 Run full test suite via `flutter test test/presentation/players_directory_screen_test.dart test/unit/application/players_directory_controller_test.dart test/unit/infrastructure/sync/hybrid_teams_repository_players_test.dart` verifying 100% pass rate
- [X] T021 Execute validation scenarios following [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/quickstart.md) on Android emulator

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Can start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (T002). Blocks Phase 4 & Phase 5.
- **Phase 3 (User Story 1)**: Can run immediately in parallel with Phase 2 on presentation file (`players_directory_screen.dart`).
- **Phase 4 (User Story 2)**: Depends on Phase 2 (T005) and Phase 3 (T007).
- **Phase 5 (User Story 3)**: Depends on Phase 4 (T009).
- **Phase 6 (Polish)**: Depends on completion of Phases 1 through 5.

### Parallel Opportunities

- T001 and T002 in Phase 1 can run in parallel.
- T003, T004, and T006 in Phase 2 can run in parallel.
- T007 (US1 UI cleanup) can run in parallel with foundational repository work.
- T010 and T012 can run in parallel once T009 is complete.
- T015, T016, and T017 can run in parallel once T014 is complete.

---

## Implementation Strategy

### MVP Scope (User Story 1 & User Story 2)
1. Complete Phase 1 (Setup: strings and domain contract).
2. Complete Phase 2 (Foundational: `loadAllPlayers()` in local and hybrid repositories).
3. Complete Phase 3 (User Story 1: remove chips from `PlayersDirectoryScreen`).
4. Complete Phase 4 (User Story 2: connect controller to cloud + Hive cache + Pull-to-Refresh).
5. **Validate MVP**: Verify cloud reading from Supabase DEV and offline caching with chips removed.

### Incremental Delivery (User Story 3 & Polish)
1. Complete Phase 5 (User Story 3: clean state, A-Z ordering, multi-field search).
2. Complete Phase 6 (Polish: `flutter analyze`, `dart format`, test suites).
3. Ready for review and commit.
