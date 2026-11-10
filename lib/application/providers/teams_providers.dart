import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/models/team_matches_schedule.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

/// Provider exposing the concrete [TeamsRepository] implementation.
final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);

  return LocalTeamsRepository(storage: storage, config: config);
});

/// Provider exposing [ManageTeamsEligibilityUseCase].
final manageTeamsEligibilityUseCaseProvider =
    Provider<ManageTeamsEligibilityUseCase>((ref) {
      final repository = ref.watch(teamsRepositoryProvider);
      final matchesRepo = ref.watch(tournamentMatchesRepositoryProvider);
      return ManageTeamsEligibilityUseCase(repository, matchesRepo);
    });

/// StateNotifierProvider exposing [TeamsController].
final teamsControllerProvider =
    StateNotifierProvider<TeamsController, TeamsCatalogState>((ref) {
      final repository = ref.watch(teamsRepositoryProvider);
      final manageUseCase = ref.watch(manageTeamsEligibilityUseCaseProvider);

      return TeamsController(
        teamsRepository: repository,
        manageTeamsEligibilityUseCase: manageUseCase,
      );
    });

/// Family provider that reactively computes the [TeamMatchSummary] for a given [teamId].
final teamMatchSummaryProvider = Provider.family<TeamMatchSummary, String>((
  ref,
  teamId,
) {
  final teamsState = ref.watch(teamsControllerProvider);
  final tournamentsState = ref.watch(tournamentsControllerProvider);
  final matchesState = ref.watch(matchesCatalogControllerProvider);

  return TeamMatchSummary.fromCatalog(
    teamId: teamId,
    teams: teamsState.teams,
    tournaments: tournamentsState.tournaments,
    matches: matchesState.matches,
  );
});

/// Family provider that reactively computes the [TeamMatchesSchedule] for a given [teamId].
final teamMatchesScheduleProvider =
    Provider.family<TeamMatchesSchedule, String>((ref, teamId) {
      final teamsState = ref.watch(teamsControllerProvider);
      final matchesState = ref.watch(matchesCatalogControllerProvider);

      return TeamMatchesSchedule.fromCatalog(
        teamId: teamId,
        teams: teamsState.teams,
        matches: matchesState.matches,
      );
    });

/// Family provider that reactively computes the [TeamSquadRoster] for a given [teamId].
final teamSquadRosterProvider = Provider.family<TeamSquadRoster, String>((
  ref,
  teamId,
) {
  final teamsState = ref.watch(teamsControllerProvider);

  return TeamSquadRoster.fromCatalog(teamId: teamId, teams: teamsState.teams);
});

/// Provider that reactively filters teams belonging to the currently authenticated coach.
final coachTeamsProvider = Provider<List<TournamentTeam>>((ref) {
  final teamsState = ref.watch(teamsControllerProvider);
  final authState = ref.watch(authControllerProvider);
  final currentCoachId = authState.session?.user.id;

  return teamsState.teams.where((team) {
    if (team.coachId == null) return false;
    if (currentCoachId != null && team.coachId == currentCoachId) return true;
    return team.coachId == 'coach-seed-1';
  }).toList();
});

