# Phase 1 Data Model: Arquitectura Offline-First, Sincronización en la Nube e Indicador de Estado de Datos

**Feature Branch**: `038-offline-first-cloud-sync`  
**Spec Reference**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/spec.md)  
**Target Persistence**: Hive/LocalStorage (`vifutbol_dev_*` namespace) + PostgreSQL schema `vifutboldev` via Supabase PostgREST.

---

## 1. Domain Entities & Enums (`lib/domain/entities/`)

### 1.1 `SyncStatus` (AppBar Indicator State)

| Value | Visual Cue | Tooltip / Semantics (ES) | When Active |
| :--- | :--- | :--- | :--- |
| `synced` | `Icons.cloud_done_outlined` (`#00E676`) | "Datos sincronizados" | Connected (or idle clean state) with `pendingCount == 0` and `errorCount == 0`. |
| `pending` | `Icons.cloud_upload_outlined` (`#FFB300`) + numeric badge | "{count} cambios pendientes" | `pendingCount > 0`, `errorCount == 0`, and flush is not actively running. |
| `syncing` | Animated `Icons.sync` (`#00E676`) | "Sincronizando con la nube" | `CloudSyncService` mutex is actively flushing or pulling cloud state. |
| `offlineOrError` | `Icons.cloud_off_outlined` / `Icons.error_outline` (`#FF3D71`) + optional badge | "Sin conexión o error de sincronización" | `NetworkConnectionStatus.disconnected` while offline/pending, OR `errorCount > 0`. |

### 1.2 `SyncOutboxOperation`

- `upsert`: Idempotent insert/update keyed by `entityId` (`uuid`).
- `delete`: Soft/hard delete by `entityId` (or scoped composite key in payload).
- `replaceBatch`: Scoped tournament replacement (used when `replaceTeamsForTournament`, `replaceMatchesForTournament`, `replaceReportsForTournament`, or `replaceNewsForTournament` run while offline).

### 1.3 `SyncOutboxEntityType`

Maps directly onto the 10 domain repository modules (`vifutboldev` normalized aggregates):

| Enum Value | Domain Aggregate | `vifutboldev` Target Table(s) (Parent -> Child order) |
| :--- | :--- | :--- |
| `tournament` | `ChampionshipTournament` (+ `RuleAuditEntry`) | `tournaments` -> `rule_audit_entries` |
| `venue` | `SportsVenue` (+ `VenuePitch`) | `sports_venues` -> `venue_pitches` |
| `team` | `TournamentTeam` (+ `RegisteredPlayer`) | `teams` -> `tournament_teams` -> `players` |
| `match` | `ChampionshipMatch` (+ `MatchReferee` refs) | `matches` (`match_referees`) |
| `lineupTracking` | `PlayerInternalTracking` / `MatchLineupConvocation` | `player_internal_trackings` / `match_lineup_convocations` |
| `matchReport` | `DigitalMatchReport` (+ `MatchEvent`) | `digital_match_reports` -> `match_events` |
| `matchAlert` | `MatchLiveAlert` | `match_live_alerts` |
| `tournamentNews` | `TournamentNewsItem` | `tournament_news` |
| `seasonHonorRoll` | `SeasonHonorRoll` | `season_honor_rolls` |
| `fanFavorite` | `FanFavoriteTeam` | `fan_favorite_teams` |

### 1.4 `SyncOutboxItemStatus`

- `queued`: Waiting in FIFO order to be pushed to `vifutboldev`.
- `retrying`: Transient network/timeout error occurred (`retryCount > 0`), eligible for next reconnect or manual flush.
- `error`: Non-transient server rejection (`4xx` RLS/validation/constraint failure) preserved for user inspection, manual retry, or discard without blocking later FIFO items (Clarification Q2).

### 1.5 `SyncOutboxItem`

| Field | Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `String` | UUID v4 unique identifier of this outbox entry. |
| `ownerUserId` | `String` | Authenticated `UserAccount.id` that originated the change (`ownerUserId` isolation per Clarification Q3). |
| `entityType` | `SyncOutboxEntityType` | Target repository/aggregate classifier. |
| `entityId` | `String` | Deterministic entity UUID (or composite scope key for `replaceBatch`). |
| `operation` | `SyncOutboxOperation` | `upsert`, `delete`, or `replaceBatch`. |
| `payloadJson` | `Map<String, dynamic>` | Serialized domain payload including UTC `updated_at` timestamp for LWW resolution. |
| `displayTitle` | `String` | Human-readable Spanish summary displayed in `SyncStatusBottomSheet` (e.g., `"Gol registrado · Min 34"`). |
| `status` | `SyncOutboxItemStatus` | `queued`, `retrying`, or `error`. |
| `createdAt` | `DateTime` | UTC creation timestamp; governs strict FIFO ordering for `queued`/`retrying` items. |
| `updatedAt` | `DateTime` | UTC last attempt/modification timestamp. |
| `retryCount` | `int` | Non-negative count of transient or manual retry attempts (`>= 0`). |
| `errorMessage` | `String?` | Present when `status == error`; Spanish explanation returned/mapped from non-transient server rejection. |

