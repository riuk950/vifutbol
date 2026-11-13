import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/sync_outbox_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';

/// Reactive controller computing [SyncSummaryState] for the active authenticated user.
class SyncStatusController extends StateNotifier<SyncSummaryState> {
  SyncStatusController({
    required this.outboxRepository,
    required this.connectivityRepository,
    required this.cloudSyncService,
    SyncSummaryState initialState = const SyncSummaryState(),
    bool autoInitialize = true,
  }) : super(initialState) {
    if (autoInitialize) {
      _init();
    }
  }

  final SyncOutboxRepository outboxRepository;
  final ConnectivityRepository connectivityRepository;
  final CloudSyncService cloudSyncService;

  StreamSubscription<NetworkConnectionStatus>? _connectivitySub;
  StreamSubscription<bool>? _syncingSub;
  StreamSubscription<List<SyncOutboxItem>>? _outboxSub;

  String? _activeUserId;
  bool _isGuestFan = false;
  bool _isConnected = true;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  List<SyncOutboxItem> _items = const [];

  Future<void> _init() async {
    try {
      final status = await connectivityRepository.checkConnectivity();
      _isConnected = status == NetworkConnectionStatus.connected;
    } catch (_) {
      _isConnected = true;
    }

    _connectivitySub = connectivityRepository.onConnectivityChanged.listen((
      status,
    ) {
      _isConnected = status == NetworkConnectionStatus.connected;
      _recomputeState();
    });

    _syncingSub = cloudSyncService.watchIsSyncing().listen((syncing) {
      _isSyncing = syncing;
      _recomputeState();
    });

    _recomputeState();
  }

  /// Updates the active user scope (`userId` + `isGuestFan`). Passing a guest or null
  /// resets visible state cleanly without deleting persisted outbox entries in Hive.
  Future<void> bindUser({
    required String? userId,
    required bool isGuestFan,
  }) async {
    final effectiveUserId = (isGuestFan || userId == null || userId.isEmpty)
        ? null
        : userId;

    if (_activeUserId == effectiveUserId && _isGuestFan == isGuestFan) {
      return;
    }

    _activeUserId = effectiveUserId;
    _isGuestFan = isGuestFan;
    await _outboxSub?.cancel();
    _outboxSub = null;

    if (effectiveUserId == null) {
      _items = const [];
      _lastSyncedAt = null;
      cloudSyncService.setActiveUser(null);
      _recomputeState();
      return;
    }

    cloudSyncService.setActiveUser(effectiveUserId);
    _items = await outboxRepository.loadItemsForUser(effectiveUserId);
    _lastSyncedAt = await outboxRepository.loadLastSyncedAt(effectiveUserId);
    _recomputeState();

    _outboxSub = outboxRepository.watchItemsForUser(effectiveUserId).listen((
      items,
    ) async {
      _items = items;
      _lastSyncedAt = await outboxRepository.loadLastSyncedAt(effectiveUserId);
      _recomputeState();
    });
  }

  void _recomputeState() {
    if (!mounted) return;
    final pendingCount = _items
        .where(
          (i) =>
              i.status == SyncOutboxItemStatus.queued ||
              i.status == SyncOutboxItemStatus.retrying,
        )
        .length;
    final errorCount = _items
        .where((i) => i.status == SyncOutboxItemStatus.error)
        .length;

    final SyncStatus computedStatus;
    if (_isSyncing) {
      computedStatus = SyncStatus.syncing;
    } else if (errorCount > 0 || !_isConnected) {
      computedStatus = SyncStatus.offlineOrError;
    } else if (pendingCount > 0) {
      computedStatus = SyncStatus.pending;
    } else {
      computedStatus = SyncStatus.synced;
    }

    state = SyncSummaryState(
      status: computedStatus,
      pendingCount: pendingCount,
      errorCount: errorCount,
      isConnected: _isConnected,
      isSyncing: _isSyncing,
      lastSyncedAt: _lastSyncedAt,
      items: List.unmodifiable(_items),
    );
  }

  /// Manually triggers single-flight synchronization for the active user.
  Future<SyncFlushResult?> syncNow() async {
    final userId = _activeUserId;
    if (userId == null || _isSyncing) return null;
    final result = await cloudSyncService.flushOutbox(userId: userId);
    _lastSyncedAt = await outboxRepository.loadLastSyncedAt(userId);
    _recomputeState();
    return result;
  }

  /// Retries an errored outbox entry manually.
  Future<SyncFlushResult?> retryItem(String itemId) async {
    final userId = _activeUserId;
    if (userId == null) return null;
    final result = await cloudSyncService.retryErroredItem(
      userId: userId,
      itemId: itemId,
    );
    _lastSyncedAt = await outboxRepository.loadLastSyncedAt(userId);
    _recomputeState();
    return result;
  }

  /// Discards an errored or pending outbox entry cleanly.
  Future<void> discardItem(String itemId) async {
    final userId = _activeUserId;
    if (userId == null) return;
    await cloudSyncService.discardItem(userId: userId, itemId: itemId);
    _items = await outboxRepository.loadItemsForUser(userId);
    _recomputeState();
  }

  @override
  void dispose() {
    unawaited(_connectivitySub?.cancel());
    unawaited(_syncingSub?.cancel());
    unawaited(_outboxSub?.cancel());
    super.dispose();
  }
}
