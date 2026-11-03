import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

/// Provider exposing the concrete [TournamentsRepository] implementation.
final tournamentsRepositoryProvider = Provider<TournamentsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);

  return LocalTournamentsRepository(storage: storage, config: config);
});

/// Provider exposing [ManageTournamentsUseCase].
final manageTournamentsUseCaseProvider = Provider<ManageTournamentsUseCase>((
  ref,
) {
  final repository = ref.watch(tournamentsRepositoryProvider);
  return ManageTournamentsUseCase(repository);
});

/// StateNotifierProvider exposing the central [TournamentsController].
final tournamentsControllerProvider =
    StateNotifierProvider<TournamentsController, TournamentsCatalogState>((
      ref,
    ) {
      final repository = ref.watch(tournamentsRepositoryProvider);
      final manageUseCase = ref.watch(manageTournamentsUseCaseProvider);

      return TournamentsController(
        tournamentsRepository: repository,
        manageTournamentsUseCase: manageUseCase,
      );
    });
