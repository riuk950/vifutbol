import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';

class _InMemoryLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      const LocalStorageStatus(isPersistent: false, storageNamespace: 'test');

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async =>
      _store[key] = value;
}

void main() {
  late _InMemoryLocalStorageRepository storage;
  late LocalMatchAlertsRepository repo;

  final now = DateTime(2026, 11, 25, 15, 0);

  setUp(() {
    storage = _InMemoryLocalStorageRepository();
    repo = LocalMatchAlertsRepository(storage: storage);
  });

  group('LocalMatchAlertsRepository - HU 26.2 user isolation', () {
    test('isolates targeted alerts per recipientUserId while keeping global alerts visible', () async {
      final alertForA = MatchLiveAlert(
        id: 'a-1',
        matchId: 'm-1',
        tournamentId: 't-1',
        type: MatchAlertType.refereeMatchAssigned,
        title: 'Nuevo partido asignado',
        message: 'Local vs Visitante',
        timestamp: now,
        recipientUserId: 'user-a',
      );
      final alertForB = MatchLiveAlert(
        id: 'a-2',
        matchId: 'm-2',
        tournamentId: 't-1',
        type: MatchAlertType.refereeMatchAssigned,
        title: 'Nuevo partido asignado',
        message: 'Equipo X vs Equipo Y',
        timestamp: now.add(const Duration(minutes: 1)),
        recipientUserId: 'user-b',
      );
      final globalAlert = MatchLiveAlert(
        id: 'g-1',
        matchId: 'm-3',
        tournamentId: 't-1',
        type: MatchAlertType.matchStarted,
        title: 'Inicio de partido',
        message: 'Comenzó el encuentro',
        timestamp: now.add(const Duration(minutes: 2)),
      );

      await repo.saveAlert(alertForA);
      await repo.saveAlert(alertForB);
      await repo.saveAlert(globalAlert);

      final userAAlerts = await repo.loadAlerts('user-a');
      final userBAlerts = await repo.loadAlerts('user-b');

      expect(userAAlerts.map((a) => a.id), ['g-1', 'a-1']);
      expect(userBAlerts.map((a) => a.id), ['g-1', 'a-2']);

      // markAllAsRead for user-a must NOT mark user-b's alert as read
      await repo.markAllAsRead('user-a');
      final afterUserA = await repo.loadAlerts('user-a');
      final afterUserB = await repo.loadAlerts('user-b');

      expect(afterUserA.every((a) => a.isRead), isTrue);
      expect(
        afterUserB.firstWhere((a) => a.id == 'a-2').isRead,
        isFalse,
      );
    });
  });
}
