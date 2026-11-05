import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_directory_controller.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

void main() {
  group('TeamsDirectoryController & State', () {
    late ChampionshipTournament tournament1;
    late ChampionshipTournament tournament2;
    late TournamentTeam team1;
    late TournamentTeam team2;
    late TournamentTeam team3;

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

      team1 = TournamentTeam(
        id: 'team-1',
        tournamentId: 'tourn-1',
        name: 'Tigres FC',
        shortCode: 'TIG',
      );

      team2 = TournamentTeam(
        id: 'team-2',
        tournamentId: 'tourn-1',
        name: 'Águilas Doradas',
        shortCode: 'AGU',
      );

      team3 = TournamentTeam(
        id: 'team-3',
        tournamentId: 'tourn-2',
        name: 'Leones del Norte',
        shortCode: 'LEO',
      );
    });

    test('initial state contains all teams and null tournament filter', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team2, team3],
        availableTournaments: [tournament1, tournament2],
      );

      expect(controller.state.filteredTeams.length, 3);
      expect(controller.state.selectedTournamentId, isNull);
      expect(controller.state.searchQuery, '');
    });

    test('filters teams by selected tournament', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team2, team3],
        availableTournaments: [tournament1, tournament2],
      );

      controller.selectTournamentFilter('tourn-1');
      expect(controller.state.filteredTeams.length, 2);
      expect(
        controller.state.filteredTeams.map((t) => t.id),
        containsAll(['team-1', 'team-2']),
      );

      controller.selectTournamentFilter('tourn-2');
      expect(controller.state.filteredTeams.length, 1);
      expect(controller.state.filteredTeams.first.id, 'team-3');

      // Reset to all
      controller.selectTournamentFilter(null);
      expect(controller.state.filteredTeams.length, 3);
    });

    test(
      'filters teams by name and shortCode (case and accent insensitive)',
      () {
        final controller = TeamsDirectoryController(
          initialTeams: [team1, team2, team3],
          availableTournaments: [tournament1, tournament2],
        );

        // Search 'aguilas' without accent matches 'Águilas Doradas'
        controller.setSearchQuery('aguilas');
        expect(controller.state.filteredTeams.length, 1);
        expect(controller.state.filteredTeams.first.id, 'team-2');

        // Search by shortCode
        controller.setSearchQuery('TIG');
        expect(controller.state.filteredTeams.length, 1);
        expect(controller.state.filteredTeams.first.id, 'team-1');
      },
    );

    test('combines tournament filter and text search', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team2, team3],
        availableTournaments: [tournament1, tournament2],
      );

      controller.selectTournamentFilter('tourn-2');
      controller.setSearchQuery('Tigres');

      // Tigres is in tourn-1, so empty in tourn-2
      expect(controller.state.filteredTeams.isEmpty, isTrue);

      controller.setSearchQuery('Leones');
      expect(controller.state.filteredTeams.length, 1);
      expect(controller.state.filteredTeams.first.id, 'team-3');
    });

    test('clearSearchQuery restores teams for current tournament filter', () {
      final controller = TeamsDirectoryController(
        initialTeams: [team1, team2, team3],
        availableTournaments: [tournament1, tournament2],
      );

      controller.selectTournamentFilter('tourn-1');
      controller.setSearchQuery('Inexistente');
      expect(controller.state.filteredTeams.isEmpty, isTrue);

      controller.clearSearchQuery();
      expect(controller.state.filteredTeams.length, 2);
    });
  });
}
