# Tasks: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Input**: Design documents from `/specs/009-standings-brackets-rankings/`
**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/`

**Tests**: Included per Constitution Principle IV (Testing & Quality Gates: unit tests for domain calculators/use cases + widget tests covering Gherkin acceptance scenarios).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths included in all descriptions

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Add Spanish localization strings (`FR-012`) and extend existing match/report entities for penalty shootout & group support.

- [X] T001 Add Spanish localization keys for standings table headers (`POS`, `EQUIPO`, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`), tiebreaker labels, knockout bracket views (`Por Rondas`, `Visor 2D`, `Por definir`, `Penales`), and rankings (`Goleadores`, `Asistencias`, `Fair Play`) in `lib/l10n/app_es.arb` and regenerate `flutter gen-l10n`
- [X] T002 [P] Extend `ChampionshipMatch` with optional `int? homePenaltyScore`, `int? awayPenaltyScore`, and `String? groupName` fields (including `copyWith`, `toJson`, `fromJson`) in `lib/domain/entities/championship_match.dart`
- [X] T003 [P] Extend `DigitalMatchReport` with optional `int? homePenaltyScore` and `int? awayPenaltyScore` fields (including `copyWith`, `toJson`, `fromJson`) in `lib/domain/entities/digital_match_report.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, repository bulk-load method, and unified competitive state controller that support all user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create `StandingsRow` and `StandingsTable` domain entities (with fields `position`, `teamId`, `teamName`, `teamShortCode`, `crestShape`, `primaryColorHex`, `played`, `won`, `drawn`, `lost`, `goalsFor`, `goalsAgainst`, `goalDifference`, `points`, `yellowCards`, `secondYellowRedCards`, `directRedCards`, `fairPlayPenaltyPoints <= 0`, `isQualified`, `isTiedOnAllCriteria`) in `lib/domain/entities/standings_table.dart`
- [X] T005 [P] Create `KnockoutMatchTieNode`, `KnockoutBracketRound`, and `KnockoutBracket` domain entities (with `nodeId`, `round`, `tieIndex`, `matchId`, `homeTeamId`, `homeTeamName`, `awayTeamId`, `awayTeamName`, `homeScore`, `awayScore`, `homePenaltyScore`, `awayPenaltyScore`, `status`, `winnerTeamId`, `nextRoundNodeId`) in `lib/domain/entities/knockout_bracket.dart`
- [X] T006 [P] Create `PlayerRankingEntry`, `TeamFairPlayRow`, and `TournamentRankingsBundle` domain entities (with `topScorers`, `topAssists`, and `teamFairPlay` where `penaltyPoints <= 0`) in `lib/domain/entities/tournament_rankings.dart`
- [X] T007 Add `Future<List<DigitalMatchReport>> loadReportsForTournament(String tournamentId)` to `lib/domain/repositories/match_reports_repository.dart` and implement it in `lib/infrastructure/repositories/local_match_reports_repository.dart`

**Checkpoint**: Foundation ready — user story implementation can now proceed.

---

## Phase 3: User Story 1 - Cálculo Determinista y Visualización de la Tabla de Posiciones de Liga con Desempate Jerárquico (Priority: P1) 🎯 MVP

**Goal**: Derive general league and per-group standings tables deterministically from completed matches and closed official match reports, resolving ties via `TournamentRulesConfig.tiebreakerOrder` (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`) and rendering aligned `tabular-nums` columns on mobile.

**Independent Test**: Close official match reports with varied scores and cards, open `StandingsTabView`, and verify `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS` and tiebreaker ordering (`goalDifference` → `goalsFor` → `headToHead` → `fairPlay` `-1`/`-3`/`-3`).

### Implementation for User Story 1

- [X] T008 [US1] Implement `StandingsCalculatorService` (`calculateTable` and `calculateGroupStageTables`) in `lib/domain/services/standings_calculator_service.dart` enforcing `FR-001` (completed matches only), `FR-002` (`pointsForWin`, `pointsForDraw`, `pointsForLoss`), `FR-003` (hierarchical `tiebreakerOrder` where `headToHead` evaluates winner in mutual completed matches or skips immediately if unplayed/drawn), and `FR-009` (`fairPlayPenaltyPoints`: `-1` per standalone yellow, `-3` per second-yellow red, `-3` per direct red)
- [X] T009 [P] [US1] Create unit test suite for `StandingsCalculatorService` covering standard points, custom rules points, `goalDifference`, `goalsFor`, `headToHead` (winner vs draw/unplayed skip), `fairPlay` (`-1`/`-3`/`-3`), group stage tables, and alphabetical fallback in `test/unit/domain/standings_calculator_service_test.dart`
- [X] T010 [US1] Build `StandingsTableCard` widget in `lib/presentation/standings/widgets/standings_table_card.dart` using `KickPulseTypography.statMetric()` with `FontFeature.tabularFigures()` (`tabular-nums`) for `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`, qualification badges, and `0 RenderFlex overflows` up to 130% text scale

