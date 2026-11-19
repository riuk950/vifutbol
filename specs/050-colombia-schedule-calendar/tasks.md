# Tasks: Unrestricted Future Match Calendar and Colombia Time Zone (12-Hour AM/PM) Standardization

**Input**: Design documents from `/specs/050-colombia-schedule-calendar/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/colombia_time_contract.md`, `quickstart.md`

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and HU 22.2 DoD.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`, `US4`)
- Exact repository file paths are included in every task description.

---

## Phase 1: Setup & Foundational Domain Service (Blocking Prerequisites)

**Purpose**: Create the pure-Dart centralized `ColombiaTimeUtils` domain service and align UTC parsing/date normalization so all user stories build on a single canonical UTC ↔ Colombia (UTC-5) source of truth.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 Create centralized `ColombiaTimeUtils` with `colombiaOffset = Duration(hours: -5)`, `minCalendarDate = DateTime(2000, 1, 1)`, `maxCalendarDate = DateTime(2100, 12, 31)`, `toColombiaWallClock`, `fromColombiaWallClock`, `nowColombia`, `todayColombia`, `colombiaDateOnly`, `presentMinuteUtc`, `formatTime12h` (zero-padded `hh:mm AM/PM`), `formatTimeOfDay12h`, `formatDate`, `formatDateTime12h`, and `formatDateTimeRange12h` in `lib/domain/services/colombia_time_utils.dart`
- [X] T002 Create comprehensive unit tests for `ColombiaTimeUtils` covering midnight UTC boundary (`09:00 PM` Colombia = `02:00 AM` UTC next day), `12:00 AM` / `12:00 PM` edge cases, zero-padded `08:00 AM` / `04:00 PM` formatting, and UTC round-trip stability across June and December (no DST) in `test/unit/domain/colombia_time_utils_test.dart`
- [X] T003 [P] Update `PostgrestTournamentMatchesRemoteDataSource._fromRow` to parse `scheduled_at` and `scheduled_end_at` as canonical UTC instants (`DateTime.parse(raw).toUtc()`) in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`
- [X] T004 [P] Update `MatchesCatalogState.normalizeDate` in `lib/domain/entities/matches_catalog_state.dart` and `MatchesCatalogController._resolveInitialDate` / `scheduleMatch` in `lib/application/controllers/matches_catalog_controller.dart` to use `ColombiaTimeUtils.colombiaDateOnly` and `ColombiaTimeUtils.todayColombia`

**Checkpoint**: Foundation ready — `ColombiaTimeUtils` is tested and all temporal normalization is anchored to Colombia (UTC-5).

---

## Phase 2: User Story 1 & User Story 2 - Unrestricted Future Scheduling & 12h AM/PM Picker in Colombia Time (Priority: P1) 🎯 MVP

**Goal**: Allow organizers to select any future date from today in Colombia time through `2100-12-31` without tournament date clamping (`FR-006`), force the time picker into 12-hour AM/PM mode (`FR-005`), interpret date + time in Colombia (UTC-5) to persist as UTC (`FR-002`), and validate past-time rejection in Colombia time (`FR-007`).

**Independent Test**: Open `ScheduleMatchDialog` on a device in 24-hour mode, verify `DatePicker` allows selecting dates in 2030/2100 with `firstDate = todayColombia` and no tournament end-date cap, verify `TimePicker` uses `alwaysUse24HourFormat: false` and displays `03:30 PM`, and verify submitted `scheduledStartTime` is the exact UTC instant (`+5h`).

### Tests for User Stories 1 & 2

- [X] T005 [P] [US2] Update unit tests in `test/unit/application/fixture_scheduling_use_case_test.dart` to verify Colombia (UTC-5) past-time validation (`presentMinuteUtc`) and UTC instant persistence
- [X] T006 [P] [US1] Update widget tests in `test/presentation/matches/schedule_match_dialog_test.dart` to verify unrestricted future `lastDate` (`2100-12-31`), `firstDate = todayColombia` (ignoring tournament start/end caps), forced 12-hour AM/PM time picker (`alwaysUse24HourFormat: false`), zero-padded AM/PM time button display, and Colombia→UTC conversion on submit

### Implementation for User Stories 1 & 2

- [X] T007 [US2] Update `FixtureSchedulingUseCase.scheduleMatch` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to validate `scheduledStartTime.toUtc().isBefore(ColombiaTimeUtils.presentMinuteUtc())`
- [X] T008 [US1] Update `ScheduleMatchDialog` in `lib/presentation/matches/widgets/schedule_match_dialog.dart` to: (a) set `firstDate = ColombiaTimeUtils.todayColombia()` and `lastDate = ColombiaTimeUtils.maxCalendarDate` (`2100-12-31`) without clamping to tournament start/end dates; (b) wrap `showTimePicker` builder in `MediaQuery(..., alwaysUse24HourFormat: false)`; (c) display `_selectedTime` via `ColombiaTimeUtils.formatTimeOfDay12h`; and (d) convert selected Colombia wall-clock date/time to UTC via `ColombiaTimeUtils.fromColombiaWallClock(...)` on submit

**Checkpoint**: User Stories 1 & 2 complete — organizers can schedule matches on any future date up to 2100 in 12h AM/PM Colombia time stored cleanly as UTC.

---

## Phase 3: User Story 3 - Consistent Colombia Time (AM/PM) Display & Day Grouping Across All Views (Priority: P1)

