# Research & Technical Audit: Reactive Organizer Panel Summary

**Feature**: `052-organizer-panel-reactive-summary` (HU 22.4)  
**Date**: 2026-11-19  
**Scope**: Real-time reactive updates, cold-start & post-sync cloud hydration, strict organizer isolation (`organizerId == currentUserId`), and visual parity between General Summary cards and "Mis Competiciones" in `OrganizerPanelContent`.

---

## 1. Gap 1 — Missing Cold-Start Hydration, Account-Switch Re-hydration & Pull-to-Refresh in `OrganizerPanelContent`

### Decision
Convert `OrganizerPanelContent` (`lib/presentation/panel/widgets/organizer_panel_content.dart`) from `ConsumerWidget` to `ConsumerStatefulWidget` with:
1. `initState()` parallel cloud hydration (`_hydrateOrganizerData()`, guarded by `_isHydrating`):
   - `ref.read(tournamentsControllerProvider.notifier).loadCatalog()`
   - `ref.read(teamsControllerProvider.notifier).loadTeams()`
   - `ref.read(matchesCatalogControllerProvider.notifier).loadAllMatches(silent: true)`
2. Reactive `ref.listen(authControllerProvider, ...)` watching `session?.user.id`: when the signed-in organizer changes (account switch / fresh sign-in), automatically re-run `_hydrateOrganizerData()`.
3. `RefreshIndicator` with `AlwaysScrollableScrollPhysics()` wrapping the `SingleChildScrollView` so organizers can manually pull to refresh at any time without losing cached counts on transient errors.

### Audit Findings
- `OrganizerPanelContent` is currently a stateless `ConsumerWidget` with zero hydration calls and no `RefreshIndicator`.
- `MatchesCatalogController` (`lib/application/controllers/matches_catalog_controller.dart`) initializes with `matches: const []` and does NOT load matches in its constructor. Consequently, opening `/panel` on a fresh session shows `pendingScheduleMatchesCount == 0` and falsely classifies every active tournament (even those with synced cloud fixtures) under "Torneos sin Fixture" until the organizer manually opens each competition.

### Rationale
Directly resolves US3 (cold-start & account-switch hydration) and FR-006 / FR-008 while keeping back-navigation instant (in-memory reactive state updates with zero redundant network requests per Clarification Q2).

### Alternatives Considered
- **Calling `loadAllMatches()` inside `MatchesCatalogController` constructor**: Rejected because `MatchesCatalogController` is used by multiple non-organizer flows and isolated widget tests that expect a clean initial state; triggering parallel hydration from `OrganizerPanelContent.initState()` and post-sync callbacks keeps side effects explicit and testable.

---

## 2. Gap 2 — Automatic Post-Sync Controller Refresh in `cloudSyncBootstrapProvider`

### Decision
Register an `OutboxSyncedCallback` on `SupabaseCloudSyncService` inside `cloudSyncBootstrapProvider` (`lib/application/providers/sync_bootstrap_provider.dart`) so that whenever background cloud synchronization completes for `tournament`, `team`, or `match` entities, the corresponding Riverpod controller (`tournamentsControllerProvider`, `teamsControllerProvider`, `matchesCatalogControllerProvider`) refreshes cleanly.

### Audit Findings
- `SupabaseCloudSyncService` (`lib/infrastructure/sync/supabase_cloud_sync_service.dart`) already exposes `registerAfterSyncCallback(OutboxSyncedCallback)` and invokes registered callbacks after each synced outbox item.
- `cloudSyncBootstrapProvider` currently instantiates the 10 hybrid repositories (registering replay handlers) but registers **zero** post-sync UI refresh callbacks.

### Rationale
Guarantees that when offline mutations finish syncing to `vifutboldev` or background sync completes, `organizerPanelMetricsProvider` and `OrganizerCompetitionsSection` immediately reflect the synchronized cloud state (FR-006, US3 Scenario 1).

### Alternatives Considered
- **Polling on a timer**: Rejected (wastes battery/bandwidth and violates reactive architecture).

---

## 3. Gap 3 — `computeOrganizerPanelMetrics` Active-Tournament & Pending-Match Precision

### Decision
Refine `computeOrganizerPanelMetrics` (`lib/application/providers/tournaments_providers.dart`) so that:
- `activeTournaments` = owned competitions where `status == TournamentStatus.openRegistration || status == TournamentStatus.inProgress` (excluding `finished`, per Clarification Q1 / FR-001).
- `activeTournamentIds` = IDs of `activeTournaments`.
- `pendingScheduleMatchesCount` = matches belonging to `activeTournamentIds` where `m.status == MatchStatus.pendingSchedule || (m.status == MatchStatus.scheduled && m.scheduledStartTime == null)` (excluding `completed`/`inProgress` matches and excluding `finished`/deleted competitions).
- `unseededTournamentsCount` = `activeTournaments` with zero matches in `allMatches`.

### Audit Findings
- Currently `computeOrganizerPanelMetrics` counts `organizerTournamentIds.contains(m.tournamentId) && m.scheduledStartTime == null`, which would erroneously include unscheduled matches belonging to a `finished` tournament or a `completed` match whose `scheduledStartTime` is null.

### Rationale
Ensures 100% mathematical parity between General Summary counters and actual pending organizer actions across all competition lifecycle transitions (US1, US2, FR-001, FR-005, FR-007).

---

## 4. Gap 4 — Live Enrolled Team Count Badge in `OrganizerCompetitionsSection`

### Decision
Watch `teamsControllerProvider` in `OrganizerCompetitionsSection` (`lib/presentation/panel/widgets/organizer_competitions_section.dart`) and render a live enrolled team count chip (`Key('organizer_competition_teams_badge_${tournament.id}')`) on each competition card using localized Spanish copy (`l10n.competitionTeamsHeaderCount(teamCount)`).

### Audit Findings
- `OrganizerCompetitionsSection` currently watches only `organizerTournamentsProvider` and displays status, category, and format badges—without showing the live enrolled team count.
- Watching `teamsControllerProvider` ensures that enrolling, approving, or withdrawing teams updates the competition card immediately on return to the Organizer Panel (US2 Scenario 3, FR-005, FR-007).

### Rationale
Reuses existing `l10n.competitionTeamsHeaderCount(count)` (zero new l10n keys required) and guarantees 100% parity between the panel card and the "Equipos" tab inside `CompetitionDetailScreen`.
