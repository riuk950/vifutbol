import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/supabase_cloud_sync_service.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> _store = <String, String>{};

  @override
  bool get isUsingFallbackMemory => true;

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
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  NetworkConnectionStatus status = NetworkConnectionStatus.connected;
  final StreamController<NetworkConnectionStatus> _controller =
      StreamController<NetworkConnectionStatus>.broadcast();

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => status;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      _controller.stream;
}

void main() {
  group('SupabaseCloudSyncService dependency ordering', () {
    late _InMemoryLocalStorage storage;
    late _FakeConnectivityRepository connectivity;
    late HiveSyncOutboxRepository outbox;
    late SupabaseCloudSyncService service;

    setUp(() {
      storage = _InMemoryLocalStorage();
      connectivity = _FakeConnectivityRepository();
      connectivity.status = NetworkConnectionStatus.disconnected;
      outbox = HiveSyncOutboxRepository(storage: storage);
      service = SupabaseCloudSyncService(
        outboxRepository: outbox,
        connectivityRepository: connectivity,
      );
      service.setActiveUser('user-1');
    });

    test('dependencyPriority enforces strict FK parent-before-child tiers', () {
      expect(
        SupabaseCloudSyncService.dependencyPriority(
          SyncOutboxEntityType.venue,
        ),
        lessThan(
          SupabaseCloudSyncService.dependencyPriority(
            SyncOutboxEntityType.tournament,
          ),
        ),
      );
      expect(
        SupabaseCloudSyncService.dependencyPriority(
          SyncOutboxEntityType.tournament,
        ),
        lessThan(
          SupabaseCloudSyncService.dependencyPriority(SyncOutboxEntityType.team),
        ),
      );
      expect(
        SupabaseCloudSyncService.dependencyPriority(SyncOutboxEntityType.team),
        lessThan(
          SupabaseCloudSyncService.dependencyPriority(
            SyncOutboxEntityType.match,
          ),
        ),
      );
      expect(
        SupabaseCloudSyncService.dependencyPriority(SyncOutboxEntityType.match),
        lessThan(
          SupabaseCloudSyncService.dependencyPriority(
            SyncOutboxEntityType.matchReport,
          ),
        ),
      );
      expect(
        SupabaseCloudSyncService.dependencyPriority(
          SyncOutboxEntityType.matchReport,
        ),
        lessThan(
          SupabaseCloudSyncService.dependencyPriority(
            SyncOutboxEntityType.seasonHonorRoll,
          ),
        ),
      );
    });

    test(
      'flushOutbox replays reverse-queued mixed mutations in strict FK order with FIFO tie-breaking',
      () async {
        final dispatchOrder = <String>[];
        for (final type in SyncOutboxEntityType.values) {
          service.registerHandler(type, (item) async {
            dispatchOrder.add('${item.entityType.name}:${item.entityId}');
          });
        }

        // Enqueue deliberately in reverse dependency order
        final baseTime = DateTime.utc(2026, 11, 19, 10, 0);
        final items = [
          SyncOutboxItem(
            id: 'i-1',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.seasonHonorRoll,
            entityId: 'hr-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Honor Roll',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime,
            updatedAt: baseTime,
          ),
          SyncOutboxItem(
            id: 'i-2',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.matchReport,
            entityId: 'mr-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Match Report',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 1)),
            updatedAt: baseTime.add(const Duration(seconds: 1)),
          ),
          SyncOutboxItem(
            id: 'i-3',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.match,
            entityId: 'm-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Match',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 2)),
            updatedAt: baseTime.add(const Duration(seconds: 2)),
          ),
          SyncOutboxItem(
            id: 'i-4',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.team,
            entityId: 'team-2',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Team 2',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 3)),
            updatedAt: baseTime.add(const Duration(seconds: 3)),
          ),
          SyncOutboxItem(
            id: 'i-5',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.team,
            entityId: 'team-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Team 1',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 2)),
            updatedAt: baseTime.add(const Duration(seconds: 2)),
          ),
          SyncOutboxItem(
            id: 'i-6',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.tournament,
            entityId: 't-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Tournament',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 5)),
            updatedAt: baseTime.add(const Duration(seconds: 5)),
          ),
          SyncOutboxItem(
            id: 'i-7',
            ownerUserId: 'user-1',
            entityType: SyncOutboxEntityType.venue,
            entityId: 'v-1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Venue',
            status: SyncOutboxItemStatus.queued,
            createdAt: baseTime.add(const Duration(seconds: 6)),
            updatedAt: baseTime.add(const Duration(seconds: 6)),
          ),
        ];

        for (final item in items) {
          await outbox.enqueue(item);
        }

        connectivity.status = NetworkConnectionStatus.connected;
        final result = await service.flushOutbox(userId: 'user-1');
        expect(result.syncedCount, 7);
        expect(result.remainingPendingCount, 0);
        expect(dispatchOrder, const [
          'venue:v-1',
          'tournament:t-1',
          'team:team-1',
          'team:team-2',
          'match:m-1',
          'matchReport:mr-1',
          'seasonHonorRoll:hr-1',
        ]);
      },
    );
  });
}
