import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/colombia_location_catalog.dart';

void main() {
  group('ColombiaLocationCatalog', () {
    test('contains exactly 33 territorial entities (32 departments + Bogotá, D.C.)', () {
      expect(ColombiaLocationCatalog.departments.length, 33);
      expect(ColombiaLocationCatalog.departments, contains('Bogotá, D.C.'));
      expect(ColombiaLocationCatalog.departments, contains('Antioquia'));
      expect(ColombiaLocationCatalog.departments, contains('Cundinamarca'));
      expect(ColombiaLocationCatalog.departments, contains('Valle del Cauca'));
      expect(ColombiaLocationCatalog.departments, contains('Amazonas'));
      expect(ColombiaLocationCatalog.departments, contains('Vichada'));
    });

    test('catalog contains over 1,100 total municipalities across Colombia', () {
      var total = 0;
      for (final dep in ColombiaLocationCatalog.departments) {
        total += ColombiaLocationCatalog.municipalitiesFor(dep).length;
      }
      expect(total, greaterThan(1100));
    });

    test('municipalitiesFor returns unmodifiable list for valid department and empty for unknown', () {
      final antioquiaMuns = ColombiaLocationCatalog.municipalitiesFor('Antioquia');
      expect(antioquiaMuns, contains('Medellín'));
      expect(antioquiaMuns, contains('Envigado'));
      expect(antioquiaMuns, contains('Rionegro'));
      expect(() => antioquiaMuns.add('Fake City'), throwsUnsupportedError);

      final unknown = ColombiaLocationCatalog.municipalitiesFor('NoExiste');
      expect(unknown, isEmpty);
    });

    test('searchDepartments performs accent-insensitive and case-insensitive matching', () {
      final results1 = ColombiaLocationCatalog.searchDepartments('bogota');
      expect(results1, contains('Bogotá, D.C.'));

      final results2 = ColombiaLocationCatalog.searchDepartments('BOGOTA');
      expect(results2, contains('Bogotá, D.C.'));

      final results3 = ColombiaLocationCatalog.searchDepartments('atlantico');
      expect(results3, contains('Atlántico'));

      final results4 = ColombiaLocationCatalog.searchDepartments('');
      expect(results4.length, 33);
    });

    test('searchMunicipalities performs accent-insensitive filtering within department', () {
      final medellin = ColombiaLocationCatalog.searchMunicipalities('Antioquia', 'medellin');
      expect(medellin, contains('Medellín'));

      final envigado = ColombiaLocationCatalog.searchMunicipalities('Antioquia', 'ENVIGADO');
      expect(envigado, contains('Envigado'));

      final none = ColombiaLocationCatalog.searchMunicipalities('Antioquia', 'Cali');
      expect(none, isEmpty);
    });

    test('isValidPair checks exact department-municipality integrity', () {
      expect(ColombiaLocationCatalog.isValidPair('Antioquia', 'Medellín'), isTrue);
      expect(ColombiaLocationCatalog.isValidPair('Valle del Cauca', 'Cali'), isTrue);
      expect(ColombiaLocationCatalog.isValidPair('Bogotá, D.C.', 'Bogotá, D.C.'), isTrue);

      // Inverted or mismatch pairs
      expect(ColombiaLocationCatalog.isValidPair('Antioquia', 'Cali'), isFalse);
      expect(ColombiaLocationCatalog.isValidPair(null, 'Medellín'), isFalse);
      expect(ColombiaLocationCatalog.isValidPair('Antioquia', null), isFalse);
      expect(ColombiaLocationCatalog.isValidPair('Invalido', 'Invalido'), isFalse);
    });
  });
}
