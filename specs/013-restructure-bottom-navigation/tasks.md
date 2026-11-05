---

description: "Task list for HU 10.1: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)"
---

# Tasks: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)

**Input**: Design documents from `/specs/013-restructure-bottom-navigation/`

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-navigation-contracts.md](contracts/ui-navigation-contracts.md), [quickstart.md](quickstart.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Centralize all new and updated Spanish UI labels in `l10n` before modifying domain/application/presentation layers.

- [X] T001 Update Spanish localization strings (`tabMatchday`/`tabMatches` -> `"Partidos"`, `tabStandings`/`tabExplore` -> `"Explorar"`, `tabNews` -> `"Noticias"`, `tabProfile` -> `"Perfil"`, `matchdayDateToday` -> `"Hoy"`, `matchdayDateTomorrow` -> `"Mañana"`, `matchdayUnscheduledSectionTitle` -> `"Por programar ({count})"`, `matchdayNoMatchesForDate` -> `"No hay partidos programados para esta fecha."`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes in `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities and state controllers required by all user stories.

**⚠️ CRITICAL**: Complete this phase before starting User Stories 1, 2, and 3.

- [X] T003 [P] Update `AppShellSection` and `AppShellState` in `lib/domain/entities/app_shell_section.dart` with the 4 ordered destinations (`matches`, `explore`, `news`, `profile`, plus static aliases `matchday` and `standings` for route compatibility) and default `activeSection = AppShellSection.matches`
- [X] T004 [P] Extend `MatchesCatalogState` in `lib/domain/entities/matches_catalog_state.dart` with `selectedDate` (`DateTime?` normalized to `DateTime(year, month, day)`), `availableCalendarDates` (`List<DateTime>` always including `Hoy` and `Mañana` plus all scheduled match dates), `scheduledMatchesForSelectedDate` (`List<ChampionshipMatch>` excluding `scheduledStartTime == null`), `unscheduledMatches` (`List<ChampionshipMatch>` where `scheduledStartTime == null` or `status == MatchStatus.pendingSchedule`), and `liveMatches` (`List<ChampionshipMatch>` where `status == MatchStatus.inProgress`)
- [X] T005 Update `MatchesCatalogController` in `lib/application/controllers/matches_catalog_controller.dart` to implement `selectDate(DateTime date)`, auto-select `selectedDate` on load (`Hoy` if matches exist today, nearest scheduled match date if matches exist on another day, or `Hoy` when empty), and update `selectedDate` to the assigned calendar day when `scheduleMatch` succeeds

**Checkpoint**: Domain and application state models ready — User Story implementation can now proceed.

---

## Phase 3: User Story 1 - Navegación Inferior Unificada con 4 Destinos para Todos los Roles (Priority: P1) 🎯 MVP

**Goal**: Present a unified 4-destination bottom `NavigationBar` (`Partidos`, `Explorar`, `Noticias`, `Perfil`) across all 5 user roles (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`), removing `"Sedes"` from the bottom bar while preserving `VenuesTabView` and state in memory via `IndexedStack`.

**Independent Test**: Authenticate or switch across all 5 roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`), verify that the bottom `NavigationBar` renders the exact 4 destinations in order (`"Partidos"`, `"Explorar"`, `"Noticias"`, `"Perfil"`), `"Sedes"` does not appear in the bottom bar, the active destination highlights with `KickPulseColors.accentPrimary`, and switching tabs preserves state in memory.

### Tests for User Story 1

- [X] T006 [P] [US1] Update unit tests in `test/application/app_shell_controller_test.dart` to verify `AppShellController` cycles through `matches`, `explore`, `news`, and `profile` in order and ignores out-of-range indices

### Implementation for User Story 1

- [X] T007 [P] [US1] Update `AppRouter` in `lib/presentation/navigation/app_router.dart` and `FanAlertsBellAction` in `lib/presentation/alerts/widgets/fan_alerts_bell_action.dart` to route `/matches` (`/matchday`), `/explore` (`/standings`), `/news`, and `/profile` to `AppShellScreen` sections while keeping `/venues` routed to a standalone `Scaffold(body: VenuesTabView())`
- [X] T008 [US1] Update `AppShellScreen` in `lib/presentation/shell/app_shell_screen.dart` to render the 4-destination `NavigationBar` (`Partidos` with `Icons.sports_soccer`, `Explorar` with `Icons.explore`, `Noticias` with `Icons.newspaper`, `Perfil` with `Icons.person`) and 4-child `IndexedStack` without `"Sedes"`
- [X] T009 [US1] Update widget tests in `test/presentation/app_shell_widget_test.dart` to verify the 4 bottom navigation destinations (`Partidos`, `Explorar`, `Noticias`, `Perfil`) and absence of `"Sedes"` in the bottom bar across all 5 user roles (`UserRole.values`)

**Checkpoint**: User Story 1 is functional and independently verified.

---

## Phase 4: User Story 2 - Pestaña Exclusiva de Partidos por Fecha sin Sub-pestaña de Noticias (Priority: P1)

**Goal**: Refactor the first tab (**"Partidos"**) to remove the internal news `SegmentedButton`, highlight `"En Juego"` matches at the top with `"EN VIVO"`, filter scheduled matches exclusively by the selected calendar date (`Hoy`, `Mañana`, specific dates), hide unscheduled matches from the calendar list, and provide an `Organizador`-only `"Por programar (N)"` section to schedule pending matches.

**Independent Test**: Open **"Partidos"**, verify the header reads `"Partidos"`, `"En Juego"` matches appear in `"EN VIVO"`, the calendar date selector (`matchday_date_chips_list`) filters matches by selected day, `matchday_segmented_button` does not exist, non-organizer roles do not see unscheduled matches, and `UserRole.organizer` sees `"Por programar (N)"` (`unscheduled_matches_section`) and can schedule a match into its calendar day.

### Tests for User Story 2

- [X] T010 [P] [US2] Add unit tests in `test/unit/application/matches_catalog_controller_test.dart` verifying `selectedDate`, `availableCalendarDates`, `scheduledMatchesForSelectedDate`, `unscheduledMatches`, and automatic `selectedDate` transition after `scheduleMatch`

### Implementation for User Story 2

- [X] T011 [US2] Refactor `MatchdayTabView` in `lib/presentation/shell/tabs/matchday_tab_view.dart` to remove `SegmentedButton` (`matchday_segmented_button`), synchronize the active tournament globally with `tournamentsControllerProvider` (including `Key('matches_tournament_selector')` when multiple tournaments exist), render `Key('live_matches_section')`, render the horizontal calendar date selector (`Key('matchday_date_chips_list')`), display `scheduledMatchesForSelectedDate`, and render the `Organizador`-only `"Por programar (N)"` section (`Key('unscheduled_matches_section')`)
- [X] T012 [US2] Update widget tests in `test/widget/matchday_fixture_widget_test.dart` and `test/widget/live_matches_feed_widget_test.dart` to verify removal of `matchday_segmented_button`, calendar date filtering, `Organizador`-only visibility of `unscheduled_matches_section` (`"Por programar (N)"`), hiding unscheduled matches for non-organizer roles, and moving a newly scheduled match to its calendar date

**Checkpoint**: User Stories 1 and 2 are functional and independently verified.

---

## Phase 5: User Story 3 - Pestaña de Primer Nivel para Noticias y Renombrado de Explorar (Priority: P2)

**Goal**: Provide direct 1-tap access to **"Noticias"** in the 3rd position of the bottom `NavigationBar` via `NewsTabView` (with category filters, `Organizador` publish/delete controls, historical read-only badge on finished tournaments, and global tournament synchronization across **"Partidos"**, **"Explorar"**, and **"Noticias"**) and ensure **"Explorar"** (2nd tab) and **"Perfil"** (4th tab) operate seamlessly.

**Independent Test**: Tap **"Explorar"** (2nd tab) and verify standings, brackets, honor roll, teams, and rankings; tap **"Noticias"** (3rd tab) and verify category filters (`Todos`, `General`, `Reprogramación`, `Disciplinario`), `Organizador` controls, historical read-only badge on finished tournaments, and global tournament sync when switching tournaments across **"Partidos"**, **"Explorar"**, and **"Noticias"**.

### Implementation for User Story 3

- [X] T013 [US3] Create `NewsTabView` in `lib/presentation/shell/tabs/news_tab_view.dart` with header `Key('news_tab_header')`, global tournament selector `Key('news_tournament_selector')` synchronized with `tournamentsControllerProvider`, and `TournamentNewsFeedView` integration, and mount `NewsTabView` at index `2` of `AppShellScreen` in `lib/presentation/shell/app_shell_screen.dart`
- [ ] T014 [US3] Add widget tests in `test/widget/tournament_news_feed_widget_test.dart` and `test/widget/standings_tab_view_test.dart` verifying `NewsTabView` top-level rendering, global tournament synchronization across `"Partidos"`, `"Explorar"`, and `"Noticias"`, and historical read-only mode in `"Noticias"`

**Checkpoint**: All User Stories (`US1`, `US2`, `US3`) are complete and independently verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Responsive/accessibility validation (`320x640` @ `130%` text scaling) and full quality gate verification.

- [X] T015 [P] Add compact viewport (`320x640` logical pixels) and `130%` text scaling widget test across all 4 tabs (`Partidos`, `Explorar`, `Noticias`, `Perfil`) in `test/presentation/app_shell_widget_test.dart` verifying zero `RenderFlex` overflows (`SC-004`)
- [X] T016 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full `flutter test` suite to validate all scenarios in `specs/013-restructure-bottom-navigation/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T002`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T003`–`T005`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T006`–`T009`)**: Depends on Phase 2 completion.
- **Phase 4: User Story 2 (`T010`–`T012`)**: Depends on Phase 2 completion (can run in parallel with US1/US3 at the controller/view level, integrates cleanly in `AppShellScreen`).
- **Phase 5: User Story 3 (`T013`–`T014`)**: Depends on Phase 2 and `T008` (`AppShellScreen` `IndexedStack` slot `2`).
- **Phase 6: Polish (`T015`–`T016`)**: Depends on Phases 3, 4, and 5 completion.

### Parallel Opportunities

- `T003` (`app_shell_section.dart`) and `T004` (`matches_catalog_state.dart`) touch distinct domain files and can run in parallel `[P]`.
- `T006` (`app_shell_controller_test.dart`), `T007` (`app_router.dart` / `fan_alerts_bell_action.dart`), and `T010` (`matches_catalog_controller_test.dart`) touch distinct files and can run in parallel `[P]`.

---

## Parallel Example: Foundational & User Story 1

```bash
# Foundational models in parallel:
Task T003: "Update AppShellSection and AppShellState in lib/domain/entities/app_shell_section.dart"
Task T004: "Extend MatchesCatalogState in lib/domain/entities/matches_catalog_state.dart"

# US1 controller tests & router updates in parallel:
Task T006: "Update unit tests in test/application/app_shell_controller_test.dart"
Task T007: "Update AppRouter in lib/presentation/navigation/app_router.dart and FanAlertsBellAction in lib/presentation/alerts/widgets/fan_alerts_bell_action.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T005`)
3. Complete Phase 3: User Story 1 (`T006`–`T009`)
4. **Validate**: Verify the 4-destination `NavigationBar` (`Partidos`, `Explorar`, `Noticias`, `Perfil`) across all 5 user roles.

### Incremental Delivery

1. Add User Story 2 (`T010`–`T012`): Calendar date filtering in `"Partidos"`, removal of `SegmentedButton`, and `Organizador`-only `"Por programar (N)"` section.
2. Add User Story 3 (`T013`–`T014`): Standalone `"Noticias"` tab (`NewsTabView`) and global championship synchronization across `"Partidos"`, `"Explorar"`, and `"Noticias"`.
3. Complete Phase 6 (`T015`–`T016`): `320x640` @ `130%` text scale verification and full test suite pass.
