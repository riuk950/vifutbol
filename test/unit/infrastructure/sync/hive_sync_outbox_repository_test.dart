import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> store = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => store[key];

  @override
  Future<void> writeString(String key, String value) async {
    store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => store.clear();
}

SyncOutboxItem _makeItem({
  required String id,
  required String userId,
  required String entityId,
  required DateTime createdAt,
  SyncOutboxItemStatus status = SyncOutboxItemStatus.queued,
  Map<String, dynamic> payload = const {'name': 'Torneo'},
}) {
  return SyncOutboxItem(
    id: id,
    ownerUserId: userId,
    entityType: SyncOutboxEntityType.tournament,
    entityId: entityId,
    operation: SyncOutboxOperation.upsert,
    payloadJson: payload,
    displayTitle: 'Torneo Prueba',
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('HiveSyncOutboxRepository', () {
    test('persists across cold restart and returns strict FIFO order', () async {
      final storage = _InMemoryLocalStorage();
      final repo1 = HiveSyncOutboxRepository(storage: storage);

      final t2 = DateTime.utc(2026, 11, 11, 10, 2);
      final t1 = DateTime.utc(2026, 11, 11, 10, 1);
      final t3 = DateTime.utc(2026, 11, 11, 10, 3);

      await repo1.enqueue(
        _makeItem(id: 'o2', userId: 'u1', entityId: 'e2', createdAt: t2),
      );
      await repo1.enqueue(
        _makeItem(id: 'o1', userId: 'u1', entityId: 'e1', createdAt: t1),
      );
      await repo1.enqueue(
        _makeItem(id: 'o3', userId: 'u1', entityId: 'e3', createdAt: t3),
      );

      // Recreate repository on same underlying storage to simulate cold restart.
      final repo2 = HiveSyncOutboxRepository(storage: storage);
      final loaded = await repo2.loadItemsForUser('u1');

      expect(loaded.map((e) => e.id).toList(), ['o1', 'o2', 'o3']);
    });

    test('isolates queued and errored items strictly by ownerUserId', () async {
      final storage = _InMemoryLocalStorage();
      final repo = HiveSyncOutboxRepository(storage: storage);
      final now = DateTime.utc(2026, 11, 11, 11, 0);

      await repo.enqueue(
        _makeItem(id: 'a1', userId: 'org-A', entityId: 't1', createdAt: now),
      );
      await repo.enqueue(
        _makeItem(id: 'b1', userId: 'org-B', entityId: 't2', createdAt: now),
      );

      final listA = await repo.loadItemsForUser('org-A');
      final listB = await repo.loadItemsForUser('org-B');

      expect(listA.map((e) => e.id), ['a1']);
      expect(listB.map((e) => e.id), ['b1']);

      await repo.removeItem('a1');
      expect(await repo.loadItemsForUser('org-A'), isEmpty);
      expect((await repo.loadItemsForUser('org-B')).length, 1);
    });

    test(
      'coalesces pending writes for same target while preserving original createdAt',
      () async {
        final storage = _InMemoryLocalStorage();
        final repo = HiveSyncOutboxRepository(storage: storage);
        final t1 = DateTime.utc(2026, 11, 11, 12, 0);
        final t2 = DateTime.utc(2026, 11, 11, 12, 5);

        await repo.enqueue(
          _makeItem(
            id: 'first-id',
            userId: 'u1',
            entityId: 'team-1',
            createdAt: t1,
            payload: {'name': 'V1'},
          ),
        );
        await repo.enqueue(
          _makeItem(
            id: 'second-id',
            userId: 'u1',
            entityId: 'team-1',
            createdAt: t2,
            payload: {'name': 'V2'},
          ),
        );

        final loaded = await repo.loadItemsForUser('u1');
        expect(loaded.length, 1);
        expect(loaded.first.id, 'first-id');
        expect(loaded.first.createdAt, t1);
        expect(loaded.first.payloadJson['name'], 'V2');
      },
    );

    test(
      'strips sensitive token/password keys from serialized payloadJson (FR-010)',
      () async {
        final storage = _InMemoryLocalStorage();
        final repo = HiveSyncOutboxRepository(storage: storage);
        final now = DateTime.utc(2026, 11, 11, 13, 0);

        await repo.enqueue(
          _makeItem(
            id: 'sec-1',
            userId: 'u1',
            entityId: 'e1',
            createdAt: now,
            payload: {
              'name': 'Equipo Seguro',
              'access_token': 'secret-jwt-value',
              'password': 'my-password',
              'nested': {'authorization': 'Bearer xyz', 'city': 'Bogotá'},
            },
          ),
        );

        final loaded = await repo.loadItemsForUser('u1');
        final payload = loaded.first.payloadJson;
        expect(payload.containsKey('access_token'), isFalse);
        expect(payload.containsKey('password'), isFalse);
        expect(
          (payload['nested'] as Map<String, dynamic>).containsKey(
            'authorization',
          ),
          isFalse,
        );
        expect((payload['nested'] as Map<String, dynamic>)['city'], 'Bogotá');
      },
    );

    test('persists and reloads lastSyncedAt per userId', () async {
      final storage = _InMemoryLocalStorage();
      final repo = HiveSyncOutboxRepository(storage: storage);
      final ts = DateTime.utc(2026, 11, 11, 14, 30);

      expect(await repo.loadLastSyncedAt('u1'), isNull);
      await repo.saveLastSyncedAt('u1', ts);

      expect(await repo.loadLastSyncedAt('u1'), ts);
      expect(await repo.loadLastSyncedAt('u2'), isNull);
    });
  });
}
