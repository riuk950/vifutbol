import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/fan_favorites_and_alerts_use_cases.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/services/local_notification_service.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('Fan Favorites and Match Alerts Use Cases', () {
    late _InMemoryLocalStorage storage;
    late LocalFanFavoritesRepository favoritesRepo;
    late LocalMatchAlertsRepository alertsRepo;
    late LocalNotificationService notifService;
    late ToggleFanFavoriteTeamUseCase toggleUseCase;
    late DispatchMatchLiveAlertsUseCase dispatchUseCase;

    setUp(() {
      storage = _InMemoryLocalStorage();
      favoritesRepo = LocalFanFavoritesRepository(storage: storage);
      alertsRepo = LocalMatchAlertsRepository(storage: storage);
      notifService = LocalNotificationService(
        storage: storage,
        alertsRepository: alertsRepo,
      );
      toggleUseCase = ToggleFanFavoriteTeamUseCase(
        favoritesRepository: favoritesRepo,
      );
      dispatchUseCase = DispatchMatchLiveAlertsUseCase(
        favoritesRepository: favoritesRepo,
        notificationService: notifService,
      );
    });

    final favoriteTeam = FanFavoriteTeam(
      userId: 'user-fan-1',
      tournamentId: 'tournament-clausura',
      teamId: 'team-alpha',
      teamName: 'Alpha FC',
      notificationsEnabled: true,
      createdAt: DateTime(2026, 11, 5, 8, 0),
    );

    test(
      'toggles favorite team: adds on first call, removes on second call',
      () async {
        // First toggle: adds
        final added = await toggleUseCase.execute(favoriteTeam);
        expect(added, isTrue);

        var favorites = await favoritesRepo.loadFavoriteTeams(
          'user-fan-1',
          'tournament-clausura',
        );
        expect(favorites.length, 1);
        expect(favorites.first.teamName, 'Alpha FC');

        // Second toggle: removes
        final removed = await toggleUseCase.execute(favoriteTeam);
        expect(removed, isFalse);

        favorites = await favoritesRepo.loadFavoriteTeams(
          'user-fan-1',
          'tournament-clausura',
        );
        expect(favorites, isEmpty);
      },
    );

    test('dispatches alert when match involves a favorite team', () async {
      await toggleUseCase.execute(favoriteTeam);

      final match = ChampionshipMatch(
        id: 'match-101',
        tournamentId: 'tournament-clausura',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-alpha',
        awayTeamId: 'team-beta',
        status: MatchStatus.inProgress,
        homeScore: 1,
        awayScore: 0,
      );

      await dispatchUseCase.dispatchMatchEventAlert(
        userId: 'user-fan-1',
        match: match,
        eventType: MatchAlertType.goalScored,
        title: '¡Gol de Alpha FC!',
        message: 'Gol de Alpha FC al minuto 25.',
      );

      final alerts = await alertsRepo.loadAlerts('user-fan-1');
      expect(alerts.length, 1);
      expect(alerts.first.title, '¡Gol de Alpha FC!');
      expect(alerts.first.isRead, isFalse);

      // Mark as read
      await alertsRepo.markAsRead(alerts.first.id);
      final updatedAlerts = await alertsRepo.loadAlerts('user-fan-1');
      expect(updatedAlerts.first.isRead, isTrue);
    });

    test('does not dispatch alert if neither team is a favorite', () async {
      await toggleUseCase.execute(favoriteTeam);

      final matchNonFavorite = ChampionshipMatch(
        id: 'match-102',
        tournamentId: 'tournament-clausura',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-gamma',
        awayTeamId: 'team-delta',
        status: MatchStatus.inProgress,
      );

      await dispatchUseCase.dispatchMatchEventAlert(
        userId: 'user-fan-1',
        match: matchNonFavorite,
        eventType: MatchAlertType.goalScored,
        title: '¡Gol!',
        message: 'Gol de Gamma.',
      );

      final alerts = await alertsRepo.loadAlerts('user-fan-1');
      expect(alerts, isEmpty);
    });
  });
}
