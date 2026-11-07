# Research: Pestaña de Información y Reglas Oficiales de la Competición (HU 13.3)

**Feature**: `020-competition-detail-rules`  
**Status**: Completed  
**Date**: 2026-11-06

---

## 1. Technical Context & Component Architecture

### 1.1 Existing Components
- **`TournamentRulesSummaryCard` (`lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart`)**:
  - Implements complete visual presentation for:
    - Scoring System (`pointsForWin`, `pointsForDraw`, `pointsForLoss`).
    - Match parameters (half duration, league rounds, group stage, knockout bracket structure).
    - Team roster quotas (`minPlayersPerTeam`, `maxPlayersPerTeam`).
    - Disciplinary policy (`yellowCardsLimitForSuspension`).
    - Ordered tie-breakers (`tiebreakerOrder`).
    - Official tournament validity dates (`startDate`, `endDate`).
    - Audit trail (`auditTrail`) — already implemented with `entry.summary` and `entry.reason`.
  - Action buttons (`onEditPressed`, `onTransitionStatusPressed`, `onBackupPressed`, `onCloseSeasonPressed`) are optional and only render when non-null. Passing `null` natively satisfies the **read-only requirement** (Clarification 1).
- **`CompetitionInfoTabView` (`lib/presentation/tournaments/widgets/competition_info_tab_view.dart`)**:
  - Currently a placeholder card.
  - Will be upgraded to a `ConsumerWidget` that coordinates `tournamentsControllerProvider`, `activeUserRoleProvider`, and `venuesControllerProvider`.
- **`SportsVenue` & `VenuesController` (`lib/application/providers/venues_providers.dart`)**:
  - Manages registered sports complexes with address, pitches count, and urban references.

---

## 2. Decision Log

| Decision ID | Context | Choice | Justification |
|-------------|---------|--------|---------------|
| D-001 | Normative consultation mode | Read-only consultation | Clarification 1: keeps competition detail focused on sports consultation; management actions reside in admin panels. |
| D-002 | Audit trail visibility | Visible only if `isOrganizer && auditTrail.isNotEmpty` | Clarification 2: hides internal administrative audit from non-organizers and saves vertical space when empty. |
| D-003 | Main venue presentation | Card below rules summary | Clarification 3: exposes physical venue details (name, address, pitches) without modifying the domain aggregate. |
| D-004 | Component reusability | Direct reuse of `TournamentRulesSummaryCard` | Avoids duplicate maintenance of scoring, tiebreakers, and knockout structure widgets. |

---

## 3. Best Practices & Invariants
- **Zero RenderFlex Overflows**: SingleChildScrollView with vertical padding ensures responsive behavior at $320 \times 640\text{ px}$ with $130\%$ text scaling.
- **Language Separation**: All UI text in Spanish via `app_es.arb`. Technical code and tests in English.
- **Role Isolation**: Non-organizer users never see the audit trail card.
