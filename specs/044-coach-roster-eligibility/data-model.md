# Data Model: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico (HU 20.1)

**Feature**: `044-coach-roster-eligibility`  
**Schema**: `vifutboldev` (PostgreSQL / Supabase) + Local Cache (Hive)

## 1. Domain Entities

### 1.1 `TeamJoinRequestStatus` (Enum)
```dart
enum TeamJoinRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}
```

### 1.2 `TeamJoinRequest` (`lib/domain/entities/team_join_request.dart`)
| Field | Type | Constraints / Notes |
|---|---|---|
| `id` | `String` | UUID inmutable |
| `teamId` | `String` | UUID del club/equipo destino |
| `tournamentTeamId` | `String?` | UUID de la inscripción en torneo (nulo si es club base sin torneo) |
| `tournamentId` | `String?` | UUID del torneo (nulo si es club base) |
| `teamName` | `String` | Nombre oficial del club |
| `teamShortCode` | `String` | Sigla del club |
| `coachAccountId` | `String` | UUID de `user_accounts` del entrenador |
| `coachName` | `String` | Nombre del entrenador que envía la invitación |
| `playerAccountId` | `String` | UUID de `user_accounts` del jugador destinatario |
| `playerName` | `String` | Nombre completo del jugador |
| `playerDocumentId` | `String` | Documento del jugador |
| `shirtNumber` | `int` | Dorsal propuesto (`1..99`) |
| `position` | `PlayerPosition` | `goalkeeper`, `defender`, `midfielder`, `forward` |
| `status` | `TeamJoinRequestStatus` | `pending`, `accepted`, `rejected`, `cancelled` |
| `createdAt` | `DateTime` | Fecha de envío |
| `updatedAt` | `DateTime` | Última actualización |

### 1.3 `AvailablePlayerCandidate` (`lib/domain/entities/available_player_candidate.dart`)
Representa un usuario con rol `player` disponible para ser invitado por un entrenador:
- `userAccountId` (`String`)
- `fullName` (`String`)
- `documentId` (`String`)
- `normalizedDocumentId` (`String`)

## 2. Relational Database Schema (`vifutboldev`)

### 2.1 New Table: `vifutboldev.team_join_requests`
```sql
CREATE TABLE IF NOT EXISTS vifutboldev.team_join_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES vifutboldev.teams(id) ON DELETE CASCADE,
  tournament_team_id uuid REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  coach_account_id uuid NOT NULL REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  player_account_id uuid NOT NULL REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  shirt_number integer NOT NULL CHECK (shirt_number BETWEEN 1 AND 99),
  position text NOT NULL CHECK (position IN ('goalkeeper', 'defender', 'midfielder', 'forward')),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);
```

### 2.2 Integrity Indexes
- `ux_team_join_requests_pending_player`: `UNIQUE (team_id, player_account_id) WHERE status = 'pending'` (un jugador no puede tener dos solicitudes pendientes simultáneas para el mismo equipo).
- `ux_team_join_requests_pending_shirt`: `UNIQUE (team_id, shirt_number) WHERE status = 'pending'` (reserva temporal del dorsal propuesto mientras la solicitud está pendiente).
- `idx_team_join_requests_player`: `(player_account_id, status)`.
- `idx_team_join_requests_team`: `(team_id, status)`.

## 3. State Transitions

### 3.1 `TeamJoinRequest` Lifecycle
- `pending` → `accepted` (Acción del jugador `player` vía RPC `respond_team_join_request(id, true)` → inserta/vincula fila en `vifutboldev.players`).
- `pending` → `rejected` (Acción del jugador `player` vía RPC `respond_team_join_request(id, false)` → libera dorsal).
- `pending` → `cancelled` (Acción del entrenador `coach` → libera dorsal).

### 3.2 `TournamentTeam` Eligibility Lifecycle
- `pendingVerification` / `incompleteRoster` → `eligible`:
  - **Guard**: `team.players.length >= max(11, tournament.rules.minPlayersPerTeam)` y `<= tournament.rules.maxPlayersPerTeam`.
  - **Actor permitido**: `UserRole.coach` (dueño del equipo) o `UserRole.organizer`.
  - Si `team.players.length < 11`, la transición a `eligible` es rechazada con `TeamEligibilityValidationFailure(insufficientPlayersForApproval)`.
