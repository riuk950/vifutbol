# Data Model: Competition Tabs Cloud Persistence and Synchronization

**Feature**: `051-competition-tabs-cloud-sync` (HU 22.3)  
**Date**: 2026-11-19  
**Storage**: Dual-layer offline-first — Local (`SharedPreferences` JSON cache + `SyncOutboxItem` queue) ↔ Remote (`Supabase` PostgreSQL schema `vifutboldev`).

---

## 1. Core Entities & Cloud Mappings

### 1.1 `ChampionshipTournament` ↔ `vifutboldev.tournaments`

| Domain Field | Dart Type | Cloud Column | SQL Type | Sync / Normalization Rule |
|---|---|---|---|---|
| `id` | `String` | `id` | `uuid` (PK) | Normalized via `ensureUuid(id, 'tournament')` before local & remote persistence |
| `name` | `String` | `name` | `text` | Required, trimmed |
| `category` | `String` | `category` | `text` | Required |
| `startDate` | `DateTime` | `start_date` | `timestamptz` | Stored UTC ISO-8601 remotely, converted `.toLocal()` on read |
| `endDate` | `DateTime` | `end_date` | `timestamptz` | Stored UTC ISO-8601 remotely, converted `.toLocal()` on read |
| `format` | `TournamentFormat` | `format` | `text` | Enum `.name` (`league`, `knockout`, `mixedGroupsAndKnockout`) |
| `status` | `TournamentStatus` | `status` | `text` | Enum `.name` (`openRegistration`, `inProgress`, `finished`) |
| `rules` | `TournamentRulesConfig` | `rules_config` | `jsonb` | Lossless JSON serialization with safe defaults on missing keys (FR-002) |
| `venueIds` | `List<String>` | `venue_ids` | `uuid[]` | Each ID normalized via `ensureUuid(id, 'venue')` |
| `ruleAuditTrail` | `List<RuleAuditEntry>` | *(child table)* | `rule_audit_entries` | Synced alongside tournament save; ordered chronologically |

#### `TournamentRulesConfig` (`rules_config` JSONB Structure)
- `pointsForWin` (`int`, default `3`)
- `pointsForDraw` (`int`, default `1`)
- `pointsForLoss` (`int`, default `0`)
- `tiebreakerOrder` (`List<TiebreakerCriterion>`, default standard order; unknown strings skipped safely)
- `leagueRounds` (`int`, default `1`)
- `groupStageConfig` (`groupCount`, `qualifiersPerGroup`, `roundsPerGroup`)
- `knockoutConfig` (`twoLegged`, `extraTime`, `penalties`, `thirdPlaceMatch`)
- `minSquadSize` / `maxSquadSize` (`int`)
- `halfDurationMinutes` (`int`)
- `yellowCardsForSuspension` (`int`)
- Backward compatibility: `TournamentRulesConfig.fromJson` MUST tolerate missing/null nested fields and apply safe domain defaults without throwing.

---

### 1.2 `RuleAuditEntry` ↔ `vifutboldev.rule_audit_entries`

| Domain Field | Dart Type | Cloud Column | SQL Type | Sync Rule |
|---|---|---|---|---|
| `id` | `String` | `id` | `uuid` (PK) | Deterministic UUIDv5 from `tournamentId + timestamp + summary` or normalized UUID |
| `tournamentId` | `String` | `tournament_id` | `uuid` (FK) | References `tournaments(id)` |
| `actorRole` | `UserRole` | `actor_role` | `text` | Enum `.name` |
| `summary` | `String` | `summary` | `text` | Immutable change description |
| `timestamp` | `DateTime` | `changed_at` | `timestamptz` | UTC ISO-8601; sorted ascending on read |

---

### 1.3 `TournamentTeam` (Enrollment) ↔ `vifutboldev.teams` + `vifutboldev.tournament_teams`

