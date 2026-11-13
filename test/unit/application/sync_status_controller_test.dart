import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/sync_status_controller.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> store = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => store[key];

  @override
  Future<void> writeString(String key, String value) async {
    store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => store.clear();
}

class _FakeConnectivity implements ConnectivityRepository {
  _FakeConnectivity([this._status = NetworkConnectionStatus.connected]);
  NetworkConnectionStatus _status;
  final _ctrl = StreamController<NetworkConnectionStatus>.broadcast();

  void setStatus(NetworkConnectionStatus status) {
    _status = status;
    _ctrl.add(status);
  }

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => _status;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged => _ctrl.stream;

  Future<void> dispose() => _ctrl.close();
}

class _FakeCloudSyncService implements CloudSyncService {
  final _syncingCtrl = StreamController<bool>.broadcast();
  String? lastBoundUser;
  int flushCalls = 0;

  void setSyncing(bool syncing) => _syncingCtrl.add(syncing);

  @override
  Future<void> discardItem({
    required String userId,
    required String itemId,
  }) async {}

  @override
  Future<SyncFlushResult> flushOutbox({required String userId}) async {
    flushCalls++;
    return const SyncFlushResult(
      syncedCount: 0,
      remainingPendingCount: 0,
      errorCount: 0,
    );
  }

  @override
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  }) async {
    return const SyncFlushResult(
      syncedCount: 0,
      remainingPendingCount: 0,
      errorCount: 0,
    );
  }

  @override
  void setActiveUser(String? userId) {
    lastBoundUser = userId;
  }

  @override
  Stream<bool> watchIsSyncing() => _syncingCtrl.stream;

  Future<void> dispose() => _syncingCtrl.close();
}

void main() {
  group('SyncStatusController', () {
    test(
      'computes synced, pending, syncing, and offlineOrError states',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _FakeConnectivity(
          NetworkConnectionStatus.connected,
        );
        final syncService = _FakeCloudSyncService();

        final controller = SyncStatusController(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
          cloudSyncService: syncService,
        );

        await controller.bindUser(userId: 'org-1', isGuestFan: false);
        expect(controller.state.status, SyncStatus.synced);
        expect(controller.state.pendingCount, 0);

        final now = DateTime.utc(2026, 11, 11, 16, 0);
        await outbox.enqueue(
          SyncOutboxItem(
            id: 'item-1',
            ownerUserId: 'org-1',
            entityType: SyncOutboxEntityType.match,
            entityId: 'm1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Partido',
            status: SyncOutboxItemStatus.queued,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.status, SyncStatus.pending);
        expect(controller.state.pendingCount, 1);
        expect(controller.state.totalAttentionCount, 1);

        syncService.setSyncing(true);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.status, SyncStatus.syncing);

        syncService.setSyncing(false);
        connectivity.setStatus(NetworkConnectionStatus.disconnected);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.status, SyncStatus.offlineOrError);

        connectivity.setStatus(NetworkConnectionStatus.connected);
        await outbox.updateItem(
          SyncOutboxItem(
            id: 'item-1',
            ownerUserId: 'org-1',
            entityType: SyncOutboxEntityType.match,
            entityId: 'm1',
            operation: SyncOutboxOperation.upsert,
            payloadJson: const {},
            displayTitle: 'Partido',
            status: SyncOutboxItemStatus.error,
            errorCode: SyncErrorCode.permissionDenied,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.status, SyncStatus.offlineOrError);
        expect(controller.state.errorCount, 1);

        // Guest fan clears visible user scope without deleting org-1 items.
        await controller.bindUser(userId: 'guest-1', isGuestFan: true);
        expect(controller.state.pendingCount, 0);
        expect(controller.state.errorCount, 0);
        expect((await outbox.loadItemsForUser('org-1')).length, 1);

        controller.dispose();
        await connectivity.dispose();
        await syncService.dispose();
      },
    );
  });
}
