# Data Model: Gestión de Equipos Inscritos en Competición (HU 15.4)

**Feature**: `027-competition-teams-management`  
**Date**: 2026-11-10

## 1. Domain Entities

### `TournamentTeam` (`lib/domain/entities/tournament_team.dart`)

Representa un equipo inscrito en un campeonato específico.

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `String` | No | Identificador único del registro de equipo en el torneo |
| `tournamentId` | `String` | No | ID del `ChampionshipTournament` al que pertenece |
| `name` | `String` | No | Nombre oficial del club ($3\text{–}60$ caracteres, único por `tournamentId`) |
| `shortCode` | `String` | No | Sigla del equipo en mayúsculas ($2\text{–}4$ caracteres) |
| `crestShape` | `TeamCrestShape` | No | Forma del escudo (`shield`, `circle`, `diamond`, `hexagon`) |
| `primaryColorHex` | `int` | No | Color principal del club (`0xFF...`) |
| `secondaryColorHex` | `int` | No | Color secundario del club (`0xFF...`) |
| `eligibilityStatus` | `TeamEligibilityStatus` | No | Estado de elegibilidad (`pendingQuota`, `eligible`, `ineligible`) |
| `players` | `List<RegisteredPlayer>` | No | Jugadores inscritos ordenados por dorsal |
| `groupName` | `String?` | Yes | **Nuevo**: Nombre del grupo asignado en torneos `mixedGroupsAndKnockout` (ej. `"Grupo A"`, `"Grupo B"`). `null` en ligas/copas o si usa asignación por defecto |
| `updatedAt` | `DateTime` | No | Marca de tiempo de última actualización |

#### Reglas de Serialización (`toJson` / `fromJson`)
- `toJson()` incluye `'groupName': groupName` (o `null`).
- `fromJson(Map<String, dynamic> json)` lee `groupName: json['groupName'] as String?`.
- `copyWith` añade `String? groupName` y `bool clearGroupName = false`.

---

## 2. Repository & Service Contracts

### `TeamsRepository` (`lib/domain/repositories/teams_repository.dart`)

Se añade la operación de eliminación individual de un equipo:

```dart
/// Removes the team with [teamId] from storage.
Future<void> deleteTeam(String teamId);
```

### `StandingsCalculatorService` (`lib/domain/services/standings_calculator_service.dart`)

En `calculateGroupStageTables`:
1. Genera la lista de nombres de grupos válidos para el torneo según `groupCount = tournament.rules.groupStageConfig.groupCount.clamp(2, 8)`:
   `['Grupo A', 'Grupo B', ...]`
2. Para cada equipo en `sortedTeams`:
   - Si `team.groupName != null` y pertenece a los grupos válidos del torneo, se ubica directamente en el bucket de ese grupo.
   - Si `team.groupName == null` o no coincide con un grupo válido del torneo, se asigna deterministamente al bucket `fallbackIndex % groupCount`.
3. Además, se expone un método auxiliar determinista `resolveEffectiveGroupName(TournamentTeam team, List<TournamentTeam> allTournamentTeams, int groupCount)` para que tanto la pestaña **Equipos** como **Clasificación** muestren exactamente el mismo grupo para cualquier equipo sin `groupName` explícito.

---

## 3. Application Layer (`ManageTeamsEligibilityUseCase` & `TeamsController`)

### `ManageTeamsEligibilityUseCase`
- `Future<TournamentTeam> enrollTeamInCompetition({required TournamentTeam team, required ChampionshipTournament tournament, required UserRole actorRole})`
  - Verifica `RolePermissionMatrix.hasCapability(actorRole, RoleCapability.manageTournaments)`.
  - Verifica `tournament.status.isEditable` (`openRegistration` o `inProgress`; lanza `TeamEligibilityValidationFailure` con `tournamentRegistrationsClosed` si está `finished`).
  - Valida `name.trim().length >= 3`, `shortCode.trim().length` entre $2$ y $4$, y que no exista otro equipo con el mismo `normalizedName` en `tournament.id`.
  - Persiste y retorna el `TournamentTeam`.
- `Future<void> removeTeamFromCompetition({required String teamId, required ChampionshipTournament tournament, required UserRole actorRole, List<ChampionshipMatch> tournamentMatches = const []})`
  - Verifica `RoleCapability.manageTournaments` y `tournament.status.isEditable`.
  - Verifica que el equipo exista en `tournament.id`.
  - Si `tournamentMatches` contiene algún partido del equipo en estado `MatchStatus.inProgress` o `MatchStatus.completed`, lanza `TeamEligibilityValidationFailure` bloqueando el retiro.
  - Invoca `_repository.deleteTeam(teamId)` (y limpia los partidos pendientes del equipo si existieran).
- `Future<TournamentTeam> moveTeamToGroup({required String teamId, required String groupName, required ChampionshipTournament tournament, required UserRole actorRole})`
  - Verifica `RoleCapability.manageTournaments` y `tournament.status.isEditable`.
  - Verifica que el equipo exista en `tournament.id` y actualiza `groupName`.

### `TeamsController`
- `Future<bool> enrollTeamInCompetition({required TournamentTeam team, required ChampionshipTournament tournament, required UserRole actorRole})`
- `Future<bool> removeTeamFromCompetition({required String teamId, required ChampionshipTournament tournament, required UserRole actorRole})`
- `Future<bool> moveTeamToGroup({required String teamId, required String groupName, required ChampionshipTournament tournament, required UserRole actorRole})`
  - Todos protegidos con bloqueo *single-flight* (`if (state.isSaving) return false;`) y recarga automática de `state.teams`.
