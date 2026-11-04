# Research & Technical Decisions: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Feature Branch**: `009-standings-brackets-rankings`  
**Date**: 2026-11-04  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/009-standings-brackets-rankings/spec.md)

---

## 1. Deterministic Standings Engine & Hierarchical Tiebreaker Resolution

### Decision
Implement a pure domain service `StandingsCalculatorService` in `lib/domain/services/standings_calculator_service.dart` that derives `StandingsTable` (both overall league and per-group tables for `mixedGroupsAndKnockout`) strictly from:
1. Enrolled eligible `TournamentTeam`s.
2. Official completed `ChampionshipMatch`es (`status == MatchStatus.completed`).
3. Closed `DigitalMatchReport`s (`isClosed == true`) for disciplinary card events (`yellowCard`, `secondYellowRedCard`, `directRedCard`).
4. `TournamentRulesConfig` (`pointsForWin`, `pointsForDraw`, `pointsForLoss`, `tiebreakerOrder`).

### Rationale
- **Zero Drift / Reproducibility**: Calculating standings as a pure projection of completed matches and closed official match reports guarantees that no out-of-sync counter or partial in-progress match ever corrupts the table (`FR-001`, `SC-002`).
- **Sub-50ms Execution**: Even for a 20-team double-round league (380 matches), an in-memory single-pass aggregation + comparator sort executes in `< 2ms` in Dart (`SC-001`).

### Tiebreaker Algorithm (`FR-003`)
1. **Primary Sort**: Total Points (`PTS`) descending.
2. **Configurable Hierarchy**: Iterate through `TournamentRulesConfig.tiebreakerOrder`:
   - `TiebreakerCriterion.goalDifference`: Compare `goalDifference` (`GF - GC`) descending.
   - `TiebreakerCriterion.goalsFor`: Compare `goalsFor` (`GF`) descending.
   - `TiebreakerCriterion.headToHead`: Filter completed matches strictly between the two tied teams (`teamA` vs `teamB`). Compute mutual points (`PTS_H2H`) and mutual goal difference (`DG_H2H`). As clarified in Session 2026-11-04: if the teams have not played each other yet or their mutual match(es) resulted in a draw (equal mutual points and equal mutual goal difference), the criterion is treated as tied (`0`) and the comparator immediately advances to the next configured criterion.
   - `TiebreakerCriterion.fairPlay`: Compare `fairPlayPenaltyPoints` descending (closer to `0` is better, e.g., `-2 > -5`), where each `yellowCard` = `-1`, `secondYellowRedCard` = `-3`, and `directRedCard` = `-3` (`FR-009`). Note: When a player receives a second yellow card in the same match (`secondYellowRedCard` with `linkedParentEventId` pointing to the second `yellowCard`), the second yellow + red expulsion counts as `-3` points total (not `-1 + -3 = -4`), while any standalone `yellowCard` counts as `-1` and `directRedCard` counts as `-3`.
3. **Deterministic Fallback**: If all configured criteria remain equal, sort alphabetically by `team.normalizedName` (`team.name.toLowerCase()`) and flag `isTiedOnAllCriteria = true` for visual indication.

---

## 2. Knockout Bracket Tree & Automatic Winner Advancement (`US2`)

### Decision
Implement `KnockoutBracketService` in `lib/domain/services/knockout_bracket_service.dart` and integrate automatic winner advancement into `ManageDigitalMatchReportUseCase.closeOfficialMatchReport` as well as bracket tree projection.
- Extend `ChampionshipMatch` and `DigitalMatchReport` with optional `homePenaltyScore` and `awayPenaltyScore` (`int?`) to support knockout ties decided by penalty shootouts (`directPenaltyShootoutOnDraw: true`).
- When a knockout match is completed (or when `KnockoutBracketService.buildBracket` / `advanceKnockoutWinners` runs), determine the winning team (`winnerTeamId`):
  - Regulation winner if `homeScore != awayScore`.
  - Penalty shootout winner if `homeScore == awayScore` and `homePenaltyScore != null && awayPenaltyScore != null && homePenaltyScore != awayPenaltyScore`.
- Pairings in round $r$ (`tieIndex` $0 \dots N-1$) map deterministically to round $r+1$ at `nextTieIndex = tieIndex ~/ 2`:
  - Even `tieIndex` ($0, 2, 4, \dots$) populates the `homeTeam` slot of `nextTieIndex`.
  - Odd `tieIndex` ($1, 3, 5, \dots$) populates the `awayTeam` slot of `nextTieIndex`.
- If the next round match already exists in `TournamentMatchesRepository`, update its `homeTeamId`/`awayTeamId`; if only one feeder tie has finished, store a placeholder or create/update the next-round `ChampionshipMatch` once decided, while `KnockoutBracket` always renders all rounds from `startingRound` to `KnockoutRound.finalMatch` (showing `"Por definir (TBD)"` for undecided slots).

### Rationale
- Guarantees 100% automatic winner propagation (`FR-006`, `SC-003`) both reactively on match report closure and deterministically when loading the bracket view.

---

## 3. Mobile UX for Knockout Brackets & Tabular Standings (`FR-005`, `FR-010`)

### Decision
- **Standings Table**: Use a condensed, zero-overflow mobile table layout where numerical columns (`PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`) use fixed widths and `KickPulseTypography.statMetric()` with `FontFeature.tabularFigures()` (`tabular-nums`). Wrap in a responsive layout that fits 360px–430px viewports cleanly and supports horizontal scrolling on ultra-narrow screens or 130% text scale (`SC-004`).
- **Knockout Bracket Viewer (`FR-005`)**: Provide two complementary modes inside the Llaves section:
  1. **Vista por Rondas (Default)**: Horizontal round selector chips (`Octavos de Final`, `Cuartos de Final`, `Semifinales`, `Gran Final`) displaying structured `Vs` pairing cards with regulation score, penalty shootout badge (if applicable), and highlighted winner badge.
  2. **Visor Panorámico 2D**: An `InteractiveViewer` (or 2D scrollable canvas) rendering the connected multi-column bracket tree from initial round to final.

### Rationale
- Aligns directly with the Session 2026-11-04 clarification (Option A), Constitution Principle V (`DESIGN.md` `tabular-nums` & dark atmospheric minimalism), and zero `RenderFlex` overflow requirements.

---

## 4. Backward Compatibility with Existing `StandingsTabView` Widget Tests

### Decision
Enhance `StandingsTabView` (`lib/presentation/shell/tabs/standings_tab_view.dart`) by keeping all existing header, format filter chips (`filter_format_*`), tournament selector chips (`select_tournament_*`), `create_tournament_button`, `TournamentRulesSummaryCard`, and `TournamentTeamsSection` intact in the scrollable view, while embedding the new reactive **Tabla de Posiciones**, **Llaves Eliminatorias**, and **Rankings Deportivos (Goleadores, Asistencias, Fair Play)** section directly above/alongside the rules summary with segmented sub-navigation tabs (`Posiciones`, `Llaves`, `Rankings`, `Equipos`).
Furthermore, ensure that `TournamentTeamsSection` and `TournamentRulesSummaryCard` remain rendered in the scroll view (or accessible by default) so existing tests (`test/widget/standings_tab_view_test.dart`, `test/widget/teams_roster_eligibility_widget_test.dart`, `test/widget/coach_lineup_tracking_widget_test.dart`) pass without modification.

### Rationale
- Prevents regressions across the 212 existing automated tests while delivering full HU 8.1 functionality in the primary Standings tab.
