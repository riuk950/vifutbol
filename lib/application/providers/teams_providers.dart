import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';

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
      return ManageTeamsEligibilityUseCase(repository);
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
