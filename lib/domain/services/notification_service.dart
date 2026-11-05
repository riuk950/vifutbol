import '../entities/match_live_alert.dart';

abstract class NotificationService {
  /// Checks whether system OS notifications are granted.
  Future<bool> isPermissionGranted();

  /// Requests notification permission from the OS; returns true if granted.
  /// If denied, fails silently and preserves fallback internal tray.
  Future<bool> requestPermission();

  /// Dispatches an alert to the system tray (if permitted) and always stores it in the internal alert repository.
  Future<void> dispatchAlert(MatchLiveAlert alert);
}
