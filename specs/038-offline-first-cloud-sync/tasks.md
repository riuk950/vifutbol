---

description: "Actionable, dependency-ordered task list for HU 17.4: Offline-First Cloud Sync (vifutboldev) & AppBar Sync Indicator"
---

# Tasks: Arquitectura Offline-First, Sincronización en la Nube e Indicador de Estado de Datos (HU 17.4)

**Input**: Design documents from `/Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/data-model.md), [offline-sync-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/contracts/offline-sync-contracts.md), [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/quickstart.md)

**Tests**: Included per story in accordance with Project Constitution Principle III (`Pruebas Automatizadas`) and [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/plan.md). Tests are written before or alongside each story increment and verified passing.

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Parallelizable task (independent files, no unmet prerequisite dependencies).
- **[US1]..[US4]**: User story traceability matching `spec.md`. Setup, Foundational, and Polish tasks intentionally omit story labels.

---

## Phase 1: Setup (Shared Infrastructure & Contracts)

**Purpose**: Prepare core sync directory structure and verify toolchain/l10n generation readiness without altering existing domain behavior.

- [X] T001 Create directory layout under `lib/infrastructure/sync/`, `lib/presentation/sync/`, `test/infrastructure/sync/`, `test/unit/infrastructure/sync/`, and `test/widget/sync/` matching `specs/038-offline-first-cloud-sync/plan.md`
- [X] T002 [P] Add localized Spanish sync status, error reason, bottom sheet, and pending-logout strings to `lib/l10n/app_es.arb` and regenerate delegates via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Sync Core & Outbox Persistence)

**Purpose**: Build pure domain sync entities, outbox repository contract, persistent Hive outbox storage, error classifier, single-flight cloud sync engine, and Riverpod sync state controller. **CRITICAL**: Complete Phase 2 before starting US1–US4.

- [X] T003 [P] Create pure domain enums `SyncStatus` (`synced`, `pending`, `syncing`, `offlineOrError`), `SyncOutboxOperation` (`upsert`, `delete`, `replaceBatch`), `SyncOutboxEntityType` (`tournament`, `venue`, `team`, `match`, `lineupTracking`, `matchReport`, `matchAlert`, `tournamentNews`, `seasonHonorRoll`, `fanFavorite`), and `SyncOutboxItemStatus` (`queued`, `retrying`, `error`) in `lib/domain/entities/sync_status.dart`
- [X] T004 [P] Create immutable domain models `SyncOutboxItem` (fields: `id` UUID v4, `ownerUserId`, `entityType`, `entityId`, `operation`, `payloadJson` with UTC `updated_at`, `displayTitle`, `status`, `createdAt` UTC, `updatedAt` UTC, non-negative `retryCount >= 0`, nullable `errorMessage`), `SyncSummaryState`, and `SyncFlushResult` in `lib/domain/entities/sync_outbox_item.dart`
- [X] T005 Define pure domain `SyncOutboxRepository` (`loadItemsForUser`, `watchItemsForUser`, `enqueue`, `updateItem`, `removeItem`, `loadLastSyncedAt`, `saveLastSyncedAt`) in `lib/domain/repositories/sync_outbox_repository.dart` (depends on T003, T004)
- [X] T006 [P] Define pure domain `CloudSyncService` (`flushOutbox`, `retryErroredItem`, `discardItem`, `watchIsSyncing`) in `lib/domain/services/cloud_sync_service.dart` (depends on T004)
- [X] T007 Implement `HiveSyncOutboxRepository` backed by `LocalStorageRepository` keys `sync_outbox_items_v1` and `sync_last_synced_at_v1_<userId>` with strict `ownerUserId` filtering, FIFO ordering by `createdAt ASC`, and reactive broadcast updates in `lib/infrastructure/sync/hive_sync_outbox_repository.dart` (depends on T005)
- [X] T008 [P] Implement `SupabaseErrorClassifier` classifying transient failures (`SocketException`, `TimeoutException`, HTTP `5xx`) vs non-transient `4xx`/`42501`/`23xxx` PostgREST rejections with human-readable Spanish `errorMessage` mapping in `lib/infrastructure/sync/supabase_error_classifier.dart`
- [X] T009 Implement `SupabaseCloudSyncService` with single-flight async mutex + coalesced rerun, reactive subscription to `ConnectivityRepository.onConnectivityChanged`, entity dispatcher registry (`SyncOutboxEntityType` handler map), `retrying` stop on transient failure, non-blocking `error` marking on `4xx` rejection continuing subsequent FIFO items, and `retryErroredItem`/`discardItem` in `lib/infrastructure/sync/supabase_cloud_sync_service.dart` (depends on T006, T007, T008)
- [X] T010 Implement `SyncStatusController` (`StateNotifier<SyncSummaryState>`) combining `authControllerProvider` (`activeUserId`, `isGuestFan`), `connectivityRepositoryProvider`, `syncOutboxRepositoryProvider.watchItemsForUser`, `sync_last_synced_at_v1_<userId>`, and `cloudSyncServiceProvider.watchIsSyncing()` in `lib/application/controllers/sync_status_controller.dart` (depends on T005, T006)
- [X] T011 Wire `syncOutboxRepositoryProvider`, `cloudSyncServiceProvider`, `syncStatusControllerProvider`, and environment remote-sync eligibility helper (`environment == AppEnvironment.development && config.supabase.isConfigured && supabaseClient != null`) in `lib/application/providers/sync_providers.dart` (depends on T007, T009, T010)
- [X] T012 [P] Write unit tests for `HiveSyncOutboxRepository` verifying cold-restart JSON persistence, strict FIFO ordering, duplicate `id` coalescing, and `ownerUserId` isolation across accounts in `test/unit/infrastructure/sync/hive_sync_outbox_repository_test.dart` (depends on T007)
- [X] T013 [P] Write unit tests for `SupabaseCloudSyncService` verifying single-flight mutex against rapid connectivity flips, transient abort + retry counter increment, non-blocking `4xx` item isolation continuing remaining FIFO items, and `retryErroredItem`/`discardItem` in `test/unit/infrastructure/sync/supabase_cloud_sync_service_test.dart` (depends on T009)
- [X] T014 [P] Write unit tests for `SyncStatusController` verifying `SyncStatus` computation (`synced`, `pending`, `syncing`, `offlineOrError`), `totalAttentionCount`, and `lastSyncedAt` hydration per user in `test/unit/application/sync_status_controller_test.dart` (depends on T010)

**Checkpoint**: Outbox persistence, error classification, mutex sync loop, and reactive state computation are implemented and green in unit tests.

---

## Phase 3: User Story 1 - Lectura en Línea con Respaldo Local Automático en Todos los Módulos (Priority: P1) 🎯 MVP

**Goal**: Enable remote-first reads from Supabase schema `vifutboldev` when connected (automatically refreshing Hive local cache) and seamless transparent fallback to `Local*Repository` offline or on network timeout across all 10 domain modules, keeping `isGuestFan` and unconfigured environments local.

**Independent Test**: Open each module online in dev -> verify data loads from `vifutboldev` tables and warms Hive local cache; disconnect network -> reopen modules and confirm previously fetched entities render smoothly from local cache without fatal errors or fake data generation.

### Remote Read Data Sources & Hybrid Read Paths for US1

- [X] T015 [P] [US1] Implement remote read mapper & read-through `HybridTournamentsRepository` wrapping `LocalTournamentsRepository` for `vifutboldev.tournaments` + `vifutboldev.rule_audit_entries` (keeping `loadDraft`/`saveDraft`/`clearDraft` strictly local) in `lib/infrastructure/repositories/hybrid_tournaments_repository.dart`
- [X] T016 [P] [US1] Implement remote read mapper & read-through `HybridVenuesRepository` wrapping `LocalVenuesRepository` for `vifutboldev.sports_venues` + `vifutboldev.venue_pitches` in `lib/infrastructure/venues/hybrid_venues_repository.dart`
- [X] T017 [P] [US1] Implement remote read mapper & read-through `HybridTeamsRepository` wrapping `LocalTeamsRepository` for `vifutboldev.teams` + `vifutboldev.tournament_teams` + `vifutboldev.players` in `lib/infrastructure/repositories/hybrid_teams_repository.dart`
- [X] T018 [P] [US1] Implement remote read mapper & read-through `HybridTournamentMatchesRepository` wrapping `LocalTournamentMatchesRepository` for `vifutboldev.matches` + `vifutboldev.match_referees` (keeping `watchMatchesForTournament` reactive stream updated) in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`
- [X] T019 [P] [US1] Implement remote read mapper & read-through `HybridLineupsTrackingRepository` wrapping `LocalLineupsTrackingRepository` for `vifutboldev.player_internal_trackings` + `vifutboldev.match_lineup_convocations` in `lib/infrastructure/repositories/hybrid_lineups_tracking_repository.dart`
- [X] T020 [P] [US1] Implement remote read mapper & read-through `HybridMatchReportsRepository` wrapping `LocalMatchReportsRepository` for `vifutboldev.digital_match_reports` + `vifutboldev.match_events` in `lib/infrastructure/repositories/hybrid_match_reports_repository.dart`
- [X] T021 [P] [US1] Implement remote read mapper & read-through `HybridMatchAlertsRepository` wrapping `LocalMatchAlertsRepository` for `vifutboldev.match_live_alerts` (including reactive `watchAlerts`) in `lib/infrastructure/repositories/hybrid_match_alerts_repository.dart`
- [X] T022 [P] [US1] Implement remote read mapper & read-through `HybridTournamentNewsRepository` wrapping `LocalTournamentNewsRepository` for `vifutboldev.tournament_news` (including reactive `watchNewsForTournament`) in `lib/infrastructure/repositories/hybrid_tournament_news_repository.dart`
- [X] T023 [P] [US1] Implement remote read mapper & read-through `HybridSeasonHonorRollRepository` wrapping `LocalSeasonHonorRollRepository` for `vifutboldev.season_honor_rolls` in `lib/infrastructure/repositories/hybrid_season_honor_roll_repository.dart`
- [X] T024 [P] [US1] Implement remote read mapper & read-through `HybridFanFavoritesRepository` wrapping `LocalFanFavoritesRepository` for `vifutboldev.fan_favorite_teams` (strictly local when `isGuestFan == true`) in `lib/infrastructure/repositories/hybrid_fan_favorites_repository.dart`

