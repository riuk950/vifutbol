import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

void main() {
  group('TeamSquadRoster Positional Grouping and Shirt Sorting (HU 20.2)', () {
    const teamId = 'team_coach_1';
    const tournamentId = 'tourn_01';

    test('groups players strictly into 4 tactical lines and sorts ascending by shirtNumber', () {
      final players = [
        const RegisteredPlayer(
          id: 'gk_13',
          fullName: 'Keylor Navas',
          documentId: 'DOC13',
          shirtNumber: 13,
          position: PlayerPosition.goalkeeper,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'gk_1',
          fullName: 'Thibaut Courtois',
          documentId: 'DOC01',
          shirtNumber: 1,
          position: PlayerPosition.goalkeeper,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'def_4',
          fullName: 'Sergio Ramos',
          documentId: 'DOC04',
          shirtNumber: 4,
          position: PlayerPosition.defender,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'def_2',
          fullName: 'Dani Carvajal',
          documentId: 'DOC02',
          shirtNumber: 2,
          position: PlayerPosition.defender,
          isEligible: false,
        ),
        const RegisteredPlayer(
          id: 'mid_10',
          fullName: 'Luka Modric',
          documentId: 'DOC10',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'mid_8',
          fullName: 'Toni Kroos',
          documentId: 'DOC08',
          shirtNumber: 8,
          position: PlayerPosition.midfielder,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'fwd_9',
          fullName: 'Karim Benzema',
          documentId: 'DOC09',
          shirtNumber: 9,
          position: PlayerPosition.forward,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'fwd_7',
          fullName: 'Cristiano Ronaldo',
          documentId: 'DOC07',
          shirtNumber: 7,
          position: PlayerPosition.forward,
          isEligible: false,
        ),
      ];

      final team = TournamentTeam(
        id: teamId,
        tournamentId: tournamentId,
        name: 'Real Madrid',
        shortCode: 'RMA',
        players: players,
      );

      final roster = TeamSquadRoster.fromCatalog(
        teamId: teamId,
        teams: [team],
      );

      expect(roster.totalPlayers, equals(8));

      // Goalkeepers: #1, #13
      expect(roster.goalkeepers.map((p) => p.shirtNumber).toList(), equals([1, 13]));
      expect(roster.goalkeepers.map((p) => p.fullName).toList(), equals(['Thibaut Courtois', 'Keylor Navas']));

      // Defenders: #2, #4
      expect(roster.defenders.map((p) => p.shirtNumber).toList(), equals([2, 4]));
      expect(roster.defenders.map((p) => p.fullName).toList(), equals(['Dani Carvajal', 'Sergio Ramos']));

      // Midfielders: #8, #10
      expect(roster.midfielders.map((p) => p.shirtNumber).toList(), equals([8, 10]));
      expect(roster.midfielders.map((p) => p.fullName).toList(), equals(['Toni Kroos', 'Luka Modric']));

      // Forwards: #7, #9
      expect(roster.forwards.map((p) => p.shirtNumber).toList(), equals([7, 9]));
      expect(roster.forwards.map((p) => p.fullName).toList(), equals(['Cristiano Ronaldo', 'Karim Benzema']));
    });

    test('supports empty lines gracefully when team has no players in a position', () {
      final players = [
        const RegisteredPlayer(
          id: 'fwd_9',
          fullName: 'Karim Benzema',
          documentId: 'DOC09',
          shirtNumber: 9,
          position: PlayerPosition.forward,
          isEligible: true,
        ),
      ];

      final team = TournamentTeam(
        id: teamId,
        tournamentId: tournamentId,
        name: 'Single Forward FC',
        shortCode: 'SFF',
        players: players,
      );

      final roster = TeamSquadRoster.fromCatalog(
        teamId: teamId,
        teams: [team],
      );

      expect(roster.goalkeepers, isEmpty);
      expect(roster.defenders, isEmpty);
      expect(roster.midfielders, isEmpty);
      expect(roster.forwards.length, equals(1));
    });
  });
}
