import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

void main() {
  group('ChampionshipTournament venueIds tests', () {
    final baseTime = DateTime(2026, 6, 1);

    test('defaults to empty venueIds list', () {
      final tournament = ChampionshipTournament(
        id: 't-1',
        name: 'Torneo Verano',
        category: 'Libre',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 60)),
        format: TournamentFormat.league,
        updatedAt: baseTime,
      );

      expect(tournament.venueIds, isEmpty);
    });

    test('supports venueIds in constructor and copyWith', () {
      final tournament = ChampionshipTournament(
        id: 't-1',
        name: 'Torneo Verano',
        category: 'Libre',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 60)),
        format: TournamentFormat.league,
        updatedAt: baseTime,
        venueIds: const ['venue-1', 'venue-2'],
      );

      expect(tournament.venueIds, equals(['venue-1', 'venue-2']));

      final copied = tournament.copyWith(venueIds: const ['venue-3']);
      expect(copied.venueIds, equals(['venue-3']));
      expect(copied.id, 't-1');
    });

    test('serializes and deserializes venueIds properly', () {
      final tournament = ChampionshipTournament(
        id: 't-1',
        name: 'Torneo Verano',
        category: 'Libre',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 60)),
        format: TournamentFormat.league,
        updatedAt: baseTime,
        venueIds: const ['venue-alpha', 'venue-beta'],
      );

      final json = tournament.toJson();
      expect(json['venueIds'], equals(['venue-alpha', 'venue-beta']));

      final restored = ChampionshipTournament.fromJson(json);
      expect(restored.venueIds, equals(['venue-alpha', 'venue-beta']));
      expect(restored, equals(tournament));
      expect(restored.hashCode, equals(tournament.hashCode));
    });

    test('handles null/missing venueIds in fromJson gracefully', () {
      final jsonWithoutVenues = <String, dynamic>{
        'id': 't-2',
        'name': 'Torneo Sin Sedes',
        'category': 'Juvenil',
        'startDate': baseTime.toIso8601String(),
        'endDate': baseTime.add(const Duration(days: 30)).toIso8601String(),
        'format': 'league',
        'status': 'openRegistration',
        'updatedAt': baseTime.toIso8601String(),
      };

      final tournament = ChampionshipTournament.fromJson(jsonWithoutVenues);
      expect(tournament.venueIds, isEmpty);
    });
  });

  group('TournamentDraft venueIds tests', () {
    final baseTime = DateTime(2026, 6, 1);

    test('defaults to empty venueIds list', () {
      final draft = TournamentDraft(
        name: 'Borrador 1',
        category: 'Senior',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 45)),
        savedAt: baseTime,
      );

      expect(draft.venueIds, isEmpty);
    });

    test('supports venueIds in constructor and copyWith', () {
      final draft = TournamentDraft(
        name: 'Borrador 1',
        category: 'Senior',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 45)),
        savedAt: baseTime,
        venueIds: const ['venue-1', 'venue-2'],
      );

      expect(draft.venueIds, equals(['venue-1', 'venue-2']));

      final copied = draft.copyWith(venueIds: const ['venue-99']);
      expect(copied.venueIds, equals(['venue-99']));
      expect(copied.name, 'Borrador 1');
    });

    test('serializes and deserializes venueIds in draft', () {
      final draft = TournamentDraft(
        name: 'Borrador 1',
        category: 'Senior',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 45)),
        savedAt: baseTime,
        venueIds: const ['venue-a', 'venue-b'],
      );

      final json = draft.toJson();
      expect(json['venueIds'], equals(['venue-a', 'venue-b']));

      final restored = TournamentDraft.fromJson(json);
      expect(restored.venueIds, equals(['venue-a', 'venue-b']));
      expect(restored, equals(draft));
      expect(restored.hashCode, equals(draft.hashCode));
    });

    test('handles missing venueIds in TournamentDraft.fromJson', () {
      final json = <String, dynamic>{
        'name': 'Borrador Antiguo',
        'category': 'Libre',
        'startDate': baseTime.toIso8601String(),
        'endDate': baseTime.add(const Duration(days: 30)).toIso8601String(),
        'format': 'league',
        'savedAt': baseTime.toIso8601String(),
      };

      final restored = TournamentDraft.fromJson(json);
      expect(restored.venueIds, isEmpty);
    });
  });
}
