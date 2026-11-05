# Contract: Fan Favorites and Match Alerts Repositories & Notification Service

**Feature**: Feed de Noticias, Marcadores en Tiempo Real y Alertas para Aficionados (HU 9.1)  
**Location**:
- `lib/domain/repositories/fan_favorites_repository.dart`
- `lib/domain/repositories/match_alerts_repository.dart`
- `lib/domain/services/notification_service.dart`

---

## 1. FanFavoritesRepository

```dart
abstract class FanFavoritesRepository {
  /// Loads all favorite teams saved by the user for a specific tournament.
  Future<List<FanFavoriteTeam>> loadFavoriteTeams(String userId, String tournamentId);

  /// Streams favorite teams for reactive UI badges.
  Stream<List<FanFavoriteTeam>> watchFavoriteTeams(String userId, String tournamentId);

  /// Adds or updates a team in the user's favorites list.
  Future<void> saveFavoriteTeam(FanFavoriteTeam favorite);

  /// Removes a team from favorites.
  Future<void> removeFavoriteTeam(String userId, String tournamentId, String teamId);

  /// Toggles favorite status: adds if not present, removes if already present.
  Future<bool> toggleFavoriteTeam(FanFavoriteTeam favorite);
}
```

---

## 2. MatchAlertsRepository

```dart
abstract class MatchAlertsRepository {
  /// Loads saved alerts for the user, ordered by timestamp descending.
  Future<List<MatchLiveAlert>> loadAlerts(String userId, {String? tournamentId});

  /// Streams alerts for updating the AppBar badge counter and tray.
  Stream<List<MatchLiveAlert>> watchAlerts(String userId, {String? tournamentId});

  /// Saves a new match or news alert.
  Future<void> saveAlert(MatchLiveAlert alert);

  /// Marks a specific alert as read (isRead = true).
  Future<void> markAsRead(String alertId);

  /// Marks all alerts as read for a given user.
  Future<void> markAllAsRead(String userId, {String? tournamentId});

  /// Clears all alerts for the user.
  Future<void> clearAlerts(String userId);
}
```

---

## 3. NotificationService

```dart
abstract class NotificationService {
  /// Checks whether system OS notifications are granted.
  Future<bool> isPermissionGranted();

  /// Requests notification permission from the OS; returns true if granted.
  /// If denied, fails silently and preserves fallback tray.
  Future<bool> requestPermission();

  /// Dispatches an alert to the system tray (if permitted) and always stores it in [MatchAlertsRepository].
  Future<void> dispatchAlert(MatchLiveAlert alert);
}
```