| Domain Field | Dart Type | Cloud Column | SQL Type | Sync Rule |
|---|---|---|---|---|
| `id` | `String` | `tournament_teams.id` | `uuid` (PK) | Normalized via `ensureUuid(id, 'tournament_team')` before local & remote write |
| `tournamentId` | `String` | `tournament_teams.tournament_id` | `uuid` (FK) | Normalized via `ensureUuid(tournamentId, 'tournament')` |
| `masterTeamId` | `String?` | `tournament_teams.team_id` | `uuid` (FK) | Links to `teams(id)` |
| `name` / `shortCode` / `crestColorHex` | `String` | `teams.*` / `tournament_teams.*` | `text` | Master team identity |
| `groupName` | `String?` | `tournament_teams.group_name` | `text` | Group assignment (`Grupo A`, `Grupo B`, etc.) |
| `eligibilityStatus` | `TeamEligibilityStatus` | `tournament_teams.eligibility_status` | `text` | `pendingVerification` \| `eligible` |
| `players` | `List<TeamPlayer>` | `players` / enrollment roster | `jsonb` / rows | Squad roster |

**State Transitions & Deletion Semantics**:
- Enrollment: `saveTeam` upserts enrollment with `eligibilityStatus` (`pendingVerification` by default, or `eligible`).
- Group Move / Eligibility Toggle: `saveTeam` updates `group_name` or `eligibility_status` and queues outbox item if offline.
- Withdrawal (`replaceTeamsForTournament`): Remote data source compares existing `tournament_teams.id` rows for `safeTournamentId` against the incoming list and deletes any withdrawn IDs before upserting remaining enrollments.

---

### 1.4 `StandingsSnapshot` (Derived — No Cloud Table) & `SeasonHonorRoll` ↔ `vifutboldev.season_honor_rolls`

- **`StandingsTable` & `KnockoutBracket`**: Computed deterministically in memory by `CalculateTournamentStandingsAndRankingsUseCase` using:
  1. `ChampionshipTournament.rules` (points + `tiebreakerOrder`)
  2. `List<TournamentTeam>` (enrolled teams + `groupName`)
  3. `List<TournamentMatch>` (official scores, status, round/phase)
  4. `List<MatchReport>` (official events, goals, cards, walkovers)
- **`SeasonHonorRoll`** ↔ `vifutboldev.season_honor_rolls`:
  - Persisted when an organizer officially closes a competition (`TournamentStatus.finished`).
  - Upserted with `onConflict: 'tournament_id'` using deterministic UUID `honor-roll|$safeTournamentId`.
  - Hydrated during competition detail refresh so finished tournaments display identical champion, runner-up, top scorer, and best defense across all devices (FR-006).

---

## 2. Offline Sync Outbox Dependency Graph (`SyncOutboxItem`)

`SupabaseCloudSyncService._executeFlush` orders all pending `SyncOutboxItem` entries by `(dependencyPriority(item.entityType), item.createdAt)`:

```text
Priority 0: venue
    └── Priority 1: tournament (includes rule_audit_entries)
            └── Priority 2: team, teamJoinRequest
                    └── Priority 3: match
                            └── Priority 4: matchReport, lineupTracking, matchAlert
                                    └── Priority 5: seasonHonorRoll, tournamentNews, fanFavorite
```

### Invariants
1. **Referential Integrity**: No child entity (`team`, `match`, `matchReport`, `seasonHonorRoll`) is flushed before a pending parent (`venue`, `tournament`, `team`, `match`) in the same flush cycle.
2. **Idempotency**: All remote writes use deterministic UUIDv5 keys and `upsert` with conflict keys, preventing duplicates on retry.
3. **RBAC Enforcement**: Only `UserRole.organizer` may trigger writes to `tournaments`, `rule_audit_entries`, `tournament_teams`, and `season_honor_rolls` (enforced both in Flutter `RolePermissionMatrix` and PostgreSQL RLS).