**Goal**: Group matches in `DailyMatchesFeedController` by Colombia calendar day (`FR-003`) and render every match time across `MatchCenterCard`, `MatchCard`, `CompetitionFixtureTabView`, `TeamMatchesTabView`, and `TeamInfoTabView` in zero-padded 12h uppercase AM/PM (`04:00 PM`, `09:00 PM`) without overflow (`FR-004`, `FR-009`).

**Independent Test**: Store a match at `2026-11-20T02:00:00Z` (`09:00 PM` Colombia on `2026-11-19`), verify `groupMatchesByActiveTournaments` places it on `2026-11-19` (not `2026-11-20`), and verify all match cards display `09:00 PM` with zero 24-hour strings and zero overflow on compact screens.

### Tests for User Story 3

- [X] T009 [P] [US3] Add midnight UTC boundary unit tests (`09:00 PM` Colombia = `02:00 AM` UTC next day staying on the Colombia date) in `test/application/controllers/daily_matches_feed_controller_test.dart`
- [X] T010 [P] [US3] Update widget tests in `test/presentation/matches/widgets/match_center_card_test.dart`, `test/presentation/tournaments/competition_fixture_widget_test.dart`, and `test/presentation/teams/team_matches_schedule_test.dart` to assert zero-padded 12h AM/PM Colombia time rendering (`04:00 PM` / `09:00 PM`)

### Implementation for User Story 3

- [X] T011 [US3] Update `DailyMatchesDateState` (`today`, `withTab`, `withCustomDate`) and `groupMatchesByActiveTournaments` in `lib/application/controllers/daily_matches_feed_controller.dart` to use `ColombiaTimeUtils.todayColombia()` and `ColombiaTimeUtils.colombiaDateOnly(match.scheduledStartTime!)`
- [X] T012 [P] [US3] Update `MatchCenterCard` in `lib/presentation/matches/widgets/match_center_card.dart` to render `ColombiaTimeUtils.formatTime12h(match.scheduledStartTime!)` with clean compact/text-scale fit (no clipping of `09:00 PM`)
- [X] T013 [P] [US3] Update `MatchCard._formatMatchDateTime` in `lib/presentation/matches/widgets/match_card.dart` to use `ColombiaTimeUtils.formatDateTimeRange12h`
- [X] T014 [P] [US3] Update `CompetitionFixtureTabView` in `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart` to format match card footers and modal dates via `ColombiaTimeUtils.formatDateTime12h`
- [X] T015 [P] [US3] Update `TeamMatchesTabView` in `lib/presentation/teams/widgets/team_matches_tab_view.dart` and `TeamInfoTabView` in `lib/presentation/teams/widgets/team_info_tab_view.dart` to format match dates and times via `ColombiaTimeUtils.formatDateTime12h` and `ColombiaTimeUtils.formatDate`

**Checkpoint**: User Story 3 complete — all match cards and daily feeds group by Colombia date and display uniform `hh:mm AM/PM`.

---

## Phase 4: User Story 4 - Unrestricted Future & Historical Calendar Navigation in Matches Screen (Priority: P2)

**Goal**: Remove the short `±2 year` cap from the top-bar calendar picker in `AppShellScreen` so any user can navigate freely from `2000-01-01` through `2100-12-31` and view matches for any future Colombia date (`FR-008`).

**Independent Test**: Open the Matchday calendar picker in `AppShellScreen`, confirm `firstDate = 2000-01-01` and `lastDate = 2100-12-31`, select a future date (e.g. `2030-06-15`), and confirm `DailyMatchesFeedController` updates to that date and loads matching games.

### Implementation for User Story 4

- [X] T016 [US4] Update `_onPickCalendarDate` in `lib/presentation/shell/app_shell_screen.dart` to use `firstDate: ColombiaTimeUtils.minCalendarDate` (`2000-01-01`) and `lastDate: ColombiaTimeUtils.maxCalendarDate` (`2100-12-31`)

**Checkpoint**: All 4 user stories are complete and independently verified.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, full regression test pass across all affected suites, and audit to confirm zero remaining `HH:mm` match time formatters.

- [X] T017 Verify zero remaining 24-hour `HH:mm` match time formatters across `lib/presentation/matches/`, `lib/presentation/tournaments/`, and `lib/presentation/teams/`
- [X] T018 Run `flutter analyze` across the entire repository and ensure zero warnings and zero errors
- [X] T019 Run all affected unit and widget test suites (`colombia_time_utils_test.dart`, `fixture_scheduling_use_case_test.dart`, `matches_catalog_controller_test.dart`, `daily_matches_feed_controller_test.dart`, `schedule_match_dialog_test.dart`, `match_center_card_test.dart`, `matchday_tab_view_test.dart`, `competition_fixture_widget_test.dart`, `team_matches_schedule_test.dart`, `team_match_summary_test.dart`, `hybrid_tournament_matches_repository_test.dart`) and confirm 100% pass rate

---

## Dependencies & Execution Order

- **Phase 1 (Foundational)**: `T001` → `T002`, `T003` [P], `T004` [P]. **BLOCKS** all user stories.
- **Phase 2 (US1 & US2 — P1)**: Depends on Phase 1 (`T005`–`T008`).
- **Phase 3 (US3 — P1)**: Depends on Phase 1 (`T009`–`T015`); UI tasks `T012`, `T013`, `T014`, `T015` can run in parallel.
- **Phase 4 (US4 — P2)**: Depends on Phase 1 (`T016`).
- **Phase 5 (Polish)**: Depends on Phases 1–4 (`T017`–`T019`).
