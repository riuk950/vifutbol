# Tasks: Pestaña de Calendario de Partidos del Equipo (Próximos e Historial) (HU 14.2)

**Input**: Design documents from `specs/022-team-matches-schedule/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-team-matches-contracts.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization keys, code generation, semantic badge variant (`KickPulseBadgeVariant.success`), deterministic `TeamMatchesSchedule` projection model, and Riverpod selector provider.

- [X] T001 Define Spanish localization keys (`teamMatchesUpcomingSectionTitle`, `teamMatchesCompletedSectionTitle`, `teamMatchesEmptyGlobalTitle`, `teamMatchesEmptyGlobalMessage`, `teamMatchesUpcomingEmpty`, `teamMatchesCompletedEmpty`, `teamMatchOutcomeWin`, `teamMatchOutcomeDraw`, `teamMatchOutcomeLoss`, `teamMatchDetailModalRefereeLabel`, `teamMatchDetailModalUnassignedReferee`, `teamMatchDetailModalUnassignedVenue`, `teamMatchDetailModalPendingSchedule`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`
- [X] T003 [P] Add semantic variant `KickPulseBadgeVariant.success` (styled with `KickPulseColors.accentPrimary` `#22C55E`) to `lib/presentation/design_system/widgets/kick_pulse_badge.dart`
- [X] T004 [P] Create `TeamMatchOutcome` enum (`win`, `draw`, `loss`), `TeamScheduledMatchItem` entity (`match`, `homeTeam`, `awayTeam`, `isHome`, `outcome`, `opponentTeam`, `isCompleted`), and `TeamMatchesSchedule` immutable model (`teamId`, `upcomingMatches`, `completedMatches`) with deterministic factory `TeamMatchesSchedule.fromCatalog` (filtering `m.homeTeamId == teamId || m.awayTeamId == teamId`, excluding `MatchStatus.cancelled`, sorting `upcomingMatches` from `{inProgress, scheduled, pendingSchedule}` by `inProgress` > `scheduled` ascending `scheduledStartTime` > `pendingSchedule` ascending `roundNumber`, sorting `completedMatches` from `{completed}` by `scheduledStartTime` descending then `roundNumber` descending, and computing `TeamMatchOutcome` from `teamId` perspective) in `lib/presentation/teams/models/team_matches_schedule.dart`
- [X] T005 Register reactive family provider `teamMatchesScheduleProvider` in `lib/application/providers/teams_providers.dart`
- [X] T006 [P] Implement unit tests for `TeamMatchesSchedule.fromCatalog` verifying exclusive team filtering, chronological ascending sort for `upcomingMatches`, descending sort for `completedMatches`, cancelled match exclusion, and accurate `TeamMatchOutcome` (`win`, `draw`, `loss`) calculation for both home and away matches in `test/presentation/teams/team_matches_schedule_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the `TeamMatchesTabView` container and wire it into the second tab ("Partidos") of `TeamDetailScreen`.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T007 Create `TeamMatchesTabView` base widget in `lib/presentation/teams/widgets/team_matches_tab_view.dart` consuming `teamMatchesScheduleProvider(teamId)` with continuous vertical scroll (`ListView` with `PageStorageKey('team_matches_tab_view')`) and section headers for "Próximos Partidos" (`Key('team_upcoming_matches_header')`) and "Resultados Anteriores" (`Key('team_completed_matches_header')`)
- [X] T008 Wire `TeamMatchesTabView(key: const PageStorageKey('team_matches_tab_view'), teamId: teamId)` into the second tab ("Partidos") of `TabBarView` in `lib/presentation/teams/team_detail_screen.dart`

**Checkpoint**: Foundation ready — `TeamMatchesTabView` is mounted in the "Partidos" tab of `TeamDetailScreen`.

---

## Phase 3: User Story 1 - Visualización de Próximos Partidos del Equipo en Orden Cronológico (Priority: P1) 🎯 MVP

**Goal**: Display in the "Partidos" tab the "Próximos Partidos" section with all upcoming matches (`inProgress`, `scheduled`, `pendingSchedule`) where the team participates as home or away, ordered chronologically from earliest to latest, reusing `MatchCenterCard` wrapped with round, date, venue, and Home/Away condition badge.

**Independent Test**: Open `TeamDetailScreen` (`/teams/:id`), tap the "Partidos" tab, and verify that "Próximos Partidos" renders only matches for that team in ascending chronological order, displaying the metadata header (round, date, venue, Local/Visitante badge) and `MatchCenterCard`.

### Implementation for User Story 1

- [X] T009 [US1] Implement the "Próximos Partidos" section and match item card (`Key('team_upcoming_match_item_${match.id}')`) with responsive metadata header (round name, date, pitch/venue, and Home/Away condition `KickPulseBadge`) wrapping `MatchCenterCard` in `lib/presentation/teams/widgets/team_matches_tab_view.dart`
- [X] T010 [P] [US1] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying that switching to the "Partidos" tab renders upcoming matches in chronological order with round, date, venue, and `MatchCenterCard`

**Checkpoint**: User Story 1 is functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Historial de Resultados Anteriores con Distintivo Semántico (Victoria, Empate, Derrota) (Priority: P2)

**Goal**: Display in the "Partidos" tab the "Resultados Anteriores" section with all completed matches of the team ordered from most recent to oldest, showing final scores and the semantic outcome badge (`Key('team_match_outcome_badge_${match.id}')`: green `success` for Victoria, yellow/amber `warning` for Empate, subtle red `live` for Derrota) calculated from the team's perspective.

**Independent Test**: Open the "Partidos" tab for a team with completed wins, draws, and losses (as home and away) and verify that "Resultados Anteriores" displays each match with its final score and corresponding semantic `KickPulseBadge` ("Victoria", "Empate", "Derrota").

### Implementation for User Story 2

- [X] T011 [US2] Implement the "Resultados Anteriores" section and completed match item card (`Key('team_completed_match_item_${match.id}')`) with metadata header, semantic outcome badge (`Key('team_match_outcome_badge_${match.id}')` mapping `TeamMatchOutcome.win` -> `KickPulseBadgeVariant.success`, `draw` -> `warning`, `loss` -> `live`), and `MatchCenterCard` in `lib/presentation/teams/widgets/team_matches_tab_view.dart`
- [X] T012 [P] [US2] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying "Resultados Anteriores" ordering and semantic outcome badges ("Victoria", "Empate", "Derrota") for home and away completed matches

**Checkpoint**: User Stories 1 and 2 work together in the continuous vertical scroll of "Partidos".

---

## Phase 5: User Story 3 - Acceso al Detalle / Informe del Partido y Estados Vacíos Informativos (Priority: P3)

**Goal**: Open the informative match detail/report modal (`ModalBottomSheet` with `Key('team_match_detail_modal')`) when tapping any match in the list (while preserving rival team navigation on crest/name taps), and display clear localized empty states when the team has no matches globally (`Key('team_matches_empty_state')`) or in either section (`Key('team_upcoming_matches_empty_state')`, `Key('team_completed_matches_empty_state')`).

**Independent Test**: Tap a match card in "Partidos" and verify `team_match_detail_modal` opens showing round, teams, score/status, semantic outcome badge, date/time, venue, and referee; also test teams with no matches or partial matches to verify empty states.

### Implementation for User Story 3

- [X] T013 [US3] Implement `_openMatchDetailModal` (`Key('team_match_detail_modal')`) on match tap and implement global (`Key('team_matches_empty_state')`) and section-level (`Key('team_upcoming_matches_empty_state')`, `Key('team_completed_matches_empty_state')`) empty states in `lib/presentation/teams/widgets/team_matches_tab_view.dart`
- [X] T014 [P] [US3] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying the match detail modal on match tap and global/partial empty states when a team has no scheduled or completed matches

**Checkpoint**: All user stories (US1–US3) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Responsive layout verification (`320x640` @ `130%` text scaling) on the "Partidos" tab and full quality gate validation.

- [X] T015 [P] Update compact viewport (`320x640` logical pixels) and `130%` text scaling test in `test/presentation/directories_responsive_widget_test.dart` to also switch to the "Partidos" tab and verify zero `RenderFlex` overflows
- [X] T016 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full test suite per `specs/022-team-matches-schedule/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T006`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T007`–`T008`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T009`–`T010`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T011`–`T012`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T013`–`T014`)**: Depends on Phase 3 and Phase 4 (`TeamMatchesTabView` items).
- **Phase 6: Polish (`T015`–`T016`)**: Depends on completion of all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Foundational phase.
- **User Story 2 (P2)**: Independent after Foundational phase; populates "Resultados Anteriores" alongside US1.
- **User Story 3 (P3)**: Adds modal interaction and empty states to the sections built in US1 and US2.

---

## Parallel Opportunities

- `T003` (`KickPulseBadgeVariant.success`), `T004` (`TeamMatchesSchedule` model), and `T006` (unit tests) can run in parallel with `T001`–`T002` (localization).
- Widget tests (`T010`, `T012`, `T014`, `T015`) are isolated by scenario and can be validated incrementally after each implementation step.

---

## Parallel Example: Phase 1 Setup

```bash
# Terminal 1: Localization
flutter gen-l10n

# Terminal 2: Unit tests for TeamMatchesSchedule
flutter test test/presentation/teams/team_matches_schedule_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T006`).
2. Complete Phase 2: Foundational (`T007`–`T008`).
3. Complete Phase 3: User Story 1 (`T009`–`T010`).
4. **STOP and VALIDATE**: Confirm upcoming matches render chronologically in the "Partidos" tab.

### Incremental Delivery

1. Setup + Foundational → `TeamMatchesTabView` wired into `TeamDetailScreen`.
2. Add User Story 1 → Upcoming matches list operational (MVP!).
3. Add User Story 2 → Completed matches history with Victoria/Empate/Derrota semantic badges operational.
4. Add User Story 3 → Match detail modal and global/section empty states complete.
5. Polish (`T015`–`T016`) → Responsive validation (`320x640` @ `130%`) and static analysis pass.