**Checkpoint**: User Story 1 domain calculator, unit tests, and tabular UI card are functional and independently testable.

---

## Phase 4: User Story 2 - Cuadro Visual y Avance Automático de Llaves en Copas Eliminatorias (Priority: P2)

**Goal**: Build the interactive chronological knockout bracket tree (`Octavos`, `Cuartos`, `Semifinal`, `Final`) with both round-by-round `Vs` cards and a 2D scrollable panoramic viewer, and automatically advance winners (regulation or penalty shootout) to the next round's pairing slot upon official report closure.

**Independent Test**: Complete a quarter-final match (in regulation `3 - 1` or via penalty shootout `1 - 1 (5 - 4)`) and verify the winning team automatically populates the corresponding semi-final slot in `KnockoutBracketCard`.

### Implementation for User Story 2

- [X] T011 [US2] Implement `KnockoutBracketService` (`buildBracket` and `computeUpdatedMatchesWithAdvancement`) in `lib/domain/services/knockout_bracket_service.dart` supporting regulation winners, penalty shootout winners (`homePenaltyScore != awayPenaltyScore`), and deterministic slot propagation (`tieIndex ~/ 2`, even → home, odd → away)
- [X] T012 [P] [US2] Create unit test suite for `KnockoutBracketService` covering multi-round bracket construction (`roundOf16` to `finalMatch`), regulation winner advancement, penalty shootout winner advancement, and undecided `"Por definir"` slots in `test/unit/domain/knockout_bracket_service_test.dart`
- [X] T013 [US2] Update `ManageDigitalMatchReportUseCase.closeOfficialMatchReport` in `lib/application/use_cases/manage_digital_match_report_use_case.dart` (and `DigitalMatchReportController` / `DigitalMatchReportScreen` in `lib/application/controllers/digital_match_report_controller.dart` and `lib/presentation/matches/digital_match_report_screen.dart`) to accept optional `homePenaltyScore` and `awayPenaltyScore` on drawn knockout matches and invoke `KnockoutBracketService.computeUpdatedMatchesWithAdvancement` to persist next-round match advancements automatically
- [X] T014 [US2] Build `KnockoutBracketCard` widget in `lib/presentation/standings/widgets/knockout_bracket_card.dart` featuring round selector chips (`Key('bracket_round_chip_${round.name}')`) with `Vs` pairing cards (`Key('bracket_tie_node_${node.nodeId}')`) and a 2D `InteractiveViewer` panoramic bracket mode (`Key('bracket_mode_panoramic_chip')`)

**Checkpoint**: User Story 2 knockout bracket tree, automatic advancement on report closure, penalty shootout resolution, and dual-mode UI viewer are complete.

---

## Phase 5: User Story 3 - Rankings Individuales y Colectivos Deportivos (Goleadores, Asistencias y Fair Play) (Priority: P3)

**Goal**: Compute and display leaderboards for Top Scorers (`Goleadores`), Top Assists (`Asistencias`), and Team Fair Play (`Fair Play` with `-1` yellow, `-3` double-yellow/red, `-3` direct red) derived deterministically from closed official match reports.

**Independent Test**: Close match reports containing goals, assists, yellow cards, double-yellow expulsions, and direct red cards, open the `Rankings` section in `StandingsTabView`, and verify descending order for scorers/assists and lowest penalty points first for Fair Play.

### Implementation for User Story 3

