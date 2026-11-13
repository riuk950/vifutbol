import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/lineups_tracking_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/use_cases/manage_lineups_tracking_use_case.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/team_lineups_tracking_state.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';

/// Provider for [LineupsTrackingRepository].
final lineupsTrackingRepositoryProvider = Provider<LineupsTrackingRepository>((
  ref,
) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final local = LocalLineupsTrackingRepository(
    storage: storage,
    config: config,
  );

  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestLineupsTrackingRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
    support: support,
  );
  final hybrid = HybridLineupsTrackingRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.lineupTracking,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

/// Provider for [ManageLineupsTrackingUseCase].
final manageLineupsTrackingUseCaseProvider =
    Provider<ManageLineupsTrackingUseCase>((ref) {
      final repository = ref.watch(lineupsTrackingRepositoryProvider);
      return ManageLineupsTrackingUseCase(repository);
    });

/// Provider for [LineupsTrackingController].
final lineupsTrackingControllerProvider =
    StateNotifierProvider<LineupsTrackingController, TeamLineupsTrackingState>((
      ref,
    ) {
      final repository = ref.watch(lineupsTrackingRepositoryProvider);
      final useCase = ref.watch(manageLineupsTrackingUseCaseProvider);
      return LineupsTrackingController(
        repository: repository,
        manageLineupsTrackingUseCase: useCase,
      );
    });
