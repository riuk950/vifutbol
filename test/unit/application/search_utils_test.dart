import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/utils/search_utils.dart';

void main() {
  group('search_utils - normalizeSearchText', () {
    test('normalizes uppercase to lowercase', () {
      expect(normalizeSearchText('VIFUTBOL'), 'vifutbol');
      expect(normalizeSearchText('Tigres FC'), 'tigres fc');
    });

    test('strips leading and trailing whitespace', () {
      expect(normalizeSearchText('   Millonarios   '), 'millonarios');
    });

    test(
      'replaces vowels with acute accents, umlauts, and special characters',
      () {
        expect(normalizeSearchText('Álvarez'), 'alvarez');
        expect(normalizeSearchText('Gómez'), 'gomez');
        expect(normalizeSearchText('Pérez'), 'perez');
        expect(normalizeSearchText('Jesús'), 'jesus');
        expect(normalizeSearchText('López'), 'lopez');
        expect(normalizeSearchText('Argüello'), 'arguello');
        expect(normalizeSearchText('Cañaveral'), 'canaveral');
      },
    );

    test('handles mixed strings with uppercase, accents, and whitespace', () {
      expect(
        normalizeSearchText('  SAN JOSÉ DE CÚCUTA  '),
        'san jose de cucuta',
      );
    });

    test('handles empty and whitespace-only strings gracefully', () {
      expect(normalizeSearchText(''), '');
      expect(normalizeSearchText('   '), '');
    });

    test(
      'matchesSearchQuery accurately performs diacritics and case-insensitive matching',
      () {
        expect(matchesSearchQuery('Álvaro Morata', 'alvaro'), isTrue);
        expect(matchesSearchQuery('Alvaro Morata', 'álvaro'), isTrue);
        expect(matchesSearchQuery('Deportivo Cali', 'dep'), isTrue);
        expect(matchesSearchQuery('Junior', 'millonarios'), isFalse);
        expect(matchesSearchQuery('Atlético Nacional', ''), isTrue);
      },
    );
  });
}
