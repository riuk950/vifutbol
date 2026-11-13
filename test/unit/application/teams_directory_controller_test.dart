import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/teams_directory_controller.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

class _MockTeamsRepository extends Mock implements TeamsRepository {}

void main() {
  group('TeamsDirectoryController & State', () {
    late _MockTeamsRepository teamsRepository;
    late TeamDirectoryItem team1;
    late TeamDirectoryItem team2;
    late TeamDirectoryItem team3;

    setUp(() {
      teamsRepository = _MockTeamsRepository();

      team1 = TeamDirectoryItem(
        id: 'team-1',
        name: 'Tigres FC',
        shortCode: 'TIG',
        categoryLabel: 'Libre',
        tournamentCount: 1,
        playerCount: 16,
        eligibilityStatus: TeamEligibilityStatus.eligible,
        updatedAt: DateTime(2026, 11, 13),
      );

      team2 = TeamDirectoryItem(
        id: 'team-2',
        name: 'Atlético Dorados',
        shortCode: 'DOR',
        categoryLabel: null,
        tournamentCount: 0,
        playerCount: 0,
        eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        updatedAt: DateTime(2026, 11, 13),
      );

      team3 = TeamDirectoryItem(
        id: 'team-3',
        name: 'Leones del Norte',
        shortCode: 'LEO',
        categoryLabel: 'Sub-20',
        tournamentCount: 1,
        playerCount: 22,
        eligibilityStatus: TeamEligibilityStatus.eligible,
        updatedAt: DateTime(2026, 11, 13),
      );
    });

    test('initial state sorts teams alphabetically A-Z by name', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team3, team2],
      );

      expect(controller.state.filteredTeams.length, 3);
      expect(controller.state.filteredTeams.map((t) => t.id).toList(), [
        'team-2', // Atlético Dorados
        'team-3', // Leones del Norte
        'team-1', // Tigres FC
      ]);
      expect(controller.state.searchQuery, '');
    });

    test(
      'loadTeams() fetches from repository and sets UiContentState',
      () async {
        when(
          () => teamsRepository.loadAllTeams(),
        ).thenAnswer((_) async => [team1, team2, team3]);

        final controller = TeamsDirectoryController(
          teamsRepository: teamsRepository,
        );

        await controller.loadTeams();

        expect(
          controller.state.viewState,
          isA<UiContentState<List<TeamDirectoryItem>>>(),
        );
        expect(controller.state.allTeams.length, 3);
        expect(controller.state.allTeams.first.id, 'team-2');
        verify(() => teamsRepository.loadAllTeams()).called(1);
      },
    );

    test(
      'loadTeams() sets UiEmptyState when repository returns empty list',
      () async {
        when(() => teamsRepository.loadAllTeams()).thenAnswer((_) async => []);

        final controller = TeamsDirectoryController(
          teamsRepository: teamsRepository,
        );

        await controller.loadTeams();

        expect(
          controller.state.viewState,
          isA<UiEmptyState<List<TeamDirectoryItem>>>(),
        );
        expect(controller.state.allTeams, isEmpty);
      },
    );

    test(
      'loadTeams() sets UiErrorState when repository throws and no cache exists',
      () async {
        when(
          () => teamsRepository.loadAllTeams(),
        ).thenThrow(Exception('Network error'));

        final controller = TeamsDirectoryController(
          teamsRepository: teamsRepository,
        );

        await controller.loadTeams();

        expect(
          controller.state.viewState,
          isA<UiErrorState<List<TeamDirectoryItem>>>(),
        );
      },
    );

    test('refreshTeams() returns true on success and updates teams', () async {
      when(
        () => teamsRepository.loadAllTeams(),
      ).thenAnswer((_) async => [team1, team2]);

      final controller = TeamsDirectoryController(
        teamsRepository: teamsRepository,
      );

      final result = await controller.refreshTeams();

      expect(result, isTrue);
      expect(controller.state.allTeams.length, 2);
      expect(
        controller.state.viewState,
        isA<UiContentState<List<TeamDirectoryItem>>>(),
      );
    });

    test(
      'refreshTeams() returns false on error and preserves cached teams',
      () async {
        when(
          () => teamsRepository.loadAllTeams(),
        ).thenThrow(Exception('Offline'));

        final controller = TeamsDirectoryController(
          teamsRepository: teamsRepository,
          initialTeams: [team1, team2],
        );

        final result = await controller.refreshTeams();

        expect(result, isFalse);
        expect(controller.state.allTeams.length, 2);
        expect(
          controller.state.viewState,
          isA<UiContentState<List<TeamDirectoryItem>>>(),
        );
      },
    );

    test(
      'filters teams by name, shortCode, and categoryLabel (case and accent insensitive)',
      () {
        final controller = TeamsDirectoryController(
          initialTeams: [team1, team2, team3],
        );

        // Search 'atletico' without accent matches 'Atlético Dorados'
        controller.setSearchQuery('atletico');
        expect(controller.state.filteredTeams.length, 1);
        expect(controller.state.filteredTeams.first.id, 'team-2');

        // Search by shortCode
        controller.setSearchQuery('TIG');
        expect(controller.state.filteredTeams.length, 1);
        expect(controller.state.filteredTeams.first.id, 'team-1');

        // Search by categoryLabel
        controller.setSearchQuery('sub-20');
        expect(controller.state.filteredTeams.length, 1);
        expect(controller.state.filteredTeams.first.id, 'team-3');
      },
    );

    test('clearSearchQuery restores full sorted team list', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team2, team3],
      );

      controller.setSearchQuery('Inexistente');
      expect(controller.state.filteredTeams, isEmpty);

      controller.clearSearchQuery();
      expect(controller.state.filteredTeams.length, 3);
    });
  });
}
