import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/detailed_football_position.dart';
import 'package:vifutbol/domain/entities/player_personal_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';

void main() {
  group('DetailedFootballPosition', () {
    test('contains exactly 15 official tactical positions', () {
      expect(DetailedFootballPosition.values.length, 15);
    });

    test('each position maps to the expected code and PlayerPosition macro line', () {
      // Goalkeeper (1)
      expect(DetailedFootballPosition.goalkeeper.code, 'POR');
      expect(DetailedFootballPosition.goalkeeper.tacticalLine, PlayerPosition.goalkeeper);

      // Defenders (5)
      expect(DetailedFootballPosition.centerBack.code, 'DFC');
      expect(DetailedFootballPosition.centerBack.tacticalLine, PlayerPosition.defender);
      expect(DetailedFootballPosition.rightBack.code, 'LD');
      expect(DetailedFootballPosition.rightBack.tacticalLine, PlayerPosition.defender);
      expect(DetailedFootballPosition.leftBack.code, 'LI');
      expect(DetailedFootballPosition.leftBack.tacticalLine, PlayerPosition.defender);
      expect(DetailedFootballPosition.rightWingBack.code, 'CAD');
      expect(DetailedFootballPosition.rightWingBack.tacticalLine, PlayerPosition.defender);
      expect(DetailedFootballPosition.leftWingBack.code, 'CAI');
      expect(DetailedFootballPosition.leftWingBack.tacticalLine, PlayerPosition.defender);

      // Midfielders (5)
      expect(DetailedFootballPosition.defensiveMidfielder.code, 'MCD');
      expect(DetailedFootballPosition.defensiveMidfielder.tacticalLine, PlayerPosition.midfielder);
      expect(DetailedFootballPosition.centralMidfielder.code, 'MC');
      expect(DetailedFootballPosition.centralMidfielder.tacticalLine, PlayerPosition.midfielder);
      expect(DetailedFootballPosition.attackingMidfielder.code, 'MCO');
      expect(DetailedFootballPosition.attackingMidfielder.tacticalLine, PlayerPosition.midfielder);
      expect(DetailedFootballPosition.rightMidfielder.code, 'MD');
      expect(DetailedFootballPosition.rightMidfielder.tacticalLine, PlayerPosition.midfielder);
      expect(DetailedFootballPosition.leftMidfielder.code, 'MI');
      expect(DetailedFootballPosition.leftMidfielder.tacticalLine, PlayerPosition.midfielder);

      // Forwards (4)
      expect(DetailedFootballPosition.rightWinger.code, 'ED');
      expect(DetailedFootballPosition.rightWinger.tacticalLine, PlayerPosition.forward);
      expect(DetailedFootballPosition.leftWinger.code, 'EI');
      expect(DetailedFootballPosition.leftWinger.tacticalLine, PlayerPosition.forward);
      expect(DetailedFootballPosition.secondStriker.code, 'MP');
      expect(DetailedFootballPosition.secondStriker.tacticalLine, PlayerPosition.forward);
      expect(DetailedFootballPosition.centerForward.code, 'DC');
      expect(DetailedFootballPosition.centerForward.tacticalLine, PlayerPosition.forward);
    });

    test('fromCode tolerantly parses codes and enum names case-insensitively', () {
      expect(DetailedFootballPosition.fromCode('por'), DetailedFootballPosition.goalkeeper);
      expect(DetailedFootballPosition.fromCode('DFC'), DetailedFootballPosition.centerBack);
      expect(DetailedFootballPosition.fromCode('rightBack'), DetailedFootballPosition.rightBack);
      expect(DetailedFootballPosition.fromCode('dc'), DetailedFootballPosition.centerForward);
      expect(DetailedFootballPosition.fromCode(null), isNull);
      expect(DetailedFootballPosition.fromCode('XYZ'), isNull);
    });

    test('byLine groups positions accurately by macro line', () {
      final gks = DetailedFootballPosition.byLine(PlayerPosition.goalkeeper);
      expect(gks.length, 1);
      expect(gks.first, DetailedFootballPosition.goalkeeper);

      final defs = DetailedFootballPosition.byLine(PlayerPosition.defender);
      expect(defs.length, 5);

      final mids = DetailedFootballPosition.byLine(PlayerPosition.midfielder);
      expect(mids.length, 5);

      final fwds = DetailedFootballPosition.byLine(PlayerPosition.forward);
      expect(fwds.length, 4);
    });
  });

  group('PlayerSex and BloodType enums', () {
    test('PlayerSex parses aliases tolerantly', () {
      expect(PlayerSex.fromRaw('male'), PlayerSex.male);
      expect(PlayerSex.fromRaw('m'), PlayerSex.male);
      expect(PlayerSex.fromRaw('Masculino'), PlayerSex.male);
      expect(PlayerSex.fromRaw('female'), PlayerSex.female);
      expect(PlayerSex.fromRaw('f'), PlayerSex.female);
      expect(PlayerSex.fromRaw('Femenino'), PlayerSex.female);
      expect(PlayerSex.fromRaw('other'), PlayerSex.other);
      expect(PlayerSex.fromRaw('o'), PlayerSex.other);
      expect(PlayerSex.fromRaw('Otro'), PlayerSex.other);
      expect(PlayerSex.fromRaw('desconocido'), isNull);
    });

    test('BloodType contains 8 values and parses standard codes', () {
      expect(BloodType.allValues.length, 8);
      expect(BloodType.fromRaw('O+'), BloodType.oPositive);
      expect(BloodType.fromRaw('o-'), BloodType.oNegative);
      expect(BloodType.fromRaw('AB+'), BloodType.abPositive);
      expect(BloodType.fromRaw('abNegative'), BloodType.abNegative);
      expect(BloodType.fromRaw('X'), isNull);
    });
  });
}
