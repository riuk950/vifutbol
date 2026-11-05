---

description: "Task list for HU 10.2: Incorporación de Navigation Drawer y Páginas de Directorio con Buscador (Competiciones, Equipos y Jugadores)"
---

# Tasks: Navigation Drawer y Páginas de Directorio con Buscador (Competiciones, Equipos y Jugadores)

**Input**: Design documents from `/specs/014-navigation-drawer-directories/`

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-navigation-contracts.md](contracts/ui-navigation-contracts.md), [quickstart.md](quickstart.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`, `US4`) to enable independent implementation and testing of each increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Localization & Shared UI Infrastructure)

**Purpose**: Centralize all new Spanish UI strings and localization classes in `l10n` before implementing UI and controllers.

- [X] T001 Define Spanish localization keys (`drawerTitle`, `drawerCompetitions`, `drawerTeams`, `drawerPlayers`, `drawerVenues`, `searchCompetitionsHint`, `searchTeamsHint`, `searchPlayersHint`, `filterAllTournaments`, `noCompetitionsFound`, `noTeamsFound`, `noPlayersFound`, `createCompetitionAction`, `registerTeamAction`, `registerPlayerAction`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes in `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Search normalization utilities and reusable search bar component required across all directory screens.

**⚠️ CRITICAL**: Complete this phase before implementing User Stories 2, 3, and 4.

- [X] T003 [P] Implement unit tests for accent-insensitive search normalization (`normalizeSearchText`) in `test/unit/application/search_utils_test.dart`
- [X] T004 [P] Implement search normalization utility function `normalizeSearchText(String input)` in `lib/application/utils/search_utils.dart`
- [X] T005 [P] Implement reusable real-time search bar widget `KickPulseSearchBar` with clear button (`X`), 44x44px minimum touch target, and Obsidian Pitch styling in `lib/presentation/design_system/widgets/kick_pulse_search_bar.dart`

**Checkpoint**: Foundation ready — User Story 1 and foundational utilities ready for directory implementations.

---

## Phase 3: User Story 1 - Apertura del Navigation Drawer Universal para Todos los Roles (Priority: P1) 🎯 MVP

**Goal**: Expose an accessible `NavigationDrawer` in `AppShellScreen` for all 5 roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`) with 4 destinations: **Competiciones**, **Equipos**, **Jugadores** y **Sedes**, closing automatically before routing.

**Independent Test**: Can be tested independently by launching `AppShellScreen` across each of the 5 roles, tapping the AppBar hamburger menu, verifying that the drawer opens with the user profile header and 4 enabled destinations, and tapping a destination closes the drawer.

### Implementation for User Story 1

- [X] T006 [P] [US1] Create `AppNavigationDrawer` widget with user profile header (`KickPulseBadge` for role) and 4 navigation destinations (`drawer_destination_competitions`, `drawer_destination_teams`, `drawer_destination_players`, `drawer_destination_venues`) in `lib/presentation/shell/widgets/app_navigation_drawer.dart`
- [X] T007 [US1] Register named directory routes (`/competitions`, `/teams`, `/players`, and updated `/venues` with AppBar back button) in `lib/presentation/navigation/app_router.dart`
- [X] T008 [US1] Integrate `drawer: const AppNavigationDrawer()` into `AppShellScreen` in `lib/presentation/shell/app_shell_screen.dart`
- [X] T009 [US1] Implement widget tests for `AppNavigationDrawer` verifying universal access across all 5 roles and automatic drawer close on destination tap in `test/presentation/app_drawer_widget_test.dart`

**Checkpoint**: User Story 1 complete — Universal Drawer navigation functional across the entire application.

---

## Phase 4: User Story 2 - Directorio de Competiciones con Buscador Superior en Tiempo Real (Priority: P1)

**Goal**: Dedicated `CompetitionsDirectoryScreen` listing all competitions, real-time accent-insensitive search by name or category, clear button, informative empty state, tap-to-select active tournament returning to shell, and contextual create button for `Organizador`.

**Independent Test**: Navigate to `/competitions`, enter search query, verify instant filtering, tap clear button, tap a tournament to select it as globally active, and verify create tournament button visibility based on role capabilities.

### Tests for User Story 2

- [X] T010 [P] [US2] Implement unit tests for `CompetitionsDirectoryController` (initial load, query filtering, clear query, select tournament) in `test/unit/application/competitions_directory_controller_test.dart`

### Implementation for User Story 2

- [X] T011 [US2] Implement `CompetitionsDirectoryState` and `CompetitionsDirectoryController` in `lib/application/controllers/competitions_directory_controller.dart` and register `competitionsDirectoryControllerProvider` in `lib/application/providers/directory_providers.dart`
- [X] T012 [US2] Implement `CompetitionsDirectoryScreen` with `KickPulseSearchBar`, competition cards (`competition_item_${id}`), empty state (`KickPulseStateView`), tap-to-select navigation, and contextual create action in `lib/presentation/directories/competitions_directory_screen.dart`
- [X] T013 [US2] Implement widget tests for `CompetitionsDirectoryScreen` verifying real-time search, tap-to-select, and create button permission gating in `test/presentation/competitions_directory_screen_test.dart`

**Checkpoint**: User Stories 1 and 2 complete and independently functional.

---

## Phase 5: User Story 3 - Directorio de Equipos con Buscador y Consulta de Plantilla (Priority: P2)

**Goal**: Dedicated `TeamsDirectoryScreen` listing registered teams across all competitions, horizontal tournament filter chips ("Todos" + torneos), real-time search by name/shortCode/category, opening team roster detail sheet on tap, and contextual create button for authorized roles.

**Independent Test**: Navigate to `/teams`, filter by tournament chip and text search, tap an individual team to view its roster details sheet, and verify create team button visibility.

### Tests for User Story 3

- [X] T014 [P] [US3] Implement unit tests for `TeamsDirectoryController` (loading teams, tournament chip filter, text search, empty state) in `test/unit/application/teams_directory_controller_test.dart`

### Implementation for User Story 3

- [X] T015 [US3] Implement `TeamsDirectoryState` and `TeamsDirectoryController` in `lib/application/controllers/teams_directory_controller.dart` and register `teamsDirectoryControllerProvider` in `lib/application/providers/directory_providers.dart`
- [X] T016 [US3] Implement `TeamsDirectoryScreen` with `KickPulseSearchBar`, horizontal tournament selector chips (`teams_tournament_chip_*`), team cards (`team_item_${id}`) with `KickPulseTeamCrest`, tap-to-open roster detail, and contextual create action in `lib/presentation/directories/teams_directory_screen.dart`
- [X] T017 [US3] Implement widget tests for `TeamsDirectoryScreen` verifying tournament filtering, text search, roster detail sheet opening, and role capability checks in `test/presentation/teams_directory_screen_test.dart`

**Checkpoint**: User Stories 1, 2, and 3 complete and independently testable.

---

## Phase 6: User Story 4 - Directorio de Jugadores con Buscador y Ficha de Rendimiento (Priority: P2)

**Goal**: Dedicated `PlayersDirectoryScreen` listing registered players, horizontal tournament filter chips, real-time search by name/dorsal/position/team, opening player performance profile sheet on tap, and contextual register player button for authorized roles.

**Independent Test**: Navigate to `/players`, search by player name, jersey number, position, or team, tap a player to open the performance profile modal, and verify register player button permissions.

### Tests for User Story 4

- [X] T018 [P] [US4] Implement unit tests for `PlayersDirectoryController` (loading players across teams, tournament filtering, multi-field search, empty state) in `test/unit/application/players_directory_controller_test.dart`

### Implementation for User Story 4

- [X] T019 [US4] Implement `PlayersDirectoryState` and `PlayersDirectoryController` in `lib/application/controllers/players_directory_controller.dart` and register `playersDirectoryControllerProvider` in `lib/application/providers/directory_providers.dart`
- [X] T020 [US4] Implement `PlayersDirectoryScreen` with `KickPulseSearchBar`, horizontal tournament filter chips, player tiles (`player_item_${id}`) with jersey number and eligibility badge, tap-to-open performance profile sheet, and contextual register player action in `lib/presentation/directories/players_directory_screen.dart`
- [X] T021 [US4] Implement widget tests for `PlayersDirectoryScreen` verifying multi-field search, player performance profile sheet opening, and role capability checks in `test/presentation/players_directory_screen_test.dart`

**Checkpoint**: All 4 User Stories complete and independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Responsive validation, keyboard behavior, accessibility (`320x640` @ `130%` text scaling), and global quality gate execution.

- [X] T022 [P] Implement compact viewport (`320x640` logical pixels) and `130%` text scaling widget tests across `AppNavigationDrawer` and all 3 directory screens verifying zero `RenderFlex` overflows in `test/presentation/directories_responsive_widget_test.dart`
- [X] T023 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full `flutter test` suite to validate all scenarios in `specs/014-navigation-drawer-directories/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T002`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T003`–`T005`)**: Depends on Phase 1 completion — blocks User Stories 2, 3, and 4.
- **Phase 3: User Story 1 (`T006`–`T009`)**: Depends on Phase 1 completion (can start in parallel with Phase 2).
- **Phase 4: User Story 2 (`T010`–`T013`)**: Depends on Phase 2 (`search_utils`, `KickPulseSearchBar`) and `T007` (routing).
- **Phase 5: User Story 3 (`T014`–`T017`)**: Depends on Phase 2 and `T007` (routing).
- **Phase 6: User Story 4 (`T018`–`T021`)**: Depends on Phase 2 and `T007` (routing).
- **Phase 7: Polish (`T022`–`T023`)**: Depends on completion of Phases 3, 4, 5, and 6.

