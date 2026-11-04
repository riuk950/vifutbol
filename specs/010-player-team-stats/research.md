# Phase 0 Research: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Feature**: `010-player-team-stats`  
**Date**: 2026-11-04

## 1. Deterministic Calculation of Player Matches Played (`PJ`), Starts (`Titularidades`), and Match-by-Match Breakdown

- **Decision**: Implement a pure domain service `PlayerTeamStatsCalculatorService` in `lib/domain/services/player_team_stats_calculator_service.dart` that derives each player's `PlayerPerformanceProfile` and each team's `TeamDetailedStats` deterministically from:
  1. `ChampionshipTournament` (`rulesConfig.yellowCardSuspensionLimit`, points rules).
  2. `TournamentTeam` and its `List<RegisteredPlayer>` roster.
  3. `List<ChampionshipMatch>` (completed and scheduled/upcoming matches).
  4. `List<DigitalMatchReport>` (filtered to `isClosed == true` for official stats).
  5. `Map<String, MatchLineupConvocation>` (team convocations for starter/substitute attribution) and `Map<String, PlayerInternalTracking>` (optional baseline tracking if present).
- **Rationale**:
  - For each closed match (`DigitalMatchReport.isClosed`) involving the player's team:
    - A player is marked as `wasStarter = true` if their `playerId` is in the team's `confirmedStarterPlayerIds` (or `starterPlayerIds` if not yet confirmed) for that team, OR if no lineup convocation exists for the team and the player recorded an official match event (`goal`, `yellowCard`, `secondYellowRedCard`, `directRedCard`, or exited in a `substitution` as `secondaryPlayerId`) without having entered as a substitute (`MatchEventType.substitution` with `primaryPlayerId == playerId`).
    - A player is marked as having participated (`participated = true`) if `wasStarter == true`, OR if they entered via `MatchEventType.substitution` (`primaryPlayerId == playerId`), OR if they recorded any official event in the closed report (`goal` as scorer or assistant, `yellowCard`, `secondYellowRedCard`, `directRedCard`).
    - Each match where `participated == true` produces a `PlayerMatchParticipation` item in chronological order and increments `matchesPlayed` (`+1`) and `startsCount` (`+1` if `wasStarter`).
  - Safe division-by-zero protection (`FR-003`): `goalsPerMatchAverage = matchesPlayed > 0 ? goals / matchesPlayed : 0.0`, formatted in UI as `toStringAsFixed(2)` (`0.00`).
- **Alternatives Considered**:
  - Counting all bench substitutes as having played (`PJ + 1`): Rejected during `/speckit-clarify` (Question 1, Option A selected) because unused bench players would artificially dilute their `goalsPerMatchAverage`.

## 2. Comprehensive Disciplinary Status Evaluation (`Habilitado` vs `Suspendido`)

- **Decision**: Evaluate `PlayerDisciplinaryStatus` (`enabled` -> `"Habilitado"`, `suspended` -> `"Suspendido"`) using the unified rule clarified in `/speckit-clarify` (Question 2, Option A):
  1. `!player.isEligible` in the team roster, OR
  2. `tracking != null && tracking.pendingSuspensionMatches > 0`, OR
  3. The player was expelled (`directRedCard` or `secondYellowRedCard`) in their team's most recent completed match report, OR
  4. Total official `yellowCards > 0` and `yellowCards % tournament.rulesConfig.yellowCardSuspensionLimit == 0` (having reached the suspension accumulation threshold in their latest yellow-card match).
- **Rationale**: Combines automatic referee report sanctions (HU 7.1) and coach/organizer tracking (HU 5.1 / HU 5.2) into a single authoritative badge (`Habilitado` in `KickPulseColors.accentPrimary` or `Suspendido` in `KickPulseColors.accentLive`).
- **Alternatives Considered**:
  - Relying solely on `RegisteredPlayer.isEligible`: Rejected because red cards recorded in closed match reports must automatically reflect in the player's disciplinary status.

## 3. Team Form (`V`, `E`, `D`), Match History, Upcoming Opponents, and Squad Contribution

- **Decision**: Compute `TeamDetailedStats` per team:
  - **Current Position & Summary Metrics**: Reuses the team's `StandingsRow` from `StandingsTable` (`position`, `played`, `won`, `drawn`, `lost`, `goalsFor`, `goalsAgainst`, `goalDifference`, `points`, `fairPlayPenaltyPoints`).
  - **Recent Form (`recentForm`)**: Sort the team's completed official matches chronologically (by `scheduledAt` ascending, then `roundNumber`) and take the last up to 5 matches (`takeLast(5)`), mapping each to `TeamFormResult.win` (`V`), `TeamFormResult.draw` (`E`), or `TeamFormResult.loss` (`D`). If a team has played fewer than 5 matches, only those `N` results are returned (`0..5`).
  - **Completed Match History (`completedMatches`)**: All completed matches for the team sorted most-recent-first, showing opponent name, home/away indicator, final score (and penalty score if applicable), round/date, and `TeamFormResult` badge.
  - **Upcoming Matches (`upcomingMatches`)**: All non-completed matches (`MatchStatus.scheduled` / `inProgress` where report is not closed) for the team sorted chronologically by `scheduledAt`, showing opponent name, round, pitch/venue name, and scheduled date/time.
  - **Squad Stats (`squadStats`)**: Full list of `PlayerPerformanceProfile` for all players enrolled in the team's roster, ordered by `shirtNumber` ascending.
- **Rationale**: Provides coaches, players, and fans a complete 360-degree view of the club in a single cohesive model.

## 4. Contextual Drill-Down Navigation & Offline Local Cache

- **Decision**:
  - In `StandingsTabView`:
    - Add a quick-access action button `"Mi Perfil Deportivo"` (`Key('open_my_player_profile_button')`) in the competitive section header so a user (especially with role `Jugador`) can immediately open the player performance profile (defaulting to the authenticated/selected player and allowing switching between registered players if desired).
    - Tapping any team row in `StandingsTableCard` (`Key('standings_row_<teamId>')`) or `TournamentRankingsCard` Fair Play (`Key('fair_play_row_<teamId>')`) opens `TeamDetailedStatsSheet` / screen.
    - Tapping any player row in `TournamentRankingsCard` (`Key('scorer_row_<playerId>')` / `Key('assist_row_<playerId>')`) or inside `TeamDetailedStatsSheet` (`Key('team_squad_player_row_<playerId>')`) opens `PlayerPerformanceProfileSheet` / screen.
  - Persist the last viewed/authenticated `PlayerPerformanceProfile` snapshot in `LocalStorageRepository` under a dedicated key (`cached_player_performance_profile_v1`) so offline queries load in `0 ms` even on cold start.
- **Rationale**: Respects the 5-tab maximum in `MOBILE_GUIDELINES.md`, avoids `LayoutBuilder` inside `SliverFillRemaining(hasScrollBody: false)`, and satisfies offline caching requirements (`FR-009`, `SC-005`).
