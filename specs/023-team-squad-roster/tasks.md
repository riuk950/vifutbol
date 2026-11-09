# Tasks: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Input**: Design documents from `specs/023-team-squad-roster/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-team-squad-contracts.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization keys, code generation, deterministic `TeamSquadRoster` projection model, and Riverpod selector provider.

- [X] T001 Define Spanish localization keys (`teamSquadGoalkeepersSectionTitle`, `teamSquadDefendersSectionTitle`, `teamSquadMidfieldersSectionTitle`, `teamSquadForwardsSectionTitle`, `teamSquadPositionGoalkeeper`, `teamSquadPositionDefender`, `teamSquadPositionMidfielder`, `teamSquadPositionForward`, `teamSquadPlayerStatusEligible`, `teamSquadPlayerStatusSuspended`, `teamSquadEmptyGlobalTitle`, `teamSquadEmptyGlobalMessage`, `teamSquadEmptyPositionMessage`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`
- [X] T003 [P] Create `TeamSquadPlayerItem` (`player`, `teamId`, `teamName`, `teamShortCode`, `tournamentId`, `performanceProfile`) and `TeamSquadRoster` immutable model (`teamId`, `team`, `goalkeepers`, `defenders`, `midfielders`, `forwards`, `allProfiles`, `totalPlayers`, `hasPlayers`, `playersForPosition`) with deterministic factory `TeamSquadRoster.fromCatalog` (sorting `team.players` by ascending `shirtNumber` with tie-break by `fullName` and `id`, partitioning into the 4 tactical lines `goalkeeper`, `defender`, `midfielder`, `forward`, and building `PlayerPerformanceProfile` synced with `isSuspended: !player.isEligible`) in `lib/presentation/teams/models/team_squad_roster.dart`
- [X] T004 Register reactive family provider `teamSquadRosterProvider` in `lib/application/providers/teams_providers.dart`
- [X] T005 [P] Implement unit tests for `TeamSquadRoster.fromCatalog` verifying empty squad handling, deterministic ascending `shirtNumber` sort, partitioning across the 4 tactical positions (`goalkeeper`, `defender`, `midfielder`, `forward`), and `PlayerPerformanceProfile` generation in `test/presentation/teams/team_squad_roster_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the `TeamSquadTabView` container and wire it into the third tab ("Plantilla") of `TeamDetailScreen`.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T006 Create `TeamSquadTabView` base widget in `lib/presentation/teams/widgets/team_squad_tab_view.dart` consuming `teamSquadRosterProvider(teamId)` with continuous vertical scroll (`ListView`)
- [X] T007 Wire `TeamSquadTabView(key: const PageStorageKey('team_squad_tab_view'), teamId: teamId)` into the third tab ("Plantilla") of `TabBarView` in `lib/presentation/teams/team_detail_screen.dart`

**Checkpoint**: Foundation ready — `TeamSquadTabView` is mounted in the "Plantilla" tab of `TeamDetailScreen`.

---

## Phase 3: User Story 1 - Despliegue de la Nómina Oficial Completa del Equipo (Priority: P1) 🎯 MVP

**Goal**: Display in the "Plantilla" tab the complete roster of registered players ordered by ascending `shirtNumber`, showing for each player a tabular shirt number badge, full name, Spanish tactical position badge (*Portero*, *Defensa*, *Centrocampista*, *Delantero*), and semantic eligibility badge (**Habilitado** in green / **Suspendido** in red).

**Independent Test**: Open `TeamDetailScreen` (`/teams/:id`), tap the "Plantilla" tab, and verify that all registered players in `team.players` are rendered in ascending `shirtNumber` order with tabular dorsal, full name, Spanish tactical position, and **Habilitado** / **Suspendido** semantic badges.

### Implementation for User Story 1

- [X] T008 [US1] Implement the player item card (`Key('team_squad_player_item_${player.id}')`) with `ConstrainedBox(constraints: BoxConstraints(minHeight: 48))`, semantic label, tabular-nums shirt badge (`Key('team_squad_player_shirt_${player.id}')`), full name, tactical position badge (`Key('team_squad_player_position_badge_${player.id}')`), and semantic eligibility badge (`Key('team_squad_player_eligibility_badge_${player.id}')` showing "Habilitado" with `KickPulseBadgeVariant.success` or "Suspendido" with `KickPulseBadgeVariant.live`) in `lib/presentation/teams/widgets/team_squad_tab_view.dart`
- [X] T009 [P] [US1] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying that switching to the "Plantilla" tab renders all registered players ordered by ascending `shirtNumber` with tabular dorsal, full name, Spanish tactical position, and "Habilitado" / "Suspendido" badges

**Checkpoint**: User Story 1 is functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Agrupación Vertical de la Plantilla en 4 Bloques por Posición Táctica (Priority: P2)

**Goal**: Structure the squad vertically into 4 fixed blocks by tactical position (**Porteros**, **Defensas**, **Centrocampistas**, **Delanteros**), each with its section header, player count badge, ascending `shirtNumber` order within the block, and contextual empty state when a tactical line has no registered players.

**Independent Test**: Open the "Plantilla" tab for a team with players across multiple lines (and a line with 0 players) and verify that the 4 section headers (`team_squad_header_goalkeeper`, `team_squad_header_defender`, `team_squad_header_midfielder`, `team_squad_header_forward`) appear in tactical order, players within each block are sorted by `shirtNumber` ascending, and any empty block displays `team_squad_empty_${position.name}`.

### Implementation for User Story 2

- [X] T010 [US2] Implement the 4 fixed tactical position blocks ("Porteros" `Key('team_squad_header_goalkeeper')`, "Defensas" `Key('team_squad_header_defender')`, "Centrocampistas" `Key('team_squad_header_midfielder')`, "Delanteros" `Key('team_squad_header_forward')`) with player count badges and section-level empty states (`Key('team_squad_empty_${position.name}')`) in `lib/presentation/teams/widgets/team_squad_tab_view.dart`
- [X] T011 [P] [US2] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying the 4 tactical blocks ("Porteros", "Defensas", "Centrocampistas", "Delanteros"), ascending `shirtNumber` order within each block, and contextual empty message when a tactical line has no registered players

**Checkpoint**: User Stories 1 and 2 work together in the continuous vertical scroll of "Plantilla".

---

## Phase 5: User Story 3 - Consulta de Perfil del Jugador y Estados Vacíos Informativos (Priority: P3)

**Goal**: Open the player performance profile modal (`PlayerPerformanceProfileCard` with squad player switcher across `roster.allProfiles`) when tapping any player card, and display the global empty state (`Key('team_squad_empty_state')`) when `team.players` is empty.

**Independent Test**: Tap a player card in "Plantilla" and verify `PlayerPerformanceProfileCard` (`Key('player_performance_profile_card')`) opens showing the player's details and squad switcher chips; also test a team with an empty `players` list and verify `Key('team_squad_empty_state')` is displayed.

### Implementation for User Story 3

- [X] T012 [US3] Implement `_openPlayerProfileSheet` on player card tap (rendering `PlayerPerformanceProfileCard` with interactive squad switcher across `roster.allProfiles`) and implement the global empty state (`Key('team_squad_empty_state')`) when `team.players` is empty in `lib/presentation/teams/widgets/team_squad_tab_view.dart`
- [X] T013 [P] [US3] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying that tapping a player card opens `PlayerPerformanceProfileCard` with squad switcher support and that a team with zero registered players renders `Key('team_squad_empty_state')`

**Checkpoint**: All user stories (US1–US3) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Responsive layout verification (`320x640` @ `130%` text scaling) on the "Plantilla" tab and full quality gate validation.

- [X] T014 [P] Update compact viewport (`320x640` logical pixels) and `130%` text scaling test in `test/presentation/directories_responsive_widget_test.dart` to also switch to the "Plantilla" tab with registered players and verify zero `RenderFlex` overflows
- [X] T015 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full test suite per `specs/023-team-squad-roster/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T005`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T006`–`T007`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T008`–`T009`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T010`–`T011`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T012`–`T013`)**: Depends on Phase 3 and Phase 4 (`TeamSquadTabView` items).
- **Phase 6: Polish (`T014`–`T015`)**: Depends on completion of all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Foundational phase.
- **User Story 2 (P2)**: Organizes the player cards from US1 into the 4 fixed tactical blocks with section headers and empty states.
- **User Story 3 (P3)**: Adds modal profile interaction and global empty state to `TeamSquadTabView`.

