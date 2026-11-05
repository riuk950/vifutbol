import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/competitions_directory_controller.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

void main() {
  group('CompetitionsDirectoryController & State', () {
    late ChampionshipTournament tournament1;
    late ChampionshipTournament tournament2;
    late ChampionshipTournament tournament3;

    setUp(() {
      tournament1 = ChampionshipTournament(
        id: 't-1',
        name: 'Liga Premier Apertura',
        category: 'Libre Masculino',
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 6, 30),
        updatedAt: DateTime(2026, 3, 1),
      );

      tournament2 = ChampionshipTournament(
        id: 't-2',
        name: 'Copa Élite Verano',
        category: 'Sub-20',
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.openRegistration,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 7, 1),
      );

      tournament3 = ChampionshipTournament(
        id: 't-3',
        name: 'Torneo Navideño Infantil',
        category: 'Infantil Sub-12',
        format: TournamentFormat.mixedGroupsAndKnockout,
        status: TournamentStatus.finished,
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 23),
        updatedAt: DateTime(2025, 12, 1),
      );
    });

    test(
      'initial state contains all tournaments when search query is empty',
      () {
        final controller = CompetitionsDirectoryController(
          initialTournaments: [tournament1, tournament2, tournament3],
        );

        expect(controller.state.filteredTournaments.length, 3);
        expect(controller.state.searchQuery, '');
      },
    );

    test(
      'filters competitions by name in real time (case and accent insensitive)',
      () {
        final controller = CompetitionsDirectoryController(
          initialTournaments: [tournament1, tournament2, tournament3],
        );

        // Search with accent for 'élite' matches 'Copa Élite Verano'
        controller.setSearchQuery('élite');
        expect(controller.state.filteredTournaments.length, 1);
        expect(controller.state.filteredTournaments.first.id, 't-2');

        // Search without accent 'elite' also matches 'Copa Élite Verano'
        controller.setSearchQuery('elite');
        expect(controller.state.filteredTournaments.length, 1);
        expect(controller.state.filteredTournaments.first.id, 't-2');
      },
    );

    test('filters competitions by category', () {
      final controller = CompetitionsDirectoryController(
        initialTournaments: [tournament1, tournament2, tournament3],
      );

      controller.setSearchQuery('sub-20');
      expect(controller.state.filteredTournaments.length, 1);
      expect(controller.state.filteredTournaments.first.id, 't-2');

      controller.setSearchQuery('Infantil');
      expect(controller.state.filteredTournaments.length, 1);
      expect(controller.state.filteredTournaments.first.id, 't-3');
    });

    test('clearSearchQuery restores all competitions', () {
      final controller = CompetitionsDirectoryController(
        initialTournaments: [tournament1, tournament2, tournament3],
      );

      controller.setSearchQuery('non-existent tournament');
      expect(controller.state.filteredTournaments.isEmpty, isTrue);

      controller.clearSearchQuery();
      expect(controller.state.filteredTournaments.length, 3);
      expect(controller.state.searchQuery, '');
    });

    test(
      'updateTournaments updates base list while preserving query filter',
      () {
        final controller = CompetitionsDirectoryController(
          initialTournaments: [tournament1],
        );

        controller.setSearchQuery('Copa');
        expect(controller.state.filteredTournaments.isEmpty, isTrue);

        controller.updateTournaments([tournament1, tournament2]);
        expect(controller.state.filteredTournaments.length, 1);
        expect(controller.state.filteredTournaments.first.id, 't-2');
      },
    );
  });
}
