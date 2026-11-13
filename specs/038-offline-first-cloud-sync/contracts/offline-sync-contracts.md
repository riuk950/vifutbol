# Phase 1 Contracts: Offline-First Cloud Sync & AppBar Status

**Feature Branch**: `038-offline-first-cloud-sync`  
**Scope**: Domain repository/service contracts (`lib/domain/`), infrastructure hybrid wrappers (`lib/infrastructure/`), application state (`lib/application/`), and presentation widgets (`lib/presentation/`).

---

## 1. Domain Contracts (`lib/domain/repositories/` & `lib/domain/services/`)

### 1.1 `SyncOutboxRepository` (`lib/domain/repositories/sync_outbox_repository.dart`)

```dart
abstract interface class SyncOutboxRepository {
  /// Loads all queued, retrying, and errored items owned by [userId], ordered FIFO by createdAt.
  Future<List<SyncOutboxItem>> loadItemsForUser(String userId);

  /// Reactive stream emitting whenever [userId]'s outbox changes.
  Stream<List<SyncOutboxItem>> watchItemsForUser(String userId);

  /// Appends (or coalesces/replaces matching id) an outbox item scoped to item.ownerUserId.
  Future<void> enqueue(SyncOutboxItem item);

  /// Updates an existing item's status, retryCount, or errorMessage.
  Future<void> updateItem(SyncOutboxItem item);

  /// Removes a successfully synced or user-discarded item by [itemId].
  Future<void> removeItem(String itemId);

  /// Reads the timestamp of the last clean completed sync for [userId].
  Future<DateTime?> loadLastSyncedAt(String userId);

  /// Persists the timestamp of the last clean completed sync for [userId].
  Future<void> saveLastSyncedAt(String userId, DateTime timestamp);
}
```

### 1.2 `CloudSyncService` (`lib/domain/services/cloud_sync_service.dart`)

```dart
abstract interface class CloudSyncService {
  /// Flushes all pending FIFO outbox items for [userId] with single-flight mutex protection.
  /// Continues past non-transient 4xx item errors (marking only rejected items as error).
  Future<SyncFlushResult> flushOutbox({required String userId});

  /// Resets an errored item back to queued and triggers a flush attempt if connected.
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  });

  /// Permanently discards an errored/pending item from local outbox at user request.
  Future<void> discardItem({
    required String userId,
    required String itemId,
  });

  /// Broadcast stream emitting whether a flush cycle is currently active for UI status.
  Stream<bool> watchIsSyncing();
}
```

`SyncFlushResult`:
- `int syncedCount`
- `int remainingPendingCount`
- `int errorCount`
- `bool abortedDueToNetwork`

---

## 2. Hybrid Repository Adapters (`lib/infrastructure/repositories/` & `lib/infrastructure/venues/`)

Each of the 10 existing domain repository contracts remains unchanged in `lib/domain/repositories/`. Each receives a hybrid adapter (plus Supabase PostgREST remote data source targeting schema `vifutboldev`):

| Domain Interface (Unchanged) | Hybrid Implementation | Local Fallback Cache |
| :--- | :--- | :--- |
| `TournamentsRepository` | `HybridTournamentsRepository` | `LocalTournamentsRepository` (drafts remain local-only) |
| `VenuesRepository` | `HybridVenuesRepository` | `LocalVenuesRepository` |
| `TeamsRepository` | `HybridTeamsRepository` | `LocalTeamsRepository` |
| `TournamentMatchesRepository` | `HybridTournamentMatchesRepository` | `LocalTournamentMatchesRepository` |
| `LineupsTrackingRepository` | `HybridLineupsTrackingRepository` | `LocalLineupsTrackingRepository` |
| `MatchReportsRepository` | `HybridMatchReportsRepository` | `LocalMatchReportsRepository` |
| `MatchAlertsRepository` | `HybridMatchAlertsRepository` | `LocalMatchAlertsRepository` |
| `TournamentNewsRepository` | `HybridTournamentNewsRepository` | `LocalTournamentNewsRepository` |
| `SeasonHonorRollRepository` | `HybridSeasonHonorRollRepository` | `LocalSeasonHonorRollRepository` |
| `FanFavoritesRepository` | `HybridFanFavoritesRepository` | `LocalFanFavoritesRepository` |

### Common Mutation Behavioral Contract Across All 10 Hybrids

1. **Context resolution**: Read current `UserAccount?` (`id`, `isGuestFan`) and `NetworkConnectionStatus`.
2. **Guest Fan (`user == null || user.isGuestFan`)**: Delegate exclusively to `Local*Repository` (no remote call, no outbox write).
3. **Online (`NetworkConnectionStatus.connected`) — Remote-first (Q1)**:
   - Execute Supabase PostgREST operation in schema `vifutboldev` (parent tables before child tables).
   - On success: update `Local*Repository` cache and return result. Outbox untouched (`pendingCount` does not increase).
   - On transient error (`SocketException`, `TimeoutException`, HTTP `5xx`): execute local write in `Local*Repository`, build `SyncOutboxItem(ownerUserId: user.id)`, call `SyncOutboxRepository.enqueue(...)`, and return local result cleanly without throwing to caller.