---

## Parallel Opportunities

- `T003` (`TeamSquadRoster` model) and `T005` (unit tests) can run in parallel with `T001`–`T002` (localization).
- Widget tests (`T009`, `T011`, `T013`, `T014`) are isolated by scenario and can be validated incrementally after each implementation step.

---

## Parallel Example: Phase 1 Setup

```bash
# Terminal 1: Localization
flutter gen-l10n

# Terminal 2: Unit tests for TeamSquadRoster
flutter test test/presentation/teams/team_squad_roster_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T005`).
2. Complete Phase 2: Foundational (`T006`–`T007`).
3. Complete Phase 3: User Story 1 (`T008`–`T009`).
4. **STOP and VALIDATE**: Confirm all registered players render ordered by `shirtNumber` with dorsal, name, position, and eligibility badges.

### Incremental Delivery

1. Setup + Foundational → `TeamSquadTabView` wired into `TeamDetailScreen`.
2. Add User Story 1 → Player cards with dorsal, position, and eligibility badges operational (MVP!).
3. Add User Story 2 → 4 tactical blocks ("Porteros", "Defensas", "Centrocampistas", "Delanteros") and section empty states operational.
4. Add User Story 3 → Player performance profile modal (`PlayerPerformanceProfileCard`) and global empty state complete.
5. Polish (`T014`–`T015`) → Responsive validation (`320x640` @ `130%`) and static analysis pass.
