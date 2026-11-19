# Interface Contract: `ColombiaTimeUtils` & Calendar/Picker Behavior

**Feature**: `050-colombia-schedule-calendar` (HU 22.2)
**Date**: 2026-11-19

## 1. Domain Utility Contract (`lib/domain/services/colombia_time_utils.dart`)

```dart
abstract final class ColombiaTimeUtils {
  static const Duration colombiaOffset = Duration(hours: -5);
  static final DateTime minCalendarDate = DateTime(2000, 1, 1);
  static final DateTime maxCalendarDate = DateTime(2100, 12, 31);

  /// Converts any [DateTime] (UTC or local) to a Colombia (UTC-5) wall-clock DateTime.
  static DateTime toColombiaWallClock(DateTime dateTime);

  /// Converts a Colombia (UTC-5) wall-clock date/time into its exact UTC instant.
  static DateTime fromColombiaWallClock(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]);

  /// Returns current Colombia wall-clock DateTime (uses `clock.now()` when [now] is null).
  static DateTime nowColombia([DateTime? now]);

  /// Returns normalized date-only `DateTime(year, month, day)` for today in Colombia (UTC-5).
  static DateTime todayColombia([DateTime? now]);

  /// Extracts normalized Colombia calendar day `DateTime(year, month, day)` from any instant.
  static DateTime colombiaDateOnly(DateTime dateTime);

  /// Returns the UTC instant truncated to the current Colombia minute for past-time validation.
  static DateTime presentMinuteUtc([DateTime? now]);

  /// Formats any instant in Colombia time as zero-padded 12h uppercase AM/PM (`04:00 PM`).
  static String formatTime12h(DateTime dateTime);

  /// Formats raw 24h [hour] (0..23) and [minute] (0..59) as zero-padded 12h AM/PM (`03:30 PM`).
  static String formatTimeOfDay12h(int hour, int minute);

  /// Formats any instant's Colombia calendar date as `dd/MM/yyyy` (or `dd/MM` when [includeYear] is false).
  static String formatDate(DateTime dateTime, {bool includeYear = true});

  /// Formats any instant in Colombia time as `dd/MM/yyyy • hh:mm AM/PM` (customizable [separator]).
  static String formatDateTime12h(
    DateTime dateTime, {
    String separator = ' • ',
    bool includeYear = true,
  });

  /// Formats a match start/end window in Colombia time: `dd/MM/yyyy • hh:mm AM/PM - hh:mm AM/PM`.
  static String formatDateTimeRange12h(DateTime start, DateTime? end);
}
```

## 2. Picker Contracts

### `ScheduleMatchDialog` (`lib/presentation/matches/widgets/schedule_match_dialog.dart`)
- Date picker: `firstDate = ColombiaTimeUtils.todayColombia()`, `lastDate = ColombiaTimeUtils.maxCalendarDate` (`2100-12-31`).
- Time picker: `builder` forces `MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child!)`.
- Submit: passes `ColombiaTimeUtils.fromColombiaWallClock(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute)` to `MatchesCatalogController.scheduleMatch`.

### `AppShellScreen` (`lib/presentation/shell/app_shell_screen.dart`)
- Date picker: `firstDate = ColombiaTimeUtils.minCalendarDate` (`2000-01-01`), `lastDate = ColombiaTimeUtils.maxCalendarDate` (`2100-12-31`).
