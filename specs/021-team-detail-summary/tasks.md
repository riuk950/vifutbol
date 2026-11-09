# Tasks: Pantalla de Detalle de Equipo con Pestañas y Resumen (Último y Próximo Partido) (HU 14.1)

**Input**: Design documents from `specs/021-team-detail-summary/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-team-detail-contracts.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization keys, code generation, deterministic `TeamMatchSummary` projection model, and Riverpod selector provider.

- [X] T001 Define Spanish localization keys (`teamDetailTabInfo`, `teamDetailTabMatches`, `teamDetailTabSquad`, `teamDetailNotFoundTitle`, `teamDetailNotFoundMessage`, `teamDetailClubProfileTitle`, `teamDetailOfficialNameLabel`, `teamDetailShortCodeLabel`, `teamDetailCompetitionLabel`, `teamDetailClubColorsLabel`, `teamDetailPrimaryColorLabel`, `teamDetailSecondaryColorLabel`, `teamDetailLastMatchTitle`, `teamDetailLastMatchEmpty`, `teamDetailNextMatchTitle`, `teamDetailNextMatchEmpty`, `teamDetailOpponentLabel`, `teamDetailVenueLabel`, `teamDetailDateLabel`, `teamDetailHomeConditionBadge`, `teamDetailAwayConditionBadge`, `teamDetailMatchesTabPlaceholderTitle`, `teamDetailMatchesTabPlaceholderMessage`, `teamDetailSquadTabPlaceholderTitle`, `teamDetailSquadTabPlaceholderMessage`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`
- [X] T003 [P] Create immutable presentation model `TeamMatchSummary` (`team`, `tournament`, `lastPlayedMatch`, `lastMatchOpponent`, `isLastMatchHome`, `nextScheduledMatch`, `nextMatchOpponent`, `isNextMatchHome`) and deterministic factory `TeamMatchSummary.fromCatalog` (filtering `m.homeTeamId == teamId || m.awayTeamId == teamId`, resolving `lastPlayedMatch` from `MatchStatus.completed` ordered by `scheduledStartTime` descending then `roundNumber` descending, and resolving `nextScheduledMatch` from `{MatchStatus.inProgress, MatchStatus.scheduled, MatchStatus.pendingSchedule}` ordered by `inProgress` > `scheduled` ascending `scheduledStartTime` > `pendingSchedule` ascending `roundNumber`) in `lib/presentation/teams/models/team_match_summary.dart`
- [X] T004 Register reactive family provider `teamMatchSummaryProvider` in `lib/application/providers/teams_providers.dart`
- [X] T005 [P] Implement unit tests for `TeamMatchSummary.fromCatalog` verifying last played match selection, upcoming match priority (`inProgress` > `scheduled` > `pendingSchedule`), cancelled match exclusion, and empty states in `test/presentation/teams/team_match_summary_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core route registration and `TeamDetailScreen` scaffold with identity header and 3-tab structure.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T006 Implement `TeamDetailScreen` scaffold in `lib/presentation/teams/team_detail_screen.dart` with `DefaultTabController(length: 3, initialIndex: 0)`, `AppBar` featuring `KickPulseTeamCrest` (`Key('team_detail_app_bar_crest')`), official name (`Key('team_detail_title')`), 3-letter `shortCode` (`Key('team_detail_short_code')`), competition name (`Key('team_detail_competition_name')`), eligibility status badge (`Key('team_detail_eligibility_badge')`), back button (`Key('team_detail_back_button')`), not-found fallback (`Key('team_detail_not_found_state')`), and fixed 3-tab `TabBar` (`Key('team_detail_tab_bar')`) with "Información" (`Key('team_detail_tab_info')`) active by default
- [X] T007 [P] Register declarative route `/teams/:id` in `lib/presentation/navigation/app_router.dart` mapping to `TeamDetailScreen(teamId: id)`

**Checkpoint**: Foundation ready — `/teams/:id` route and `TeamDetailScreen` container are operational.

---

## Phase 3: User Story 1 - Navegación al Detalle de Equipo y Encabezado de Identidad del Club (Priority: P1) 🎯 MVP

**Goal**: Allow users to open `/teams/:id` (`TeamDetailScreen`) by selecting a team in `TeamsDirectoryScreen` or tapping the home/away team crest or name in `MatchCenterCard`, displaying the team identity header and 3 horizontal tabs with "Información" selected by default.

**Independent Test**: Tap a team in `TeamsDirectoryScreen` or tap a team crest/name inside `MatchCenterCard` and verify navigation to `TeamDetailScreen`, presence of `KickPulseTeamCrest`, team name, `shortCode`, competition name, eligibility badge, and the 3 tabs ("Información", "Partidos", "Plantilla") with "Información" selected by default.

### Implementation for User Story 1

- [X] T008 [US1] Update `_onTeamTapped` in `lib/presentation/directories/teams_directory_screen.dart` to select the team and navigate to `TeamDetailScreen(teamId: team.id)` with `RouteSettings(name: '/teams/${team.id}')`
- [X] T009 [P] [US1] Add independent team touch targets (`Key('match_card_home_team_${match.id}')` and `Key('match_card_away_team_${match.id}')`) in `lib/presentation/matches/widgets/match_center_card.dart` to navigate to `/teams/:id` (ignoring tap if already viewing that same team route) while preserving the central score/time hub `onTap` action
- [X] T010 [P] [US1] Update directory tap test in `test/presentation/teams_directory_screen_test.dart` and add team touch target navigation tests in `test/presentation/matches/widgets/match_center_card_test.dart`

**Checkpoint**: User Story 1 is functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Ficha del Club y Resumen de Último y Próximo Partido en la Pestaña "Información" (Priority: P2)

**Goal**: Display in the default "Información" tab the Club Profile Card (with official name, short code, primary/secondary club color accents, and tournament) alongside the highlighted "Último Partido" card (`FT` score, opponent, date, venue) and "Próximo Partido" card (opponent, date, time, venue/pitch).

**Independent Test**: Open `TeamDetailScreen` for a team with completed and scheduled matches and verify that `TeamInfoTabView` renders `team_club_profile_card`, `team_last_match_card` with final score and `FT`, and `team_next_match_card` with opponent, date, time, and pitch.

### Implementation for User Story 2

- [X] T011 [US2] Implement `TeamInfoTabView` in `lib/presentation/teams/widgets/team_info_tab_view.dart` rendering Club Profile Card (`Key('team_club_profile_card')` with `Key('team_primary_color_swatch')`, `Key('team_secondary_color_swatch')`, club color accents, short code, eligibility, and tournament name), Last Match Card (`Key('team_last_match_card')` / `Key('team_last_match_content')` with opponent, final score `FT`, date, and venue), and Next Match Card (`Key('team_next_match_card')` / `Key('team_next_match_content')` with opponent, date, scheduled time, and venue/pitch or pending schedule badge)
- [X] T012 [US2] Wire `TeamInfoTabView(teamId: teamId)` into the first tab ("Información") of `TabBarView` in `lib/presentation/teams/team_detail_screen.dart`
- [X] T013 [P] [US2] Implement widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying Club Profile Card, Last Match Card (`FT` score, opponent, date, venue), and Next Match Card rendering

**Checkpoint**: User Stories 1 and 2 work together and independently.

---

## Phase 5: User Story 3 - Estados Informativos para Equipos Sin Partidos Previos o Sin Próximos Encuentros (Priority: P3)

**Goal**: Display clear localized empty messages inside the "Último Partido" card (*"Sin partidos previos disputados"*) and "Próximo Partido" card (*"Sin próximos partidos agendados"*) when a team has no completed matches or no upcoming scheduled matches.

**Independent Test**: Open `TeamDetailScreen` for a team without completed matches and/or without scheduled future matches and verify that `team_last_match_empty_state` shows *"Sin partidos previos disputados"* and `team_next_match_empty_state` shows *"Sin próximos partidos agendados"*.

### Implementation for User Story 3

- [X] T014 [US3] Implement empty state views (`Key('team_last_match_empty_state')` with `l10n.teamDetailLastMatchEmpty` and `Key('team_next_match_empty_state')` with `l10n.teamDetailNextMatchEmpty`) inside `TeamInfoTabView` in `lib/presentation/teams/widgets/team_info_tab_view.dart`
- [X] T015 [P] [US3] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying empty states when a team has no previous played matches or no upcoming scheduled matches

**Checkpoint**: User Story 3 complete — All match summary states (populated, partial, and empty) are handled cleanly.

---

## Phase 6: User Story 4 - Alternancia de Pestañas Horizontales y Conservación de Contexto (Priority: P4)

**Goal**: Enable smooth switching between "Información", "Partidos", and "Plantilla" tabs while keeping the team identity header fixed and showing preparation state views (`KickPulseStateView`) in "Partidos" and "Plantilla" prior to HU 14.2 and HU 14.3.

**Independent Test**: In `TeamDetailScreen`, switch across "Información", "Partidos", and "Plantilla" tabs, verifying active tab indicator updates, `KickPulseStateView` placeholders (`team_matches_tab_placeholder`, `team_squad_tab_placeholder`), and scroll/context preservation on return to "Información".

### Implementation for User Story 4

- [X] T016 [US4] Implement preparation state views (`KickPulseStateView`) for "Partidos" (`Key('team_matches_tab_placeholder')`) and "Plantilla" (`Key('team_squad_tab_placeholder')`) tabs with `PageStorageKey` state preservation in `lib/presentation/teams/team_detail_screen.dart`
- [X] T017 [P] [US4] Add widget tests in `test/presentation/teams/team_detail_screen_test.dart` verifying tab switching across "Información", "Partidos", and "Plantilla", and not-found state (`Key('team_detail_not_found_state')`) for unknown team IDs

**Checkpoint**: All user stories (US1–US4) are independently functional and tested.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Responsive layout verification (`320x640` @ `130%` text scaling) and full quality gate validation.

- [X] T018 [P] Add compact viewport (`320x640` logical pixels) and `130%` text scaling test for `TeamDetailScreen` in `test/presentation/directories_responsive_widget_test.dart` verifying zero `RenderFlex` overflows
- [X] T019 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full test suite per `specs/021-team-detail-summary/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T005`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T006`–`T007`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T008`–`T010`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T011`–`T013`)**: Depends on Phase 2 completion.
- **Phase 5: User Story 3 (`T014`–`T015`)**: Depends on Phase 4 (`TeamInfoTabView`).
- **Phase 6: User Story 4 (`T016`–`T017`)**: Depends on Phase 2 (`TeamDetailScreen`).
- **Phase 7: Polish (`T018`–`T019`)**: Depends on completion of all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Foundational phase.
- **User Story 2 (P2)**: Independent after Foundational phase; integrates `TeamInfoTabView` into `TeamDetailScreen`.
- **User Story 3 (P3)**: Extends `TeamInfoTabView` from US2 with empty states for last/next match cards.
- **User Story 4 (P4)**: Completes secondary tabs ("Partidos", "Plantilla") and tab state preservation in `TeamDetailScreen`.

