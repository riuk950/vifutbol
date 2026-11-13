import 'package:vifutbol/domain/entities/sync_status.dart';

/// Persistent FIFO outbox entry scoped to its originating authenticated user.
class SyncOutboxItem {
  final String id;
  final String ownerUserId;
  final SyncOutboxEntityType entityType;
  final String entityId;
  final SyncOutboxOperation operation;
  final Map<String, dynamic> payloadJson;
  final String displayTitle;
  final SyncOutboxItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final SyncErrorCode? errorCode;
  final String? errorMessage;

  const SyncOutboxItem({
    required this.id,
    required this.ownerUserId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.displayTitle,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.errorCode,
    this.errorMessage,
  }) : assert(retryCount >= 0, 'retryCount must be non-negative');

  SyncOutboxItem copyWith({
    String? id,
    String? ownerUserId,
    SyncOutboxEntityType? entityType,
    String? entityId,
    SyncOutboxOperation? operation,
    Map<String, dynamic>? payloadJson,
    String? displayTitle,
    SyncOutboxItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    SyncErrorCode? errorCode,
    bool clearErrorCode = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SyncOutboxItem(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      displayTitle: displayTitle ?? this.displayTitle,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'entityType': entityType.name,
      'entityId': entityId,
      'operation': operation.name,
      'payloadJson': payloadJson,
      'displayTitle': displayTitle,
      'status': status.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'retryCount': retryCount,
      if (errorCode != null) 'errorCode': errorCode!.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory SyncOutboxItem.fromJson(Map<String, dynamic> json) {
    final rawRetryCount = (json['retryCount'] as num?)?.toInt() ?? 0;
    final rawErrorCode = json['errorCode'] as String?;

    return SyncOutboxItem(
      id: json['id'] as String,
      ownerUserId: json['ownerUserId'] as String,
      entityType: SyncOutboxEntityType.values.byName(
        json['entityType'] as String,
      ),
      entityId: json['entityId'] as String,
      operation: SyncOutboxOperation.values.byName(json['operation'] as String),
      payloadJson: Map<String, dynamic>.from(
        (json['payloadJson'] as Map?) ?? const <String, dynamic>{},
      ),
      displayTitle: json['displayTitle'] as String? ?? '',
      status: SyncOutboxItemStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      retryCount: rawRetryCount < 0 ? 0 : rawRetryCount,
      errorCode: rawErrorCode == null
          ? null
          : SyncErrorCode.values.byName(rawErrorCode),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOutboxItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerUserId == other.ownerUserId &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          operation == other.operation &&
          status == other.status &&
          retryCount == other.retryCount &&
          errorCode == other.errorCode &&
          errorMessage == other.errorMessage &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    ownerUserId,
    entityType,
    entityId,
    operation,
    status,
    retryCount,
    errorCode,
    errorMessage,
    updatedAt,
  );
}

/// Aggregated reactive state consumed by the AppBar indicator, bottom sheet, and logout guard.
class SyncSummaryState {
  final SyncStatus status;
  final int pendingCount;
  final int errorCount;
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final List<SyncOutboxItem> items;

  const SyncSummaryState({
    this.status = SyncStatus.synced,
    this.pendingCount = 0,
    this.errorCount = 0,
    this.isConnected = true,
    this.isSyncing = false,
    this.lastSyncedAt,
    this.items = const [],
  });

  /// Total items requiring user awareness before signing out or leaving a venue.
  int get totalAttentionCount => pendingCount + errorCount;

  SyncSummaryState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? errorCount,
    bool? isConnected,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    List<SyncOutboxItem>? items,
  }) {
    return SyncSummaryState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      items: items ?? this.items,
    );
  }
}

/// Summary returned by a single-flight flush cycle.
class SyncFlushResult {
  final int syncedCount;
  final int remainingPendingCount;
  final int errorCount;
  final bool abortedDueToNetwork;

  const SyncFlushResult({
    required this.syncedCount,
    required this.remainingPendingCount,
    required this.errorCount,
    this.abortedDueToNetwork = false,
  });

  bool get isFullySynced =>
      remainingPendingCount == 0 && errorCount == 0 && !abortedDueToNetwork;
}
