import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/tournament_news_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournament_news_use_cases.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';

final tournamentNewsRepositoryProvider = Provider<TournamentNewsRepository>((
  ref,
) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final local = LocalTournamentNewsRepository(storage: storage, config: config);

  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestTournamentNewsRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
  );
  final hybrid = HybridTournamentNewsRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.tournamentNews,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

final publishTournamentNewsUseCaseProvider =
    Provider<PublishTournamentNewsUseCase>((ref) {
      final repo = ref.watch(tournamentNewsRepositoryProvider);
      final tournamentsRepo = ref.watch(tournamentsRepositoryProvider);
      return PublishTournamentNewsUseCase(
        newsRepository: repo,
        tournamentsRepository: tournamentsRepo,
      );
    });

final deleteTournamentNewsUseCaseProvider =
    Provider<DeleteTournamentNewsUseCase>((ref) {
      final repo = ref.watch(tournamentNewsRepositoryProvider);
      final tournamentsRepo = ref.watch(tournamentsRepositoryProvider);
      return DeleteTournamentNewsUseCase(
        newsRepository: repo,
        tournamentsRepository: tournamentsRepo,
      );
    });

final tournamentNewsControllerProvider =
    StateNotifierProvider<TournamentNewsController, TournamentNewsState>((ref) {
      final repo = ref.watch(tournamentNewsRepositoryProvider);
      final publishUseCase = ref.watch(publishTournamentNewsUseCaseProvider);
      final deleteUseCase = ref.watch(deleteTournamentNewsUseCaseProvider);

      return TournamentNewsController(
        newsRepository: repo,
        publishUseCase: publishUseCase,
        deleteUseCase: deleteUseCase,
      );
    });
