# Quickstart Validation Guide: HU 22.1 Fixture & Match Schedule Cloud Sync

**Feature**: `049-fixture-schedule-cloud-sync`
**References**: [spec.md](spec.md), [data-model.md](data-model.md), [contracts/matches_cloud_sync_contract.md](contracts/matches_cloud_sync_contract.md)

## 1. Prerequisites

- Flutter SDK installed and project dependencies fetched (`flutter pub get`).
- Environment configured for Supabase DEV (`vifutboldev` on Oracle Cloud).
- At least one competition in `openRegistration` with >= 2 eligible teams (e.g., `Liga1` with the 20 seeded eligible teams).
- Organizer test account (e.g., `organizador12@gmail.com`) and a second non-organizer account (e.g., `player1@gmail.com` or `entrenador1@gmail.com`).

## 2. Automated Verification Commands

```bash
# 1. Static analysis (must exit with 0 errors and 0 warnings)
flutter analyze

# 2. Unit tests for hybrid matches repository, outbox replay, use case, and daily feed
flutter test test/infrastructure/repositories/hybrid_tournament_matches_repository_test.dart
flutter test test/unit/application/fixture_scheduling_use_case_test.dart
flutter test test/unit/application/daily_matches_feed_controller_test.dart

# 3. Widget tests for ScheduleMatchDialog, CompetitionFixture, and MatchdayTabView
flutter test test/presentation/tournaments/competition_fixture_widget_test.dart
flutter test test/presentation/matches/matchday_tab_view_test.dart
```

## 3. End-to-End Validation Scenarios (DEV Cloud)

### Scenario A — Batch Fixture Generation & Cross-Device Persistence (US1)
1. Sign in as Organizer and open `Liga1` → **Fixture / Jornadas**.
2. Tap FAB → **"Generar Fixture"**.
3. **Expected**: All generated rounds appear immediately; top-bar sync badge settles to synced; querying `vifutboldev.matches` in DEV shows the exact count of generated matches with matching UUIDs.
4. Restart the app (or sign in as `player1@gmail.com`) and open `Liga1` → **Fixture**.
5. **Expected**: All rounds and matches load identically with zero duplicates.

### Scenario B — Fixture Regeneration Guard & Clean Replacement (FR-002a)
1. With no matches started/completed in `Liga1`, tap **"Generar Fixture"** again.
2. **Expected**: Confirmation dialog appears in Spanish; upon confirming, prior remote rows are pruned and replaced cleanly in `vifutboldev.matches` with zero orphaned rows.

### Scenario C — Match Scheduling with Optional Logistics & Immediate Visibility in "Partidos" (US2, US3)
1. Tap an unscheduled match in Jornada 1 to open `ScheduleMatchDialog`.
2. Set a future date and start time, leaving venue/pitch/referee unassigned (or assigning them), and tap **"Confirmar Programación"**.
3. **Expected**: Match saves and syncs to `vifutboldev.matches` with `status = 'scheduled'` and `scheduled_at` set; top-bar sync indicator reflects synced state.
4. Switch to the main **"Partidos"** tab and select that date in the calendar.
5. **Expected**: The match appears under `Liga1` with teams, start time, status, and venue/pitch/referee (or `"Por definir"` when unassigned). Unscheduled matches do **not** appear in **"Partidos"**.
6. Reload the app as a different role (`player1@gmail.com` or `entrenador1@gmail.com`), open **"Partidos"**, and select that date.
7. **Expected**: The scheduled match loads automatically from Supabase DEV and matches identical details.

### Scenario D — Offline Generation/Scheduling & Reconnect Recovery (US4)
1. Enable airplane mode / disconnect network.
2. Schedule another match (or generate a fixture on a second competition).
3. **Expected**: Changes save locally immediately; top-bar sync indicator shows offline/pending count.
4. Restore network connectivity.
5. **Expected**: `SupabaseCloudSyncService` automatically flushes the FIFO outbox to `vifutboldev.matches`; zero duplicate rows exist in the cloud database; top-bar indicator returns to synced.
