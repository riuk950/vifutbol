# Data Model: Pestaña de Información y Reglas Oficiales de la Competición (HU 13.3)

**Feature**: `020-competition-detail-rules`  
**Status**: Completed  
**Date**: 2026-11-06

---

## 1. Entity & Value Object Definitions

```mermaid
classDiagram
    class ChampionshipTournament {
        +String id
        +String name
        +String category
        +TournamentFormat format
        +TournamentStatus status
        +DateTime startDate
        +DateTime endDate
        +TournamentRulesConfig rules
        +List~RuleAuditEntry~ auditTrail
    }

    class TournamentRulesConfig {
        +int pointsForWin
        +int pointsForDraw
        +int pointsForLoss
        +int matchDurationMinutes
        +int minPlayersPerTeam
        +int maxPlayersPerTeam
        +int yellowCardsLimitForSuspension
        +List~TiebreakerCriterion~ tiebreakerOrder
        +KnockoutBracketStructure? knockoutStructure
    }

    class RuleAuditEntry {
        +String id
        +DateTime timestamp
        +String modifiedByRole
        +String summary
        +String reason
    }

    class SportsVenue {
        +String id
        +String name
        +String address
        +String urbanReference
        +List~VenuePitch~ pitches
        +VenueOperationalStatus status
    }

    class UserRole {
        <<enumeration>>
        organizer
        coach
        referee
        player
        fan
    }

    ChampionshipTournament --> TournamentRulesConfig : contains
    ChampionshipTournament --> RuleAuditEntry : contains audit history
    SportsVenue --> VenuePitch : contains pitches
```

---

## 2. Invariants & Visibility Rules

| Component / Section | Invariant / Guard Condition | Target Audience / Roles | Visual Treatment |
|---------------------|-----------------------------|-------------------------|------------------|
| **Tournament Header & Status** | `tournament != null` | All roles (`organizer`, `coach`, `referee`, `player`, `fan`) | Status badge, format badge, category, dates `DD/MM/AAAA`. |
| **Scoring System** | `rules != null` | All roles | Metrics boxes: `pointsForWin`, `pointsForDraw`, `pointsForLoss`. |
| **Tiebreaker Criteria** | `format.hasStandingsTable` | All roles | Ordered list of `tiebreakerOrder` (1. Diff, 2. GF, etc.). |
| **Match Parameters** | Always present | All roles | Duration per half (`matchDurationMinutes`), format, and rounds. |
| **Squad & Discipline** | Always present | All roles | `minPlayersPerTeam`, `maxPlayersPerTeam`, `yellowCardsLimitForSuspension`. |
| **Knockout Structure** | `format == knockoutCup \|\| mixed` | All roles | Total rounds, third place match, overtime & penalties policies. |
| **Audit Trail Card** | `isOrganizer && tournament.auditTrail.isNotEmpty` | `UserRole.organizer` ONLY | Chronological list of audit changes. Completely hidden for non-organizers and when empty. |
| **Main Venue Card** | `primaryVenue != null` | All roles | Name, address, active pitches count, icon. Omitted if no venue is resolved. |
| **Management Actions** | Disabled / `null` in tab | All roles (Read-Only) | All action callbacks (`onEditPressed`, etc.) set to `null`. |

---

## 3. Venue Resolution Flow

```mermaid
flowchart TD
    A["CompetitionInfoTabView (tournamentId)"] --> B["Look up Tournament Matches in matchesControllerProvider"]
    B --> C{"Any match has venueId?"}
    C -- Yes --> D["Find SportsVenue in venuesControllerProvider matching venueId"]
    C -- No --> E["Fallback: venuesCatalogState.venues.firstOrNull"]
    D --> F{"Venue found?"}
    E --> F
    F -- Yes --> G["Render Primary Sports Venue Card"]
    F -- No --> H["Omit Venue Card gracefully"]
```
