# Research & Technical Decisions: Unrestricted Future Calendar & Colombia Time (AM/PM)

**Feature**: `050-colombia-schedule-calendar` (HU 22.2)
**Date**: 2026-11-19

## 1. Codebase Audit Findings

An audit of date/time pickers and match time formatting across `lib/` identified the exact locations causing short date limits, device-timezone drift, and 24-hour formatting:

1. **Restrictive Date Pickers**:
   - `lib/presentation/matches/widgets/schedule_match_dialog.dart`: Currently clamps `firstDate` to `max(tournament.startDate, today)` and `lastDate` to `tournament.endDate`.
   - `lib/presentation/shell/app_shell_screen.dart` (`_onPickCalendarDate`): Currently limits the Matchday calendar picker to `firstDate: DateTime(now.year - 2)` and `lastDate: DateTime(now.year + 2)`.
   - **Decision**: Standardize `minCalendarDate = DateTime(2000, 1, 1)` (for historical navigation in Matchday) and `maxCalendarDate = DateTime(2100, 12, 31)` (for both `ScheduleMatchDialog` and `AppShellScreen`). In `ScheduleMatchDialog`, set `firstDate = ColombiaTimeUtils.todayColombia()` without clamping to tournament start/end dates (Clarification Q1 / `FR-006`).

2. **Device Time Zone Dependence & Midnight UTC Drift**:
   - `ScheduleMatchDialog._submit()` creates a device-local `DateTime(y, m, d, h, min)`, which shifts if the device is not in UTC-5.
   - `DailyMatchesFeedController` (`DailyMatchesDateState.today`, `withTab`, `withCustomDate`, `groupMatchesByActiveTournaments`) uses device-local `DateTime.now()` and `match.scheduledStartTime!.year/month/day`. If a device is in UTC or Europe, a match at `9:00 PM` Colombia (`02:00 AM` UTC next day) jumps to the wrong calendar day!
   - **Decision**: Introduce a pure-Dart, zero-external-dependency domain service `ColombiaTimeUtils` (`lib/domain/services/colombia_time_utils.dart`) anchored to fixed `UTC-5` (`Duration(hours: -5)`), because Colombia (`America/Bogota`) does not observe Daylight Saving Time.
   - **Rationale**: Pure arithmetic on UTC instants (`toUtc().add(Duration(hours: -5))` and `DateTime.utc(...).add(Duration(hours: 5))`) is deterministic, requires no heavy timezone database initialization on startup, works identically offline/online and in headless `flutter test` environments regardless of host OS timezone, and has zero DST bugs.
   - **Alternatives considered**: `timezone` package (`tz.getLocation('America/Bogota')`) — rejected as unnecessary overhead and initialization complexity since Colombia has had a permanent UTC-5 offset with no DST since 1993.

3. **24-Hour Time Pickers & 24-Hour Match Displays**:
   - `ScheduleMatchDialog._pickTime()` uses default `showTimePicker`, which inherits the device's 24-hour setting.
   - Five UI widgets currently format match times using 24-hour `HH:mm`:
     - `lib/presentation/matches/widgets/match_center_card.dart` (`DateFormat('HH:mm')`)
     - `lib/presentation/matches/widgets/match_card.dart` (`DateFormat('HH:mm')`)
     - `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart` (manual 24h padding + `DateFormat('dd/MM/yyyy • HH:mm')`)
     - `lib/presentation/teams/widgets/team_matches_tab_view.dart` (`DateFormat('dd/MM/yyyy - HH:mm')`, `DateFormat('dd/MM HH:mm')`)
     - `lib/presentation/teams/widgets/team_info_tab_view.dart` (`DateFormat('dd/MM/yyyy HH:mm')`)
   - **Decision**:
     - Wrap `showTimePicker` builder in `MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!)` (`FR-005`).
     - Format all match times via `ColombiaTimeUtils.formatTime12h(...)` / `formatDateTime12h(...)` / `formatDateTimeRange12h(...)` using deterministic zero-padded `hh:mm AM/PM` (`08:00 AM`, `04:00 PM`, `12:00 PM`, `12:00 AM`) per Clarification Q2 (`FR-004`).
     - Avoid relying on `DateFormat('hh:mm a', 'es')` because ICU Spanish locale renders `"a. m."` / `"p. m."` with non-breaking spaces and periods that cause overflow on compact cards; explicit uppercase `AM` / `PM` matches the spec (`08:00 AM`, `04:30 PM`) and keeps card layouts crisp.
   - **Rationale**: Eliminates locale-dependent formatting inconsistencies and prevents layout overflow in `MatchCenterCard`'s 94px center hub (`FR-009`).

4. **Database Compatibility (`vifutboldev.matches`)**:
   - `scheduled_at` and `scheduled_end_at` are already `timestamp with time zone` (`timestamptz`) in PostgreSQL, and `PostgrestTournamentMatchesRemoteDataSource._toRow` already serializes `.toUtc().toIso8601String()`.
   - **Decision**: No database migration required. Ensure `_fromRow` parses `scheduled_at` / `scheduled_end_at` as UTC instants (`DateTime.parse(raw).toUtc()`) so `ColombiaTimeUtils` always receives unambiguous UTC instants.
