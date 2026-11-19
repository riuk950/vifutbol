# Research & Technical Audit: Competition Tabs Cloud Persistence and Synchronization

**Feature**: `051-competition-tabs-cloud-sync` (HU 22.3)  
**Date**: 2026-11-19  
**Scope**: Cloud persistence, lossless rule serialization, cold-start parallel hydration, deterministic standings computation, and dependency-ordered offline recovery for the "Información", "Equipos", and "Clasificación" tabs of `CompetitionDetailScreen`.

---

## 1. Live Database Schema Verification (`vifutboldev`)

### Decision
Reuse the existing PostgreSQL schema in `vifutboldev` without introducing new SQL migrations.

### Audit Findings
Inspection of the live DEV Supabase database (`vifutboldev`) confirmed that all required tables, JSONB columns, foreign keys, and Row Level Security (RLS) policies are already deployed and aligned with the domain entities:
- `vifutboldev.tournaments`: Stores `id` (uuid PK), `name`, `category`, `start_date`, `end_date`, `format`, `status`, `rules_config` (`jsonb`), `venue_ids` (`uuid[]`), `created_by`, `created_at`, `updated_at`. RLS: `select_public` (all roles), `insert/update/delete_organizer` (authenticated organizer).
- `vifutboldev.rule_audit_entries`: Stores `id` (uuid PK), `tournament_id` (FK → `tournaments.id`), `actor_role`, `summary`, `changed_at`, `created_at`. RLS: `select_public`, `insert_organizer`.
- `vifutboldev.teams` & `vifutboldev.tournament_teams`: Stores master teams and competition enrollments (`id`, `tournament_id` FK, `team_id` FK, `group_name`, `eligibility_status`, `roster_json` / player links).
- `vifutboldev.season_honor_rolls`: Stores persisted season closure / honor roll records keyed by unique `tournament_id` (`champion_team_id`, `runner_up_team_id`, `top_scorer_player_id`, `best_defense_team_id`, `closed_at`).

### Rationale
Zero schema drift means all engineering effort can focus on repository integrity, hydration orchestration, outbox dependency ordering, and UI resilience without migration downtime.

### Alternatives Considered
- **Materialized `standings` table in Postgres**: Rejected during clarification (FR-005). Standings tables and knockout brackets are deterministic pure functions of synchronized `tournaments.rules_config`, `tournament_teams`, `tournament_matches`, and `match_reports`. A duplicate materialized table would risk stale or divergent rows across devices.

---

## 2. Gap 1 — Cold-Start Parallel Hydration & Pull-to-Refresh in `CompetitionDetailScreen`

### Decision
Add an explicit parallel cloud hydration workflow triggered in `_CompetitionDetailScreenState.initState()` (via `Future.microtask`) and exposed as a reusable `Future<void> _refreshCompetitionData()` callback passed to all four tab views (`RefreshIndicator` pull-to-refresh).

### Audit Findings
- `_CompetitionDetailScreenState` (`lib/presentation/tournaments/competition_detail_screen.dart`) currently has **no `initState()`**. Opening `/competitions/:id` on a cold start or after clearing local cache renders empty placeholders because none of the underlying controllers (`tournamentsControllerProvider`, `teamsControllerProvider`, `matchesCatalogControllerProvider`, `venuesControllerProvider`, `standingsAndRankingsControllerProvider(tournamentId)`) are guaranteed to have hydrated from Supabase yet.
- `CompetitionInfoTabView`, `CompetitionTeamsTabView`, and `CompetitionStandingsTabView` do not wrap their scroll views in `RefreshIndicator`, and `CompetitionInfoTabView` currently resolves `primaryVenue` only from `matchesCatalog` instead of checking `tournament.venueIds` first.

### Rationale
Instant rendering of cached local state combined with parallel remote refresh (`Future.wait`) satisfies FR-004 and SC-005 (< 5s cold-start hydration on mobile connectivity) while preserving cached content when offline (FR-010). Checking `tournament.venueIds` first ensures linked venues configured on the tournament render accurately in "Información" even before any match is scheduled.

### Alternatives Considered
- **Lazy per-tab hydration on tab switch**: Rejected during clarification. Switching quickly between tabs on a cold start would cause repeated loading flashes and stale standings if teams/matches hadn't hydrated yet.

---

## 3. Gap 2 — `HybridTeamsRepository.replaceForTournament` Missing Remote Pruning & UUID Normalization

### Decision
Update `PostgrestTeamsRemoteDataSource.replaceForTournament` and `HybridTeamsRepository` (`lib/infrastructure/repositories/hybrid_teams_repository.dart`) to:
1. Normalize `team.id` and `team.tournamentId` with deterministic UUIDv5 (`HybridRepositorySupport.ensureUuid`) before both local and remote writes so local cache keys match remote rows identically.
2. Prune withdrawn enrollments in `vifutboldev.tournament_teams` when `replaceForTournament(tournamentId, teams)` is called: fetch existing remote enrollment IDs for `safeTournamentId`, delete any remote IDs not present in the incoming `teams` list, and upsert the remaining enrollments.

