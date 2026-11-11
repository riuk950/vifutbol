# Data Model: Inscripción de Equipos mediante FAB Menu con Buscador (HU 18.4)

**Feature**: `035-competition-fab-team-search`  
**Date**: 2026-11-11  

---

## 1. Entidades Existentes Involucradas (Sin Cambios de Esquema Persistido)

### 1.1 `TournamentTeam` (`lib/domain/entities/tournament_team.dart`)
- **Identidad y Vínculo**:
  - `id: String` — Identificador único de la inscripción del equipo en el torneo destino (`'team-${uuid}'`).
  - `tournamentId: String` — Identificador de la competición destino.
  - `name: String` — Nombre del club.
  - `shortCode: String` — Sigla (2–4 caracteres en mayúsculas).
- **Metadatos Visuales y Deportivos**:
  - `crestShape: TeamCrestShape`
  - `primaryColorHex: int`
  - `secondaryColorHex: int`
  - `coachId: String?`
  - `groupName: String?` — Para formato `mixedGroupsAndKnockout`, asignado al grupo con menor cantidad de participantes si no se especifica uno.
- **Estado y Nómina**:
  - `eligibilityStatus: TeamEligibilityStatus` — Siempre `TeamEligibilityStatus.pendingVerification` al inscribirse desde el modal.
  - `players: List<RegisteredPlayer>` — Copia de jugadores no conflictivos del club origen, cada uno con `id` único para la nueva inscripción e `isEligible: false`.

### 1.2 `RegisteredPlayer` (`lib/domain/entities/registered_player.dart`)
- `id: String` — Identificador único por instancia de jugador en el equipo inscrito.
- `fullName: String`
- `documentId: String` / `normalizedDocumentId` (`documentId.trim().toUpperCase()`) — Clave de unicidad por campeonato.
- `shirtNumber: int`
- `position: PlayerPosition`
- `isEligible: bool` — Forzado a `false` al copiar la plantilla base (todos pendientes de validación conforme a HU 16.3 y Clarificación Q2).

---

## 2. Modelos de Transferencia / Vista (Nuevos o Derivados)

### 2.1 `EnrollExistingTeamResult` (`lib/application/use_cases/manage_teams_eligibility_use_case.dart`)
Resultado estructurado devuelto al inscribir un equipo existente desde el catálogo global:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `enrolledTeam` | `TournamentTeam` | Instancia persistida en el repositorio para la competición destino. |
| `copiedPlayersCount` | `int` | Cantidad de jugadores de la plantilla base copiados en estado pendiente. |
| `skippedConflictingPlayersCount` | `int` | Cantidad de jugadores omitidos porque su `normalizedDocumentId` ya pertenece a otro club de la misma competición (o exceden el cupo máximo). |
| `assignedGroupName` | `String?` | Grupo asignado automáticamente en formato mixto (`null` en liga/copa). |

### 2.2 `CatalogTeamEntry` (Modelo de Presentación en `AddTeamsToCompetitionModal`)
Representa cada club deduplicado en el catálogo mostrado por el buscador:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `sourceTeam` | `TournamentTeam` | Registro representativo del club (preferencia al de mayor nómina y `updatedAt` más reciente). |
| `normalizedKey` | `String` | `normalizeSearchText(sourceTeam.name)` usado para deduplicación y comparación insensible a mayúsculas/tildes. |
| `isEnrolledInCurrentTournament` | `bool` | `true` si existe un equipo en la competición actual cuyo `id == sourceTeam.id` o `normalizeSearchText(name) == normalizedKey`. |

---

## 3. Reglas de Transición y Validación

1. **Deduplicación del Catálogo Global**:
   - Agrupar todos los `TournamentTeam` de `teamsControllerProvider.teams` por `normalizeSearchText(team.name)`.
   - Seleccionar como candidato representativo el registro con mayor `players.length`; ante empate, el de `updatedAt` más reciente (o perteneciente a la competición actual si ya está inscrito).
   - Ordenar alfabéticamente por `name` (`a.name.toLowerCase().compareTo(b.name.toLowerCase())`).
2. **Detección de Equipo Ya Inscrito (`FR-005`)**:
   - `enrolledIds`: `currentTournamentTeams.map((t) => t.id).toSet()`
   - `enrolledNormalizedNames`: `currentTournamentTeams.map((t) => normalizeSearchText(t.name)).toSet()`
   - Un candidato está `Inscrito` si `enrolledIds.contains(candidate.id) || enrolledNormalizedNames.contains(normalizeSearchText(candidate.name))`.
3. **Resolución de Conflicto de Jugadores (`Clarificación Q4`)**:
   - Construir `existingTournamentDocs` con todos los `player.normalizedDocumentId` de los equipos actualmente inscritos en `tournament.id`.
   - Para cada `player` en `sourceTeam.players`:
     - Si `existingTournamentDocs.contains(player.normalizedDocumentId)` o ya fue agregado en esta iteración -> incrementar `skippedConflictingPlayersCount` y omitir.
     - Si la lista acumulada alcanza `tournament.rules.maxPlayersPerTeam` -> incrementar `skippedConflictingPlayersCount` y omitir.
     - En caso contrario, agregar copia con nuevo `id` e `isEligible: false`.
4. **Asignación Automática de Grupo (`FR-007`)**:
   - Si `tournament.format == TournamentFormat.mixedGroupsAndKnockout`:
     - Obtener grupos válidos con `StandingsCalculatorService.buildValidGroupNames(tournament.rules.groupStageConfig.groupCount)`.
     - Contar participantes actuales usando `StandingsCalculatorService.resolveEffectiveGroupName(...)` y seleccionar el primer grupo con conteo mínimo.
