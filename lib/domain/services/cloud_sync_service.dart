import 'package:vifutbol/domain/entities/sync_outbox_item.dart';

/// Contract for orchestrating single-flight FIFO synchronization between local Hive outbox and cloud.
abstract interface class CloudSyncService {
  /// Flushes pending FIFO outbox items for [userId] with single-flight mutex protection.
  /// Non-transient 4xx rejections mark only the affected item in error state and continue flushing valid items.
  Future<SyncFlushResult> flushOutbox({required String userId});

  /// Resets an errored item back to queued and triggers a flush cycle if connected.
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  });

  /// Permanently discards an errored or pending item from local outbox at user request.
  Future<void> discardItem({required String userId, required String itemId});

  /// Broadcast stream emitting whether an outbox flush cycle is currently active.
  Stream<bool> watchIsSyncing();

  /// Registers or updates the active authenticated user ID for reactive reconnect flushes.
  void setActiveUser(String? userId);
}