### 1.6 `SyncSummaryState`

Immutable UI/application state exposed by `SyncStatusController`:

| Field | Type | Notes |
| :--- | :--- | :--- |
| `status` | `SyncStatus` | Computed from `isSyncing`, `isConnected`, `pendingCount`, `errorCount`. |
| `pendingCount` | `int` | Count of `queued` + `retrying` items for `activeUserId`. |
| `errorCount` | `int` | Count of `error` items for `activeUserId`. |
| `totalAttentionCount` | `int` | `pendingCount + errorCount` shown in AppBar badge and checked during sign-out guard (`Q3`). |
| `isConnected` | `bool` | Reflects `ConnectivityRepository`. |
| `isSyncing` | `bool` | True while `CloudSyncService` mutex holds the active flush lock. |
| `lastSyncedAt` | `DateTime?` | Timestamp of last completed clean sync cycle (persisted locally per user). |
| `items` | `List<SyncOutboxItem>` | FIFO-ordered items scoped exclusively to `activeUserId`. |

---

## 2. State Transitions & Synchronization Rules

### 2.1 Write Path State Machine (Clarification Q1)

1. **Authenticated non-guest user + `NetworkConnectionStatus.connected`**:
   - Execute remote mutation directly in `vifutboldev`.
   - If remote succeeds -> update `Local*Repository` cache -> `SyncOutboxItem` is NOT created (`pendingCount` unchanged).
   - If remote fails with transient network/timeout/5xx -> save to `Local*Repository` -> enqueue `SyncOutboxItem(status: queued, ownerUserId: user.id)` -> `SyncStatus` transitions toward `offlineOrError`/`pending`.
2. **Authenticated non-guest user + `NetworkConnectionStatus.disconnected`**:
   - Save immediately to `Local*Repository` -> enqueue `SyncOutboxItem(status: queued, ownerUserId: user.id)` -> AppBar badge updates immediately.
3. **Guest Fan (`isGuestFan == true`)**:
   - Save only to `Local*Repository` -> zero Supabase calls, zero outbox entries, AppBar indicator remains hidden.

### 2.2 Outbox Flush State Machine (Clarification Q2 & Q3)

1. Filter stored `SyncOutboxItem` list to `ownerUserId == activeUserId` ordered by `createdAt ASC`.
2. Acquire single-flight lock (`_isFlushing = true` -> UI `SyncStatus.syncing`).
3. For each item where `status == queued || status == retrying`:
   - Execute remote operation against `vifutboldev` using `onConflict: 'id'` + `updated_at` (LWW).
   - **On success**: remove item from `SyncOutboxRepository`, update `lastSyncedAt`, refresh local cache if needed, continue FIFO loop.
   - **On transient error** (`SocketException`, `TimeoutException`, HTTP `5xx`): mark `status = retrying`, increment `retryCount`, keep item at head of pending queue, **abort** flush loop cleanly (`offlineOrError`), wait for next connectivity regain or manual retry.
   - **On non-transient rejection** (`PostgrestException` `4xx`, RLS `42501`, FK/unique/check `23xxx`): mark ONLY this item `status = error` with mapped Spanish `errorMessage`, persist it, and **continue** flushing subsequent valid FIFO items (`Clarification Q2`).
4. Release lock and recompute `SyncSummaryState`:
   - If `isSyncing` -> `syncing`
   - Else if `errorCount > 0` || (`!isConnected && pendingCount > 0`) || `!isConnected` -> `offlineOrError`
   - Else if `pendingCount > 0` -> `pending`
   - Else -> `synced`

---

## 3. Local Storage Keys & `ownerUserId` Isolation

Persisted inside `LocalStorageRepository` (Hive namespace `vifutbol_dev_*`):

| Key Pattern | Value Shape | Scope |
| :--- | :--- | :--- |
| `sync_outbox_items_v1` | JSON array of serialized `SyncOutboxItem` across all users | Global to device storage, strictly filtered at read/flush time by `ownerUserId`. |
| `sync_last_synced_at_v1_<userId>` | ISO-8601 UTC timestamp string | Scoped per authenticated `userId`. |

> **Sign-out Preservation Rule (Q3)**: Signing out clears active auth session (`authControllerProvider`) without deleting `sync_outbox_items_v1`, leaving queued items intact under their original `ownerUserId` until that account either confirms "Sincronizar y salir" (flushing before sign-out) or logs back in later.
