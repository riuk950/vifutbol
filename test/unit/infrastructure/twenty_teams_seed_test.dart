import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/infrastructure/data/twenty_teams_seed.dart';

void main() {
  group('TwentyTeamsSeedData', () {
    test('generates exactly 20 teams with 18 players each', () {
      final teams = TwentyTeamsSeedData.generate(
        tournamentId: 'test-tournament-id',
      );

      expect(teams.length, equals(20));

      final teamIds = <String>{};
      final shortCodes = <String>{};
      final allDocIds = <String>{};

      for (final team in teams) {
        expect(team.tournamentId, equals('test-tournament-id'));
        expect(team.players.length, equals(18));
        expect(team.eligibilityStatus, equals(TeamEligibilityStatus.eligible));

        // Verificamos unicidad de equipos y códigos
        expect(
          teamIds.add(team.id),
          isTrue,
          reason: 'Duplicate team ID: ${team.id}',
        );
        expect(
          shortCodes.add(team.shortCode),
          isTrue,
          reason: 'Duplicate short code: ${team.shortCode}',
        );

        // Verificamos plantilla de jugadores
        final shirtNumbers = team.players.map((p) => p.shirtNumber).toSet();
        expect(shirtNumbers.length, equals(18));
        expect(shirtNumbers.contains(1), isTrue); // Arquero titular

        final goalkeepers = team.players.where(
          (p) => p.position == PlayerPosition.goalkeeper,
        );
        expect(goalkeepers.length, equals(2));

        final defenders = team.players.where(
          (p) => p.position == PlayerPosition.defender,
        );
        expect(defenders.length, equals(6));

        final midfielders = team.players.where(
          (p) => p.position == PlayerPosition.midfielder,
        );
        expect(midfielders.length, equals(6));

        final forwards = team.players.where(
          (p) => p.position == PlayerPosition.forward,
        );
        expect(forwards.length, equals(4));

        for (final player in team.players) {
          expect(player.fullName.trim().isNotEmpty, isTrue);
          expect(player.documentId.isNotEmpty, isTrue);
          expect(player.isEligible, isTrue);
          allDocIds.add(player.documentId);
        }
      }

      // Total de 360 jugadores únicos generados
      expect(allDocIds.length, equals(360));
    });
  });
}
