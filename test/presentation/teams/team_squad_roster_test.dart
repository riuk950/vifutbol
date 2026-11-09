import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

void main() {
  group('TeamSquadRoster.fromCatalog Unit Tests', () {
    const tournamentId = 'tourn_01';
    const teamId = 'team_01';

    test(
      'returns empty lists and totalPlayers = 0 when team is not found in catalog',
      () {
        final roster = TeamSquadRoster.fromCatalog(
          teamId: 'non_existent',
          teams: [],
        );

        expect(roster.teamId, equals('non_existent'));
        expect(roster.team, isNull);
        expect(roster.hasPlayers, isFalse);
        expect(roster.totalPlayers, equals(0));
        expect(roster.goalkeepers, isEmpty);
        expect(roster.defenders, isEmpty);
        expect(roster.midfielders, isEmpty);
        expect(roster.forwards, isEmpty);
        expect(roster.allProfiles, isEmpty);
      },
    );

    test('returns empty lists when team has no registered players', () {
      final emptyTeam = TournamentTeam(
        id: teamId,
        tournamentId: tournamentId,
        name: 'FC Barcelona',
        shortCode: 'FCB',
        players: const [],
      );

      final roster = TeamSquadRoster.fromCatalog(
        teamId: teamId,
        teams: [emptyTeam],
      );

      expect(roster.teamId, equals(teamId));
      expect(roster.team, equals(emptyTeam));
      expect(roster.hasPlayers, isFalse);
      expect(roster.totalPlayers, equals(0));
      expect(roster.goalkeepers, isEmpty);
      expect(roster.defenders, isEmpty);
      expect(roster.midfielders, isEmpty);
      expect(roster.forwards, isEmpty);
    });

    test(
      'sorts players deterministically by ascending shirtNumber within each tactical line',
      () {
        final players = [
          const RegisteredPlayer(
            id: 'p_def_4',
            fullName: 'Sergio Ramos',
            documentId: 'DOC04',
            shirtNumber: 4,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p_def_3',
            fullName: 'Gerard Piqué',
            documentId: 'DOC03',
            shirtNumber: 3,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p_def_2',
            fullName: 'Dani Carvajal',
            documentId: 'DOC02',
            shirtNumber: 2,
            position: PlayerPosition.defender,
            isEligible: false,
          ),
        ];

        final team = TournamentTeam(
          id: teamId,
          tournamentId: tournamentId,
          name: 'Defenders FC',
          shortCode: 'DFC',
          players: players,
        );

        final roster = TeamSquadRoster.fromCatalog(
          teamId: teamId,
          teams: [team],
        );

        expect(roster.totalPlayers, equals(3));
        expect(roster.defenders.length, equals(3));
        expect(roster.defenders[0].shirtNumber, equals(2));
        expect(roster.defenders[0].fullName, equals('Dani Carvajal'));
        expect(roster.defenders[1].shirtNumber, equals(3));
        expect(roster.defenders[1].fullName, equals('Gerard Piqué'));
        expect(roster.defenders[2].shirtNumber, equals(4));
        expect(roster.defenders[2].fullName, equals('Sergio Ramos'));
      },
    );

    test('partitions players correctly into the 4 tactical positions', () {
      final players = [
        const RegisteredPlayer(
          id: 'p1',
          fullName: 'Thibaut Courtois',
          documentId: 'DOC01',
          shirtNumber: 1,
          position: PlayerPosition.goalkeeper,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'p2',
          fullName: 'David Alaba',
          documentId: 'DOC02',
          shirtNumber: 4,
          position: PlayerPosition.defender,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'p3',
          fullName: 'Luka Modric',
          documentId: 'DOC03',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
          isEligible: true,
        ),
        const RegisteredPlayer(
          id: 'p4',
          fullName: 'Vinicius Jr',
          documentId: 'DOC04',
          shirtNumber: 7,
          position: PlayerPosition.forward,
          isEligible: false,
        ),
      ];

      final team = TournamentTeam(
        id: teamId,
        tournamentId: tournamentId,
        name: 'Galacticos',
        shortCode: 'GLC',
        players: players,
      );

      final roster = TeamSquadRoster.fromCatalog(teamId: teamId, teams: [team]);

      expect(roster.hasPlayers, isTrue);
      expect(roster.totalPlayers, equals(4));

      expect(roster.goalkeepers.length, equals(1));
      expect(roster.goalkeepers.first.fullName, equals('Thibaut Courtois'));

      expect(roster.defenders.length, equals(1));
      expect(roster.defenders.first.fullName, equals('David Alaba'));

      expect(roster.midfielders.length, equals(1));
      expect(roster.midfielders.first.fullName, equals('Luka Modric'));

      expect(roster.forwards.length, equals(1));
      expect(roster.forwards.first.fullName, equals('Vinicius Jr'));

      expect(
        roster.playersForPosition(PlayerPosition.goalkeeper),
        equals(roster.goalkeepers),
      );
      expect(
        roster.playersForPosition(PlayerPosition.defender),
        equals(roster.defenders),
      );
      expect(
        roster.playersForPosition(PlayerPosition.midfielder),
        equals(roster.midfielders),
      );
      expect(
        roster.playersForPosition(PlayerPosition.forward),
        equals(roster.forwards),
      );
    });

    test(
      'generates PlayerPerformanceProfile synchronized with isSuspended: !isEligible',
      () {
        final eligiblePlayer = const RegisteredPlayer(
          id: 'p_elig',
          fullName: 'Player One',
          documentId: 'D1',
          shirtNumber: 8,
          position: PlayerPosition.midfielder,
          isEligible: true,
        );
        final suspendedPlayer = const RegisteredPlayer(
          id: 'p_susp',
          fullName: 'Player Two',
          documentId: 'D2',
          shirtNumber: 9,
          position: PlayerPosition.forward,
          isEligible: false,
        );

        final team = TournamentTeam(
          id: teamId,
          tournamentId: tournamentId,
          name: 'Team Alpha',
          shortCode: 'ALP',
          players: [eligiblePlayer, suspendedPlayer],
        );

        final roster = TeamSquadRoster.fromCatalog(
          teamId: teamId,
          teams: [team],
        );

        expect(roster.allProfiles.length, equals(2));

        final profileElig = roster.midfielders.first.performanceProfile;
        expect(profileElig.playerId, equals('p_elig'));
        expect(profileElig.isSuspended, isFalse);
        expect(profileElig.teamName, equals('Team Alpha'));
        expect(profileElig.teamShortCode, equals('ALP'));

        final profileSusp = roster.forwards.first.performanceProfile;
        expect(profileSusp.playerId, equals('p_susp'));
        expect(profileSusp.isSuspended, isTrue);
      },
    );
  });
}
