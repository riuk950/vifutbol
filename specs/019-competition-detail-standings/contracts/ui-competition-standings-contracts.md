# UI Component Contracts: Pestaña de Clasificación en Detalle de Competición (HU 13.2)

**Feature**: `019-competition-detail-standings`  
**Status**: Completed  
**Date**: 2026-11-06

---

## 1. Widget Specifications

### 1.1 `CompetitionStandingsTabView`
- **Location**: `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart`
- **Type**: `ConsumerStatefulWidget` or `ConsumerWidget`
- **Parameters**:
  - `required String tournamentId`
- **Responsibility**:
  - Watches `standingsAndRankingsControllerProvider(tournamentId)` and `tournamentsControllerProvider`.
  - Determines tournament format (`TournamentFormat.league`, `knockoutCup`, `mixedGroupsAndKnockout`).
  - Renders subview selection chips in the header.
  - Dynamically renders content based on `state.activeViewMode`:
    - `CompetitiveViewMode.standings`: `StandingsTableCard` (or empty state `competition_detail_standings_empty_state`).
    - `CompetitiveViewMode.brackets`: `KnockoutBracketCard` (or empty state `competition_detail_brackets_empty_state`).
    - `CompetitiveViewMode.rankings`: `TournamentRankingsCard` (or empty state `competition_detail_rankings_empty_state`).

---

## 2. Widget Keys Matrix

| Key Identifier | Widget Type | Description |
|----------------|-------------|-------------|
| `competition_detail_standings_content` | `Widget` | Root container for the Standings tab view |
| `competition_standings_subview_selector` | `Row` / `Wrap` | Container for ChoiceChips subviews |
| `subview_chip_standings` | `ChoiceChip` | Selector chip for "Posiciones" / "Clasificación" |
| `subview_chip_brackets` | `ChoiceChip` | Selector chip for "Llaves" (cup/mixed only) |
| `subview_chip_rankings` | `ChoiceChip` | Selector chip for "Estadísticas" / "Rankings" |
| `competition_standings_table_card` | `StandingsTableCard` | Official standings table card |
| `competition_knockout_bracket_card` | `KnockoutBracketCard` | Knockout bracket tree card |
| `competition_tournament_rankings_card` | `TournamentRankingsCard` | Rankings card (scorers, cards, clean sheets) |
| `competition_detail_standings_empty_state` | `KickPulseStateView` | Empty state when standings table has no teams/points |
| `competition_detail_brackets_empty_state` | `KickPulseStateView` | Empty state when bracket has no rounds defined |
| `competition_detail_rankings_empty_state` | `KickPulseStateView` | Empty state when rankings have no events |
| `competition_detail_standings_loading` | `CircularProgressIndicator` | Loading state while computing competitive snapshot |

---

## 3. Localization Keys Contract (`lib/l10n/app_es.arb`)

```json
{
  "competitionStandingsSubviewsTitle": "Vista competitiva",
  "competitionStandingsEmptyTitle": "Sin Clasificación Disponible",
  "competitionStandingsEmptyDescription": "La tabla de posiciones se generará cuando se registren los primeros resultados oficiales.",
  "competitionBracketsEmptyTitle": "Sin Llaves Disponibles",
  "competitionBracketsEmptyDescription": "El cuadro eliminatorio se generará al definirse los cruces de la fase final.",
  "competitionRankingsEmptyTitle": "Sin Estadísticas Disponibles",
  "competitionRankingsEmptyDescription": "Los rankings de goleadores, tarjetas y vallas invictas se actualizarán con los eventos oficiales."
}
```
*(Reutiliza claves existentes: `competitiveViewStandings`, `competitiveViewBrackets`, `competitiveViewRankings`)*.
