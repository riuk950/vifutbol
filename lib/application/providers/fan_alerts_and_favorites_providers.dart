import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/fan_alerts_and_favorites_controllers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/fan_favorites_and_alerts_use_cases.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';
import 'package:vifutbol/infrastructure/repositories/local_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/services/local_notification_service.dart';

final fanFavoritesRepositoryProvider = Provider<FanFavoritesRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  return LocalFanFavoritesRepository(storage: storage);
});

final matchAlertsRepositoryProvider = Provider<MatchAlertsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  return LocalMatchAlertsRepository(storage: storage);
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