### Conditional Provider Wiring & US1 Automated Verification

- [X] T025 [P] [US1] Update conditional Hybrid vs Local provider selection using `sync_providers.dart` in `lib/application/providers/tournaments_providers.dart`, `lib/application/providers/venues_providers.dart`, and `lib/application/providers/teams_providers.dart` (depends on T011, T015–T017)
- [X] T026 [P] [US1] Update conditional Hybrid vs Local provider selection using `sync_providers.dart` in `lib/application/providers/matches_catalog_providers.dart`, `lib/application/providers/lineups_tracking_providers.dart`, and `lib/application/providers/digital_match_report_providers.dart` (depends on T011, T018–T020)
- [X] T027 [P] [US1] Update conditional Hybrid vs Local provider selection using `sync_providers.dart` in `lib/application/providers/tournament_news_providers.dart`, `lib/application/providers/fan_alerts_and_favorites_providers.dart`, and `lib/application/providers/backup_and_season_closure_providers.dart` (depends on T011, T021–T024)
- [X] T028 [US1] Write unit tests covering remote-read-updates-local-cache, transient/offline fallback without crash, empty unseeded first-run offline behavior, and guest-fan local read isolation across all 10 hybrid repositories in `test/unit/infrastructure/sync/hybrid_repositories_read_test.dart` (depends on T015–T024)