### Parallel Opportunities

- `T003` (`search_utils_test.dart`), `T004` (`search_utils.dart`), and `T005` (`kick_pulse_search_bar.dart`) can run in parallel `[P]`.
- `T006` (`app_navigation_drawer.dart`) can run in parallel with foundational tasks `[P]`.
- User story controller tests (`T010`, `T014`, `T018`) touch distinct files and can run in parallel `[P]`.
- Responsive tests `T022` can run independently once the screens exist `[P]`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 3: User Story 1 (`T006`–`T009`)
3. **Validate**: Verify universal `NavigationDrawer` opening, user profile header, and 4 navigation options across all 5 user roles.

### Incremental Delivery

1. Add Foundational utilities (`T003`–`T005`): `normalizeSearchText` and `KickPulseSearchBar`.
2. Add User Story 2 (`T010`–`T013`): `CompetitionsDirectoryScreen` with real-time search, tap-to-select, and create tournament button.
3. Add User Story 3 (`T014`–`T017`): `TeamsDirectoryScreen` with tournament selector chips, search, and roster detail modal.
4. Add User Story 4 (`T018`–`T021`): `PlayersDirectoryScreen` with tournament selector chips, search, and player performance profile sheet.
5. Complete Phase 7 (`T022`–`T023`): `320x640` @ `130%` text scaling, keyboard dismissal, static analysis, format, and full test suite verification.
