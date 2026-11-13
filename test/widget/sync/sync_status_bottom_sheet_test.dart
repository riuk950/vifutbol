import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/sync_status_controller.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/sync/sync_status_bottom_sheet.dart';

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
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
}

class _DummyCloudSyncService implements CloudSyncService {
  @override
  Future<void> discardItem({
    required String userId,
    required String itemId,
  }) async {}

  @override
  Future<SyncFlushResult> flushOutbox({required String userId}) async =>
      const SyncFlushResult(
        syncedCount: 0,
        remainingPendingCount: 0,
        errorCount: 0,
      );

  @override
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  }) async => const SyncFlushResult(
    syncedCount: 0,
    remainingPendingCount: 0,
    errorCount: 0,
  );

  @override
  void setActiveUser(String? userId) {}

  @override
  Stream<bool> watchIsSyncing() => const Stream<bool>.empty();
}

class _SpySyncController extends SyncStatusController {
  _SpySyncController(SyncSummaryState initial)
    : super(
        outboxRepository: HiveSyncOutboxRepository(
          storage: _InMemoryLocalStorage(),
        ),
        connectivityRepository: _FakeConnectivity(),
        cloudSyncService: _DummyCloudSyncService(),
        initialState: initial,
        autoInitialize: false,
      );

  int syncNowCalls = 0;
  String? retriedId;
  String? discardedId;

  @override
  Future<SyncFlushResult?> syncNow() async {
    syncNowCalls++;
    return const SyncFlushResult(
      syncedCount: 1,
      remainingPendingCount: 0,
      errorCount: 0,
    );
  }

  @override
  Future<SyncFlushResult?> retryItem(String itemId) async {
    retriedId = itemId;
    return const SyncFlushResult(
      syncedCount: 1,
      remainingPendingCount: 0,
      errorCount: 0,
    );
  }

  @override
  Future<void> discardItem(String itemId) async {
    discardedId = itemId;
  }
}

void main() {
  Widget wrapSheet(_SpySyncController controller) {
    return ProviderScope(
      overrides: [
        syncStatusControllerProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('es'),
        home: Scaffold(body: SyncStatusBottomSheet()),
      ),
    );
  }

  group('SyncStatusBottomSheet (US4)', () {
    testWidgets(
      'displays synced empty state with formatted timestamp when queue is empty',
      (tester) async {
        final ctrl = _SpySyncController(
          SyncSummaryState(
            status: SyncStatus.synced,
            isConnected: true,
            lastSyncedAt: DateTime(2026, 11, 11, 14, 30),
          ),
        );

        await tester.pumpWidget(wrapSheet(ctrl));
        await tester.pump();

        expect(find.text('Todos los datos están al día'), findsOneWidget);
        expect(find.textContaining('11/11/2026 14:30'), findsOneWidget);
        expect(
          find.text(
            'No hay cambios locales pendientes de respaldo en la nube.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays pending and error items with Retry/Discard actions and triggers manual sync',
      (tester) async {
        final now = DateTime.utc(2026, 11, 11, 15, 0);
        final ctrl = _SpySyncController(
          SyncSummaryState(
            status: SyncStatus.offlineOrError,
            pendingCount: 1,
            errorCount: 1,
            isConnected: true,
            items: [
              SyncOutboxItem(
                id: 'item-queued',
                ownerUserId: 'u1',
                entityType: SyncOutboxEntityType.matchReport,
                entityId: 'm1',
                operation: SyncOutboxOperation.upsert,
                payloadJson: const {},
                displayTitle: 'Gol Min 34',
                status: SyncOutboxItemStatus.queued,
                createdAt: now,
                updatedAt: now,
              ),
              SyncOutboxItem(
                id: 'item-err',
                ownerUserId: 'u1',
                entityType: SyncOutboxEntityType.tournament,
                entityId: 't1',
                operation: SyncOutboxOperation.upsert,
                payloadJson: const {},
                displayTitle: 'Copa Norte',
                status: SyncOutboxItemStatus.error,
                errorCode: SyncErrorCode.permissionDenied,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
        );

        await tester.pumpWidget(wrapSheet(ctrl));
        await tester.pump();

        expect(find.textContaining('Gol Min 34'), findsOneWidget);
        expect(find.textContaining('Copa Norte'), findsOneWidget);
        expect(
          find.text(
            'No tienes permisos para modificar este recurso en el servidor.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('sync_retry_item_item-err')));
        await tester.pump();
        expect(ctrl.retriedId, 'item-err');

        await tester.tap(find.byKey(const Key('sync_discard_item_item-err')));
        await tester.pump();
        expect(ctrl.discardedId, 'item-err');

        await tester.tap(find.byKey(const Key('sync_now_button')));
        await tester.pump();
        expect(ctrl.syncNowCalls, 1);
      },
    );

    testWidgets('disables Sync Now CTA when offline', (tester) async {
      final ctrl = _SpySyncController(
        const SyncSummaryState(
          status: SyncStatus.offlineOrError,
          pendingCount: 2,
          isConnected: false,
        ),
      );

      await tester.pumpWidget(wrapSheet(ctrl));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('sync_now_button')),
      );
      expect(button.onPressed, isNull);
    });
  });
}