**Checkpoint**: User Story 1 (P1 MVP read-through & offline cache fallback across all 10 domain modules) is independently functional and tested.

---

## Phase 4: User Story 2 - Guardado Local Offline y Cola Persistente de Sincronización Automática FIFO (Priority: P1) 🎯 MVP

**Goal**: Implement Clarification Q1 remote-first online mutations (updating local cache with zero outbox entry on success; persisting locally + enqueueing `SyncOutboxItem` on disconnection/network error), FIFO idempotent parent-before-child cloud replay handlers in `SupabaseCloudSyncService` using `uuid` + UTC `updated_at` LWW, non-blocking `4xx` rejection isolation (Q2), strict `ownerUserId` queue scoping (Q3), and zero cloud writes for `isGuestFan`.

**Independent Test**: Perform sequential offline writes across modules, cold-restart app verifying items remain intact in Hive scoped to the logged-in `ownerUserId`, restore connectivity and confirm FIFO chronological replay onto `vifutboldev` without duplicates while returning `pendingSyncCount` to zero; verify connected remote-first writes do not leave outbox items and one `4xx` rejected item marks only itself `error` while subsequent FIFO items succeed.

### Hybrid Write Mutations & Parent-Child Remote Upserts/Deletes

- [X] T029 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.tournament`), and replay handler (`tournaments` -> `rule_audit_entries`, preserving local drafts) to `lib/infrastructure/repositories/hybrid_tournaments_repository.dart` (depends on T015)
- [X] T030 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.venue`), and replay handler (`sports_venues` -> `venue_pitches`) to `lib/infrastructure/venues/hybrid_venues_repository.dart` (depends on T016)
- [X] T031 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.team`), and replay handler (`teams` -> `tournament_teams` -> `players`, plus `replaceTeamsForTournament` / `deleteTeam`) to `lib/infrastructure/repositories/hybrid_teams_repository.dart` (depends on T017)
- [X] T032 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.match`), and replay handler (`matches`, `saveMatchesBatch`, `replaceMatchesForTournament`) to `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart` (depends on T018)
- [X] T033 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.lineupTracking`), and replay handler (`player_internal_trackings`, `match_lineup_convocations`) to `lib/infrastructure/repositories/hybrid_lineups_tracking_repository.dart` (depends on T019)
- [X] T034 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.matchReport`), and replay handler (`digital_match_reports` -> `match_events` idempotent UUID upsert, unifying `loadPendingSyncQueue`/`synchronizePendingEvents`) to `lib/infrastructure/repositories/hybrid_match_reports_repository.dart` (depends on T020)
- [X] T035 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.matchAlert`), and replay handler (`match_live_alerts`: `saveAlert`, `markAsRead`, `markAllAsRead`, `clearAlerts`) to `lib/infrastructure/repositories/hybrid_match_alerts_repository.dart` (depends on T021)
- [X] T036 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.tournamentNews`), and replay handler (`tournament_news`: `saveNewsItem`, `deleteNewsItem`, `replaceNewsForTournament`) to `lib/infrastructure/repositories/hybrid_tournament_news_repository.dart` (depends on T022)
- [X] T037 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.seasonHonorRoll`), and replay handler (`season_honor_rolls`: `saveHonorRoll`, `deleteHonorRollForTournament`) to `lib/infrastructure/repositories/hybrid_season_honor_roll_repository.dart` (depends on T023)
- [X] T038 [P] [US2] Add remote-first online write, offline local+outbox enqueue (`SyncOutboxEntityType.fanFavorite`), and replay handler (`fan_favorite_teams`: `saveFavoriteTeam`, `removeFavoriteTeam`, `toggleFavoriteTeam`, strictly bypassing outbox/remote for `isGuestFan`) to `lib/infrastructure/repositories/hybrid_fan_favorites_repository.dart` (depends on T024)

### Replay Wiring & US2 Automated Verification

- [X] T039 [US2] Register all 10 `SyncOutboxEntityType` replay handlers (`onConflict: 'id'` + UTC `updated_at` LWW + local cache refresh after flush) and active authenticated user reconnect flush trigger inside `lib/application/providers/sync_providers.dart` and `lib/infrastructure/sync/supabase_cloud_sync_service.dart` (depends on T029–T038)
- [X] T040 [US2] Write comprehensive unit tests covering Q1 remote-first connected writes (`pendingCount == 0`), offline fallback enqueueing across all 10 entity types, guest-fan zero-outbox isolation, parent-before-child replay ordering, idempotent retry deduplication (`SC-002`), and Q2/Q3 queue behaviors in `test/unit/infrastructure/sync/hybrid_repositories_offline_first_test.dart` (depends on T039)

**Checkpoint**: User Story 2 (complete offline-first write + persistent FIFO sync MVP across all 10 domain modules) is independently functional and verified.

---

## Phase 5: User Story 3 - Indicador de Estado de Datos en el Encabezado Visible Solo por Rol Operativo (Priority: P2)

**Goal**: Surface `SyncStatusAppBarAction` inside `AppShellScreen.AppBar.actions` strictly for operational roles `{UserRole.organizer, UserRole.coach, UserRole.referee}` (and non-guest, remote-enabled sessions), visually communicating all 4 states (`synced`, `pending` with numeric badge, animated `syncing`, `offlineOrError`) with accessible icons/semantics and minimum `48x48` tap target.

**Independent Test**: Toggle active role across all 5 `UserRole` values plus `guestFan` mode in widget tests; assert `Key('app_bar_sync_status_action')` renders for `organizer`/`coach`/`referee`, hides completely for `player`/`fan`/`guestFan`, and transitions visually across all 4 `SyncStatus` states.

- [X] T041 [US3] Add `RoleCapability.viewCloudSyncIndicator` enabled exclusively for `{UserRole.organizer, UserRole.coach, UserRole.referee}` and disabled for `{UserRole.player, UserRole.fan}` in `lib/domain/entities/role_permission_matrix.dart`
- [X] T042 [P] [US3] Write unit tests validating `RolePermissionMatrix.hasCapability(..., RoleCapability.viewCloudSyncIndicator)` across all 5 roles in `test/unit/domain/role_permission_matrix_sync_test.dart` (depends on T041)
- [X] T043 [US3] Build `SyncStatusAppBarAction` (`Key('app_bar_sync_status_action')`, `Key('app_bar_sync_status_badge')`) enforcing `48x48` minimum tap target, KickPulse semantic colors (`#00E676`, `#FFB300`, `#FF3D71`), distinct icons (`Icons.cloud_done_outlined`, `Icons.cloud_upload_outlined`, animated `Icons.sync`, `Icons.cloud_off_outlined`/`Icons.error_outline`), numeric badge, `Semantics`/tooltip from `l10n`, and strict role/`!isGuestFan` gating in `lib/presentation/sync/sync_status_app_bar_action.dart` (depends on T002, T011, T041)
- [X] T044 [US3] Insert `SyncStatusAppBarAction` inside `AppBar.actions` before `FanAlertsBellAction` in `lib/presentation/shell/app_shell_screen.dart` without displacing existing calendar/news/alerts controls (depends on T043)
- [X] T045 [US3] Write widget tests verifying AppBar indicator role visibility (`organizer`, `coach`, `referee` vs hidden for `player`, `fan`, `guestFan`), 4-state icon/badge updates, `>= 44x44` hit target, and 1.3x text-scaling stability in `test/widget/shell/app_bar_sync_indicator_test.dart` (depends on T044)

