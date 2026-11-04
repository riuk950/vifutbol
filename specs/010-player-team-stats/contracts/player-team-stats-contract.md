# Interface & UI Contract: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Feature**: `010-player-team-stats`  
**Date**: 2026-11-04

## 1. Domain Service Contract (`PlayerTeamStatsCalculatorService`)

```dart
class PlayerTeamStatsCalculatorService {
  const PlayerTeamStatsCalculatorService();

  /// Computes deterministic `PlayerPerformanceProfile` for every registered player
  /// across all tournament teams, and `TeamDetailedStats` for every team.
  ({
    Map<String, PlayerPerformanceProfile> playerProfilesById,
    Map<String, TeamDetailedStats> teamStatsById,
  }) calculateAll({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required StandingsTable mainStandingsTable,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> reports,
    Map<String, MatchLineupConvocation> convocationsByTeamId = const {},
    Map<String, PlayerInternalTracking> trackingByPlayerId = const {},
  });
}
```

### Invariants
1. **Zero-Division Protection (`FR-003`)**: When `matchesPlayed == 0`, `goalsPerMatchAverage` MUST equal `0.0` (`formattedGoalsAverage == '0.00'`), never `NaN` or `Infinity`.
2. **Closed-Report Exclusivity**: Only reports where `report.isClosed == true` contribute to completed match history, form (`V`, `E`, `D`), goals, assists, cards, and matches played from match reports.
3. **Recent Form Bound (`FR-004`)**: `recentForm.length` is always in `0..5`, ordered chronologically for the last up to 5 completed matches of the team.

---

## 2. UI Widget & Interaction Contract

### 2.1 Entry Points in `StandingsTabView` (`FR-005`)
- **Quick Access Button**: `Key('open_my_player_profile_button')` in the competitive section header opens the `PlayerPerformanceProfileSheet` for the active/authenticated player (and allows switching between enrolled tournament players via a selector chip/dropdown inside the sheet).
- **Standings Table Drill-Down**: Tapping `Key('standings_row_<teamId>')` in `StandingsTableCard` opens `TeamDetailedStatsSheet` for `<teamId>`.
- **Rankings Drill-Down**:
  - Tapping `Key('scorer_row_<playerId>')` or `Key('assist_row_<playerId>')` in `TournamentRankingsCard` opens `PlayerPerformanceProfileSheet` for `<playerId>`.
  - Tapping `Key('fair_play_row_<teamId>')` in `TournamentRankingsCard` opens `TeamDetailedStatsSheet` for `<teamId>`.

### 2.2 `PlayerPerformanceProfileCard` / `PlayerPerformanceProfileSheet`
- **Root Key**: `Key('player_performance_profile_card')`
- **Disciplinary Badge Key**: `Key('player_disciplinary_badge')` displaying `"Habilitado"` or `"Suspendido"`.
- **Metric Cards (`tabular-nums`)**:
  - `Key('player_metric_matches_played')` (`Partidos`)
  - `Key('player_metric_starts')` (`Titularidades`)
  - `Key('player_metric_goals')` (`Goles`)
  - `Key('player_metric_assists')` (`Asistencias`)
  - `Key('player_metric_goal_average')` (`Promedio de Gol`, e.g. `0.50` or `0.00`)
  - `Key('player_metric_yellow_cards')` (`Tarjetas Amarillas`)
  - `Key('player_metric_red_cards')` (`Tarjetas Rojas`)
- **Empty Participation State (`FR-006`)**:
  - When `matchesPlayed == 0` and `matchParticipations.isEmpty`, renders `Key('player_empty_participations_message')` with the exact Spanish text:
    `"Aún no registras participaciones en partidos oficiales de este torneo."`
- **Match-by-Match List**:
  - Each row uses `Key('player_match_participation_<matchId>')`.

### 2.3 `TeamDetailedStatsCard` / `TeamDetailedStatsSheet`
- **Root Key**: `Key('team_detailed_stats_card')`
- **Summary & Position Header**: Displays current rank (`#1`), points (`PTS`), `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG` with `tabular-nums`.
- **Recent Form Strip (`V`, `E`, `D`)**:
  - `Key('team_recent_form_strip')` displaying up to 5 badges (`V` in `KickPulseColors.accentPrimary`, `E` in `KickPulseColors.accentWarning`, `D` in `KickPulseColors.accentLive`), or an empty-state message in Spanish if `completedMatches.isEmpty`.
- **Completed Match History Section**:
  - Each item uses `Key('team_history_match_<matchId>')`.
- **Upcoming Matches Section**:
  - Each item uses `Key('team_upcoming_match_<matchId>')`.
- **Squad List with Individual Stats**:
  - Each player row uses `Key('team_squad_player_row_<playerId>')`. Tapping a row opens `PlayerPerformanceProfileSheet` for that player.
