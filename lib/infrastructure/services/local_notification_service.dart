import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';
import 'package:vifutbol/domain/services/notification_service.dart';

class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    required this.storage,
    required this.alertsRepository,
  });

  final LocalStorageRepository storage;
  final MatchAlertsRepository alertsRepository;

  static const String permissionStorageKey =
      'vifutbol.notifications_permission.v1';

  @override
  Future<bool> isPermissionGranted() async {
    try {
      final dynamic future = storage.readString(permissionStorageKey);
      final val = future is Future ? await future : null;
      return val == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    // In local/mock service, grants permission and records status.
    await storage.writeString(permissionStorageKey, 'granted');
    return true;
  }

  Future<void> revokePermission() async {
    await storage.writeString(permissionStorageKey, 'denied');
  }

  @override
  Future<void> dispatchAlert(MatchLiveAlert alert) async {
    // 1. Always persist in the internal alerts repository (guarantees in-app tray access)
    await alertsRepository.saveAlert(alert);

    // 2. If OS push permissions are granted, dispatch to system (simulated locally without crash)
    final hasPermission = await isPermissionGranted();
    if (hasPermission) {
      // System dispatch simulated gracefully
    }
  }
}
