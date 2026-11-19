# Data Model: Fixture Generation, Match Scheduling Cloud Sync, and Daily Matches Visibility

**Feature**: `049-fixture-schedule-cloud-sync` (HU 22.1)
**Date**: 2026-11-19

## 1. Entities & Schema Mapping

### 1.1 `ChampionshipMatch` ↔ `vifutboldev.matches`

| Domain Field (`ChampionshipMatch`) | Cloud Column (`vifutboldev.matches`) | Type | Nullable | Validation / Rules |
|---|---|---|---|---|
| `id` | `id` | `uuid` (PK) | No | Deterministic UUIDv5 (`ensureUuid(id, 'match')`); identical in Hive & Supabase |
| `tournamentId` | `tournament_id` | `uuid` (FK → `tournaments.id`) | No | Must reference an existing synchronized tournament |
| `roundNumber` | `round_number` | `integer` | No | `>= 1` |
| `roundName` | `round_name` | `text` | No | Non-empty (e.g., `"Jornada 1"`, `"Cuartos de Final"`) |
| `homeTeamId` | `home_tournament_team_id` | `uuid` (FK → `tournament_teams.id`) | No | Must differ from `awayTeamId` |
| `awayTeamId` | `away_tournament_team_id` | `uuid` (FK → `tournament_teams.id`) | No | Must differ from `homeTeamId` |
| `scheduledStartTime` | `scheduled_at` | `timestamptz` | Yes | Stored UTC, converted `.toLocal()` on read. Mandatory when scheduling; `!= null` determines visibility in `MatchdayTabView` |
| `scheduledEndTime` | `scheduled_end_at` | `timestamptz` | Yes | Computed as `scheduledStartTime + (halfDurationMinutes * 2 + 15) min` |
| `venueId` | `venue_id` | `uuid` (FK → `sports_venues.id`) | Yes | Optional during scheduling (Clarification Q2) |
| `pitchId` | `pitch_id` | `uuid` (FK → `venue_pitches.id`) | Yes | Optional during scheduling; cleared if `venueId` is null |
| `pitchName` | `pitch_name` | `text` | Yes | Cached display name for pitch; fallback `"Por definir"` in UI when null |
| `refereeId` | `referee_id` | `uuid` (FK → `match_referees.id`) | Yes | Optional during scheduling (Clarification Q2) |
| `refereeName` | `referee_name` | `text` | Yes | Cached display name for referee; fallback `"Por definir"` in UI when null |
| `status` | `status` | `text` | No | Enum: `pendingSchedule`, `scheduled`, `inProgress`, `completed`, `postponed`, `cancelled` |
| `homeScore` | `home_score` | `integer` | Yes | `>= 0` when set |
| `awayScore` | `away_score` | `integer` | Yes | `>= 0` when set |
| `homePenaltyScore` | `home_penalty_score` | `integer` | Yes | `>= 0` when set |
| `awayPenaltyScore` | `away_penalty_score` | `integer` | Yes | `>= 0` when set |
| `groupName` | `group_name` | `text` | Yes | Optional group label (e.g., `"Grupo A"`) |
| `updatedAt` | `updated_at` | `timestamptz` | No | UTC ISO-8601 timestamp |

### 1.2 `SyncOutboxItem` (Local Hive FIFO Queue)

| Operation (`SyncOutboxOperation`) | `entityType` | `entityId` | `payloadJson` | Replay Behavior |
|---|---|---|---|---|
| `replaceBatch` | `SyncOutboxEntityType.match` | `tournamentId` | `{"tournamentId": "<uuid>", "matches": [ ...ChampionshipMatch.toJson() ]}` | Calls `remote.replaceForTournament(tournamentId, matches)` (prunes stale IDs + idempotent batch `upsert` on `id`) |
| `upsert` | `SyncOutboxEntityType.match` | `match.id` | `{"match": ChampionshipMatch.toJson()}` | Calls `remote.upsertMatch(match)` (idempotent `upsert` on `id`) |

## 2. State Transitions

### 2.1 Match Scheduling Lifecycle

```text
[pendingSchedule]  ──(organizer sets scheduledStartTime [optional: venue, pitch, referee])──>  [scheduled]
       ▲                                                                                           │
       │                                                                                           ├──(organizer reschedules date/time or updates optional logistics)──> [scheduled]
       │                                                                                           │
       └────(fixture regenerated while no match in tournament is inProgress/completed)─────────────┘
```

- **Regeneration Guard (`FR-002a`)**:
  - Allowed only if `existingMatches.every((m) => m.status != MatchStatus.inProgress && m.status != MatchStatus.completed)`.
  - Requires explicit organizer confirmation when `existingMatches.isNotEmpty`.
  - Replaces all prior tournament matches cleanly in Hive and `vifutboldev.matches`.

### 2.2 Daily Matches Feed Visibility Rule (`FR-008`, `FR-009`)

- Included in `MatchdayTabView` for `selectedDate` **iff**:
  1. `match.scheduledStartTime != null`
  2. `DateTime(localStart.year, localStart.month, localStart.day) == normalizedSelectedDate`
  3. Parent tournament has `status == openRegistration || status == inProgress`
- Unscheduled matches (`scheduledStartTime == null`) are excluded from `MatchdayTabView` and remain visible in `CompetitionDetailScreen` (Jornadas / Fixture tab).

## 3. Collision Detection Rules (Updated for Optional Logistics)

When scheduling a match in `FixtureSchedulingUseCase.scheduleMatch`:
- **Home/Away Team Collision**: ALWAYS checked against all overlapping matches across all tournaments.
- **Pitch Collision**: Checked ONLY when `pitch != null` (non-null `pitchId`).
- **Referee Collision**: Checked ONLY when `referee != null` (non-null `refereeId`).
