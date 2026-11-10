# Data Model: Coach Team & Roster Governance

**Feature Branch**: `029-coach-team-roster-governance` | **Date**: 2026-11-10

## 1. Entity: `TournamentTeam` (Updated)

Represents a sports team or club managed by a coach and optionally enrolled in a championship tournament.

```dart
class TournamentTeam {
  const TournamentTeam({
    required this.id,
    required this.name,
    required this.shortCode,
    this.tournamentId = '',
    this.groupName,
    this.eligibilityStatus = TeamEligibilityStatus.pendingReview,
    this.players = const <RegisteredPlayer>[],
    required this.updatedAt,
    this.coachId = 'coach-seed-1',
  });

  final String id;
  final String name;
  final String shortCode;
  final String tournamentId;
  final String? groupName;
  final TeamEligibilityStatus eligibilityStatus;
  final List<RegisteredPlayer> players;
  final DateTime updatedAt;
  final String? coachId;
}
```

### Attributes & Validation Rules

| Attribute | Type | Nullable | Validation / Invariant |
|---|---|:---:|---|
| `id` | `String` | No | Unique immutable identifier (e.g., `team-12345678`). |
| `name` | `String` | No | Minimum 3 characters, trimmed. Must be unique within tournament (if assigned). |
| `shortCode` | `String` | No | 2 to 4 characters, trimmed, uppercase alfanumeric. |
| `tournamentId` | `String` | No | Non-empty when enrolled in a competition; empty string `''` when autonomous. |
| `groupName` | `String?` | Yes | Assigned stage group name if mixed format. |
| `eligibilityStatus` | `TeamEligibilityStatus` | No | `pendingReview`, `readyForApproval`, `eligible`, `rejected`. |
| `players` | `List<RegisteredPlayer>` | No | Squad roster list of players. |
| `updatedAt` | `DateTime` | No | Timestamp of latest mutation. |
| `coachId` | `String?` | Yes | ID of the owning coach user account. Defaults to `'coach-seed-1'` for seeds/legacy. |

### JSON Serialization Mapping

```json
{
  "id": "team-tigres-fc",
  "name": "Tigres FC",
  "shortCode": "TIG",
  "tournamentId": "tournament-clausura-2026",
  "groupName": null,
  "eligibilityStatus": "pendingReview",
  "players": [],
  "updatedAt": "2026-11-10T12:00:00.000Z",
  "coachId": "usr-coach-101"
}
```

---

## 2. Role Capability Matrix Mapping

### Matrix Invariants

```text
UserRole.coach:
  - RoleCapability.manageTeamRoster (EXCLUSIVE for team & roster creation)
  - RoleCapability.manageLineups
  - RoleCapability.viewPersonalStats
  - RoleCapability.viewPublicContent

UserRole.organizer:
  - RoleCapability.manageTournaments
  - RoleCapability.manageVenues
  - RoleCapability.approveRegistrations (Approval/Fiscalization ONLY, NO roster creation)
  - RoleCapability.assignReferees
  - RoleCapability.recordMatchEvents
  - RoleCapability.closeMatchReport
  - RoleCapability.viewPersonalStats
  - RoleCapability.viewPublicContent

UserRole.referee:
  - RoleCapability.recordMatchEvents
  - RoleCapability.closeMatchReport
  - RoleCapability.viewPersonalStats
  - RoleCapability.viewPublicContent

UserRole.player:
  - RoleCapability.viewPersonalStats
  - RoleCapability.viewPublicContent

UserRole.fan:
  - RoleCapability.viewPublicContent
```
