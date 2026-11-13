import 'dart:async';

import 'package:clock/clock.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/sync_outbox_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/supabase_error_classifier.dart';

/// Handler signature registered by each hybrid repository for replaying outbox entries.
typedef OutboxReplayHandler = Future<void> Function(SyncOutboxItem item);

/// Optional callback invoked after an item succeeds so local caches stay refreshed.
typedef OutboxSyncedCallback = Future<void> Function(SyncOutboxItem item);

/// Centralized FIFO outbox synchronization engine with single-flight mutex protection,
/// automatic reconnect & active-user restore flushing, and non-blocking `4xx` error isolation.
class SupabaseCloudSyncService implements CloudSyncService {
  SupabaseCloudSyncService({
    required this.outboxRepository,
    required this.connectivityRepository,
    Clock? clock,
  }) : _clock = clock ?? const Clock() {
    _connectivitySub = connectivityRepository.onConnectivityChanged.listen((
      status,
    ) {
      if (status == NetworkConnectionStatus.connected &&
          _activeUserId != null) {
        unawaited(flushOutbox(userId: _activeUserId!));
      }
    });
  }

  final SyncOutboxRepository outboxRepository;
  final ConnectivityRepository connectivityRepository;
  final Clock _clock;

  final Map<SyncOutboxEntityType, OutboxReplayHandler> _handlers = {};
  final List<OutboxSyncedCallback> _afterSyncCallbacks = [];
  final StreamController<bool> _isSyncingController =
      StreamController<bool>.broadcast();
  StreamSubscription<NetworkConnectionStatus>? _connectivitySub;

  String? _activeUserId;
  bool _isSyncing = false;
  Future<SyncFlushResult>? _inFlightFlush;
  String? _queuedRerunUserId;

  /// Registers the remote replay handler for [entityType].
  void registerHandler(
    SyncOutboxEntityType entityType,
    OutboxReplayHandler handler,
  ) {
    _handlers[entityType] = handler;
  }

  /// Registers a callback triggered after each individual item syncs cleanly.
  void registerAfterSyncCallback(OutboxSyncedCallback callback) {
    _afterSyncCallbacks.add(callback);
  }

  @override
  void setActiveUser(String? userId) {
    final normalized = (userId == null || userId.trim().isEmpty)
        ? null
        : userId.trim();
    if (_activeUserId == normalized) {
      return;
    }
    _activeUserId = normalized;
    if (normalized != null) {
      // Trigger immediate check when authenticated user logs in / restores session already online (E1).
      unawaited(_flushIfConnected(normalized));
    }
  }

  Future<void> _flushIfConnected(String userId) async {
    final connectivity = await connectivityRepository.checkConnectivity();
    if (connectivity == NetworkConnectionStatus.connected &&
        _activeUserId == userId) {
      await flushOutbox(userId: userId);
    }
  }

  void _emitSyncing(bool syncing) {
    _isSyncing = syncing;
    if (!_isSyncingController.isClosed) {
      _isSyncingController.add(syncing);
    }
  }

  @override
  Stream<bool> watchIsSyncing() async* {
    yield _isSyncing;
    yield* _isSyncingController.stream;
  }

  @override
  Future<SyncFlushResult> flushOutbox({required String userId}) {
    if (_inFlightFlush != null) {
      _queuedRerunUserId = userId;
      return _inFlightFlush!;
    }

    final completer = Completer<SyncFlushResult>();
    _inFlightFlush = completer.future;

    () async {
      try {
        var result = await _executeFlush(userId);
        var totalSynced = result.syncedCount;
        while (_queuedRerunUserId != null) {
          final rerunUserId = _queuedRerunUserId!;
          _queuedRerunUserId = null;
          if (_activeUserId == null || _activeUserId == rerunUserId) {
            final next = await _executeFlush(rerunUserId);
            totalSynced += next.syncedCount;
            result = SyncFlushResult(
              syncedCount: totalSynced,
              remainingPendingCount: next.remainingPendingCount,
              errorCount: next.errorCount,
              abortedDueToNetwork: next.abortedDueToNetwork,
            );
          }
        }
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _inFlightFlush = null;
      }
    }();

    return completer.future;
  }