**Checkpoint**: User Story 3 (role-gated AppBar sync indicator with all 4 accessible states) is independently testable and verified.

---

## Phase 6: User Story 4 - Panel de Resumen de Sincronización, Disparo Manual y Protección de Cierre de Sesión (Priority: P2)

**Goal**: Deliver `SyncStatusBottomSheet` (last sync timestamp, itemized pending/error items with readable Spanish descriptions and per-item `"Reintentar"` / `"Descartar"` buttons, plus single-flight `"Sincronizar ahora"` CTA) and the Q3 sign-out guard dialog (`SignOutPendingSyncDialog`) in `ProfileTabView` when `pendingSyncCount > 0`.

**Independent Test**: Open `SyncStatusBottomSheet` from `SyncStatusAppBarAction` with pending + errored items -> assert timestamps, Spanish rejection reason, single-flight `"Sincronizar ahora"` button behavior, and `"Reintentar"`/`"Descartar"`; trigger sign out with `pendingSyncCount > 0` -> confirm 3-option dialog (`"Sincronizar y salir"`, `"Salir conservando pendientes"`, `"Cancelar"`) protects queued items per `ownerUserId`.

- [X] T046 [P] [US4] Build `SyncStatusBottomSheet` displaying connectivity pill, localized `lastSyncedAt` timestamp ("Aún sin sincronizar" when null), scrollable `SyncOutboxItem` list (`displayTitle`, entity label, status pill, Spanish `errorMessage`, `>=44px` `"Reintentar"` and `"Descartar"` buttons), and single-flight `"Sincronizar ahora"` button (`Key('sync_now_button')`) in `lib/presentation/sync/sync_status_bottom_sheet.dart` (depends on T002, T011)
- [X] T047 [US4] Connect `SyncStatusAppBarAction` tap action to open `SyncStatusBottomSheet.show(context)` in `lib/presentation/sync/sync_status_app_bar_action.dart` (depends on T043, T046)
- [X] T048 [P] [US4] Build `SignOutPendingSyncDialog` in Spanish offering `"Sincronizar y salir"` (`Key('logout_sync_and_exit_button')`, enabled when connected), `"Salir conservando pendientes"` (`Key('logout_keep_pending_button')`), and `"Cancelar"` (`Key('logout_cancel_button')`) in `lib/presentation/sync/sign_out_pending_sync_dialog.dart` (depends on T002, T011)
- [X] T049 [US4] Update `ProfileTabView._handleLogout` to inspect `syncStatusControllerProvider.totalAttentionCount` (for authenticated non-guest accounts) and show `SignOutPendingSyncDialog` before calling `authControllerProvider.notifier.signOut()` (preserving existing dialog when `totalAttentionCount == 0`) in `lib/presentation/shell/tabs/profile_tab_view.dart` (depends on T048)
- [X] T050 [P] [US4] Write widget tests for `SyncStatusBottomSheet` (timestamp rendering, empty synced view, pending + error item controls `"Reintentar"`/`"Descartar"`, disabled `"Sincronizar ahora"` offline/while syncing, double-tap protection) in `test/widget/sync/sync_status_bottom_sheet_test.dart` (depends on T046)
- [X] T051 [P] [US4] Write widget tests for `SignOutPendingSyncDialog` and `ProfileTabView._handleLogout` verifying all 3 branches (`"Sincronizar y salir"`, `"Salir conservando pendientes"` preserving `ownerUserId` outbox items, `"Cancelar"`) and standard dialog fallback when `totalAttentionCount == 0` in `test/widget/sync/sign_out_pending_sync_dialog_test.dart` (depends on T049)

