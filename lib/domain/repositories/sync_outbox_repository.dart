import 'package:vifutbol/domain/entities/sync_outbox_item.dart';

/// Contract for persisting, isolating by [ownerUserId], and streaming FIFO sync outbox items.
abstract interface class SyncOutboxRepository {
  /// Loads all queued, retrying, and errored items owned by [userId], ordered FIFO by createdAt.
  Future<List<SyncOutboxItem>> loadItemsForUser(String userId);

  /// Reactive stream emitting whenever [userId]'s outbox changes.
  Stream<List<SyncOutboxItem>> watchItemsForUser(String userId);

  /// Appends (or coalesces an existing queued/retrying entry for the same target) scoped to `item.ownerUserId`.
  Future<void> enqueue(SyncOutboxItem item);

  /// Updates an existing item's status, retryCount, errorCode, or errorMessage.
  Future<void> updateItem(SyncOutboxItem item);

  /// Removes a successfully synced or user-discarded item by [itemId].
  Future<void> removeItem(String itemId);

  /// Reads the timestamp of the last clean completed sync for [userId].
  Future<DateTime?> loadLastSyncedAt(String userId);

  /// Persists the timestamp of the last clean completed sync for [userId].
  Future<void> saveLastSyncedAt(String userId, DateTime timestamp);
}
