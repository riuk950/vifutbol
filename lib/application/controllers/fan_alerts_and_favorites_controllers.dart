import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/fan_favorites_and_alerts_use_cases.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';

// --- Favorites ---

class FanFavoritesState {
  final List<FanFavoriteTeam> favorites;
  final bool isLoading;

  const FanFavoritesState({this.favorites = const [], this.isLoading = false});

  bool isFavorite(String teamId) {
    return favorites.any((f) => f.teamId == teamId);
  }

  FanFavoritesState copyWith({
    List<FanFavoriteTeam>? favorites,
    bool? isLoading,
  }) {
    return FanFavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FanFavoritesController extends StateNotifier<FanFavoritesState> {
  FanFavoritesController({
    required this.favoritesRepository,
    required this.toggleUseCase,
  }) : super(const FanFavoritesState());

  final FanFavoritesRepository favoritesRepository;
  final ToggleFanFavoriteTeamUseCase toggleUseCase;

  StreamSubscription<List<FanFavoriteTeam>>? _subscription;

  Future<void> loadFavorites(String userId, String tournamentId) async {
    state = state.copyWith(isLoading: true);
    await _subscription?.cancel();

    _subscription = favoritesRepository
        .watchFavoriteTeams(userId, tournamentId)
        .listen((favorites) {
          state = state.copyWith(favorites: favorites, isLoading: false);
        });
  }

  Future<bool> toggleFavorite(FanFavoriteTeam team) async {
    return toggleUseCase.execute(team);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// --- Alerts Tray ---

class FanAlertsTrayState {
  final List<MatchLiveAlert> alerts;
  final bool isLoading;
  final bool isPermissionGranted;

  const FanAlertsTrayState({
    this.alerts = const [],
    this.isLoading = false,
    this.isPermissionGranted = true,
  });

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  FanAlertsTrayState copyWith({
    List<MatchLiveAlert>? alerts,
    bool? isLoading,
    bool? isPermissionGranted,
  }) {
    return FanAlertsTrayState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
    );
  }
}

class FanAlertsTrayController extends StateNotifier<FanAlertsTrayState> {
  FanAlertsTrayController({
    required this.alertsRepository,
    required this.notificationService,
  }) : super(const FanAlertsTrayState());

  final MatchAlertsRepository alertsRepository;
  final NotificationService notificationService;

  StreamSubscription<List<MatchLiveAlert>>? _subscription;

  Future<void> init(String userId, {String? tournamentId}) async {
    state = state.copyWith(isLoading: true);
    final hasPermission = await notificationService.isPermissionGranted();
    state = state.copyWith(isPermissionGranted: hasPermission);

    await _subscription?.cancel();
    _subscription = alertsRepository
        .watchAlerts(userId, tournamentId: tournamentId)
        .listen((alerts) {
          state = state.copyWith(alerts: alerts, isLoading: false);
        });
  }

  Future<void> markAsRead(String alertId) async {
    await alertsRepository.markAsRead(alertId);
  }

  Future<void> markAllAsRead(String userId, {String? tournamentId}) async {
    await alertsRepository.markAllAsRead(userId, tournamentId: tournamentId);
  }

  Future<void> requestSystemPermission() async {
    final granted = await notificationService.requestPermission();
    state = state.copyWith(isPermissionGranted: granted);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
