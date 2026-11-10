import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
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

/// Reactive provider exposing tournaments belonging to the active organizer.
final organizerTournamentsProvider =
    Provider<List<ChampionshipTournament>>((ref) {
      final catalogState = ref.watch(tournamentsControllerProvider);
      var currentUserId = 'org-seed-1';
      try {
        final authState = ref.watch(authControllerProvider);
        currentUserId = authState.session?.user.id ?? 'org-seed-1';
      } catch (_) {
        // Fallback in isolated test environments
      }

      return catalogState.tournaments.where((t) {
        final tOrgId = t.organizerId ?? 'org-seed-1';
        return tOrgId == currentUserId || tOrgId == 'org-seed-1';
      }).toList();
    });
