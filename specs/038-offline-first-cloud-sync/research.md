# Phase 0 Research & Architectural Decisions: Arquitectura Offline-First, Sincronización en la Nube e Indicador de Estado de Datos

**Feature Branch**: `038-offline-first-cloud-sync`  
**Spec Reference**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/spec.md)  
**Target Environment**: Development (`AppEnvironment.development`, Supabase schema `vifutboldev`) with safe fallback to pure local persistence in offline/unconfigured/isolated test environments.

---

## Decision 1: Hybrid Repository Pattern & Conditional Provider Selection

- **Decision**: Wrap each of the 10 existing domain repositories behind a hybrid offline-first repository implementation in `lib/infrastructure/repositories/` (and `lib/infrastructure/venues/`) that coordinates a `Local*Repository` (Hive-backed via `LocalStorageRepository`), a Supabase PostgREST remote data source targeting schema `vifutboldev`, `SyncOutboxRepository`, and `ConnectivityRepository`. Select the hybrid implementation inside each existing Riverpod provider in `lib/application/providers/` only when `config.environment == AppEnvironment.development && config.supabase.isConfigured && supabaseClient != null`; otherwise fall back to the existing `Local*Repository`.
- **Rationale**:
  - Preserves all 10 existing domain repository contracts in `lib/domain/repositories/` with zero breaking changes to presentation controllers and existing use cases.
  - Keeps `domain/` completely pure (no imports from `supabase_flutter` or `hive`), satisfying Constitution Principle IV (Arquitectura Limpia).
  - Guarantees existing widget and unit tests that override only local storage or mock repositories continue working with zero regressions.
- **Alternatives Considered**:
  - *Direct Supabase calls inside application controllers*: Rejected because it violates Clean Architecture, couples UI logic to PostgREST payloads, and duplicates offline queueing logic across every controller.
  - *Generic raw-JSON proxy repository*: Rejected because domain entities (`TournamentTeam`, `SportsVenue`, `DigitalMatchReport`, `ChampionshipTournament`) map across multiple normalized Postgres tables in `vifutboldev` requiring ordered parent-before-child upserts.

---

## Decision 2: Online Remote-First Write Strategy vs Offline Queueing (Clarification Q1)

- **Decision**:
  - **Authenticated non-guest users when `NetworkConnectionStatus.connected`**:
    - **Writes**: Attempt the remote operation against `vifutboldev` first. On success, update the local `Local*Repository` cache immediately and return without inserting an outbox entry (keeping `pendingSyncCount == 0` and indicator state `synced`). Only if the write fails due to connectivity loss, timeout (`TimeoutException`), socket error (`SocketException`), or transient HTTP 5xx error, fall back immediately: persist locally in `Local*Repository` and append a `SyncOutboxItem` to `SyncOutboxRepository` scoped to `ownerUserId`. Non-transient 4xx validation/RLS errors during live online writes surface immediately to the caller.
    - **Reads**: Attempt remote fetch when connected, update the local `Local*Repository` cache with fresh cloud rows, and return cloud data. On offline status or transient network failure, fall back seamlessly to reading from `Local*Repository` without blocking UI workflows.
  - **Authenticated non-guest users when `NetworkConnectionStatus.disconnected`**:
    - Persist writes locally immediately (`Local*Repository`), enqueue `SyncOutboxItem` into persistent FIFO storage (`HiveSyncOutboxRepository`), and update reactive `SyncSummaryState` (`pending` with incremented badge count).
  - **Guest Fans (`user?.isGuestFan == true`)**:
    - Bypass remote writes and `SyncOutboxRepository` completely; operate strictly against local `Local*Repository` (`FR-009`).
- **Rationale**: Satisfies Clarification Q1 verbatim, ensures instant feedback on the pitch when offline, avoids superfluous pending-badge flickering during healthy online sessions, and honors guest privacy/local isolation.
- **Alternatives Considered**:
  - *Always enqueue-then-flush even when online*: Rejected per Clarification Q1 because it introduces momentary `pending` -> `syncing` -> `synced` flicker for normal online writes.

