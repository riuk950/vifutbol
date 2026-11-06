---

description: "Task list for HU 12.1: Acceso a \"Panel\" en Navigation Drawer y Ocultación Temporal de \"Explorar\""
---

# Tasks: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Input**: Design documents from `/specs/016-drawer-panel-access/`

**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/ui-navigation-contracts.md](contracts/ui-navigation-contracts.md), [quickstart.md](quickstart.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`) to enable independent implementation and testing of each increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Localization & Routing Infrastructure)

**Purpose**: Centralize new Spanish UI strings and prepare application routing before implementing presentation components.

- [X] T001 Define Spanish localization keys (`drawerPanel`, `panelPlaceholderTitle`, `panelPlaceholderSubtitle`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes in `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`
- [X] T003 [P] Register route `/panel` and `/explore` redirection to `/matches` in `lib/presentation/navigation/app_router.dart`

---

## Phase 2: Foundational (Panel Screen Base Scaffold)

**Purpose**: Base screen destination for `/panel` required for user story navigation and verification.

**⚠️ CRITICAL**: Complete this phase before implementing User Story 2.

- [X] T004 Implement `PanelScreen` container with AppBar ("Panel"), back button (`BackButton`), and styled role placeholder card in `lib/presentation/panel/panel_screen.dart`
- [X] T005 [P] Implement widget tests for `PanelScreen` verifying AppBar title, back button popping, and active role badge in `test/presentation/panel_screen_test.dart`

**Checkpoint**: Foundation ready — `/panel` route and screen ready for Drawer integration.

---

## Phase 3: User Story 1 - Ocultación Temporal de "Explorar" en NavigationBar (Priority: P1) 🎯 MVP

**Goal**: Present exactly 3 navigation tabs ("Partidos", "Noticias", "Perfil") in `NavigationBar` on `AppShellScreen`, mapping visual indices (0: `matches`, 1: `news`, 2: `profile`) to `AppShellSection` while preserving domain compatibility and redirecting `/explore` to `/matches`.

**Independent Test**: Can be tested independently by launching `AppShellScreen`, verifying exactly 3 tabs rendered in the bottom navigation bar, switching between Partidos, Noticias, and Perfil tabs, and confirming that accessing `/explore` safely redirects to `/matches`.

### Implementation for User Story 1

- [X] T006 [US1] Update `AppShellScreen` in `lib/presentation/shell/app_shell_screen.dart` to render 3 destinations ("Partidos", "Noticias", "Perfil") in `NavigationBar` and map visual indices bidirectionally to `AppShellSection`
- [X] T007 [US1] Update widget tests in `test/presentation/app_shell_widget_test.dart` to verify 3 tabs structure across all roles, tab index switching, and safe handling of `AppShellSection.explore` fallback

**Checkpoint**: User Story 1 complete — Bottom navigation bar clean with exactly 3 tabs and explore redirection functional.

---

## Phase 4: User Story 2 - Acceso y Visibilidad Condicionada del Ítem "Panel" en el Navigation Drawer (Priority: P1)

**Goal**: Expose "Panel" (`Key('drawer_destination_panel')`) in position 0 of `AppNavigationDrawer` (above "Competiciones"), visible exclusively for `Organizador`, `Entrenador`, `Árbitro` and `Jugador`, hidden for `Aficionado`, closing the Drawer and navigating to `/panel` on tap.

**Independent Test**: Can be tested independently by launching `AppNavigationDrawer` across all 5 roles (`UserRole.organizer`, `UserRole.coach`, `UserRole.referee`, `UserRole.player`, `UserRole.fan`), verifying that "Panel" appears at the top of destinations for the 4 operational roles, is completely absent for `fan`, and tapping it closes the Drawer and opens `/panel`.

### Implementation for User Story 2

- [X] T008 [US2] Update `AppNavigationDrawer` in `lib/presentation/shell/widgets/app_navigation_drawer.dart` to insert "Panel" in position 0 with `Icons.dashboard_outlined`, conditioned on `activeRole != UserRole.fan`, closing the drawer before routing to `/panel`
- [X] T009 [US2] Update widget tests in `test/presentation/app_drawer_widget_test.dart` to verify "Panel" presence and position for operational roles, absence for `fan`, and navigation to `/panel`

**Checkpoint**: User Stories 1 and 2 complete — Full navigation restructuring and role-gated panel access operational.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Responsive validation, accessibility (`320x640` @ `130%` text scaling), and global quality gate execution.

- [X] T010 [P] Implement compact viewport (`320x640` logical pixels) and `130%` text scaling widget tests across `AppShellScreen`, `AppNavigationDrawer`, and `PanelScreen` verifying zero `RenderFlex` overflows in `test/presentation/directories_responsive_widget_test.dart`
- [X] T011 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full `flutter test` suite to validate all scenarios in `specs/016-drawer-panel-access/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T003`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T004`–`T005`)**: Depends on Phase 1 completion — blocks User Story 2.
- **Phase 3: User Story 1 (`T006`–`T007`)**: Depends on Phase 1 (`T003` routing). Can proceed in parallel with Phase 2.
- **Phase 4: User Story 2 (`T008`–`T009`)**: Depends on Phase 1 (`T001`–`T002`) and Phase 2 (`T004` `PanelScreen`).
- **Phase 5: Polish (`T010`–`T011`)**: Depends on completion of Phases 3 and 4.

### Parallel Opportunities

- `T001` / `T002` and `T003` can proceed in parallel `[P]`.
- `T004` and `T005` can proceed in parallel `[P]`.
- User Story 1 (`T006`–`T007`) can proceed in parallel with Foundational (`T004`–`T005`) `[P]`.
- Responsive test additions `T010` can proceed once screens are updated `[P]`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T003`)
2. Complete Phase 3: User Story 1 (`T006`–`T007`)
3. **Validate**: Verify 3-tabs `NavigationBar` and `/explore` redirection.

### Incremental Delivery

1. Setup + Foundational (`T001`–`T005`)
2. Deliver User Story 1 (`T006`–`T007`) $\to$ Validate MVP
3. Deliver User Story 2 (`T008`–`T009`) $\to$ Validate role-gated "Panel" in Drawer
4. Polish & Quality Gates (`T010`–`T011`) $\to$ Full suite green
