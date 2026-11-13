import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/fan_alerts_and_favorites_controllers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/use_cases/fan_favorites_and_alerts_use_cases.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/services/local_notification_service.dart';

final fanFavoritesRepositoryProvider = Provider<FanFavoritesRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final local = LocalFanFavoritesRepository(storage: storage);

  final config = ref.watch(environmentConfigProvider);
  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestFanFavoritesRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
    support: support,
  );
  final hybrid = HybridFanFavoritesRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.fanFavorite,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

final matchAlertsRepositoryProvider = Provider<MatchAlertsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final local = LocalMatchAlertsRepository(storage: storage);

  final config = ref.watch(environmentConfigProvider);
  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestMatchAlertsRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
  );
  final hybrid = HybridMatchAlertsRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.matchAlert,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final alertsRepo = ref.watch(matchAlertsRepositoryProvider);
  return LocalNotificationService(
    storage: storage,
    alertsRepository: alertsRepo,
  );
});

final toggleFanFavoriteTeamUseCaseProvider =
    Provider<ToggleFanFavoriteTeamUseCase>((ref) {
      final repo = ref.watch(fanFavoritesRepositoryProvider);
      return ToggleFanFavoriteTeamUseCase(favoritesRepository: repo);
    });

final dispatchMatchLiveAlertsUseCaseProvider =
    Provider<DispatchMatchLiveAlertsUseCase>((ref) {
      final favRepo = ref.watch(fanFavoritesRepositoryProvider);
      final notifService = ref.watch(notificationServiceProvider);
      return DispatchMatchLiveAlertsUseCase(
        favoritesRepository: favRepo,
        notificationService: notifService,
      );
    });

final fanFavoritesControllerProvider =
    StateNotifierProvider<FanFavoritesController, FanFavoritesState>((ref) {
      final repo = ref.watch(fanFavoritesRepositoryProvider);
      final toggleUseCase = ref.watch(toggleFanFavoriteTeamUseCaseProvider);

      return FanFavoritesController(
        favoritesRepository: repo,
        toggleUseCase: toggleUseCase,
      );
    });

final fanAlertsTrayControllerProvider =
    StateNotifierProvider<FanAlertsTrayController, FanAlertsTrayState>((ref) {
      final alertsRepo = ref.watch(matchAlertsRepositoryProvider);
      final notifService = ref.watch(notificationServiceProvider);

      return FanAlertsTrayController(
        alertsRepository: alertsRepo,
        notificationService: notifService,
      );
    });
