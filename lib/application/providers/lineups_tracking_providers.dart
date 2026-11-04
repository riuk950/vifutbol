import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/lineups_tracking_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/manage_lineups_tracking_use_case.dart';
import 'package:vifutbol/domain/entities/team_lineups_tracking_state.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';

/// Provider for [LineupsTrackingRepository].
final lineupsTrackingRepositoryProvider = Provider<LineupsTrackingRepository>((
  ref,
) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  return LocalLineupsTrackingRepository(storage: storage, config: config);
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
