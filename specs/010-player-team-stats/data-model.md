# Phase 1 Data Model: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Feature**: `010-player-team-stats`  
**Date**: 2026-11-04

## 1. Domain Entities

### 1.1 `PlayerPerformanceProfile` (`lib/domain/entities/player_performance_profile.dart`)

Models the complete individual performance profile and match-by-match breakdown of a player in a tournament.

| Field | Type | Description |
|-------|------|-------------|
| `playerId` | `String` | Unique identifier of the player (`RegisteredPlayer.id`). |
| `tournamentId` | `String` | Unique identifier of the tournament. |
| `fullName` | `String` | Official full name of the player. |
| `shirtNumber` | `int` | Official jersey number (`1..99`). |
| `position` | `PlayerPosition` | Tactical position (`goalkeeper`, `defender`, `midfielder`, `forward`). |
| `teamId` | `String` | Enrolled team identifier. |
| `teamName` | `String` | Enrolled team full name. |
| `teamShortCode` | `String` | Enrolled team short code (e.g., ` RCN`). |
| `matchesPlayed` | `int` | Official matches played (`PJ >= 0`). |
| `startsCount` | `int` | Official matches started (`Titularidades >= 0`). |
| `goals` | `int` | Total official goals scored (`>= 0`). |
| `assists` | `int` | Total official assists recorded (`>= 0`). |
| `goalsPerMatchAverage` | `double` | Safe ratio `matchesPlayed > 0 ? goals / matchesPlayed : 0.0`. Formatted to 2 decimal places (`0.00`). |
| `yellowCards` | `int` | Total official yellow cards (`>= 0`). |
| `redCards` | `int` | Total official red cards (`secondYellowRedCard` + `directRedCard`, `>= 0`). |
| `isSuspended` | `bool` | Whether the player is currently suspended (`Suspendido`) or enabled (`Habilitado`). |
| `matchParticipations` | `List<PlayerMatchParticipation>` | Chronological breakdown (most recent first) of official completed matches where the player participated or recorded events. |

**Computed Getters**:
- `bool get hasParticipations => matchesPlayed > 0 || matchParticipations.isNotEmpty;`
- `String get formattedGoalsAverage => goalsPerMatchAverage.toStringAsFixed(2);`

---

### 1.2 `PlayerMatchParticipation` (`lib/domain/entities/player_performance_profile.dart`)

Models a single match entry in the player's match-by-match breakdown (`FR-002`).

| Field | Type | Description |
|-------|------|-------------|
| `matchId` | `String` | Official match ID. |
| `roundNumber` | `int` | Matchday / round number. |
| `roundName` | `String` | Display name of the round/matchday. |
| `scheduledAt` | `DateTime` | Match date/time. |
| `opponentTeamId` | `String` | Opponent club ID. |
| `opponentTeamName` | `String` | Opponent club name. |
| `opponentShortCode` | `String` | Opponent short code. |
| `isHome` | `bool` | Whether the player's team played as home team. |
| `teamScore` | `int` | Goals scored by the player's team. |
| `opponentScore` | `int` | Goals scored by the opponent team. |
| `wasStarter` | `bool` | `true` if starter (`Titular`), `false` if substitute (`Suplente`). |
| `goals` | `int` | Goals scored by the player in this match. |
| `assists` | `int` | Assists provided by the player in this match. |
| `yellowCards` | `int` | Yellow cards received by the player in this match. |
| `redCards` | `int` | Red cards (`secondYellowRedCard` + `directRedCard`) received in this match. |

---

### 1.3 `TeamDetailedStats` (`lib/domain/entities/team_detailed_stats.dart`)

Models the consolidated team statistics sheet (`FR-004`).

| Field | Type | Description |
|-------|------|-------------|
| `tournamentId` | `String` | Tournament ID. |
| `teamId` | `String` | Team ID. |
| `teamName` | `String` | Official team name. |
| `teamShortCode` | `String` | Short code (e.g., `RCN`). |
| `category` | `TeamCategory` | Category of the team. |
| `primaryColorHex` | `String` | Team primary color hex. |
| `standingsRow` | `StandingsRow` | Current position and cumulative metrics (`position`, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`, `fairPlayPenaltyPoints`). |
| `recentForm` | `List<TeamFormResult>` | Up to last 5 completed match outcomes (`win` -> `V`, `draw` -> `E`, `loss` -> `D`). |
| `completedMatches` | `List<TeamMatchHistoryItem>` | Completed official matches for this team. |
| `upcomingMatches` | `List<TeamUpcomingMatchItem>` | Scheduled/upcoming matches against next opponents. |
| `squadStats` | `List<PlayerPerformanceProfile>` | Full roster of players with their individual tournament statistics. |

---

### 1.4 Supporting Value Objects in `team_detailed_stats.dart`

- **`enum TeamFormResult { win, draw, loss }`**
  - UI codes in Spanish: `win` -> `V`, `draw` -> `E`, `loss` -> `D`.
- **`TeamMatchHistoryItem`**:
  - `matchId`, `roundName`, `scheduledAt`, `opponentTeamId`, `opponentTeamName`, `opponentShortCode`, `isHome`, `teamScore`, `opponentScore`, `teamPenaltyScore`, `opponentPenaltyScore`, `result` (`TeamFormResult`).
- **`TeamUpcomingMatchItem`**:
  - `matchId`, `roundName`, `scheduledAt`, `opponentTeamId`, `opponentTeamName`, `opponentShortCode`, `isHome`, `venueName`, `pitchName`.

---

## 2. Snapshot Extension (`TournamentCompetitiveSnapshot`)

`TournamentCompetitiveSnapshot` in `lib/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart` is extended with:
- `final Map<String, TeamDetailedStats> teamDetailedStatsById;`
- `final Map<String, PlayerPerformanceProfile> playerProfilesById;`
- `final PlayerPerformanceProfile? cachedMyPlayerProfile;`

This guarantees `O(1)` instant lookup when a user taps any team or player in `StandingsTabView`, `StandingsTableCard`, or `TournamentRankingsCard`.
