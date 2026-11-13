import 'package:uuid/uuid.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';

class ToggleFanFavoriteTeamUseCase {
  const ToggleFanFavoriteTeamUseCase({required this.favoritesRepository});

  final FanFavoritesRepository favoritesRepository;

  Future<bool> execute(FanFavoriteTeam favorite) async {
    return favoritesRepository.toggleFavoriteTeam(favorite);
  }
}

class DispatchMatchLiveAlertsUseCase {
  const DispatchMatchLiveAlertsUseCase({
    required this.favoritesRepository,
    required this.notificationService,
  });

  final FanFavoritesRepository favoritesRepository;
  final NotificationService notificationService;

  Future<void> dispatchMatchEventAlert({
    required String userId,
    required ChampionshipMatch match,
    required MatchAlertType eventType,
    required String title,
    required String message,
  }) async {
    final favorites = await favoritesRepository.loadFavoriteTeams(
      userId,
      match.tournamentId,
    );

    // Check if either participating team is marked as favorite with notifications enabled
    final isFavorite = favorites.any(
      (f) =>
          f.notificationsEnabled &&
          (f.teamId == match.homeTeamId || f.teamId == match.awayTeamId),
    );

    if (isFavorite) {
      final alert = MatchLiveAlert(
        id: const Uuid().v4(),
        matchId: match.id,
        tournamentId: match.tournamentId,
        type: eventType,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await notificationService.dispatchAlert(alert);
    }
  }
}