---

## Decision 3: Composite Domain Aggregate Sync Across the 18 `vifutboldev` Tables

- **Decision**: Map the 10 domain repository interfaces to normalized parent-child operations inside `vifutboldev` so every entity aggregate stays referentially intact on upsert and delete:
  1. `TournamentsRepository` -> `tournaments` (parent) + `rule_audit_entries` (`tournament_id` FK). Local `TournamentDraft` methods (`loadDraft`, `saveDraft`, `clearDraft`) remain 100% local.
  2. `VenuesRepository` -> `sports_venues` (parent) + `venue_pitches` (`venue_id` FK).
  3. `TeamsRepository` -> `teams` (parent) + `tournament_teams` (`tournament_id`, `team_id` FKs) + `players` (`team_id` FK).
  4. `TournamentMatchesRepository` -> `matches` + `match_referees`.
  5. `LineupsTrackingRepository` -> `player_internal_trackings` + `match_lineup_convocations`.
  6. `MatchReportsRepository` -> `digital_match_reports` (parent) + `match_events` (`report_id`, `match_id` FKs). Offline events created through `MatchReportsRepository.saveReport(..., newlyCreatedEvents: ...)` also register in the unified `SyncOutboxRepository` so the referee's offline goals/cards increment the AppBar badge accurately and flush once idempotently.
  7. `MatchAlertsRepository` -> `match_live_alerts`.
  8. `TournamentNewsRepository` -> `tournament_news`.
  9. `SeasonHonorRollRepository` -> `season_honor_rolls`.
  10. `FanFavoritesRepository` -> `fan_favorite_teams`.
- **Rationale**: Prevents foreign-key violations (`23503`) during cloud sync by persisting parent rows before child rows inside each aggregate mutation and ordering FIFO sync items by creation sequence.
- **Alternatives Considered**:
  - *Single generic table sync*: Rejected because `TournamentTeam` and `DigitalMatchReport` aggregate multiple normalized Postgres tables created in HU 17.2 (`202611110002`).

---

## Decision 4: Persistent FIFO Outbox (`HiveSyncOutboxRepository`), Mutex, and Non-Blocking Rejection Handling (Clarification Q2)

- **Decision**:
  - Implement `HiveSyncOutboxRepository` backed by `LocalStorageRepository` (using a dedicated namespace-scoped JSON/Hive persistence key `sync_outbox_v1` plus `sync_last_completed_at_v1`) so outbox items survive cold app restarts (`FR-004`) and work cleanly in tests via the in-memory `LocalStorageRepository` fallback.
  - Execute synchronization in `CloudSyncService` guarded by an internal single-flight async mutex (`_isFlushing` + coalesced rerun flag) triggered by:
    - `ConnectivityRepository.onConnectivityChanged` transitioning to `NetworkConnectionStatus.connected`,
    - Active user change / login where `ownerUserId` has queued items,
    - Explicit manual user trigger ("Sincronizar ahora") from `SyncStatusBottomSheet`.
  - Use idempotent UUID v4 primary keys (`onConflict: 'id'` on PostgREST `.upsert()`) and UTC `updated_at` LWW timestamps (`SC-002`).
  - **Non-transient server rejections (Clarification Q2)**: When processing FIFO items (`SyncOutboxItemStatus.queued` / `retrying`), if Supabase returns a transient network/timeout/5xx failure, increment `retryCount` and stop the current flush cycle cleanly in `offlineOrError` / `pending` state. If Supabase returns a non-transient 4xx business/permission/validation rejection (`PostgrestException` with `4xx` / `42501` RLS / `23xxx` constraint error), transition ONLY that item to `SyncOutboxItemStatus.error` storing `errorMessage` (human-readable Spanish cause) and **continue** flushing subsequent valid FIFO items (`continue` loop). Users can inspect, retry, or discard errored items inside `SyncStatusBottomSheet`.