- [X] T015 [US3] Implement `SportsRankingsCalculatorService` in `lib/domain/services/sports_rankings_calculator_service.dart` calculating `topScorers` (tiebroken by assists desc, matchesPlayed asc), `topAssists` (tiebroken by goals desc, matchesPlayed asc), and `teamFairPlay` (`-1` per standalone yellow, `-3` per `secondYellowRedCard`, `-3` per `directRedCard`, sorted closest to `0` first)
- [X] T016 [P] [US3] Create unit test suite for `SportsRankingsCalculatorService` in `test/unit/domain/sports_rankings_calculator_service_test.dart` verifying scorers, assists, and Fair Play penalty weighting (`-1`, `-3`, `-3`)
- [X] T017 [US3] Build `TournamentRankingsCard` widget in `lib/presentation/standings/widgets/tournament_rankings_card.dart` with category chips (`Key('rankings_category_scorers')`, `Key('rankings_category_assists')`, `Key('rankings_category_fair_play')`) and `tabular-nums` metric badges

**Checkpoint**: All three user stories (`US1`, `US2`, `US3`) domain services and presentation widgets are built.

---

## Phase 6: Application Orchestration, `StandingsTabView` Integration & End-to-End Verification

**Purpose**: Connect `US1`, `US2`, and `US3` into the application layer and `StandingsTabView` while preserving 100% compatibility with existing tests.

- [X] T018 Implement `CalculateTournamentStandingsAndRankingsUseCase` (`TournamentCompetitiveSnapshot`) in `lib/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart` and `StandingsAndRankingsController` Riverpod provider in `lib/application/controllers/standings_and_rankings_controller.dart`
- [X] T019 [P] Create unit test suite for `CalculateTournamentStandingsAndRankingsUseCase` in `test/unit/application/calculate_tournament_standings_and_rankings_use_case_test.dart`
- [X] T020 Integrate `StandingsTableCard`, `KnockoutBracketCard`, and `TournamentRankingsCard` with competitive view selector chips (`Posiciones`, `Llaves`, `Rankings`) into `StandingsTabView` in `lib/presentation/shell/tabs/standings_tab_view.dart` while preserving existing keys (`create_tournament_button`, `filter_format_*`, `select_tournament_*`), `TournamentRulesSummaryCard`, and `TournamentTeamsSection`
- [X] T021 Create comprehensive widget test suite in `test/widget/standings_brackets_rankings_widget_test.dart` verifying all Gherkin scenarios for `US1` (standings & tiebreakers), `US2` (knockout bracket rounds, 2D viewer & automatic winner advancement), `US3` (scorers, assists & Fair Play rankings), and zero `RenderFlex` overflows at 130% text scale
- [X] T022 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and `flutter test --coverage` across the entire repository to verify 0 analyzer issues and 100% test pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T001`–`T003`) — blocks user story phases.
- **Phase 3 (`US1` - Standings & Tiebreakers)**: Depends on Phase 2 (`T004`, `T007`).
- **Phase 4 (`US2` - Knockout Brackets & Auto-Advancement)**: Depends on Phase 2 (`T005`, `T007`).
- **Phase 5 (`US3` - Scorers, Assists & Fair Play Rankings)**: Depends on Phase 2 (`T006`, `T007`).
- **Phase 6 (Integration & Verification)**: Depends on Phases 3, 4, and 5.

### Parallel Opportunities

- `T002` and `T003` can run in parallel during Phase 1.
- `T004`, `T005`, and `T006` (domain entity files) can run in parallel during Phase 2.
- Once Phase 2 finishes, `US1` (`T008`–`T010`), `US2` (`T011`–`T014`), and `US3` (`T015`–`T017`) can be developed independently.

---

## Parallel Example: Foundational & Domain Services

```bash
# Create domain entities in parallel:
Task: "T004 [P] Create StandingsRow and StandingsTable domain entities in lib/domain/entities/standings_table.dart"
Task: "T005 [P] Create KnockoutMatchTieNode, KnockoutBracketRound, and KnockoutBracket domain entities in lib/domain/entities/knockout_bracket.dart"
Task: "T006 [P] Create PlayerRankingEntry, TeamFairPlayRow, and TournamentRankingsBundle domain entities in lib/domain/entities/tournament_rankings.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Phase 1 & Phase 2 (`T001`–`T007`).
2. Complete Phase 3 (`US1`: `T008`–`T010`) to deliver deterministic League & Group Standings with full tiebreaker hierarchy.
3. Add Phase 4 (`US2`: `T011`–`T014`) for Knockout Brackets & Automatic Winner Advancement.
4. Add Phase 5 (`US3`: `T015`–`T017`) for Individual & Fair Play Rankings.
5. Complete Phase 6 (`T018`–`T022`) to unify all views in `StandingsTabView` and pass all quality gates.
