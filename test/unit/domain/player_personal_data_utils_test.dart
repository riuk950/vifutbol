import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/detailed_football_position.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/services/player_personal_data_utils.dart';

void main() {
  group('PlayerPersonalDataUtils.calculateAge', () {
    test('calculates exact age when birthday has already passed this year', () {
      final birth = DateTime(2000, 3, 15);
      final ref = DateTime(2026, 6, 1);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: ref), 26);
    });

    test('calculates exact age on the exact day of birthday', () {
      final birth = DateTime(2000, 3, 15);
      final ref = DateTime(2026, 3, 15);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: ref), 26);
    });

    test('calculates exact age when birthday has not yet arrived this year', () {
      final birth = DateTime(2000, 7, 20);
      final ref = DateTime(2026, 3, 15);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: ref), 25);
    });

    test('calculates exact age for leap year birthday (Feb 29)', () {
      final birth = DateTime(2004, 2, 29);
      final refBefore = DateTime(2026, 2, 28);
      final refAfter = DateTime(2026, 3, 1);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: refBefore), 21);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: refAfter), 22);
    });

    test('clamps negative age to 0 if future date is passed', () {
      final birth = DateTime(2030, 1, 1);
      final ref = DateTime(2026, 3, 15);
      expect(PlayerPersonalDataUtils.calculateAge(birth, referenceDate: ref), 0);
    });
  });

  group('PlayerPersonalDataUtils.composeFullName', () {
    test('composes all four name parts correctly', () {
      final full = PlayerPersonalDataUtils.composeFullName(
        firstName: 'Juan',
        secondName: 'Carlos',
        firstSurname: 'Pérez',
        secondSurname: 'Gómez',
      );
      expect(full, 'Juan Carlos Pérez Gómez');
    });

    test('omits optional secondName and secondSurname without double spaces', () {
      final full = PlayerPersonalDataUtils.composeFullName(
        firstName: 'Juan',
        secondName: null,
        firstSurname: 'Pérez',
        secondSurname: null,
      );
      expect(full, 'Juan Pérez');
    });

    test('trims leading, trailing and empty string inputs cleanly', () {
      final full = PlayerPersonalDataUtils.composeFullName(
        firstName: '  María  ',
        secondName: '   ',
        firstSurname: '  Rodríguez  ',
        secondSurname: '',
      );
      expect(full, 'María Rodríguez');
    });
  });

  group('PlayerPersonalDataUtils.derivePrimaryPosition', () {
    test('returns tactical line of first position', () {
      final line = PlayerPersonalDataUtils.derivePrimaryPosition([
        DetailedFootballPosition.rightBack,
        DetailedFootballPosition.rightWingBack,
      ]);
      expect(line, PlayerPosition.defender);
    });

    test('defaults to midfielder when list is empty', () {
      final line = PlayerPersonalDataUtils.derivePrimaryPosition(const []);
      expect(line, PlayerPosition.midfielder);
    });
  });
}