4. **Offline (`NetworkConnectionStatus.disconnected`)**:
   - Execute local write in `Local*Repository`, enqueue `SyncOutboxItem(ownerUserId: user.id)` into `SyncOutboxRepository`, and return local result immediately.
5. **Replay Registration**: `CloudSyncService` dispatches each `SyncOutboxItem` by `entityType` to the matching `Supabase*RemoteDataSource` upsert/delete/replace method using `onConflict: 'id'` and `updated_at`.

---

## 3. Application Layer & Providers (`lib/application/`)

### 3.1 Sync Providers (`lib/application/providers/sync_providers.dart`)

- `syncOutboxRepositoryProvider` (`Provider<SyncOutboxRepository>`): backed by `HiveSyncOutboxRepository(localStorageRepositoryProvider)`.
- `cloudSyncServiceProvider` (`Provider<CloudSyncService>`): wires `syncOutboxRepositoryProvider`, `connectivityRepositoryProvider`, `supabaseClientProvider`, and the 10 remote data sources; listens to `connectivityRepository.onConnectivityChanged` and triggers `flushOutbox` when transitioning to `connected` for the signed-in non-guest user.
- `syncStatusControllerProvider` (`StateNotifierProvider<SyncStatusController, SyncSummaryState>`): combines `authControllerProvider` (`activeUserId`, `isGuestFan`), `connectivityRepositoryProvider`, `syncOutboxRepositoryProvider.watchItemsForUser(userId)`, and `cloudSyncServiceProvider.watchIsSyncing()` into `SyncSummaryState`.

### 3.2 Provider Switching Rule (All 8 Domain Provider Files)

In each provider file (`tournaments_providers.dart`, `venues_providers.dart`, `teams_providers.dart`, `matches_catalog_providers.dart`, `lineups_tracking_providers.dart`, `digital_match_report_providers.dart`, `tournament_news_providers.dart`, `fan_alerts_and_favorites_providers.dart`, `backup_and_season_closure_providers.dart`):

```dart
final useRemote = config.environment == AppEnvironment.development &&
    config.supabase.isConfigured &&
    supabaseClient != null;
```
- When `useRemote == true`: return `Hybrid*Repository(...)`.
- When `useRemote == false`: return existing `Local*Repository(...)`.

---

## 4. Presentation Layer Contracts (`lib/presentation/`)

### 4.1 Role Gating in `RolePermissionMatrix`

- Add `RoleCapability.viewCloudSyncIndicator`:
  - `true` for `{UserRole.organizer, UserRole.coach, UserRole.referee}`
  - `false` for `{UserRole.player, UserRole.fan}`
- Presentation additionally checks `!(user?.isGuestFan ?? true)` and `useRemote` (so local-only/guest sessions hide the indicator).

### 4.2 `SyncStatusAppBarAction` (`lib/presentation/sync/sync_status_app_bar_action.dart`)

- Inserted in `AppShellScreen.AppBar.actions` right before `FanAlertsBellAction`.
- Renders `SizedBox.shrink()` when role lacks `RoleCapability.viewCloudSyncIndicator` or `isGuestFan == true`.
- Minimum tap area `48x48` dp; renders distinct state icon + color + numeric badge (`pendingCount + errorCount > 0`) + localized `tooltip`/`Semantics`.
- Keys for deterministic widget testing:
  - `Key('app_bar_sync_status_action')`
  - `Key('app_bar_sync_status_badge')`

### 4.3 `SyncStatusBottomSheet` (`lib/presentation/sync/sync_status_bottom_sheet.dart`)

- Modal sheet opened by tapping `SyncStatusAppBarAction`.
- Displays:
  - Connection banner pill ("En línea" / "Sin conexión")
  - Current sync state header & `lastSyncedAt` relative/formatted Spanish timestamp
  - Scrollable list of `items` (`SyncOutboxItem`) scoped to active user:
    - Shows `displayTitle`, entity badge, status pill (`En cola` / `Reintentando` / `Error`)
    - For `status == error`: displays `errorMessage` + `"Reintentar"` and `"Descartar"` action buttons (`>=44px` height)
  - Primary CTA button `"Sincronizar ahora"` (`Key('sync_now_button')`), disabled when syncing or offline.

### 4.4 Sign-Out Guard (`ProfileTabView._handleLogout`)

- Reads `syncStatusControllerProvider.totalAttentionCount` before signing out.
- If `totalAttentionCount > 0` and user is non-guest: opens `SignOutPendingSyncDialog` in Spanish with:
  - `"Sincronizar y salir"` (`Key('logout_sync_and_exit_button')`, enabled only when connected)
  - `"Salir conservando pendientes"` (`Key('logout_keep_pending_button')`)
  - `"Cancelar"` (`Key('logout_cancel_button')`)
- If `totalAttentionCount == 0`: preserves existing logout confirmation dialog unchanged.
