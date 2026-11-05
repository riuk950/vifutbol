import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/players_directory_controller.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

void main() {
  group('PlayersDirectoryController & State', () {
    late ChampionshipTournament tournament1;
    late ChampionshipTournament tournament2;
    late PlayerDirectoryItem player1;
    late PlayerDirectoryItem player2;
    late PlayerDirectoryItem player3;
    late PlayerDirectoryItem player4;

    setUp(() {
      tournament1 = ChampionshipTournament(
        id: 'tourn-1',
        name: 'Liga Premier Apertura',
        category: 'Libre',
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 6, 30),
        updatedAt: DateTime(2026, 3, 1),
      );

      tournament2 = ChampionshipTournament(
        id: 'tourn-2',
        name: 'Copa Élite',
        category: 'Sub-20',
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.openRegistration,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 7, 1),
      );

      player1 = const PlayerDirectoryItem(
        player: RegisteredPlayer(
          id: 'p-1',
          fullName: 'Carlos Gómez',
          documentId: 'DOC-101',
          shirtNumber: 10,
          position: PlayerPosition.forward,
          isEligible: true,
        ),
        teamId: 'team-1',
        teamName: 'Tigres FC',
        teamShortCode: 'TIG',
        tournamentId: 'tourn-1',
        tournamentName: 'Liga Premier Apertura',
      );

      player2 = const PlayerDirectoryItem(
        player: RegisteredPlayer(
          id: 'p-2',
          fullName: 'Andrés Álvarez',
          documentId: 'DOC-102',
          shirtNumber: 1,
          position: PlayerPosition.goalkeeper,
          isEligible: true,
        ),
        teamId: 'team-1',
        teamName: 'Tigres FC',
        teamShortCode: 'TIG',
        tournamentId: 'tourn-1',
        tournamentName: 'Liga Premier Apertura',
      );

      player3 = const PlayerDirectoryItem(
        player: RegisteredPlayer(
          id: 'p-3',
          fullName: 'Mateo Fernández',
          documentId: 'DOC-103',
          shirtNumber: 8,
          position: PlayerPosition.midfielder,
          isEligible: true,
        ),
        teamId: 'team-2',
        teamName: 'Águilas Doradas',
        teamShortCode: 'AGU',
        tournamentId: 'tourn-1',
        tournamentName: 'Liga Premier Apertura',
      );

      player4 = const PlayerDirectoryItem(
        player: RegisteredPlayer(
          id: 'p-4',
          fullName: 'Sebastián Peña',
          documentId: 'DOC-104',
          shirtNumber: 4,
          position: PlayerPosition.defender,
          isEligible: false,
        ),
        teamId: 'team-3',
        teamName: 'Halcones Sub-20',
        teamShortCode: 'HAL',
        tournamentId: 'tourn-2',
        tournamentName: 'Copa Élite',
      );
    });

    test('initial state contains all players and null tournament filter', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      expect(controller.state.allPlayers.length, 4);
      expect(controller.state.filteredPlayers.length, 4);
      expect(controller.state.selectedTournamentId, isNull);
      expect(controller.state.searchQuery, isEmpty);
    });

    test('filters players by selected tournament', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      controller.selectTournament('tourn-2');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-4');

      // Clear tournament filter by passing null
      controller.selectTournament(null);
      expect(controller.state.filteredPlayers.length, 4);
    });

    test('filters players by full name (case and accent insensitive)', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      // Search 'alvarez' should match 'Andrés Álvarez'
      controller.updateSearchQuery('alvarez');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-2');

      // Search 'gomez' without accent should match 'Carlos Gómez'
      controller.updateSearchQuery('gomez');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-1');
    });

    test('filters players by shirt number', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      controller.updateSearchQuery('10');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-1');
    });

    test('filters players by position name and localized Spanish position', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      // Spanish position: 'portero'
      controller.updateSearchQuery('portero');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-2');

      // Spanish position: 'delantero'
      controller.updateSearchQuery('delantero');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-1');
    });

    test('filters players by team name or team shortCode', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      // Search by team shortCode 'AGU'
      controller.updateSearchQuery('AGU');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-3');

      // Search by team name with accent: 'aguilas'
      controller.updateSearchQuery('aguilas');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-3');
    });

    test('combines tournament filter and search query correctly', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
        availableTournaments: [tournament1, tournament2],
      );

      controller.selectTournament('tourn-1');
      controller.updateSearchQuery('Carlos');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-1');

      // 'Peña' belongs to tourn-2, so with tourn-1 filter it should yield empty
      controller.updateSearchQuery('Peña');
      expect(controller.state.filteredPlayers, isEmpty);
    });

    test('clearSearchQuery resets the query', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2],
        availableTournaments: [tournament1],
      );

      controller.updateSearchQuery('Carlos');
      expect(controller.state.filteredPlayers.length, 1);

      controller.clearSearchQuery();
      expect(controller.state.searchQuery, isEmpty);
      expect(controller.state.filteredPlayers.length, 2);
    });
  });
}
