# Implementation Plan: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Branch**: `009-standings-brackets-rankings` | **Date**: 2026-11-04 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/009-standings-brackets-rankings/spec.md)

**Input**: Feature specification from `/specs/009-standings-brackets-rankings/spec.md`

## Summary

Implement deterministic calculation and mobile-first visualization of League/Group Standings Tables (`PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`) with configurable hierarchical tiebreakers (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`), interactive Knockout Elimination Brackets (`Octavos`, `Cuartos`, `Semifinal`, `Final` with round-by-round `Vs` cards, 2D panoramic viewer, and automatic winner advancement on regulation or penalty shootout closure), and Individual & Collective Sports Rankings (`Goleadores`, `Asistencias`, `Fair Play`). All calculations are derived deterministically from closed official match reports (`DigitalMatchReport`) and completed matches (`ChampionshipMatch`) under each tournament's `TournamentRulesConfig`, with full offline support and `tabular-nums` alignment.

## Technical Context

**Language/Version**: Dart ^3.11.0 / Flutter >=3.24.0  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `shared_preferences: ^2.3.2`, `flutter_localizations`, `intl`  
**Storage**: Offline-first persistence via `LocalStorageRepository` (`SharedPreferences`) backing `LocalTournamentsRepository`, `LocalTeamsRepository`, `LocalTournamentMatchesRepository`, and `LocalMatchReportsRepository`  
**Testing**: `flutter_test` (Unit tests for domain calculators & use cases; Widget tests covering all Gherkin scenarios and layout/overflow checks)  
**Target Platform**: Mobile (iOS & Android, optimized for 360px–430px viewports and up to 130% text scaling)  
**Project Type**: Mobile App (Flutter Clean / Hexagonal Architecture)  
**Performance Goals**: `< 50ms` for deterministic standings, tiebreaker resolution, bracket tree projection, and sports rankings calculation (`SC-001`); 60fps UI scrolling with `0 RenderFlex overflows` (`SC-004`)  
**Constraints**: Offline-capable with 0s perceived latency from local cache (`SC-005`); strict adherence to `KickPulse` dark design system (`DESIGN.md`) and `tabular-nums` (`FontFeature.tabularFigures()`)  
**Scale/Scope**: Supports League (`league`), Knockout Cup (`knockoutCup`), and Mixed Groups + Knockout (`mixedGroupsAndKnockout`) tournaments up to 32 teams and ratusan of matches/events

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Clean / Hexagonal Architecture (`domain` → `application` → `infrastructure` → `presentation`)**: **PASS**. Pure domain entities (`StandingsTable`, `KnockoutBracket`, `TournamentRankingsBundle`) and pure domain services (`StandingsCalculatorService`, `KnockoutBracketService`, `SportsRankingsCalculatorService`) have zero framework or I/O dependencies. Orchestration lives in `CalculateTournamentStandingsAndRankingsUseCase` and `ManageDigitalMatchReportUseCase`.
- **II. Offline-First & Local Persistence**: **PASS**. Standings, brackets, and rankings are computed deterministically from locally cached `ChampionshipTournament`, `TournamentTeam`, `ChampionshipMatch`, and `DigitalMatchReport` records via `LocalStorageRepository`, working 100% offline.
- **III. Strict Role-Based Access Control (RBAC)**: **PASS**. All 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) have read access to standings, brackets, and rankings (`RoleCapability.viewPublicStandings`), while match report closure and penalty shootout recording remain strictly gated by `RoleCapability.closeMatchReport` / `RoleCapability.manageTournaments`.
- **IV. Testing & Quality Gates**: **PASS**. Unit tests for all tiebreaker permutations (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`), knockout winner advancement (including penalty shootouts), and rankings, plus widget tests for all Gherkin scenarios and `0` analyzer warnings.
- **V. KickPulse Design System & Accessibility (`DESIGN.md`)**: **PASS**. Uses `KickPulseColors`, `KickPulseTypography.statMetric()` with `FontFeature.tabularFigures()` (`tabular-nums`) for all numerical columns (`FR-010`), and responsive round-by-round + 2D panoramic bracket views (`FR-005`).
- **VI. Language Policy (English Code / Spanish UI via `app_es.arb`)**: **PASS**. All classes, methods, variables, files, and tests are in English; all user-facing labels and messages are centralized in `lib/l10n/app_es.arb`.

## Project Structure

### Documentation (this feature)

```text
specs/009-standings-brackets-rankings/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── standings-brackets-rankings-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── championship_match.dart              # Updated with optional homePenaltyScore, awayPenaltyScore, groupName
│   │   ├── digital_match_report.dart            # Updated with optional homePenaltyScore, awayPenaltyScore
│   │   ├── standings_table.dart                 # NEW: StandingsRow & StandingsTable entities
│   │   ├── knockout_bracket.dart                # NEW: KnockoutMatchTieNode, KnockoutBracketRound & KnockoutBracket
│   │   └── tournament_rankings.dart             # NEW: PlayerRankingEntry, TeamFairPlayRow & TournamentRankingsBundle
│   ├── repositories/
│   │   └── match_reports_repository.dart        # Updated with loadReportsForTournament(String tournamentId)
│   └── services/
│       ├── standings_calculator_service.dart    # NEW: Deterministic league/group standings & hierarchical tiebreakers
│       ├── knockout_bracket_service.dart        # NEW: Bracket tree builder & automatic winner advancement
│       └── sports_rankings_calculator_service.dart # NEW: Scorers, assists & Fair Play (-1/-3/-3) calculator
├── application/
│   ├── use_cases/
│   │   ├── calculate_tournament_standings_and_rankings_use_case.dart # NEW: Aggregates competitive snapshot
│   │   └── manage_digital_match_report_use_case.dart # Updated: Supports penalty scores on knockout draw & auto-advances winner on close
│   └── controllers/
│       └── standings_and_rankings_controller.dart # NEW: Riverpod state notifier for standings, brackets & rankings
├── infrastructure/
│   └── repositories/
│       └── local_match_reports_repository.dart  # Updated: Implements loadReportsForTournament
├── presentation/
│   ├── shell/
│   │   └── tabs/
│   │       └── standings_tab_view.dart          # Updated: Integrates Standings, Knockout Bracket, and Rankings views
│   └── standings/
│       └── widgets/
│           ├── standings_table_card.dart        # NEW: Tabular-nums responsive standings table widget (league & groups)
│           ├── knockout_bracket_card.dart       # NEW: Round-by-round Vs cards + 2D InteractiveViewer panoramic bracket
│           └── tournament_rankings_card.dart    # NEW: Goleadores, Asistencias & Fair Play leaderboard widget
└── l10n/
    └── app_es.arb                               # Updated: Spanish strings for standings, brackets, tiebreakers & rankings

test/
├── unit/
│   ├── domain/
│   │   ├── standings_calculator_service_test.dart
│   │   ├── knockout_bracket_service_test.dart
│   │   └── sports_rankings_calculator_service_test.dart
│   └── application/
│       └── calculate_tournament_standings_and_rankings_use_case_test.dart
└── widget/
    └── standings_brackets_rankings_widget_test.dart
```

**Structure Decision**: Follows the established Flutter Clean / Hexagonal Architecture layout (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`) and mirrors the testing hierarchy (`test/unit/domain`, `test/unit/application`, `test/widget`).

## Complexity Tracking

> No Constitution violations exist. Clean separation between pure domain calculation services and presentation widgets keeps cyclomatic complexity low and testability at 100%.
