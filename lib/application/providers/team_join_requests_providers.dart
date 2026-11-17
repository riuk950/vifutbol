import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/team_join_requests_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/use_cases/manage_team_join_requests_use_case.dart';
import 'package:vifutbol/domain/repositories/team_join_requests_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_team_join_requests_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_team_join_requests_repository.dart';

/// Provider exposing [TeamJoinRequestsRepository].
final teamJoinRequestsRepositoryProvider =
    Provider<TeamJoinRequestsRepository>((ref) {
      final storage = ref.watch(localStorageRepositoryProvider);
      final config = ref.watch(environmentConfigProvider);
      final local = LocalTeamJoinRequestsRepository(
        storage: storage,
        config: config,
      );

      final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
      final client = ref.watch(supabaseClientProvider);
      final connectivity = ref.watch(connectivityRepositoryProvider);

      if (!useRemote || client == null) {
        return local;
      }

      final remote = PostgrestTeamJoinRequestsRemoteDataSource(
        client: client,
        schema: config.supabase.schema,
      );

      return HybridTeamJoinRequestsRepository(
        local: local,
        remote: remote,
        connectivity: connectivity,
      );
    });

/// Provider exposing [ManageTeamJoinRequestsUseCase].
final manageTeamJoinRequestsUseCaseProvider =
    Provider<ManageTeamJoinRequestsUseCase>((ref) {
      final repository = ref.watch(teamJoinRequestsRepositoryProvider);
      final teamsRepo = ref.watch(teamsRepositoryProvider);

      return ManageTeamJoinRequestsUseCase(
        repository: repository,
        teamsRepository: teamsRepo,
      );
    });

/// StateNotifierProvider exposing [TeamJoinRequestsController].
final teamJoinRequestsControllerProvider =
    StateNotifierProvider<TeamJoinRequestsController, TeamJoinRequestsState>((
      ref,
    ) {
      final manageUseCase = ref.watch(manageTeamJoinRequestsUseCaseProvider);

      return TeamJoinRequestsController(manageUseCase: manageUseCase);
    });

/// Provider returning the number of pending team join requests for the current player.
final playerPendingRequestsCountProvider = Provider<int>((ref) {
  final state = ref.watch(teamJoinRequestsControllerProvider);
  return state.playerRequests.length;
});
