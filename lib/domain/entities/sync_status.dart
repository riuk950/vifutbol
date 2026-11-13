/// Global reactive status of local vs cloud data synchronization.
enum SyncStatus {
  /// All authenticated changes are persisted in the cloud (`pendingCount == 0`, `errorCount == 0`).
  synced,

  /// Local changes are queued in FIFO outbox awaiting upload (`pendingCount > 0`, `errorCount == 0`).
  pending,

  /// A single-flight outbox flush cycle is actively executing.
  syncing,

  /// Device is offline or one or more outbox items failed non-transiently.
  offlineOrError,
}

/// Mutation kind stored inside a persistent FIFO outbox item.
enum SyncOutboxOperation { upsert, delete, replaceBatch }

/// Domain aggregate classifier mapped onto normalized `vifutboldev` tables.
enum SyncOutboxEntityType {
  tournament,
  venue,
  team,
  match,
  lineupTracking,
  matchReport,
  matchAlert,
  tournamentNews,
  seasonHonorRoll,
  fanFavorite,
}

/// Processing status of an individual item stored in the local outbox.
enum SyncOutboxItemStatus { queued, retrying, error }

/// Normalized non-transient rejection codes resolved by presentation l10n.
enum SyncErrorCode {
  permissionDenied,
  constraintViolation,
  validationFailed,
  notFound,
  unknown,
}