  Future<SyncFlushResult> _executeFlush(String userId) async {
    final connectivity = await connectivityRepository.checkConnectivity();
    final currentItems = await outboxRepository.loadItemsForUser(userId);
    final pendingItems = currentItems
        .where(
          (item) =>
              item.status == SyncOutboxItemStatus.queued ||
              item.status == SyncOutboxItemStatus.retrying,
        )
        .toList();
    final existingErrors = currentItems
        .where((item) => item.status == SyncOutboxItemStatus.error)
        .length;

    if (connectivity == NetworkConnectionStatus.disconnected) {
      return SyncFlushResult(
        syncedCount: 0,
        remainingPendingCount: pendingItems.length,
        errorCount: existingErrors,
        abortedDueToNetwork: pendingItems.isNotEmpty,
      );
    }

    if (pendingItems.isEmpty) {
      return SyncFlushResult(
        syncedCount: 0,
        remainingPendingCount: 0,
        errorCount: existingErrors,
      );
    }

    _emitSyncing(true);
    var syncedCount = 0;
    var abortedDueToNetwork = false;

    try {
      for (final item in pendingItems) {
        final handler = _handlers[item.entityType];
        if (handler == null) {
          await outboxRepository.updateItem(
            item.copyWith(
              status: SyncOutboxItemStatus.error,
              errorCode: SyncErrorCode.unknown,
              errorMessage:
                  'No replay handler registered for ${item.entityType.name}',
              updatedAt: _clock.now().toUtc(),
            ),
          );
          continue;
        }

        try {
          await handler(item);
          await outboxRepository.removeItem(item.id);
          await outboxRepository.saveLastSyncedAt(userId, _clock.now().toUtc());
          syncedCount++;
          for (final cb in _afterSyncCallbacks) {
            await cb(item);
          }
        } catch (error) {
          if (SupabaseErrorClassifier.isTransientError(error)) {
            await outboxRepository.updateItem(
              item.copyWith(
                status: SyncOutboxItemStatus.retrying,
                retryCount: item.retryCount + 1,
                updatedAt: _clock.now().toUtc(),
              ),
            );
            abortedDueToNetwork = true;
            break;
          }

          // Non-transient server rejection: mark ONLY this item in error state
          // and continue processing remaining valid FIFO items (Clarification Q2).
          final classified = SupabaseErrorClassifier.classifyRejection(error);
          await outboxRepository.updateItem(
            item.copyWith(
              status: SyncOutboxItemStatus.error,
              errorCode: classified.code,
              errorMessage: classified.safeDetail,
              updatedAt: _clock.now().toUtc(),
            ),
          );
        }
      }
    } finally {
      _emitSyncing(false);
    }

    final remaining = await outboxRepository.loadItemsForUser(userId);
    final remainingPending = remaining
        .where(
          (i) =>
              i.status == SyncOutboxItemStatus.queued ||
              i.status == SyncOutboxItemStatus.retrying,
        )
        .length;
    final totalErrors = remaining
        .where((i) => i.status == SyncOutboxItemStatus.error)
        .length;

    return SyncFlushResult(
      syncedCount: syncedCount,
      remainingPendingCount: remainingPending,
      errorCount: totalErrors,
      abortedDueToNetwork: abortedDueToNetwork,
    );
  }

  @override
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  }) async {
    final items = await outboxRepository.loadItemsForUser(userId);
    final targetIndex = items.indexWhere((item) => item.id == itemId);
    if (targetIndex >= 0) {
      final target = items[targetIndex];
      await outboxRepository.updateItem(
        target.copyWith(
          status: SyncOutboxItemStatus.queued,
          retryCount: target.retryCount + 1,
          updatedAt: _clock.now().toUtc(),
          clearErrorCode: true,
          clearErrorMessage: true,
        ),
      );
    }
    return flushOutbox(userId: userId);
  }

  @override
  Future<void> discardItem({
    required String userId,
    required String itemId,
  }) async {
    final items = await outboxRepository.loadItemsForUser(userId);
    final belongsToUser = items.any((item) => item.id == itemId);
    if (belongsToUser) {
      await outboxRepository.removeItem(itemId);
    }
  }

  /// Releases connectivity subscriptions and stream controllers.
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _isSyncingController.close();
  }
}
