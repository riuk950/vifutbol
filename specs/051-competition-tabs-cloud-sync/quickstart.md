# Quickstart & Verification Guide: HU 22.3 Competition Tabs Cloud Sync

**Feature**: `051-competition-tabs-cloud-sync`  
**Date**: 2026-11-19

---

## 1. Automated Verification Commands

Run targeted unit, repository, sync, and widget tests for HU 22.3:

```bash
flutter test \
  test/infrastructure/repositories/hybrid_tournaments_repository_test.dart \
  test/infrastructure/repositories/hybrid_teams_repository_test.dart \
  test/infrastructure/sync/supabase_cloud_sync_service_test.dart \
  test/presentation/tournaments/competition_detail_screen_test.dart \
  test/presentation/tournaments/competition_info_tab_view_test.dart \
  test/presentation/tournaments/competition_teams_tab_view_test.dart \
  test/presentation/tournaments/competition_standings_tab_view_test.dart \
  test/presentation/tournaments/competition_fixture_widget_test.dart
```

Run static analysis (must report **0 issues**):

```bash
flutter analyze
```

---

## 2. Manual E2E Cold-Start & Cross-Device Validation Scenarios

### Scenario A — Competition Info, Rules & Audit Cloud Sync (SC-001)
1. Sign in as Organizer (`organizador` account) on DEV environment (`vifutboldev`).
2. Edit `Liga1`: update scoring rules / tiebreaker order / linked venues and save.
3. Verify top-bar sync indicator transitions to synced (`Sincronizado`).
4. Clear local app storage (or sign in on a second device / incognito session as Fan or Coach).
5. Open `Liga1` → **"Información"** tab.
6. **Expected**: All rules, tiebreakers, linked venue, status, and rule audit entries appear within 5 seconds identically to what was saved.

### Scenario B — Teams Enrollment, Group Move, Eligibility & Withdrawal (SC-002)
1. As Organizer on `Liga1` → **"Equipos"** tab:
   - Toggle a team's eligibility (`Pendiente` ↔ `Habilitado`).
   - Move a team to another group (if mixed format) or withdraw a test team.
2. Clear local storage (or reload on a second device) and open `Liga1` → **"Equipos"**.
3. **Expected**: Exact same team roster, group assignment, and eligibility badges appear; withdrawn team does not reappear.

### Scenario C — Deterministic Standings Consistency (SC-003)
1. Record or update an official match result / report in `Liga1`.
2. Open `Liga1` → **"Clasificación"** tab on a second device (or after clearing local cache).
3. Pull to refresh on **"Clasificación"**.
4. **Expected**: Every row (`PJ, PG, PE, PP, GF, GC, DG, PTS`) and tiebreaker ordering matches identically across devices.

### Scenario D — Offline Dependency-Ordered Recovery (SC-004)
1. Disconnect network (Airplane mode).
2. As Organizer, edit competition rules, toggle a team's eligibility, and update a match score.
3. Verify changes persist locally and the top-bar sync indicator shows pending items.
4. Reconnect network.
5. **Expected**: Outbox flushes automatically in strict order (`venue → tournament → team → match → matchReport → seasonHonorRoll`) with zero `23503` FK errors and zero duplicates; all tabs remain accessible offline without crashes.
