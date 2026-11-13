import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

void main() {
  group('HybridRepositorySupport UUID helpers', () {
    final validUuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    test('uuidOrNull returns value for valid UUID and null for non-UUID', () {
      const valid = '12345678-1234-4234-8234-123456789abc';
      expect(HybridRepositorySupport.uuidOrNull(valid), valid);
      expect(
        HybridRepositorySupport.uuidOrNull('tournament-1794583638953'),
        isNull,
      );
      expect(HybridRepositorySupport.uuidOrNull('team-1'), isNull);
      expect(HybridRepositorySupport.uuidOrNull(''), isNull);
      expect(HybridRepositorySupport.uuidOrNull(null), isNull);
    });

    test(
      'ensureUuid converts legacy tournament id tournament-1794583638953 to a valid RFC4122 UUID v5',
      () {
        const legacyId = 'tournament-1794583638953';
        final result1 = HybridRepositorySupport.ensureUuid(
          legacyId,
          'tournament',
        );
        final result2 = HybridRepositorySupport.ensureUuid(
          legacyId,
          'tournament',
        );

        expect(validUuidRegex.hasMatch(result1), isTrue);
        expect(result1, result2, reason: 'Must be completely deterministic');
        expect(result1, isNot(equals(legacyId)));
      },
    );

    test('ensureUuid preserves already-valid UUID strings as-is', () {
      const valid = '550e8400-e29b-41d4-a716-446655440000';
      final result = HybridRepositorySupport.ensureUuid(valid, 'tournament');
      expect(result, equals(valid));
    });

    test('ensureUuidOrNull returns null for null or empty string', () {
      expect(HybridRepositorySupport.ensureUuidOrNull(null), isNull);
      expect(HybridRepositorySupport.ensureUuidOrNull(''), isNull);
      expect(HybridRepositorySupport.ensureUuidOrNull('   '), isNull);

      const legacyTeam = 'team-12345';
      final mapped = HybridRepositorySupport.ensureUuidOrNull(
        legacyTeam,
        'team',
      );
      expect(mapped, isNotNull);
      expect(validUuidRegex.hasMatch(mapped!), isTrue);
    });

    test(
      'different legacy ids produce different deterministic UUID values',
      () {
        final t1 = HybridRepositorySupport.ensureUuid(
          'tournament-1',
          'tournament',
        );
        final t2 = HybridRepositorySupport.ensureUuid(
          'tournament-2',
          'tournament',
        );
        expect(t1, isNot(equals(t2)));
      },
    );
  });
}
