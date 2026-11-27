import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/models/team_matches_schedule.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

/// Provider exposing the concrete [TeamsRepository] implementation.
final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final local = LocalTeamsRepository(storage: storage, config: config);

  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestTeamsRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
  );
  final hybrid = HybridTeamsRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(SyncOutboxEntityType.team, hybrid.replayOutboxItem);
  return hybrid;
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

List<TournamentTeam> _resolveEffectiveTeams(Ref ref, String teamId) {
  final teamsState = ref.watch(teamsControllerProvider);
  if (teamsState.teams.any((t) => t.id == teamId)) {
    return teamsState.teams;
  }

  final directoryState = ref.watch(teamsDirectoryControllerProvider);
  final matchIndex = directoryState.allTeams.indexWhere((t) => t.id == teamId);
  if (matchIndex < 0) {
    return teamsState.teams;
  }

  final item = directoryState.allTeams[matchIndex];
  return [
    ...teamsState.teams,
    TournamentTeam(
      id: item.id,
      tournamentId: '',
      name: item.name,
      shortCode: item.shortCode,
      crestShape: item.crestShape,
      primaryColorHex: item.primaryColorHex,
      secondaryColorHex: item.secondaryColorHex,
      eligibilityStatus: item.eligibilityStatus,
      coachId: item.coachId,
      delegateName: item.delegateName,
      foundedDate: item.foundedDate,
      crestUrl: item.crestUrl,
      updatedAt: item.updatedAt,
    ),
  ];
}

/// Family provider that reactively computes the [TeamMatchSummary] for a given [teamId].
final teamMatchSummaryProvider = Provider.family<TeamMatchSummary, String>((
  ref,
  teamId,
) {
  final teams = _resolveEffectiveTeams(ref, teamId);
  final tournamentsState = ref.watch(tournamentsControllerProvider);
  final matchesState = ref.watch(matchesCatalogControllerProvider);

  return TeamMatchSummary.fromCatalog(
    teamId: teamId,
    teams: teams,
    tournaments: tournamentsState.tournaments,
    matches: matchesState.matches,
  );
});

/// Family provider that reactively computes the [TeamMatchesSchedule] for a given [teamId].
final teamMatchesScheduleProvider =
    Provider.family<TeamMatchesSchedule, String>((ref, teamId) {
      final teams = _resolveEffectiveTeams(ref, teamId);
      final matchesState = ref.watch(matchesCatalogControllerProvider);

      return TeamMatchesSchedule.fromCatalog(
        teamId: teamId,
        teams: teams,
        matches: matchesState.matches,
      );
    });

/// Family provider that reactively computes the [TeamSquadRoster] for a given [teamId].
final teamSquadRosterProvider = Provider.family<TeamSquadRoster, String>((
  ref,
  teamId,
) {
  final teams = _resolveEffectiveTeams(ref, teamId);

  return TeamSquadRoster.fromCatalog(teamId: teamId, teams: teams);
});

/// Provider that reactively filters teams belonging to the currently authenticated coach.
final coachTeamsProvider = Provider<List<TournamentTeam>>((ref) {
  final teamsState = ref.watch(teamsControllerProvider);
  final authState = ref.watch(authControllerProvider);
  final currentCoachId = authState.session?.user.id.trim();

  if (currentCoachId != null && currentCoachId.isNotEmpty) {
    return teamsState.teams
        .where((team) => team.coachId == currentCoachId)
        .toList();
  }

  return teamsState.teams
      .where((team) => team.coachId == 'coach-seed-1')
      .toList();
});
