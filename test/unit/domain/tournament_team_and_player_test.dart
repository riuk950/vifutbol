import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

void main() {
  group('RegisteredPlayer Domain Entity', () {
    test('normalizes documentId correctly for comparison', () {
      const player = RegisteredPlayer(
        id: 'p1',
        fullName: 'Carlos Rodriguez',
        documentId: ' 10203040ab ',
        shirtNumber: 10,
        position: PlayerPosition.midfielder,
      );

      expect(player.normalizedDocumentId, equals('10203040AB'));
    });

    test('serializes and deserializes to/from JSON correctly', () {
      const player = RegisteredPlayer(
        id: 'p-1',
        fullName: 'Andrés Guardado',
        documentId: '98765432',
        shirtNumber: 18,
        position: PlayerPosition.midfielder,
        isEligible: true,
      );

      final json = player.toJson();
      final restored = RegisteredPlayer.fromJson(json);

      expect(restored.id, equals(player.id));
      expect(restored.fullName, equals(player.fullName));
      expect(restored.documentId, equals(player.documentId));
      expect(restored.shirtNumber, equals(player.shirtNumber));
      expect(restored.position, equals(player.position));
      expect(restored.isEligible, isTrue);
    });
  });

  group('TournamentTeam Aggregate Root', () {
    test('sorts players automatically by shirtNumber ascending', () {
      final p1 = const RegisteredPlayer(
        id: 'p1',
        fullName: 'Player 10',
        documentId: '100',
        shirtNumber: 10,
        position: PlayerPosition.midfielder,
      );
      final p2 = const RegisteredPlayer(
        id: 'p2',
        fullName: 'Player 1',
        documentId: '101',
        shirtNumber: 1,
        position: PlayerPosition.goalkeeper,
      );
      final p3 = const RegisteredPlayer(
        id: 'p3',
        fullName: 'Player 4',
        documentId: '102',
        shirtNumber: 4,
        position: PlayerPosition.defender,
      );

      final team = TournamentTeam(
        id: 't1',
        tournamentId: 'tour-1',
        name: 'Atlético Norte FC',
        shortCode: 'ATN',
        players: [p1, p2, p3],
      );

      expect(
        team.players.map((p) => p.shirtNumber).toList(),
        equals([1, 4, 10]),
      );
    });

    test('normalizedName lowercases and trims', () {
      final team = TournamentTeam(
        id: 't1',
        tournamentId: 'tour-1',
        name: '  Atlético Norte FC  ',
        shortCode: 'ATN',
      );

      expect(team.normalizedName, equals('atlético norte fc'));
    });

    test('meetsMinimumQuota and hasAvailableSlot evaluate correctly', () {
      final p1 = const RegisteredPlayer(
        id: 'p1',
        fullName: 'P1',
        documentId: '101',
        shirtNumber: 1,
        position: PlayerPosition.goalkeeper,
      );
      final p2 = const RegisteredPlayer(
        id: 'p2',
        fullName: 'P2',
        documentId: '102',
        shirtNumber: 2,
        position: PlayerPosition.defender,
      );

      final team = TournamentTeam(
        id: 't1',
        tournamentId: 'tour-1',
        name: 'Team A',
        shortCode: 'TMA',
        players: [p1, p2],
      );

      expect(team.meetsMinimumQuota(3), isFalse);
      expect(team.meetsMinimumQuota(2), isTrue);
      expect(team.hasAvailableSlot(2), isFalse);
      expect(team.hasAvailableSlot(3), isTrue);
    });

    test('serializes and deserializes to/from JSON correctly', () {
      final team = TournamentTeam(
        id: 'team-123',
        tournamentId: 'tour-99',
        name: 'Real Sabana Club',
        shortCode: 'RSC',
        crestShape: TeamCrestShape.hexagon,
        primaryColorHex: 0xFF1E88E5,
        secondaryColorHex: 0xFF0D47A1,
        eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        players: [
          const RegisteredPlayer(
            id: 'p-1',
            fullName: 'David Ospina',
            documentId: '11223344',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: false,
          ),
        ],
      );

      final json = team.toJson();
      final restored = TournamentTeam.fromJson(json);

      expect(restored.id, equals(team.id));
      expect(restored.tournamentId, equals(team.tournamentId));
      expect(restored.name, equals(team.name));
      expect(restored.shortCode, equals('RSC'));
      expect(restored.crestShape, equals(TeamCrestShape.hexagon));
      expect(restored.primaryColorHex, equals(0xFF1E88E5));
      expect(restored.secondaryColorHex, equals(0xFF0D47A1));
      expect(
        restored.eligibilityStatus,
        equals(TeamEligibilityStatus.pendingVerification),
      );
      expect(restored.players.length, equals(1));
      expect(restored.players.first.fullName, equals('David Ospina'));
    });
  });

  group('TeamsCatalogState', () {
    test('filters teams for specific tournament and selects team', () {
      final t1 = TournamentTeam(
        id: 'team-1',
        tournamentId: 'tournament-A',
        name: 'Team 1',
        shortCode: 'T1',
      );
      final t2 = TournamentTeam(
        id: 'team-2',
        tournamentId: 'tournament-B',
        name: 'Team 2',
        shortCode: 'T2',
      );

      const state = TeamsCatalogState();
      final updated = state.copyWith(teams: [t1, t2], selectedTeamId: 'team-1');

      expect(updated.teamsForTournament('tournament-A'), equals([t1]));
      expect(updated.teamsForTournament('tournament-B'), equals([t2]));
      expect(updated.selectedTeam, equals(t1));

      final cleared = updated.copyWith(clearSelectedTeamId: true);
      expect(cleared.selectedTeam, isNull);
    });
  });
}
