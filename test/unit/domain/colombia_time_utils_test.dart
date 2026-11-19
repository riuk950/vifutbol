import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';

void main() {
  group('ColombiaTimeUtils', () {
    test('converts midnight UTC boundary (09:00 PM Colombia = 02:00 AM UTC next day)', () {
      final utcInstant = DateTime.utc(2026, 11, 20, 2, 0);

      final colombiaDay = ColombiaTimeUtils.colombiaDateOnly(utcInstant);
      final formattedTime = ColombiaTimeUtils.formatTime12h(utcInstant);
      final formattedDateTime = ColombiaTimeUtils.formatDateTime12h(utcInstant);

      expect(colombiaDay, DateTime(2026, 11, 19));
      expect(formattedTime, '09:00 PM');
      expect(formattedDateTime, '19/11/2026 • 09:00 PM');
    });

    test('round-trips Colombia wall-clock to UTC and back without DST drift in June and December', () {
      // June (Northern Hemisphere summer)
      final juneUtc = ColombiaTimeUtils.fromColombiaWallClock(2027, 6, 15, 15, 30);
      expect(juneUtc, DateTime.utc(2027, 6, 15, 20, 30));
      expect(ColombiaTimeUtils.formatDateTime12h(juneUtc), '15/06/2027 • 03:30 PM');

      // December (Northern Hemisphere winter)
      final decUtc = ColombiaTimeUtils.fromColombiaWallClock(2027, 12, 20, 21, 45);
      expect(decUtc, DateTime.utc(2027, 12, 21, 2, 45));
      expect(ColombiaTimeUtils.colombiaDateOnly(decUtc), DateTime(2027, 12, 20));
      expect(ColombiaTimeUtils.formatTime12h(decUtc), '09:45 PM');
    });

    test('formats 12:00 AM, 12:00 PM, and zero-padded single-digit hours in uppercase AM/PM', () {
      expect(ColombiaTimeUtils.formatTimeOfDay12h(0, 0), '12:00 AM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(0, 5), '12:05 AM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(8, 0), '08:00 AM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(11, 59), '11:59 AM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(12, 0), '12:00 PM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(12, 30), '12:30 PM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(16, 0), '04:00 PM');
      expect(ColombiaTimeUtils.formatTimeOfDay12h(23, 59), '11:59 PM');
    });

    test('formats date-time range cleanly in Colombia AM/PM', () {
      final start = ColombiaTimeUtils.fromColombiaWallClock(2028, 3, 10, 15, 30);
      final end = start.add(const Duration(minutes: 105));
      expect(
        ColombiaTimeUtils.formatDateTimeRange12h(start, end),
        '10/03/2028 • 03:30 PM - 05:15 PM',
      );
    });

    test('todayColombia and presentMinuteUtc respect UTC-5 clock across UTC day boundary', () {
      // 2026-11-20 03:15:40 UTC == 2026-11-19 10:15:40 PM Colombia
      final fixedUtc = DateTime.utc(2026, 11, 20, 3, 15, 40);
      withClock(Clock.fixed(fixedUtc), () {
        expect(ColombiaTimeUtils.todayColombia(), DateTime(2026, 11, 19));
        expect(
          ColombiaTimeUtils.presentMinuteUtc(),
          DateTime.utc(2026, 11, 20, 3, 15),
        );
      });
    });
  });
}
