# Data Model: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Feature Branch**: `009-standings-brackets-rankings`  
**Date**: 2026-11-04  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/009-standings-brackets-rankings/spec.md)

---

## 1. Domain Entities (`lib/domain/entities/`)

### 1.1 `StandingsRow` (`lib/domain/entities/standings_table.dart`)
Represents a single team's calculated standing within a league or group table.

| Field | Type | Description |
|-------|------|-------------|
| `position` | `int` | 1-based rank position in the table |
| `teamId` | `String` | Unique team identifier |
| `teamName` | `String` | Official team name |
| `teamShortCode` | `String` | 3–4 character team abbreviation |
| `crestShape` | `TeamCrestShape` | Team crest shape for badge rendering |
| `primaryColorHex` | `int` | Team primary color |
| `played` | `int` | Matches played (`PJ`) |
| `won` | `int` | Matches won (`PG`) |
| `drawn` | `int` | Matches drawn (`PE`) |
| `lost` | `int` | Matches lost (`PP`) |
| `goalsFor` | `int` | Goals scored (`GF`) |
| `goalsAgainst` | `int` | Goals conceded (`GC`) |
| `goalDifference` | `int` | `goalsFor - goalsAgainst` (`DG`) |
| `points` | `int` | Total points (`PTS`) calculated via `TournamentRulesConfig` |
| `yellowCards` | `int` | Standalone yellow cards accumulated |
| `secondYellowRedCards` | `int` | Double-yellow expulsions accumulated |
| `directRedCards` | `int` | Direct red cards accumulated |
| `fairPlayPenaltyPoints` | `int` | Total disciplinary penalty (`<= 0`: `-1` per yellow, `-3` per 2nd yellow/red, `-3` per direct red) |
| `isQualified` | `bool` | Whether this position qualifies for the next stage / podium |
| `isTiedOnAllCriteria` | `bool` | True if tied with adjacent team on all configured criteria (resolved alphabetically) |

### 1.2 `StandingsTable` (`lib/domain/entities/standings_table.dart`)
Aggregate containing the ordered standings rows for a tournament or group.

| Field | Type | Description |
|-------|------|-------------|
| `tournamentId` | `String` | Parent tournament ID |
| `groupName` | `String?` | `null` for general league table, or `"Grupo A"`, `"Grupo B"`, etc. |
| `rows` | `List<StandingsRow>` | Deterministically ordered standings rows |
| `appliedTiebreakers` | `List<TiebreakerCriterion>` | Ordered criteria used to resolve ties |
| `completedMatchesCount` | `int` | Total completed matches included in calculation |
| `updatedAt` | `DateTime` | Calculation timestamp |

---

### 1.3 `KnockoutMatchTieNode` & `KnockoutBracketRound` & `KnockoutBracket` (`lib/domain/entities/knockout_bracket.dart`)
Models the complete elimination bracket tree from `startingRound` through `finalMatch`.

#### `KnockoutMatchTieNode`
| Field | Type | Description |
|-------|------|-------------|
| `nodeId` | `String` | Deterministic slot ID (e.g. `ko-quarterFinals-0`) |
| `round` | `KnockoutRound` | `roundOf16`, `quarterFinals`, `semiFinals`, or `finalMatch` |
| `tieIndex` | `int` | 0-based index within the round (`0 .. round.tieCount - 1`) |
| `matchId` | `String?` | Associated `ChampionshipMatch.id` if scheduled/created |
| `homeTeamId` | `String?` | Home team ID (`null` if `"TBD"`) |
| `homeTeamName` | `String` | Home team display name or `"Por definir"` |
| `awayTeamId` | `String?` | Away team ID (`null` if `"TBD"`) |
| `awayTeamName` | `String` | Away team display name or `"Por definir"` |
| `homeScore` | `int?` | Regulation goals scored by home team |
| `awayScore` | `int?` | Regulation goals scored by away team |
| `homePenaltyScore` | `int?` | Penalty shootout score for home team (when drawn in regulation) |
| `awayPenaltyScore` | `int?` | Penalty shootout score for away team (when drawn in regulation) |
| `status` | `MatchStatus` | `scheduled`, `inProgress`, or `completed` |
| `winnerTeamId` | `String?` | Determined winner advancing to next round (`null` until completed) |
| `nextRoundNodeId` | `String?` | Target node ID in the next round (`null` for `finalMatch`) |