### Audit Findings
- Currently `PostgrestTeamsRemoteDataSource.replaceForTournament` (`lib/infrastructure/repositories/hybrid_teams_repository.dart:247-254`) only loops `upsert(team)` and never deletes removed enrollments. When an organizer withdraws a team from a competition (US2 Scenario 3, FR-003), the team disappears locally until the next remote reload, at which point it resurrects as an orphaned cloud record.

### Rationale
Matches the exact remote-pruning pattern already established for matches in HU 22.1 (`PostgrestTournamentMatchesRemoteDataSource.replaceForTournament`). Guarantees 0 local-only orphaned withdrawals (SC-002).

### Alternatives Considered
- **Soft-delete column `deleted_at` on `tournament_teams`**: Rejected because existing schema and `replaceForTournament` semantics use hard-delete synchronization of the enrollment set, and no schema migration is required.

---

## 4. Gap 3 — `HybridTournamentsRepository.saveTournament` Local/Remote UUID Drift

### Decision
Normalize `tournament.id` (and `venueIds` entries) using `HybridRepositorySupport.ensureUuid` before persisting to `LocalTournamentsRepository` and `PostgrestTournamentsRemoteDataSource`, and verify lossless round-trip serialization of all `TournamentRulesConfig` fields (including backward-compatible defaults when optional JSON keys are absent).

### Audit Findings
- `PostgrestTournamentsRemoteDataSource.upsert` transforms `tournament.id` via `ensureUuid(tournament.id, 'tournament')`, whereas `local.saveTournament(tournament)` stores the raw incoming `tournament.id`. If a non-UUID identifier (e.g., local test/legacy ID) is created offline and later synced, local and remote caches diverge and produce duplicate tournament cards upon reload.
- `HybridTournamentsRepository.saveTournament` must also ensure rule-change `RuleAuditEntry` records are persisted locally and synchronized without duplicates via deterministic UUIDs.

### Rationale
Normalizing IDs at the repository boundary guarantees a 1:1 identity between SharedPreferences local cache and `vifutboldev.tournaments`, preventing duplicate rows and broken foreign keys on offline replay.

### Alternatives Considered
- **Normalize only on remote read**: Rejected because offline outbox items referencing the tournament ID would still carry unnormalized IDs until flushed.

---

## 5. Gap 4 — `SupabaseCloudSyncService._executeFlush` Dependency-Ordered Replay

### Decision
Sort pending `SyncOutboxItem` records in `SupabaseCloudSyncService._executeFlush` (`lib/infrastructure/sync/supabase_cloud_sync_service.dart`) by a strict foreign-key dependency priority map, preserving FIFO (`createdAt` ascending) within the same priority tier:

| Tier | `SyncEntityType` | Depends On |
|------|------------------|------------|
| 0 | `venue` | None |
| 1 | `tournament` | `venue` |
| 2 | `team`, `teamJoinRequest` | `tournament` |
| 3 | `match` | `tournament`, `team`, `venue` |
| 4 | `matchReport`, `lineupTracking`, `matchAlert` | `match`, `team` |
| 5 | `seasonHonorRoll`, `tournamentNews`, `fanFavorite` | `tournament`, `team`, `matchReport` |

### Audit Findings
- `_executeFlush` currently iterates `pendingItems` strictly in queue insertion order. If an organizer edits a match or team enrollment while offline and later creates/updates the parent competition or venue—or if an earlier parent item failed transiently and was retried after a child item—PostgREST rejects the child write with PostgreSQL `23503` (foreign key violation).

### Rationale
Deterministic topological sorting by entity tier before replay guarantees parents are always synchronized before dependents with zero `23503` FK errors (FR-007, SC-004).

### Alternatives Considered
- **Retry-loop until convergence**: Rejected because failing child items increment retry counts, trigger unnecessary network errors, and risk exhausting max retries before the parent succeeds.

---

## 6. Gap 5 — Deterministic Standings Reactivity & Duplicate-Tap Protection

### Decision
1. Ensure `CompetitionDetailScreen` refreshes `standingsAndRankingsControllerProvider(tournamentId).notifier.loadCompetitiveSnapshot()` after parallel hydration of tournaments, teams, matches, and match reports completes, and whenever a user pulls to refresh the "Clasificación" tab.
2. Add duplicate-tap guards (`isSaving` / in-flight operation flags) in `CompetitionTeamsTabView` for group reassignment (`moveTeamToGroup`), team withdrawal (`removeTeamFromCompetition`), and eligibility toggle (`toggleTeamEligibility`), plus surface clear Spanish error/offline feedback while retaining cached content.
3. Ensure `StandingsAndRankingsController` exposes a non-destructive error state when refresh fails offline while cached snapshot data exists.

### Audit Findings
- `StandingsAndRankingsController` currently calls `loadCompetitiveSnapshot()` only once in its constructor. If the provider is instantiated before `tournaments`, `teams`, and `matches` finish hydrating from Supabase on a cold start, the "Clasificación" tab displays an empty state until the user leaves and re-enters the screen.
- In `CompetitionTeamsTabView`, rapid double-taps on group move or eligibility toggle actions can dispatch overlapping async mutations to `TeamsController`.

### Rationale
Directly addresses FR-004, FR-005, FR-008, FR-010, and SC-003 without altering the pure deterministic calculation engine in `StandingsCalculatorService` / `CalculateTournamentStandingsAndRankingsUseCase`.
