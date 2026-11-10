import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

void main() {
  group('TournamentTeam Coach Governance Entity Tests', () {
    test(
      'defaults coachId to coach-seed-1 and tournamentId to empty string',
      () {
        final team = TournamentTeam(
          id: 'team-1',
          name: 'Club Atlético Viña',
          shortCode: 'CAV',
        );

        expect(team.coachId, equals('coach-seed-1'));
        expect(team.tournamentId, equals(''));
        expect(team.name, equals('Club Atlético Viña'));
        expect(team.shortCode, equals('CAV'));
      },
    );

    test('preserves explicit coachId and tournamentId', () {
      final team = TournamentTeam(
        id: 'team-2',
        tournamentId: 'tourn-99',
        name: 'Deportivo Valparaíso',
        shortCode: 'DVA',
        coachId: 'coach-custom-42',
      );

      expect(team.coachId, equals('coach-custom-42'));
      expect(team.tournamentId, equals('tourn-99'));
    });

    test('copyWith updates coachId and tournamentId appropriately', () {
      final initial = TournamentTeam(
        id: 'team-1',
        name: 'Original Team',
        shortCode: 'ORG',
      );

      final updated = initial.copyWith(
        coachId: 'coach-updated',
        tournamentId: 'tourn-123',
      );

      expect(updated.coachId, equals('coach-updated'));
      expect(updated.tournamentId, equals('tourn-123'));
      expect(updated.name, equals('Original Team'));
    });

    test(
      'toJson and fromJson preserves coachId and tournamentId in round-trip',
      () {
        final original = TournamentTeam(
          id: 'team-3',
          tournamentId: 'tourn-abc',
          name: 'Everton Viña',
          shortCode: 'EVE',
          coachId: 'coach-everton-1',
          crestShape: TeamCrestShape.shield,
          primaryColorHex: 0xFF123456,
          secondaryColorHex: 0xFF654321,
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: [
            RegisteredPlayer(
              id: 'player-1',
              fullName: 'Carlos Caszely',
              documentId: '11223344-5',
              shirtNumber: 9,
              position: PlayerPosition.forward,
            ),
          ],
        );

        final json = original.toJson();
        expect(json['coachId'], equals('coach-everton-1'));
        expect(json['tournamentId'], equals('tourn-abc'));

        final reconstructed = TournamentTeam.fromJson(json);
        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.coachId, equals('coach-everton-1'));
        expect(reconstructed.tournamentId, equals('tourn-abc'));
        expect(reconstructed.name, equals(original.name));
        expect(reconstructed.players.length, equals(1));
        expect(reconstructed.players.first.fullName, equals('Carlos Caszely'));
      },
    );

    test(
      'fromJson falls back to coach-seed-1 and empty tournamentId when missing',
      () {
        final legacyJson = {
          'id': 'legacy-team',
          'name': 'Legacy FC',
          'shortCode': 'LFC',
        };

        final reconstructed = TournamentTeam.fromJson(legacyJson);
        expect(reconstructed.coachId, equals('coach-seed-1'));
        expect(reconstructed.tournamentId, equals(''));
      },
    );
  });
}
