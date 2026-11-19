import 'package:clock/clock.dart';

/// Centralized Colombia (`America/Bogota`, fixed UTC-5 without DST) time utilities.
///
/// Ensures all match scheduling, calendar-day grouping, past-time validation,
/// and 12-hour AM/PM formatting are deterministic and independent of the
/// device's local timezone or 24-hour clock preference.
abstract final class ColombiaTimeUtils {
  /// Official Colombia offset from UTC (`UTC-5`, permanent year-round).
  static const Duration colombiaOffset = Duration(hours: -5);

  /// Earliest selectable date for historical Matchday calendar navigation.
  static final DateTime minCalendarDate = DateTime(2000, 1, 1);

  /// Unrestricted future horizon for scheduling and Matchday calendar navigation.
  static final DateTime maxCalendarDate = DateTime(2100, 12, 31);

  /// Converts any [dateTime] (UTC or local) into a wall-clock [DateTime]
  /// whose `year`, `month`, `day`, `hour`, `minute`, and `second` reflect
  /// official Colombia time (UTC-5).
  static DateTime toColombiaWallClock(DateTime dateTime) {
    final shifted = dateTime.toUtc().add(colombiaOffset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  /// Converts a Colombia (UTC-5) wall-clock date/time into its exact UTC instant.
  static DateTime fromColombiaWallClock(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    return DateTime.utc(year, month, day, hour, minute, second).subtract(
      colombiaOffset,
    );
  }

  /// Returns the current wall-clock [DateTime] in Colombia (UTC-5).
  static DateTime nowColombia([DateTime? now]) {
    return toColombiaWallClock(now ?? clock.now());
  }

  /// Returns today's normalized calendar date `DateTime(year, month, day)` in Colombia (UTC-5).
  static DateTime todayColombia([DateTime? now]) {
    final c = nowColombia(now);
    return DateTime(c.year, c.month, c.day);
  }

  /// Extracts the normalized Colombia calendar day `DateTime(year, month, day)` from any instant.
  static DateTime colombiaDateOnly(DateTime dateTime) {
    final c = toColombiaWallClock(dateTime);
    return DateTime(c.year, c.month, c.day);
  }

  /// Returns the UTC instant truncated to the current Colombia minute for past-time validation.
  static DateTime presentMinuteUtc([DateTime? now]) {
    final c = nowColombia(now);
    return fromColombiaWallClock(c.year, c.month, c.day, c.hour, c.minute);
  }

  /// Formats any instant in Colombia time as zero-padded 12-hour uppercase AM/PM (`04:00 PM`).
  static String formatTime12h(DateTime dateTime) {
    final c = toColombiaWallClock(dateTime);
    return formatTimeOfDay12h(c.hour, c.minute);
  }

  /// Formats a 24-hour [hour] (0..23) and [minute] (0..59) as zero-padded `hh:mm AM/PM`.
  static String formatTimeOfDay12h(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  /// Formats any instant's Colombia calendar date as `dd/MM/yyyy` (or `dd/MM`).
  static String formatDate(DateTime dateTime, {bool includeYear = true}) {
    final c = toColombiaWallClock(dateTime);
    final dd = c.day.toString().padLeft(2, '0');
    final mm = c.month.toString().padLeft(2, '0');
    if (!includeYear) return '$dd/$mm';
    return '$dd/$mm/${c.year}';
  }

  /// Formats any instant in Colombia time as `dd/MM/yyyy • hh:mm AM/PM`.
  static String formatDateTime12h(
    DateTime dateTime, {
    String separator = ' • ',
    bool includeYear = true,
  }) {
    return '${formatDate(dateTime, includeYear: includeYear)}$separator${formatTime12h(dateTime)}';
  }

  /// Formats a match start and optional end window in Colombia time:
  /// `dd/MM/yyyy • hh:mm AM/PM - hh:mm AM/PM`.
  static String formatDateTimeRange12h(DateTime start, DateTime? end) {
    final base = formatDateTime12h(start);
    if (end == null) return base;
    return '$base - ${formatTime12h(end)}';
  }
}
