import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/competitions_directory_controller.dart';
import 'package:vifutbol/application/controllers/players_directory_controller.dart';
import 'package:vifutbol/application/controllers/teams_directory_controller.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';

/// Provider exposing [CompetitionsDirectoryController] and its reactive state.
final competitionsDirectoryControllerProvider =
    StateNotifierProvider.autoDispose<
      CompetitionsDirectoryController,
      CompetitionsDirectoryState
    >((ref) {
      final initialTournaments = ref
          .read(tournamentsControllerProvider)
          .tournaments;
      final controller = CompetitionsDirectoryController(
        initialTournaments: initialTournaments,
      );

      ref.listen(tournamentsControllerProvider, (prev, next) {
        controller.updateTournaments(next.tournaments);
      });

      return controller;
    });

/// Provider exposing [TeamsDirectoryController] and its reactive state.
final teamsDirectoryControllerProvider =
    StateNotifierProvider.autoDispose<
      TeamsDirectoryController,
      TeamsDirectoryState
    >((ref) {
      final tournaments = ref.watch(tournamentsControllerProvider).tournaments;
      final teamsRepository = ref.watch(teamsRepositoryProvider);

      final controller = TeamsDirectoryController(
        availableTournaments: tournaments,
      );

      teamsRepository.loadTeams().then((teams) {
        if (controller.mounted) {
          controller.updateData(teams: teams, tournaments: tournaments);
        }
      });

      return controller;
    });

/// Provider exposing [PlayersDirectoryController] and its reactive state.
final playersDirectoryControllerProvider =
    StateNotifierProvider.autoDispose<
      PlayersDirectoryController,
      PlayersDirectoryState
    >((ref) {
      final tournaments = ref.watch(tournamentsControllerProvider).tournaments;
      final teamsRepository = ref.watch(teamsRepositoryProvider);

      final controller = PlayersDirectoryController(
        availableTournaments: tournaments,
      );

      teamsRepository.loadTeams().then((teams) {
        if (controller.mounted) {
          final tournamentMap = {for (final t in tournaments) t.id: t.name};
          final List<PlayerDirectoryItem> items = [];
          for (final team in teams) {
            final tName = tournamentMap[team.tournamentId] ?? '';
            for (final player in team.players) {
              items.add(
                PlayerDirectoryItem(
                  player: player,
                  teamId: team.id,
                  teamName: team.name,
                  teamShortCode: team.shortCode,
                  tournamentId: team.tournamentId,
                  tournamentName: tName,
                ),
              );
            }
          }
          controller.updateData(players: items, tournaments: tournaments);
        }
      });

      return controller;
    });
