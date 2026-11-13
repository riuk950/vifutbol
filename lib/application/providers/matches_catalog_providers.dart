import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';

/// Provider exposing the concrete [TournamentMatchesRepository].
final tournamentMatchesRepositoryProvider =
    Provider<TournamentMatchesRepository>((ref) {
      final storage = ref.watch(localStorageRepositoryProvider);
      final config = ref.watch(environmentConfigProvider);
      final local = LocalTournamentMatchesRepository(
        storage: storage,
        config: config,
      );

      final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
      final client = ref.watch(supabaseClientProvider);
      if (!useRemote || client == null) {
        return local;
      }

      final support = ref.watch(hybridRepositorySupportProvider);
      final remote = PostgrestTournamentMatchesRemoteDataSource(
        client: client,
        schema: config.supabase.schema,
      );
      final hybrid = HybridTournamentMatchesRepository(
        local: local,
        remote: remote,
        support: support,
      );
      ref
          .read(supabaseCloudSyncServiceProvider)
          .registerHandler(SyncOutboxEntityType.match, hybrid.replayOutboxItem);
      return hybrid;
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

/// Provider exposing [DailyMatchesFeedController].
final dailyMatchesFeedControllerProvider =
    StateNotifierProvider<DailyMatchesFeedController, DailyMatchesFeedState>((
      ref,
    ) {
      return DailyMatchesFeedController(ref);
    });

/// Provider exposing whether the Calendar action in AppBar should be visible.
final isMatchdayCalendarActionVisibleProvider = Provider<bool>((ref) {
  final shellState = ref.watch(appShellControllerProvider);
  return shellState.activeSection == AppShellSection.matchday;
});
