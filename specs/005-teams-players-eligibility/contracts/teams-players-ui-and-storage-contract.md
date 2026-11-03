# UI & Persistence Contracts: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Feature**: `005-teams-players-eligibility`  
**Date**: 2026-04-17

## 1. Repository Contract (`TeamsRepository`)

**Path**: `lib/domain/repositories/teams_repository.dart`

```dart
abstract interface class TeamsRepository {
  Future<List<TournamentTeam>> loadTeams();
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId);
  Future<TournamentTeam> saveTeam(TournamentTeam team);
}
```

### Persistence Key & Development Seeds (`LocalTeamsRepository`)
- **Storage Key**: `'vifutbol.teams.catalog.v1'` (JSON array of `TournamentTeam`).
- **Development Seeds (`AppEnvironment.development`)**:
  - Para `'tournament-seed-liga-clausura'` (`minPlayersPerTeam: 7`, `maxPlayersPerTeam: 18`):
    1. `"Atlético Norte FC"` (`shortCode: 'ATN'`, `TeamEligibilityStatus.eligible`, `7` jugadores inscritos con dorsales `1, 4, 5, 8, 9, 10, 11` y documentos `'10100001'`..`'10100007'`).
    2. `"Real Sabana Club"` (`shortCode: 'RSC'`, `TeamEligibilityStatus.pendingQuota`, `5` jugadores inscritos con dorsales `1, 2, 6, 7, 10` y documentos `'20200001'`..`'20200005'`, faltando `2` jugadores para alcanzar el mínimo de `7`).

## 2. Application Use Case Contract (`ManageTeamsEligibilityUseCase`)

**Path**: `lib/application/use_cases/manage_teams_eligibility_use_case.dart`

- `registerOrUpdateTeam(...)`:
  - Verifica permiso de gestión de equipo (`RoleCapability.manageTeamRoster || RoleCapability.manageTournaments || RoleCapability.approveRegistrations`).
  - Verifica que `tournament.status == TournamentStatus.openRegistration`; de lo contrario lanza `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.tournamentRegistrationsClosed)`.
  - Valida `name.trim().length >= 3` y `shortCode.trim().length` entre `2` y `4`.
  - Valida unicidad de `name` dentro de `tournament.id` (`TeamEligibilityErrorCode.duplicateTeamNameInTournament`).
- `enrollOrUpdatePlayer(...)`:
  - Verifica permiso (`Organizador` o `Entrenador`) y `tournament.status == TournamentStatus.openRegistration`.
  - Valida `fullName.trim().length >= 3`, `documentId.trim().length >= 5`, y `shirtNumber` en `1..99`.
  - Si es jugador nuevo y `team.players.length >= tournament.rules.maxPlayersPerTeam`, lanza `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.maxPlayersQuotaReached)`.
  - Verifica que el `documentId` normalizado no esté inscrito en ningún otro equipo (ni en otro registro del mismo equipo) dentro del mismo `tournament.id`. Si existe colisión, lanza `TeamEligibilityValidationFailure` con código `playerAlreadyRegisteredInTournament` y mensaje exacto:
    `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`
  - Verifica que `shirtNumber` no esté asignado a otro jugador del mismo equipo. Si existe colisión, lanza `TeamEligibilityValidationFailure` con código `duplicateShirtNumberInTeam` y mensaje exacto:
    `"El número de camiseta $shirtNumber ya está en uso en este equipo."`
  - Recalcula automáticamente `eligibilityStatus` (`pendingQuota` si `< minPlayersPerTeam`, `readyForApproval` si alcanza `minPlayersPerTeam` y estaba en `pendingQuota`, o mantiene `eligible` si ya estaba habilitado).
- `removePlayer(...)`:
  - Verifica permiso (`Organizador` o `Entrenador`) y `tournament.status == TournamentStatus.openRegistration`.
  - Remueve al jugador y, si el total queda por debajo de `tournament.rules.minPlayersPerTeam`, revierte `eligibilityStatus` a `TeamEligibilityStatus.pendingQuota` y `isEligible = false` en los jugadores restantes.
- `approveTeamEligibility(...)`:
  - Verifica exclusivamente `RoleCapability.approveRegistrations` (`Organizador`).
  - Verifica `team.players.length >= tournament.rules.minPlayersPerTeam` y `<= tournament.rules.maxPlayersPerTeam`; de lo contrario lanza `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.insufficientPlayersForApproval)`.
  - Marca el equipo como `TeamEligibilityStatus.eligible` y todos sus `players` con `isEligible = true`.

## 3. UI & Routing Contract

- **Routes (`AppRouter`)**:
  - `/tournaments/teams/detail`: Abre `TeamRosterDetailScreen`.
- **Mobile Form Guidelines**:
  - El formulario de jugador (`PlayerEnrollmentSheet` / diálogo en `TeamRosterDetailScreen`) configura `keyboardType: TextInputType.number` para el campo de documento de identidad (`player_document_input`) y para el campo de dorsal (`player_shirt_number_input`), con validación en línea y botón protegido contra doble pulsación.