- **Rationale**: Prevents head-of-line blocking where one invalid permission/validation item traps subsequent valid goals, rosters, or tournament edits offline, while still preserving FIFO causality for valid mutations.
- **Alternatives Considered**:
  - *Strict FIFO halt on first 4xx rejection*: Rejected per Clarification Q2 because a single bad item blocks all later valid data indefinitely.

---

## Decision 5: `ownerUserId` Queue Isolation & Safe Sign-Out Guard (Clarification Q3)

- **Decision**:
  - Tag every `SyncOutboxItem` with `ownerUserId` (the active `UserAccount.id` at creation time).
  - `SyncOutboxRepository` queries (`watchItemsForUser(userId)`, `loadPendingForUser(userId)`, `countPendingAndErrorsForUser(userId)`) and `CloudSyncService.flushForUser(userId)` filter strictly by the currently authenticated user ID. Items belonging to another user remain untouched and invisible in Hive across account switches.
  - When a user taps sign out in `ProfileTabView` and `pendingSyncCount > 0` (sum of `queued` + `retrying` + `error` items for the active `ownerUserId`), present an explicit 3-action confirmation dialog in Spanish:
    1. **"Sincronizar y salir"** (enabled when `NetworkConnectionStatus.connected`): invokes `cloudSyncService.flushOutbox()` first and proceeds to `signOut()` if zero pending/error items remain (or warns cleanly if errors persist).
    2. **"Salir conservando pendientes"**: executes `signOut()` without deleting the `ownerUserId` outbox entries in Hive; when that user signs back in later, `SyncStatusController` restores their count and flushes on connectivity.
    3. **"Cancelar"**: closes the dialog without signing out.
- **Rationale**: Protects team/referee offline work during shared-device account switches and satisfies Clarification Q3 verbatim.

---

## Decision 6: Role-Gated AppBar Sync Indicator & Bottom Sheet UX

- **Decision**:
  - Add `RoleCapability.viewCloudSyncIndicator` to `lib/domain/entities/role_permission_matrix.dart`, enabled for `{UserRole.organizer, UserRole.coach, UserRole.referee}` and disabled for `{UserRole.player, UserRole.fan}` (plus explicit guard against `user?.isGuestFan == true`).
  - Place `SyncStatusAppBarAction` inside `AppShellScreen`'s `AppBar.actions` list (just before `FanAlertsBellAction` so top-right action density remains balanced and keyboard/focus order is natural).
  - Visual & accessibility contract (`MOBILE_GUIDELINES.md` + `DESIGN.md`):
    - Minimum `48x48` logical pixel hit target (`ConstrainedBox(minWidth: 48, minHeight: 48)` inside `IconButton`/`InkWell`), exceeding `44x44` guideline.
    - Non-color-only state cues (distinct icon + badge count + semantic label):
      - `synced`: `Icons.cloud_done_outlined` (`KickPulseColors.accentPrimary` `#00E676` + tooltip "Datos sincronizados en la nube").
      - `pending`: `Icons.cloud_upload_outlined` (`#FFB300` amber + numeric `Badge` showing `pendingCount`).
      - `syncing`: animated rotating `Icons.sync` / subtle `CircularProgressIndicator` inside semantic wrapper (`tooltip`: "Sincronizando con la nube...").
      - `offlineOrError`: `Icons.cloud_off_outlined` or `Icons.error_outline` (`KickPulseColors.accentLive` `#FF3D71` + badge when count > 0 + tooltip "Sin conexión o error de sincronización").
    - Tapping opens `SyncStatusBottomSheet` showing: current connectivity status, human-readable last sync timestamp (`lastSyncedAt`), itemized pending/failed outbox entries with entity type + concise Spanish summary + failure reason (for `error` items), per-item "Reintentar" / "Descartar" controls, and a full-width "Sincronizar ahora" button.
  - All UI copy placed in `lib/l10n/app_es.arb` (`flutter gen-l10n`), enforcing Constitution Principle VI.
- **Rationale**: Satisfies `FR-006`, `FR-007`, `FR-008`, `FR-009`, and `MOBILE_GUIDELINES.md` non-color cue and touch-target requirements without polluting non-operational roles (`player`, `fan`, `guestFan`).
