import '../entities/match_live_alert.dart';

abstract class MatchAlertsRepository {
  /// Loads saved alerts for the user, ordered by timestamp descending.
  Future<List<MatchLiveAlert>> loadAlerts(
    String userId, {
    String? tournamentId,
  });

  /// Streams alerts for updating the AppBar badge counter and tray.
  Stream<List<MatchLiveAlert>> watchAlerts(
    String userId, {
    String? tournamentId,
  });

  /// Saves a new match or news alert.
  Future<void> saveAlert(MatchLiveAlert alert);

  /// Marks a specific alert as read (isRead = true).
  Future<void> markAsRead(String alertId);

  /// Marks all alerts as read for a given user.
  Future<void> markAllAsRead(String userId, {String? tournamentId});

  /// Clears all alerts for the user.
  Future<void> clearAlerts(String userId);
}
