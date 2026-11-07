# UI Component Contracts: Pestaña de Información y Reglas Oficiales (HU 13.3)

**Feature**: `020-competition-detail-rules`  
**Status**: Completed  
**Date**: 2026-11-06

---

## 1. Widget Specifications

### 1.1 `CompetitionInfoTabView`
- **Location**: `lib/presentation/tournaments/widgets/competition_info_tab_view.dart`
- **Type**: `ConsumerWidget`
- **Parameters**:
  - `required String tournamentId`
- **Responsibility**:
  - Watches `tournamentsControllerProvider`, `activeUserRoleProvider`, `matchesControllerProvider`, and `venuesControllerProvider`.
  - Locates the tournament by `tournamentId`.
  - If loading: renders `CircularProgressIndicator` with key `competition_detail_info_loading`.
  - If not found: renders `KickPulseStateView` with key `competition_detail_info_not_found`.
  - If found: renders a scrollable column containing:
    1. `TournamentRulesSummaryCard` with `isOrganizer: isOrganizer` and action callbacks passed as `null` (strictly read-only).
    2. Primary Venue Card (`KickPulseCard`) with key `competition_main_venue_card` (if a venue is resolved).

### 1.2 `TournamentRulesSummaryCard`
- **Location**: `lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart`
- **Type**: `StatelessWidget`
- **Audit Trail Guard Contract**:
  - Renders audit trail card ONLY if `isOrganizer && tournament.auditTrail.isNotEmpty`.
  - For non-organizers or when `auditTrail.isEmpty`, omits the card completely.

---

## 2. Widget Keys Matrix

| Key Identifier | Widget Type | Description |
|----------------|-------------|-------------|
| `competition_detail_info_content` | `Widget` | Root container for the Info tab view |
| `competition_detail_info_loading` | `CircularProgressIndicator` | Centered loading indicator while tournaments load |
| `competition_detail_info_not_found` | `KickPulseStateView` | Empty/error state when tournament ID is not found |
| `competition_tournament_rules_card` | `TournamentRulesSummaryCard` | Official rules summary card |
| `competition_main_venue_card` | `KickPulseCard` | Venue summary card showing name, address, and pitches |
| `competition_venue_pitches_badge` | `Container` / `Text` | Badge displaying count of active pitches |

---

## 3. Localization Keys Contract (`lib/l10n/app_es.arb`)

```json
{
  "competitionMainVenueTitle": "Sede Principal",
  "competitionMainVenueAddress": "Dirección",
  "competitionMainVenuePitches": "{count, plural, =1{1 cancha disponible} other{{count} canchas disponibles}}",
  "@competitionMainVenuePitches": {
    "description": "Number of pitches in primary venue",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "competitionInfoNotFoundTitle": "Competición No Encontrada",
  "competitionInfoNotFoundDescription": "No se pudo cargar la información reglamentaria del campeonato solicitado."
}
```
*(Reutiliza claves existentes: `tournamentScoringTitle`, `tournamentPointsWin`, `tournamentPointsDraw`, `tournamentPointsLoss`, `tournamentTiebreakersTitle`, `tournamentRulesTitle`, `matchDurationLabel`, `tournamentSquadLimits`, `tournamentDisciplinaryRules`, `tournamentAuditTrailTitle`)*.
