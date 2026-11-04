# Data Model: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Feature**: `006-coach-lineups-tracking`  
**Date**: 2026-11-04

## 1. Enumerations (`lib/domain/entities/lineup_enums.dart`)

### `PlayerConvocationRole`
Clasificación táctica de un jugador dentro de la convocatoria de un partido:
- `notConvoked`: `"No convocado"`
- `starter`: `"Titular"`
- `substitute`: `"Suplente"`

### `PlayerDisciplinaryState`
Estado disciplinario calculado para un jugador en el campeonato:
- `eligible`: `"Habilitado"` (`#10B981`)
- `warningAccumulation`: `"En capilla"` / alerta por acumulación de amarillas (`#F59E0B`)
- `suspended`: `"Suspendido"` (`#EF4444`)

### `ConvocationStatus`
Estado del registro de convocatoria para el partido:
- `draft`: Borrador en preparación por el `Entrenador` (conservado ante interrupciones móviles)
- `confirmed`: Alineación oficial confirmada y sincronizada con el acta digital del `Árbitro`

---

## 2. Entities

### `PlayerInternalTracking` (`lib/domain/entities/player_internal_tracking.dart`)
Métricas acumuladas de rendimiento y disciplina de un jugador dentro de un equipo/campeonato.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `playerId` | `String` | Non-empty | Identificador único del `RegisteredPlayer` |
| `teamId` | `String` | Non-empty | Identificador del `TournamentTeam` |
| `tournamentId` | `String` | Non-empty | Identificador del `ChampionshipTournament` |
| `matchesPlayed` | `int` | `>= 0` | Partidos disputados en el campeonato |
| `goals` | `int` | `>= 0` | Goles anotados |
| `assists` | `int` | `>= 0` | Asistencias registradas |
| `yellowCards` | `int` | `>= 0` | Tarjetas amarillas acumuladas |
| `redCards` | `int` | `>= 0` | Tarjetas rojas acumuladas |
| `pendingSuspensionMatches` | `int` | `>= 0` | Fechas de suspensión pendientes de cumplir |

**Computed Rules**:
- `effectiveSuspensionMatches(int yellowCardSuspensionLimit)`:
  - Si `pendingSuspensionMatches > 0`, retorna `pendingSuspensionMatches`.
  - Si `yellowCardSuspensionLimit > 0 && yellowCards >= yellowCardSuspensionLimit`, retorna `1`.
  - En caso contrario, retorna `0`.
- `isSuspended(int yellowCardSuspensionLimit)` → `effectiveSuspensionMatches(yellowCardSuspensionLimit) > 0`.
- `isAtYellowCardWarning(int yellowCardSuspensionLimit)` → `!isSuspended(yellowCardSuspensionLimit) && yellowCardSuspensionLimit > 1 && yellowCards == yellowCardSuspensionLimit - 1`.
- `disciplinaryState(int yellowCardSuspensionLimit)` → Retorna `PlayerDisciplinaryState.suspended`, `warningAccumulation` o `eligible`.

---

### `MatchLineupConvocation` (`lib/domain/entities/match_lineup_convocation.dart`)
Representa la convocatoria y alineación de un equipo para su próximo partido programado.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Non-empty | Identificador único de la convocatoria |
| `tournamentId` | `String` | Non-empty | Identificador del campeonato |
| `teamId` | `String` | Non-empty | Identificador del equipo |
| `matchLabel` | `String` | Non-empty | Etiqueta del próximo encuentro programado (p. ej. `"Jornada 1 · Próximo Partido Oficial"`) |
| `starterPlayerIds` | `List<String>` | Sin duplicados | Identificadores de jugadores titulares |
| `substitutePlayerIds` | `List<String>` | Disjunto de `starterPlayerIds` | Identificadores de jugadores suplentes habilitados |
| `captainPlayerId` | `String?` | Debe pertenecer a `starterPlayerIds` al confirmar | Identificador del capitán del equipo |
| `status` | `ConvocationStatus` | `draft` \| `confirmed` | Estado actual de la selección en edición |
| `confirmedStarterPlayerIds` | `List<String>` | Snapshot oficial | Última lista de titulares confirmada y visible para el `Árbitro` |
| `confirmedSubstitutePlayerIds` | `List<String>` | Snapshot oficial | Última lista de suplentes confirmada y visible para el `Árbitro` |
| `confirmedCaptainPlayerId` | `String?` | Snapshot oficial | Último capitán confirmado y visible para el `Árbitro` |
| `confirmedAt` | `DateTime?` | Nullable | Fecha/hora de la última confirmación oficial |
| `updatedAt` | `DateTime` | Non-null | Fecha/hora de la última modificación (borrador o confirmación) |

**Invariants**:
- Ningún `playerId` puede estar simultáneamente en `starterPlayerIds` y `substitutePlayerIds`.
- Si un jugador deja de ser titular y era `captainPlayerId`, `captainPlayerId` se limpia automáticamente (`null`) o se reasigna.
- `isSyncedWithRefereeReport` es `true` cuando `confirmedAt != null` y `confirmedStarterPlayerIds.isNotEmpty`.

---

### `TeamLineupsTrackingState` (`lib/domain/entities/team_lineups_tracking_state.dart`)
Estado inmutable del controlador de convocatorias y seguimiento interno:
- `convocationsByTeamId`: `Map<String, MatchLineupConvocation>`
- `trackingByPlayerId`: `Map<String, PlayerInternalTracking>`
- `isLoading`: `bool`
- `isSaving`: `bool`
- `errorMessage`: `String?`

---

## 3. Domain Validation Error Codes (`lib/domain/failures/app_failure.dart`)

Se añade `LineupConvocationErrorCode` y `LineupConvocationValidationFailure`:
- `unauthorizedRole`: El rol activo no posee `RoleCapability.manageLineups` ni `RoleCapability.manageTournaments`.
- `teamNotFound`: El equipo indicado no existe.
- `teamNotEligible`: El equipo aún no se encuentra en estado `"Habilitado"` (`TeamEligibilityStatus.eligible`).
- `suspendedPlayerSelected`: Se intentó seleccionar o confirmar a un jugador con sanción activa (`details`: nombre del jugador / fechas).
- `invalidStartersCount`: La cantidad de titulares seleccionados no coincide con `requiredStarters` (`details`: `"{selected}/{required}"`).
- `missingCaptain`: No se ha designado un capitán o el capitán designado no forma parte de los titulares.
- `invalidTrackingMetrics`: Valores negativos en estadísticas o sanciones del seguimiento interno.
