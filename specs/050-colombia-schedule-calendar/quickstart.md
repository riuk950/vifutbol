# Quickstart Validation Guide: HU 22.2 Unrestricted Future Calendar & Colombia Time (AM/PM)

**Feature**: `050-colombia-schedule-calendar`
**References**: [spec.md](spec.md), [data-model.md](data-model.md), [contracts/colombia_time_contract.md](contracts/colombia_time_contract.md)

## 1. Automated Verification Commands

```bash
# 1. Static analysis (0 errors, 0 warnings)
flutter analyze

# 2. Unit tests for ColombiaTimeUtils (midnight UTC boundaries, 12:00 AM/PM, UTC round-trip)
flutter test test/unit/domain/colombia_time_utils_test.dart

# 3. Application & controller tests (past-time validation & Colombia day grouping)
flutter test test/unit/application/fixture_scheduling_use_case_test.dart
flutter test test/application/controllers/daily_matches_feed_controller_test.dart

# 4. Widget tests (ScheduleMatchDialog future date & AM/PM picker, MatchCenterCard, MatchdayTabView, CompetitionFixture, TeamMatches)
flutter test test/presentation/matches/schedule_match_dialog_test.dart
flutter test test/presentation/matches/widgets/match_center_card_test.dart
flutter test test/presentation/shell/tabs/matchday_tab_view_test.dart
flutter test test/presentation/tournaments/competition_fixture_widget_test.dart
flutter test test/presentation/teams/team_matches_schedule_test.dart
```

## 2. Manual & End-to-End Validation Scenarios

1. **Future Date Selection (US1)**: Open `ScheduleMatchDialog` on any match → tap Date → navigate to a date 2+ years in the future (e.g., 2028 or 2030) → confirm selection and save.
2. **12h AM/PM Picker & UTC-5 Storage (US2)**: Set device clock to 24-hour mode → open `ScheduleMatchDialog` → tap Time → verify picker displays 12h AM/PM → select `09:00 PM` → save → verify `vifutboldev.matches.scheduled_at` stores `02:00:00+00` of the following UTC day.
3. **Midnight Boundary Grouping (US3)**: Open **Partidos** (`MatchdayTabView`) → select the Colombia evening date (not the next day) → confirm the `09:00 PM` match appears on that evening's date formatted as `09:00 PM`.
4. **Future Date Navigation in Partidos (US4)**: Tap calendar icon in top AppBar on **Partidos** → select the future date (e.g., 2028) → confirm the scheduled match appears cleanly with `AM`/`PM` formatting.
