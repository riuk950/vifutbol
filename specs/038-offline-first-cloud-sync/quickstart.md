# Quickstart & Verification Guide: Arquitectura Offline-First y Sincronización en la Nube (HU 17.4)

**Feature Branch**: `038-offline-first-cloud-sync`  
**Target Environment**: Development (`--dart-define=APP_ENV=dev` / `.env.dev`, Supabase schema `vifutboldev`)

---

## 1. Prerequisites

1. Ensure `.env.dev` contains valid `SUPABASE_DEV_URL` and `SUPABASE_DEV_ANON_KEY` (already configured from HU 17.1–17.3).
2. Ensure Supabase self-hosted stack (`vifutboldev` schema, 18 tables, RLS active) is reachable on the dev host.
3. Generate updated localization delegates whenever `lib/l10n/app_es.arb` changes:
   ```bash
   flutter gen-l10n
   ```

---

## 2. Automated Verification Commands

Run formatting, static analysis, and unit/widget/integration tests after implementation:

```bash
# 1. Regenerate l10n and format check
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test

# 2. Static analysis (must exit 0 with No issues found)
flutter analyze

# 3. Targeted sync unit & widget tests
flutter test test/unit/infrastructure/sync/
flutter test test/unit/application/sync_status_controller_test.dart
flutter test test/widget/sync/
flutter test test/widget/shell/app_bar_sync_indicator_test.dart

# 4. Full regression suite
flutter test
```

---

## 3. Manual E2E Offline-First Validation on DEV Emulator (`emulator-5554`)

### Scenario A — Organizer/Coach/Referee Visibility vs Fan/Player/Guest Hiding (`FR-006`, `FR-009`)
1. Launch app in dev: `flutter run -d emulator-5554`.
2. Sign in as `organizador1@gmail.com` (`UserRole.organizer`).
   - **Expected**: Cloud sync indicator icon (`Icons.cloud_done_outlined`) appears in `AppBar.actions` with no error badge.
3. Switch role in Profile tab to `Jugador` (`UserRole.player`) and `Aficionado` (`UserRole.fan`), or sign in as Guest Fan.
   - **Expected**: Cloud sync indicator disappears immediately from `AppBar.actions`.

### Scenario B — Online Remote-First Write (`Clarification Q1`)
1. Stay connected (`adb shell svc wifi enable`), signed in as Organizer.
2. Create or update a tournament / team / match.
   - **Expected**: AppBar stays `synced` (`pendingCount == 0`), and row appears immediately in `vifutboldev`.

### Scenario C — Offline Mutation -> Reconnect Auto-Sync (`FR-002`–`FR-005`, `SC-001`–`SC-004`)
1. Switch to Referee (`UserRole.referee`), open an active match digital report, and disable network (`adb shell svc wifi disable && adb shell svc data disable`).
2. Record 2 offline events (e.g., 1 goal, 1 yellow card).
   - **Expected**: AppBar immediately shows amber/error offline indicator with badge `2`; tapping it opens `SyncStatusBottomSheet` listing both pending events; data persists locally.
3. Re-enable network (`adb shell svc wifi enable && adb shell svc data enable`).
   - **Expected**: Within 5 seconds (`SC-004`), indicator briefly animates `syncing` then settles to green `synced` (`pendingCount == 0`), and both `match_events` rows exist exactly once in `vifutboldev.match_events` (`SC-002`).

### Scenario D — Non-Transient Rejection & Sign-Out Preservation (`Clarifications Q2 & Q3`)
1. While offline, enqueue a valid change plus an item designed to fail server validation/RLS, then reconnect:
   - **Expected**: Valid item flushes cleanly; rejected item stays marked `Error` in `SyncStatusBottomSheet` with a Spanish reason + `"Reintentar"` / `"Descartar"` actions (`Q2`).
2. Tap Sign Out while `pendingSyncCount > 0`:
   - **Expected**: 3-option dialog prompts `"Sincronizar y salir"`, `"Salir conservando pendientes"`, `"Cancelar"`. Choosing `"Salir conservando pendientes"` signs out safely; logging back in with the same account restores the pending count and flushes on connectivity (`Q3`).