---

## Parallel Opportunities

- `T003` (`TeamMatchSummary` model) and `T005` (unit tests) can run in parallel with `T001`–`T002` (localization).
- `T007` (`AppRouter` route registration) can run in parallel with `T006` (`TeamDetailScreen` scaffold).
- `T008` (`TeamsDirectoryScreen` tap navigation) and `T009` (`MatchCenterCard` team tap zones) can run in parallel.
- `T013`, `T015`, `T017`, and `T018` (widget and responsive test suites) can run in parallel with their respective UI tasks once widget keys are defined.

---

## Parallel Example: User Story 1

```bash
# Run directory navigation update and MatchCenterCard touch zones in parallel:
Task T008: "Update _onTeamTapped in lib/presentation/directories/teams_directory_screen.dart"
Task T009: "Add independent team touch targets in lib/presentation/matches/widgets/match_center_card.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T005`)
2. Complete Phase 2: Foundational (`T006`–`T007`)
3. Complete Phase 3: User Story 1 (`T008`–`T010`)
4. **STOP and VALIDATE**: Verify navigation to `/teams/:id` from directory and match cards, header identity, and 3-tab structure.

### Incremental Delivery

1. Setup + Foundational → `TeamMatchSummary` selector and `/teams/:id` container ready.
2. User Story 1 (P1) → Navigation from directory & match cards + club identity header (MVP!).
3. User Story 2 (P2) → Club Profile Card + Last & Next Match summary cards in "Información" tab.
4. User Story 3 (P3) → Empty states (*"Sin partidos previos disputados"*, *"Sin próximos partidos agendados"*).
5. User Story 4 (P4) → Tab switching and preparation views for "Partidos" and "Plantilla".
6. Polish → Responsive verification (`320x640` @ `130%`), static analysis, and formatting.
