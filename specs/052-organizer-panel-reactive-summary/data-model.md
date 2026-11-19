# Data Model: Reactive Organizer Panel Summary

**Feature**: `052-organizer-panel-reactive-summary` (HU 22.4)  
**Date**: 2026-11-19  
**Schema Changes**: None — reuses existing `vifutboldev.tournaments`, `vifutboldev.tournament_teams`, and `vifutboldev.matches` tables and local offline caches.

---

## 1. Derived Reactive Aggregates

### 1.1 `organizerTournamentsProvider` (`List<ChampionshipTournament>`)
- **Sources watched**:
  - `tournamentsControllerProvider` (`TournamentsCatalogState.tournaments`)
  - `authControllerProvider` (`AuthFlowState.session?.user.id`)
- **Isolation Rule (`FR-002`, HU 19.3)**:
  - `effectiveUserId = (sessionUserId != null && sessionUserId.trim().isNotEmpty) ? sessionUserId : 'org-seed-1'`
  - Filters strictly where `(t.organizerId ?? 'org-seed-1') == effectiveUserId`.
  - Guarantees zero cross-organizer leakage when multiple organizers exist in `vifutboldev.tournaments`.

### 1.2 `OrganizerPanelData` (`organizerPanelMetricsProvider`)
Computed purely by `computeOrganizerPanelMetrics(organizerTournaments, allMatches)`:

| Metric Field | Formula | Scope / Constraint |
|---|---|---|
| `activeTournamentsCount` | Count of `t` in `organizerTournaments` where `t.status == openRegistration \|\| t.status == inProgress` | Excludes `finished` and deleted competitions (FR-001) |
| `pendingScheduleMatchesCount` | Count of `m` in `allMatches` where `activeTournamentIds.contains(m.tournamentId)` AND `(m.status == pendingSchedule \|\| (m.status == scheduled && m.scheduledStartTime == null))` | Scoped strictly to active owned competitions; excludes `completed`/`inProgress` matches and other organizers' matches |
| `unseededTournamentsCount` | Count of `t` in `activeTournaments` where `!allMatches.any((m) => m.tournamentId == t.id)` | Drops by 1 immediately upon fixture generation; increments by 1 on new competition creation |

### 1.3 Per-Competition Card Summary (`OrganizerCompetitionsSection`)
- **Sources watched**:
  - `organizerTournamentsProvider`
  - `teamsControllerProvider` (`TeamsCatalogState.teams`)
- **Derived per card**:
  - `enrolledTeamsCount = teams.where((team) => team.tournamentId == tournament.id).length`
  - Rendered with `Key('organizer_competition_teams_badge_${tournament.id}')` and `l10n.competitionTeamsHeaderCount(enrolledTeamsCount)`.

---

## 2. Reactive Update & Hydration Triggers

```text
1. In-memory mutations (instant, <100ms, works offline & online):
   - TournamentsController (save / status transition / delete) ──▶ organizerTournamentsProvider ──▶ organizerPanelMetricsProvider + OrganizerCompetitionsSection
   - MatchesCatalogController (generateFixture / scheduleMatch) ──▶ organizerPanelMetricsProvider
   - TeamsController (enroll / withdraw / approve) ──▶ OrganizerCompetitionsSection (team count badge)

2. Cloud hydration triggers (FR-006):
   - OrganizerPanelContent.initState() ──▶ Future.wait([tournaments.loadCatalog(), teams.loadTeams(), matches.loadAllMatches(silent: true)])
   - authControllerProvider user ID change (sign-in / account switch) ──▶ _hydrateOrganizerData()
   - CloudSyncService.registerAfterSyncCallback (tournament / team / match) ──▶ refresh corresponding controller
   - RefreshIndicator (pull-to-refresh) ──▶ _hydrateOrganizerData()
```