**Checkpoint**: All 4 user stories (US1–US4) and all 3 Clarifications (Q1–Q3) are implemented and verified by automated unit and widget tests.

---

## Phase 7: Polish, Full Regression & DEV Cloud Verification

**Purpose**: Ensure formatting, zero analyzer issues, full regression pass, and live DEV validation against `vifutboldev` on `emulator-5554`.

- [X] T052 Run `flutter gen-l10n` and `dart format --output=none --set-exit-if-changed lib test` fixing any formatting diffs across modified Dart files
- [X] T053 Run `flutter analyze` and resolve any static analysis warnings or dead code notices to exit cleanly (`No issues found`)
- [X] T054 Run full automated suite `flutter test` across unit and widget tests confirming zero failures or regressions
- [ ] T055 Execute live DEV verification Scenarios A–D from `specs/038-offline-first-cloud-sync/quickstart.md` on `emulator-5554` against Supabase `vifutboldev` (checking role visibility, online remote-first, offline queue cold-restart preservation, `< 5s` reconnect flush without duplicate rows, `4xx` non-blocking error card, and sign-out preservation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — starts immediately.
- **Phase 2 (Foundational)**: Depends on T001–T002; **BLOCKS Phases 3, 4, 5, and 6**.
- **Phase 3 (US1 — Read-through + Cache)**: Depends on Phase 2 completion. Delivers online reads + offline cache fallback for all 10 repositories.
- **Phase 4 (US2 — Offline Writes + FIFO Replay)**: Depends on Phase 3 (adds mutation & replay logic into the 10 hybrid repositories and provider dispatcher). Can begin per-repository as soon as each repository's Phase 3 read implementation finishes.
- **Phase 5 (US3 — Role-Gated AppBar Indicator)**: Depends on Phase 2 (`syncStatusControllerProvider` + l10n); independent of Phase 3/4 hybrid internals and can execute in parallel once Phase 2 passes.
- **Phase 6 (US4 — Bottom Sheet & Sign-Out Guard)**: Depends on Phase 5 (`SyncStatusAppBarAction` tap hook) and Phase 2 (`SyncStatusController` + `CloudSyncService`).
- **Phase 7 (Polish & DEV E2E)**: Depends on Phases 3–6 completion.

### Parallel Opportunities

- **Phase 2**: T003 + T004 (`sync_status.dart`, `sync_outbox_item.dart`) in parallel; T005 + T006 in parallel; T008 (`SupabaseErrorClassifier`) in parallel with T007 (`HiveSyncOutboxRepository`); T012 + T013 + T014 unit tests in parallel once implementations exist.
- **Phase 3 (US1)**: All 10 hybrid read adapters T015–T024 target separate files and can be built in parallel; provider batches T025–T027 run in parallel immediately afterward.
- **Phase 4 (US2)**: All 10 hybrid write + replay implementations T029–T038 target separate files and can be built in parallel before wiring dispatcher T039.
- **Phase 5 & Phase 6**: `RolePermissionMatrix` test (T042) runs in parallel with UI; `SyncStatusBottomSheet` (T046) and `SignOutPendingSyncDialog` (T048) + their widget tests (T050, T051) parallelize across separate files.

---

## Parallel Example: Phase 3 (US1) & Phase 4 (US2)

```bash
# Phase 3 (US1) — Build remote read + cache fallback adapters simultaneously:
Task: "T015 [P] [US1] HybridTournamentsRepository read path in lib/infrastructure/repositories/hybrid_tournaments_repository.dart"
Task: "T016 [P] [US1] HybridVenuesRepository read path in lib/infrastructure/venues/hybrid_venues_repository.dart"
Task: "T017 [P] [US1] HybridTeamsRepository read path in lib/infrastructure/repositories/hybrid_teams_repository.dart"
# ...through T024 in parallel

# Phase 6 (US4) — Build UI surfaces and tests in parallel:
Task: "T046 [P] [US4] SyncStatusBottomSheet in lib/presentation/sync/sync_status_bottom_sheet.dart"
Task: "T048 [P] [US4] SignOutPendingSyncDialog in lib/presentation/sync/sign_out_pending_sync_dialog.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US2 Core Sync Pipeline)

1. Complete **Phase 1 + Phase 2** (Foundational sync core, Hive outbox, mutex service, error classifier, sync controller).
2. Complete **Phase 3 (US1)** -> Verify online reads from `vifutboldev` warm local Hive cache and offline reads render safely.
3. Complete **Phase 4 (US2)** -> Verify remote-first online writes, offline FIFO queuing, cold-restart durability, non-blocking `4xx` isolation, and `ownerUserId` scoping. **At this checkpoint, data safety & cloud synchronization MVP is live.**
4. Layer **Phase 5 (US3)** + **Phase 6 (US4)** for AppBar visibility by role, manual sync drawer, retry/discard UX, and sign-out protection.
5. Finish with **Phase 7** (`dart format`, `flutter analyze`, `flutter test`, and live DEV E2E checks on `emulator-5554`).

---

## Notes

- All domain files under `lib/domain/` MUST NOT import `supabase_flutter` or `hive` (Constitution Principle IV).
- Keep all technical code/test identifiers in English and all UI strings in `lib/l10n/app_es.arb` (Constitution Principle VI).
- All interactive AppBar and BottomSheet action controls must maintain `>= 48x48` logical pixels hit target and non-color state differentiation (`MOBILE_GUIDELINES.md`).
