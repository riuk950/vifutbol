import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';

void main() {
  group('ChampionshipTournament organizerId Tests', () {
    final baseTime = DateTime(2026, 5, 1);

    test('supports organizerId in constructor and copyWith', () {
      final tournament = ChampionshipTournament(
        id: 'tournament-1',
        name: 'Torneo Apertura',
        category: 'Libre',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 90)),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: baseTime,
        organizerId: 'org-123',
      );

      expect(tournament.organizerId, 'org-123');

      final copied = tournament.copyWith(organizerId: 'org-456');
      expect(copied.organizerId, 'org-456');
      expect(copied.id, 'tournament-1');
    });

    test('serializes organizerId to JSON', () {
      final tournament = ChampionshipTournament(
        id: 'tournament-1',
        name: 'Torneo Apertura',
        category: 'Libre',
        startDate: baseTime,
        endDate: baseTime.add(const Duration(days: 90)),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: baseTime,
        organizerId: 'org-123',
      );

      final json = tournament.toJson();
      expect(json['organizerId'], 'org-123');
    });

    test('deserializes organizerId from JSON and uses fallback if null', () {
      final jsonWithOrganizer = <String, dynamic>{
        'id': 'tournament-1',
        'name': 'Torneo Apertura',
        'category': 'Libre',
        'startDate': baseTime.toIso8601String(),
        'endDate': baseTime.add(const Duration(days: 90)).toIso8601String(),
        'format': 'league',
        'status': 'openRegistration',
        'updatedAt': baseTime.toIso8601String(),
        'organizerId': 'org-custom',
      };

      final tournament1 = ChampionshipTournament.fromJson(jsonWithOrganizer);
      expect(tournament1.organizerId, 'org-custom');

      final jsonWithoutOrganizer = <String, dynamic>{
        'id': 'tournament-2',
        'name': 'Torneo Clausura',
        'category': 'Libre',
        'startDate': baseTime.toIso8601String(),
        'endDate': baseTime.add(const Duration(days: 90)).toIso8601String(),
        'format': 'league',
        'status': 'openRegistration',
        'updatedAt': baseTime.toIso8601String(),
      };

      final tournament2 = ChampionshipTournament.fromJson(jsonWithoutOrganizer);
      expect(tournament2.organizerId, 'org-seed-1');
    });
  });
}