#### `KnockoutBracketRound`
| Field | Type | Description |
|-------|------|-------------|
| `round` | `KnockoutRound` | Enum identifier of the round |
| `roundTitle` | `String` | Localized Spanish title (`Octavos de Final`, `Cuartos de Final`, `Semifinales`, `Gran Final`) |
| `ties` | `List<KnockoutMatchTieNode>` | Ordered list of pairings in this round |

#### `KnockoutBracket`
| Field | Type | Description |
|-------|------|-------------|
| `tournamentId` | `String` | Associated tournament ID |
| `rounds` | `List<KnockoutBracketRound>` | Chronological rounds from `startingRound` to `finalMatch` |
| `championTeamId` | `String?` | Winner of `finalMatch` if completed |
| `championTeamName` | `String?` | Display name of tournament champion |

---

### 1.4 `PlayerRankingEntry` & `TeamFairPlayRow` & `TournamentRankingsBundle` (`lib/domain/entities/tournament_rankings.dart`)
Models individual and collective sports rankings derived from closed official match reports.

#### `PlayerRankingEntry`
| Field | Type | Description |
|-------|------|-------------|
| `rank` | `int` | 1-based ranking position |
| `playerId` | `String` | Unique player ID |
| `playerName` | `String` | Full name of player |
| `shirtNumber` | `int` | Official dorsal number |
| `teamId` | `String` | Enrolled team ID |
| `teamName` | `String` | Enrolled team display name |
| `teamShortCode` | `String` | Enrolled team short code |
| `goals` | `int` | Total official goals scored |
| `assists` | `int` | Total official assists recorded |
| `matchesPlayed` | `int` | Total matches with participation/events |
| `yellowCards` | `int` | Total yellow cards |
| `redCards` | `int` | Total red cards (`secondYellowRedCard` + `directRedCard`) |

#### `TeamFairPlayRow`
| Field | Type | Description |
|-------|------|-------------|
| `rank` | `int` | 1-based Fair Play rank (1 = best disciplinary record) |
| `teamId` | `String` | Unique team ID |
| `teamName` | `String` | Team name |
| `teamShortCode` | `String` | Team short code |
| `yellowCards` | `int` | Count of standalone yellow cards (`-1` each) |
| `secondYellowRedCards` | `int` | Count of double-yellow expulsions (`-3` each) |
| `directRedCards` | `int` | Count of direct red cards (`-3` each) |
| `penaltyPoints` | `int` | Total Fair Play score (`<= 0`, closer to `0` is better) |

#### `TournamentRankingsBundle`
| Field | Type | Description |
|-------|------|-------------|
| `tournamentId` | `String` | Tournament ID |
| `topScorers` | `List<PlayerRankingEntry>` | Sorted by `goals` desc, then `assists` desc, then `matchesPlayed` asc, then `playerName` asc |
| `topAssists` | `List<PlayerRankingEntry>` | Sorted by `assists` desc, then `goals` desc, then `matchesPlayed` asc, then `playerName` asc |
| `teamFairPlay` | `List<TeamFairPlayRow>` | Sorted by `penaltyPoints` desc (closest to `0` first), then `directRedCards` asc, then `teamName` asc |

---

## 2. Updates to Existing Entities & Repositories

1. **`ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)**:
   - Add optional `final int? homePenaltyScore;` and `final int? awayPenaltyScore;` and `final String? groupName;` (with backward-compatible `toJson`/`fromJson` and `copyWith`).
2. **`DigitalMatchReport` (`lib/domain/entities/digital_match_report.dart`)**:
   - Add optional `final int? homePenaltyScore;` and `final int? awayPenaltyScore;` so referees closing a tied knockout match can record the penalty shootout outcome (`Penales: 5 - 4`).
3. **`MatchReportsRepository` (`lib/domain/repositories/match_reports_repository.dart`) & `LocalMatchReportsRepository`**:
   - Add `Future<List<DigitalMatchReport>> loadReportsForTournament(String tournamentId);` to load all persisted match reports for a tournament in a single read operation.
