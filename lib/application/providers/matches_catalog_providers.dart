import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';

/// Provider exposing the concrete [TournamentMatchesRepository].
final tournamentMatchesRepositoryProvider =
    Provider<TournamentMatchesRepository>((ref) {
      final storage = ref.watch(localStorageRepositoryProvider);
      final config = ref.watch(environmentConfigProvider);

      return LocalTournamentMatchesRepository(storage: storage, config: config);
    });

/// Provider exposing [FixtureSchedulingUseCase].
final fixtureSchedulingUseCaseProvider = Provider<FixtureSchedulingUseCase>((
  ref,
) {
  final repository = ref.watch(tournamentMatchesRepositoryProvider);
  return FixtureSchedulingUseCase(matchesRepository: repository);
});

/// StateNotifierProvider exposing the central [MatchesCatalogController].
final matchesCatalogControllerProvider =
    StateNotifierProvider<MatchesCatalogController, MatchesCatalogState>((ref) {
      final repository = ref.watch(tournamentMatchesRepositoryProvider);
      final useCase = ref.watch(fixtureSchedulingUseCaseProvider);

      return MatchesCatalogController(
        matchesRepository: repository,
        fixtureSchedulingUseCase: useCase,
      );
    });
