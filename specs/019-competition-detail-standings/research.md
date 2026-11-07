# Research: Pestaña de Clasificación y Resultados de Equipos en el Detalle de Competición (HU 13.2)

**Feature**: `019-competition-detail-standings`  
**Status**: Completed  
**Date**: 2026-11-06

---

## 1. Technical Context & Reusability Analysis

### 1.1 Existing Architecture
- **State Management & Controller**: `StandingsAndRankingsController` (`lib/application/controllers/standings_and_rankings_controller.dart`) exposes:
  - `activeViewMode` (`CompetitiveViewMode` with `.standings`, `.brackets`, `.rankings`).
  - `selectViewMode(CompetitiveViewMode mode)`.
  - `snapshot` (`TournamentCompetitiveSnapshot` containing `mainStandingsTable`, `groupStandingsTables`, `knockoutBracket`, and `rankings`).
  - `isLoading` (`bool`).
- **Visual Presentation Widgets**:
  - `StandingsTableCard` (`lib/presentation/standings/widgets/standings_table_card.dart`): Displays official standings table with `#`, team crest, team name, and stats `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS` formatted with `FontFeature.tabularFigures()`. Supports multi-group tables (`groupTables`) with built-in group selector chips.
  - `KnockoutBracketCard` (`lib/presentation/standings/widgets/knockout_bracket_card.dart`): Renders interactive knockout rounds and matches tree.
  - `TournamentRankingsCard` (`lib/presentation/standings/widgets/tournament_rankings_card.dart`): Renders top scorers, disciplinary (yellow/red cards), and clean sheets lists.
  - `KickPulseStateView` (`lib/presentation/design_system/widgets/kick_pulse_state_view.dart`): Standard design system component for empty, loading, and error states.

### 1.2 Tournament Format Adaptation
In `lib/domain/entities/tournament_enums.dart`:
- `TournamentFormat.league`:
  - `hasStandingsTable`: `true`
  - `hasKnockoutBracket`: `false`
  - Subviews: "Posiciones" (`standings`), "Estadísticas" (`rankings`).
  - Default: `standings`.
- `TournamentFormat.knockoutCup`:
  - `hasStandingsTable`: `false`
  - `hasKnockoutBracket`: `true`
  - Subviews: "Llaves" (`brackets`), "Estadísticas" (`rankings`).
  - Default: `brackets`.
- `TournamentFormat.mixedGroupsAndKnockout`:
  - `hasStandingsTable`: `true`
  - `hasKnockoutBracket`: `true`
  - Subviews: "Posiciones" (`standings`), "Llaves" (`brackets`), "Estadísticas" (`rankings`).
  - Default: `standings` (Resolved via Clarification 1).

### 1.3 Offline & Memory Considerations
- `StandingsAndRankingsController` caches `TournamentCompetitiveSnapshot`.
- Tab switching in `CompetitionDetailScreen` preserves tab state without triggering fresh repository reads if the snapshot has already been calculated.
- When tapping rows, as resolved in Clarification 2, team items are read-only in this phase (`onTeamSelected: null`), preventing unnecessary modal rebuilds.

---

## 2. Decision Log

| Decision ID | Context | Choice | Justification |
|-------------|---------|--------|---------------|
| D-001 | Navigation within "Clasificación" tab | ChoiceChips selector in tab header | Keeps UI modular, eliminates excessive vertical scroll, and mirrors proven `StandingsTabView` UX. |
| D-002 | Default subview for mixed format | `CompetitiveViewMode.standings` | Clarification 1: group phase is the entry point for all competing teams before playoff brackets. |
| D-003 | Team row interaction | Read-only display | Clarification 2: avoids out-of-scope modal sheets and keeps feature focused on position consultation. |
| D-004 | Rankings components | Complete `TournamentRankingsCard` | Clarification 2 (Q2): reutilizes full existing widget covering scorers, cards, and clean sheets. |
| D-005 | Empty states per subview | `KickPulseStateView` with visible chips | Clarification 3: users can still navigate to other subviews even if one subview has no data. |

---

## 3. Best Practices & Invariants
- **Tabular Figures**: Every numeric column in `StandingsTableCard` uses `KickPulseTypography` with `FontFeature.tabularFigures()`.
- **Zero RenderFlex Overflows**: The standings card supports horizontal scrolling for compact viewports ($320\text{ px}$) while vertical list is bounded.
- **Language Separation**: UI texts in Spanish via `app_es.arb`; technical code, identifiers, and tests in English.
