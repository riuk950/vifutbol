import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/supabase_error_classifier.dart';

/// User context snapshot read lazily per repository call.
typedef SyncUserContextReader = ({String? userId, bool isGuest}) Function();

/// Shared offline-first coordinator used by all 10 hybrid repositories (`FR-001`–`FR-005`, Q1).
class HybridRepositorySupport {
  HybridRepositorySupport({
    required this.connectivity,
    required this.outbox,
    required this.userContextReader,
    Uuid? uuid,
    Clock? clock,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? const Clock();

  final ConnectivityRepository connectivity;
  final SyncOutboxRepository outbox;
  final SyncUserContextReader userContextReader;
  final Uuid _uuid;
  final Clock _clock;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Returns [value] only if it is a valid UUID string; otherwise `null`.
  static String? uuidOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return _uuidRegex.hasMatch(trimmed) ? trimmed : null;
  }

  /// Returns [id] if it is already a valid UUID; otherwise converts non-UUID
  /// strings (e.g. legacy/local ids like "tournament-1794583638953" or "team-123")
  /// into a deterministic UUID v5 so PostgreSQL uuid columns never fail with 22P02.
  static String ensureUuid(String id, [String namespacePrefix = 'entity']) {
    final valid = uuidOrNull(id);
    if (valid != null) return valid;
    return const Uuid().v5(
      Namespace.url.value,
      '$namespacePrefix|${id.trim()}',
    );
  }

  /// Returns [id] converted to a deterministic UUID v5 if non-null and not empty;
  /// otherwise returns `null`.
  static String? ensureUuidOrNull(
    String? id, [
    String namespacePrefix = 'entity',
  ]) {
    if (id == null) return null;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    return ensureUuid(trimmed, namespacePrefix);
  }

  /// Generates a deterministic UUID v5 for composite child keys without native UUID IDs.
  String deterministicUuid(String seed) {
    return _uuid.v5(Namespace.url.value, seed);
  }

  /// Returns current UTC timestamp from injected clock.
  DateTime nowUtc() => _clock.now().toUtc();

  /// Executes remote read with local cache refresh when connected, falling back cleanly
  /// to [localFallback] when offline or on remote fetch failure (`FR-001`).
  Future<T> executeRead<T>({
    required Future<T> Function() remoteFetch,
    required Future<void> Function(T data) cacheUpdate,
    required Future<T> Function() localFallback,
    bool allowRemoteForGuest = true,
  }) async {
    final user = userContextReader();
    if (!allowRemoteForGuest && user.isGuest) {
      return localFallback();
    }

    final status = await connectivity.checkConnectivity();
    if (status != NetworkConnectionStatus.connected) {
      return localFallback();
    }

    try {
      final remoteData = await remoteFetch();
      await cacheUpdate(remoteData);
      return remoteData;
    } catch (_) {
      return localFallback();
    }
  }

  /// Executes remote-first write when online (updating local cache with zero outbox entry)
  /// or saves locally and enqueues into FIFO outbox when offline or on transient network failure (`Q1`).
  Future<T> executeMutation<T>({
    required Future<T> Function() localWrite,
    required Future<T> Function() remoteWrite,
    required SyncOutboxEntityType entityType,
    required String entityId,
    required SyncOutboxOperation operation,
    required Map<String, dynamic> Function() buildPayload,
    required String displayTitle,
  }) async {
    final user = userContextReader();
    if (user.isGuest || user.userId == null || user.userId!.trim().isEmpty) {
      return localWrite();
    }

    final status = await connectivity.checkConnectivity();
    if (status == NetworkConnectionStatus.connected) {
      try {
        final remoteResult = await remoteWrite();
        await localWrite();
        return remoteResult;
      } catch (error) {
        if (!SupabaseErrorClassifier.isTransientError(error)) {
          rethrow;
        }
        final localResult = await localWrite();
        await _enqueue(
          ownerUserId: user.userId!,
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payloadJson: buildPayload(),
          displayTitle: displayTitle,
        );
        return localResult;
      }
    }

    final localResult = await localWrite();
    await _enqueue(
      ownerUserId: user.userId!,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: buildPayload(),
      displayTitle: displayTitle,
    );
    return localResult;
  }

  Future<void> _enqueue({
    required String ownerUserId,
    required SyncOutboxEntityType entityType,
    required String entityId,
    required SyncOutboxOperation operation,
    required Map<String, dynamic> payloadJson,
    required String displayTitle,
  }) async {
    final now = nowUtc();
    final item = SyncOutboxItem(
      id: _uuid.v4(),
      ownerUserId: ownerUserId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: {...payloadJson, 'updated_at': now.toIso8601String()},
      displayTitle: displayTitle,
      status: SyncOutboxItemStatus.queued,
      createdAt: now,
      updatedAt: now,
    );
    await outbox.enqueue(item);
  }
}
