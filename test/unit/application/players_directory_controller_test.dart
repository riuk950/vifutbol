import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/players_directory_controller.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

class _MockTeamsRepository extends Mock implements TeamsRepository {}

void main() {
  group('PlayersDirectoryController & State', () {
    late _MockTeamsRepository teamsRepository;
    late PlayerDirectoryItem player1;
    late PlayerDirectoryItem player2;
    late PlayerDirectoryItem player3;
    late PlayerDirectoryItem player4;

    setUp(() {
      teamsRepository = _MockTeamsRepository();

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

    test(
      'initial state sorts players alphabetically A-Z by fullName without tournament fields',
      () {
        final controller = PlayersDirectoryController(
          initialPlayers: [player1, player2, player3, player4],
        );

        expect(controller.state.allPlayers.length, 4);
        expect(controller.state.filteredPlayers.length, 4);
        expect(controller.state.searchQuery, isEmpty);

        // Alphabetical check: Andrés (p-2) -> Carlos (p-1) -> Mateo (p-3) -> Sebastián (p-4)
        expect(
          controller.state.filteredPlayers[0].player.fullName,
          'Andrés Álvarez',
        );
        expect(
          controller.state.filteredPlayers[1].player.fullName,
          'Carlos Gómez',
        );
        expect(
          controller.state.filteredPlayers[2].player.fullName,
          'Mateo Fernández',
        );
        expect(
          controller.state.filteredPlayers[3].player.fullName,
          'Sebastián Peña',
        );
      },
    );

    test(
      'loadPlayers fetches from TeamsRepository and updates state',
      () async {
        when(
          () => teamsRepository.loadAllPlayers(),
        ).thenAnswer((_) async => [player1, player2]);

        final controller = PlayersDirectoryController(
          teamsRepository: teamsRepository,
        );

        expect(controller.state.allPlayers, isEmpty);
        await controller.loadPlayers();

        expect(controller.state.allPlayers.length, 2);
        expect(
          controller.state.viewState,
          isA<UiContentState<List<PlayerDirectoryItem>>>(),
        );
        expect(
          controller.state.filteredPlayers[0].player.fullName,
          'Andrés Álvarez',
        );
        verify(() => teamsRepository.loadAllPlayers()).called(1);
      },
    );

    test(
      'loadPlayers sets UiErrorState when empty and repository throws exception',
      () async {
        when(
          () => teamsRepository.loadAllPlayers(),
        ).thenThrow(Exception('DB error'));

        final controller = PlayersDirectoryController(
          teamsRepository: teamsRepository,
        );

        await controller.loadPlayers();

        expect(controller.state.allPlayers, isEmpty);
        expect(
          controller.state.viewState,
          isA<UiErrorState<List<PlayerDirectoryItem>>>(),
        );
      },
    );

    test('refreshPlayers returns true on success and updates data', () async {
      when(
        () => teamsRepository.loadAllPlayers(),
      ).thenAnswer((_) async => [player1, player2, player3]);

      final controller = PlayersDirectoryController(
        teamsRepository: teamsRepository,
        initialPlayers: [player1],
      );

      final result = await controller.refreshPlayers();

      expect(result, isTrue);
      expect(controller.state.allPlayers.length, 3);
    });

    test(
      'refreshPlayers returns false on exception and preserves existing state',
      () async {
        when(
          () => teamsRepository.loadAllPlayers(),
        ).thenThrow(Exception('Network error'));

        final controller = PlayersDirectoryController(
          teamsRepository: teamsRepository,
          initialPlayers: [player1, player2],
        );

        final result = await controller.refreshPlayers();

        expect(result, isFalse);
        // Existing players preserved
        expect(controller.state.allPlayers.length, 2);
        expect(controller.state.filteredPlayers.length, 2);
      },
    );

    test('filters players by full name (case and accent insensitive)', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
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
      );

      controller.updateSearchQuery('10');
      expect(controller.state.filteredPlayers.length, 1);
      expect(controller.state.filteredPlayers.first.player.id, 'p-1');
    });

    test('filters players by position name and localized Spanish position', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2, player3, player4],
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

    test('clearSearchQuery resets the query', () {
      final controller = PlayersDirectoryController(
        initialPlayers: [player1, player2],
      );

      controller.updateSearchQuery('Carlos');
      expect(controller.state.filteredPlayers.length, 1);

      controller.clearSearchQuery();
      expect(controller.state.searchQuery, isEmpty);
      expect(controller.state.filteredPlayers.length, 2);
    });
  });
}
