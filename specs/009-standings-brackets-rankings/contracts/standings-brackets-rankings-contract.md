# Contracts: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Feature Branch**: `009-standings-brackets-rankings`  
**Date**: 2026-11-04  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/009-standings-brackets-rankings/spec.md)

---

## 1. Domain Service Contracts (`lib/domain/services/`)

### 1.1 `StandingsCalculatorService` (`lib/domain/services/standings_calculator_service.dart`)

```dart
class StandingsCalculatorService {
  const StandingsCalculatorService();

  /// Computes a single deterministic standings table for a league or specific group.
  StandingsTable calculateTable({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> closedReports,
    String? groupName,
  });

  /// Computes per-group standings tables for [TournamentFormat.mixedGroupsAndKnockout].
  List<StandingsTable> calculateGroupStageTables({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> closedReports,
  });
}
```

**Contract Guarantees**:
- Only matches with `status == MatchStatus.completed` and non-null `homeScore` / `awayScore` are counted (`FR-001`).
- Points per match strictly apply `tournament.rules.pointsForWin`, `pointsForDraw`, and `pointsForLoss` (`FR-002`).
- Tiebreakers iterate strictly in `tournament.rules.tiebreakerOrder` (`FR-003`):
  - `goalDifference`: higher `GF - GC` wins.
  - `goalsFor`: higher `GF` wins.
  - `headToHead`: compares mutual completed matches between tied teams; if they haven't played yet or drew (equal mutual points and equal mutual goal difference), returns `0` (tied) and advances immediately to the next criterion.
  - `fairPlay`: compares `fairPlayPenaltyPoints` (`-1` per standalone yellow card, `-3` per second-yellow red expulsion, `-3` per direct red card); closer to `0` wins (`FR-009`).

---

### 1.2 `KnockoutBracketService` (`lib/domain/services/knockout_bracket_service.dart`)

```dart
class KnockoutBracketService {
  const KnockoutBracketService();

  /// Builds the full chronological knockout bracket tree from [startingRound] to [finalMatch],
  /// automatically propagating winners of completed ties into the next round slots.
  KnockoutBracket buildBracket({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> reports,
  });

  /// Evaluates completed knockout matches and generates/updates next-round [ChampionshipMatch]
  /// records when feeder ties have a determined winner.
  List<ChampionshipMatch> computeUpdatedMatchesWithAdvancement({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> currentMatches,
    required List<DigitalMatchReport> reports,
    DateTime? now,
  });
}
```

**Contract Guarantees**:
- Winner determination supports both regulation wins (`homeScore != awayScore`) and penalty shootout resolution (`homeScore == awayScore` with `homePenaltyScore != awayPenaltyScore`).
- Even-indexed tie winners (`tieIndex % 2 == 0`) advance as `homeTeam` of `nextTieIndex = tieIndex ~/ 2` in the subsequent `KnockoutRound`; odd-indexed tie winners (`tieIndex % 2 == 1`) advance as `awayTeam`.

---

### 1.3 `SportsRankingsCalculatorService` (`lib/domain/services/sports_rankings_calculator_service.dart`)

```dart
class SportsRankingsCalculatorService {
  const SportsRankingsCalculatorService();

  /// Computes top scorers, top assists, and team Fair Play standings from closed match reports.
  TournamentRankingsBundle calculateRankings({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<DigitalMatchReport> closedReports,
  });
}
```

**Contract Guarantees**:
- `topScorers`: includes players with `goals > 0`, ordered by `goals` desc, then `assists` desc, then `matchesPlayed` asc, then `playerName` asc (`FR-007`).
- `topAssists`: includes players with `assists > 0`, ordered by `assists` desc, then `goals` desc, then `matchesPlayed` asc, then `playerName` asc (`FR-008`).
- `teamFairPlay`: includes all enrolled teams, ordered by `penaltyPoints` desc (closest to `0` first), then `directRedCards` asc, then `secondYellowRedCards` asc, then `yellowCards` asc, then `teamName` asc (`FR-009`).

---

## 2. Application Use Case Contract (`lib/application/use_cases/`)

### `CalculateTournamentStandingsAndRankingsUseCase` (`lib/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart`)

```dart
class CalculateTournamentStandingsAndRankingsUseCase {
  const CalculateTournamentStandingsAndRankingsUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.tournamentMatchesRepository,
    required this.matchReportsRepository,
    this.standingsCalculator = const StandingsCalculatorService(),
    this.knockoutBracketService = const KnockoutBracketService(),
    this.rankingsCalculator = const SportsRankingsCalculatorService(),
  });

  Future<TournamentCompetitiveSnapshot> execute(String tournamentId);
}
```

---

## 3. UI & Widget Key Contracts (`lib/presentation/shell/tabs/standings_tab_view.dart` & `lib/presentation/standings/widgets/`)

To support deterministic widget testing and preserve 100% compatibility with existing tests:
- **Existing Preserved Keys**:
  - `Key('create_tournament_button')`
  - `Key('filter_format_${format.name}')`
  - `Key('select_tournament_${tournament.id}')`
- **New Competitive Section Keys**:
  - `Key('competitive_view_selector_standings')` — Sub-tab chip for Tabla de Posiciones
  - `Key('competitive_view_selector_brackets')` — Sub-tab chip for Llaves Eliminatorias
  - `Key('competitive_view_selector_rankings')` — Sub-tab chip for Rankings Deportivos (Goleadores / Asistencias / Fair Play)
  - `Key('standings_table_card')` — Main standings table container
  - `Key('standings_row_${row.teamId}')` — Individual team row in the standings table
  - `Key('knockout_bracket_card')` — Main knockout bracket container
  - `Key('bracket_mode_rounds_chip')` / `Key('bracket_mode_panoramic_chip')` — Toggle between round-by-round cards (`Vs`) and 2D panoramic viewer
  - `Key('bracket_round_chip_${round.name}')` — Round selector chip (`roundOf16`, `quarterFinals`, `semiFinals`, `finalMatch`)
  - `Key('bracket_tie_node_${node.nodeId}')` — Individual knockout pairing card
  - `Key('rankings_section_card')` — Main rankings container
  - `Key('rankings_category_scorers')` / `Key('rankings_category_assists')` / `Key('rankings_category_fair_play')` — Category selector chips
  - `Key('scorer_row_${entry.playerId}')` / `Key('assist_row_${entry.playerId}')` / `Key('fair_play_row_${row.teamId}')`
