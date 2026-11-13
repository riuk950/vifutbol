import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/supabase_cloud_sync_service.dart';

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

class _ControllableConnectivity implements ConnectivityRepository {
  _ControllableConnectivity([
    this._current = NetworkConnectionStatus.disconnected,
  ]);

  NetworkConnectionStatus _current;
  final StreamController<NetworkConnectionStatus> _controller =
      StreamController<NetworkConnectionStatus>.broadcast();

  void emit(NetworkConnectionStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => _current;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      _controller.stream;

  Future<void> dispose() => _controller.close();
}

SyncOutboxItem _item(String id, DateTime at, {String userId = 'u1'}) {
  return SyncOutboxItem(
    id: id,
    ownerUserId: userId,
    entityType: SyncOutboxEntityType.team,
    entityId: 'entity-$id',
    operation: SyncOutboxOperation.upsert,
    payloadJson: {'id': 'entity-$id'},
    displayTitle: 'Equipo $id',
    status: SyncOutboxItemStatus.queued,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('SupabaseCloudSyncService', () {
    test(
      'executes FIFO single-flight flush without duplicate concurrent runs',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _ControllableConnectivity(
          NetworkConnectionStatus.connected,
        );
        final now = DateTime.utc(2026, 11, 11, 15, 0);
        final service = SupabaseCloudSyncService(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
          clock: Clock.fixed(now),
        );

        await outbox.enqueue(_item('1', now));
        await outbox.enqueue(_item('2', now.add(const Duration(seconds: 1))));

        final processedOrder = <String>[];
        service.registerHandler(SyncOutboxEntityType.team, (item) async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          processedOrder.add(item.id);
        });

        final results = await Future.wait([
          service.flushOutbox(userId: 'u1'),
          service.flushOutbox(userId: 'u1'),
          service.flushOutbox(userId: 'u1'),
        ]);

        expect(processedOrder, ['1', '2']);
        expect(results.first.syncedCount, 2);
        expect(await outbox.loadItemsForUser('u1'), isEmpty);

        await service.dispose();
        await connectivity.dispose();
      },
    );

    test(
      'marks only 4xx rejected item as error and continues flushing valid FIFO items (Q2) with credential redaction (FR-010)',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _ControllableConnectivity(
          NetworkConnectionStatus.connected,
        );
        final now = DateTime.utc(2026, 11, 11, 15, 0);
        final service = SupabaseCloudSyncService(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
          clock: Clock.fixed(now),
        );

        await outbox.enqueue(_item('1', now));
        await outbox.enqueue(_item('2', now.add(const Duration(seconds: 1))));
        await outbox.enqueue(_item('3', now.add(const Duration(seconds: 2))));

        final syncedIds = <String>[];
        service.registerHandler(SyncOutboxEntityType.team, (item) async {
          if (item.id == '2') {
            throw const PostgrestException(
              message:
                  'RLS denied with Bearer eyJhbGciOiJIUzI1NiJ9.abc.def password=secret',
              code: '42501',
            );
          }
          syncedIds.add(item.id);
        });

        final result = await service.flushOutbox(userId: 'u1');

        expect(syncedIds, ['1', '3']);
        expect(result.syncedCount, 2);
        expect(result.errorCount, 1);
        expect(result.remainingPendingCount, 0);

        final remaining = await outbox.loadItemsForUser('u1');
        expect(remaining.length, 1);
        expect(remaining.first.id, '2');
        expect(remaining.first.status, SyncOutboxItemStatus.error);
        expect(remaining.first.errorCode, SyncErrorCode.permissionDenied);
        expect(remaining.first.errorMessage, isNot(contains('eyJ')));
        expect(remaining.first.errorMessage, isNot(contains('secret')));

        await service.dispose();
        await connectivity.dispose();
      },
    );

    test(
      'aborts FIFO loop cleanly on transient SocketException preserving retrying item order',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _ControllableConnectivity(
          NetworkConnectionStatus.connected,
        );
        final now = DateTime.utc(2026, 11, 11, 15, 0);
        final service = SupabaseCloudSyncService(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
          clock: Clock.fixed(now),
        );

        await outbox.enqueue(_item('1', now));
        await outbox.enqueue(_item('2', now.add(const Duration(seconds: 1))));

        var calls = 0;
        service.registerHandler(SyncOutboxEntityType.team, (item) async {
          calls++;
          if (item.id == '1') {
            throw const SocketException('Network down');
          }
        });

        final result = await service.flushOutbox(userId: 'u1');
        expect(calls, 1);
        expect(result.abortedDueToNetwork, isTrue);
        expect(result.remainingPendingCount, 2);

        final remaining = await outbox.loadItemsForUser('u1');
        expect(remaining.first.status, SyncOutboxItemStatus.retrying);
        expect(remaining.first.retryCount, 1);
        expect(remaining.last.status, SyncOutboxItemStatus.queued);

        await service.dispose();
        await connectivity.dispose();
      },
    );

    test(
      'triggers flush when active user binds while already connected (E1) and supports retry/discard',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _ControllableConnectivity(
          NetworkConnectionStatus.connected,
        );
        final now = DateTime.utc(2026, 11, 11, 15, 0);
        final service = SupabaseCloudSyncService(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
          clock: Clock.fixed(now),
        );

        await outbox.enqueue(_item('1', now, userId: 'org-1'));
        var shouldFail = false;
        final synced = <String>[];
        service.registerHandler(SyncOutboxEntityType.team, (item) async {
          if (shouldFail) {
            throw const PostgrestException(message: 'Bad input', code: '400');
          }
          synced.add(item.id);
        });

        service.setActiveUser('org-1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(synced, ['1']);
        expect(await outbox.loadItemsForUser('org-1'), isEmpty);

        // Enqueue an error item then retry and discard.
        shouldFail = true;
        await outbox.enqueue(_item('err-1', now, userId: 'org-1'));
        await service.flushOutbox(userId: 'org-1');
        expect(
          (await outbox.loadItemsForUser('org-1')).first.status,
          SyncOutboxItemStatus.error,
        );

        shouldFail = false;
        await service.retryErroredItem(userId: 'org-1', itemId: 'err-1');
        expect(await outbox.loadItemsForUser('org-1'), isEmpty);

        await outbox.enqueue(_item('disc-1', now, userId: 'org-1'));
        await service.discardItem(userId: 'org-1', itemId: 'disc-1');
        expect(await outbox.loadItemsForUser('org-1'), isEmpty);

        await service.dispose();
        await connectivity.dispose();
      },
    );
  });
}
