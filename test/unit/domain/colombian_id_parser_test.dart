import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/colombian_id_scan_result.dart';
import 'package:vifutbol/domain/entities/player_personal_enums.dart';
import 'package:vifutbol/domain/services/colombian_id_parser.dart';

void main() {
  group('ColombianIdParser.parsePdf417', () {
    test('parses standard null-separated Colombian PDF417 payload with leading zeros', () {
      // Standard token structure: docId, 1st surname, 2nd surname, 1st name, 2nd name, sex, DOB, blood
      final raw = 'PubDSK_1\x000010203040\x00PEREZ\x00GOMEZ\x00JUAN\x00CARLOS\x00M\x0019950824\x00O+\x00';
      final result = ColombianIdParser.parsePdf417(raw);

      expect(result.source, ColombianIdScanSource.pdf417);
      expect(result.documentId, '10203040');
      expect(result.firstSurname, 'Pérez');
      expect(result.secondSurname, 'Gómez');
      expect(result.firstName, 'Juan');
      expect(result.secondName, 'Carlos');
      expect(result.sex, PlayerSex.male);
      expect(result.birthDate, DateTime(1995, 8, 24));
      expect(result.bloodType, BloodType.oPositive);
    });

    test('parses payload with accents and special characters (Ñ, Á)', () {
      final raw = '\x000052345678\x00MUÑOZ\x00PEÑA\x00MARÍA\x00FERNANDA\x00F\x0020011205\x00AB-\x00';
      final result = ColombianIdParser.parsePdf417(raw);

      expect(result.documentId, '52345678');
      expect(result.firstSurname, 'Muñoz');
      expect(result.secondSurname, 'Peña');
      expect(result.firstName, 'María');
      expect(result.secondName, 'Fernanda');
      expect(result.sex, PlayerSex.female);
      expect(result.birthDate, DateTime(2001, 12, 5));
      expect(result.bloodType, BloodType.abNegative);
    });

    test('handles single surname and single given name in PDF417', () {
      final raw = '\x000080123456\x00RODRIGUEZ\x00\x00ANDRES\x00\x00M\x0019880210\x00A+\x00';
      final result = ColombianIdParser.parsePdf417(raw);

      expect(result.documentId, '80123456');
      expect(result.firstSurname, 'Rodríguez');
      expect(result.secondSurname, isNull);
      expect(result.firstName, 'Andrés');
      expect(result.secondName, isNull);
      expect(result.sex, PlayerSex.male);
      expect(result.birthDate, DateTime(1988, 2, 10));
      expect(result.bloodType, BloodType.aPositive);
    });

    test('returns empty result when raw payload is invalid or empty', () {
      expect(ColombianIdParser.parsePdf417(''), ColombianIdScanResult.empty);
      expect(ColombianIdParser.parsePdf417('INVALID_RANDOM_TEXT_123'), ColombianIdScanResult.empty);
    });
  });

  group('ColombianIdParser.parseMrzAndOcr', () {
    test('parses standard ICAO 9303 TD1 3-line MRZ from digital ID', () {
      final mrzText = '''
REPÚBLICA DE COLOMBIA
IDENTIFICACIÓN PERSONAL
I<COL10203040<<<<<<<<<<<<<<<0
9508244M3001015COL<<<<<<<<<<<6
PEREZ<GOMEZ<<JUAN<CARLOS<<<<<<
RH O+
''';
      final refDate = DateTime(2026, 1, 1);
      final result = ColombianIdParser.parseMrzAndOcr(mrzText, referenceDate: refDate);

      expect(result.source, ColombianIdScanSource.mrzOcr);
      expect(result.documentId, '10203040');
      expect(result.birthDate, DateTime(1995, 8, 24));
      expect(result.sex, PlayerSex.male);
      expect(result.firstSurname, 'Pérez');
      expect(result.secondSurname, 'Gómez');
      expect(result.firstName, 'Juan');
      expect(result.secondName, 'Carlos');
      expect(result.bloodType, BloodType.oPositive);
    });

    test('infers century correctly: 05 -> 2005 and 85 -> 1985 relative to 2026', () {
      final refDate = DateTime(2026, 1, 1);

      final mrz2005 = '''
I<COL1098765432<<<<<<<<<<<<<0
0503158F3501015COL<<<<<<<<<<<2
GARCIA<<ANA<SOFIA<<<<<<<<<<<<<
''';
      final res2005 = ColombianIdParser.parseMrzAndOcr(mrz2005, referenceDate: refDate);
      expect(res2005.birthDate, DateTime(2005, 3, 15));
      expect(res2005.sex, PlayerSex.female);

      final mrz1985 = '''
I<COL79123456<<<<<<<<<<<<<<<0
8511202M2801015COL<<<<<<<<<<<9
LOPEZ<<CARLOS<<<<<<<<<<<<<<<<<
''';
      final res1985 = ColombianIdParser.parseMrzAndOcr(mrz1985, referenceDate: refDate);
      expect(res1985.birthDate, DateTime(1985, 11, 20));
      expect(res1985.sex, PlayerSex.male);
    });

    test('normalizes OCR misrecognized chevrons (« to <) in MRZ lines', () {
      final mrzCorrupt = '''
I<COL10345678«««««««««««««««0
0201104M3201015COL«««««««««««1
TORRES«CASTRO««FELIPE«««««««««
''';
      final res = ColombianIdParser.parseMrzAndOcr(mrzCorrupt, referenceDate: DateTime(2026, 1, 1));
      expect(res.documentId, '10345678');
      expect(res.birthDate, DateTime(2002, 1, 10));
      expect(res.firstSurname, 'Torres');
      expect(res.secondSurname, 'Castro');
      expect(res.firstName, 'Felipe');
    });

    test('extracts blood type and NUIP from printed OCR text when MRZ is partial', () {
      final printedOcr = '''
CÉDULA DIGITAL
NUIP: 1.025.456.789
APELLIDOS: MORALES VARGAS
NOMBRES: DANIEL
FECHA DE NACIMIENTO: 1999-04-12
SEXO: M
G.S. RH: B+
''';
      final res = ColombianIdParser.parseMrzAndOcr(printedOcr);
      expect(res.documentId, '1025456789');
      expect(res.bloodType, BloodType.bPositive);
      expect(res.sex, PlayerSex.male);
    });
  });

  group('ColombianIdParser.mergeResults', () {
    test('prioritizes primary fields and fills missing from secondary', () {
      final primary = const ColombianIdScanResult(
        documentId: '10203040',
        firstName: 'Juan',
        firstSurname: 'Pérez',
        source: ColombianIdScanSource.pdf417,
      );

      final secondary = ColombianIdScanResult(
        documentId: '10203040',
        secondName: 'Carlos',
        secondSurname: 'Gómez',
        sex: PlayerSex.male,
        birthDate: DateTime(1995, 8, 24),
        bloodType: BloodType.oPositive,
        source: ColombianIdScanSource.mrzOcr,
      );

      final merged = ColombianIdParser.mergeResults(primary, secondary);

      expect(merged.source, ColombianIdScanSource.pdf417);
      expect(merged.documentId, '10203040');
      expect(merged.firstName, 'Juan');
      expect(merged.secondName, 'Carlos');
      expect(merged.firstSurname, 'Pérez');
      expect(merged.secondSurname, 'Gómez');
      expect(merged.sex, PlayerSex.male);
      expect(merged.birthDate, DateTime(1995, 8, 24));
      expect(merged.bloodType, BloodType.oPositive);
    });

    test('returns secondary if primary is empty', () {
      final secondary = const ColombianIdScanResult(
        documentId: '52345678',
        firstName: 'María',
        source: ColombianIdScanSource.mrzOcr,
      );
      final merged = ColombianIdParser.mergeResults(ColombianIdScanResult.empty, secondary);
      expect(merged, secondary);
    });
  });
}
