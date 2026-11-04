# Data Model: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Feature**: `007-fixture-generation-assignment`  
**Date**: 2026-11-04

## 1. Enumerations (`lib/domain/entities/match_enums.dart`)

### `MatchStatus`
Estado operativo del partido:
- `pendingSchedule`: `"Pendiente de Programación"` (emparejamiento creado por fixture pero sin fecha/cancha asignada)
- `scheduled`: `"Programado"` (fecha, hora, cancha y árbitro oficialmente asignados)
- `inProgress`: `"En Juego"` (partido en disputa)
- `completed`: `"Finalizado"` (acta deportiva cerrada)
- `cancelled`: `"Cancelado"`

### `ScheduleCollisionType`
Tipo de colisión o conflicto de horario detectado:
- `pitchConflict`: Cancha ocupada por otro encuentro en el mismo intervalo
- `refereeConflict`: Árbitro designado en otro partido simultáneo
- `teamConflict`: Uno de los equipos tiene otro partido programado en el mismo horario

---

## 2. Entities

### `ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)
Representa un partido programado o disputado dentro de un campeonato.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Non-empty | Identificador único del partido |
| `tournamentId` | `String` | Non-empty | Identificador del campeonato al que pertenece |
| `roundNumber` | `int` | `>= 1` | Número de jornada o ronda |
| `roundName` | `String` | Non-empty | Etiqueta de la ronda (p. ej. `"Jornada 1"`, `"Cuartos de Final"`) |
| `homeTeamId` | `String` | Non-empty | Identificador del equipo local |
| `awayTeamId` | `String` | Non-empty, != `homeTeamId` | Identificador del equipo visitante |
| `scheduledStartTime` | `DateTime?` | Nullable | Fecha y hora oficial de inicio del partido |
| `scheduledEndTime` | `DateTime?` | Nullable | Fecha y hora calculada de finalización estimada |
| `venueId` | `String?` | Nullable | Sede deportiva asignada |
| `pitchId` | `String?` | Nullable | Cancha específica dentro de la sede |
| `pitchName` | `String?` | Nullable | Nombre visible de la cancha |
| `refereeId` | `String?` | Nullable | Árbitro oficial designado |
| `refereeName` | `String?` | Nullable | Nombre visible del árbitro |
| `status` | `MatchStatus` | Enum | Estado actual del partido |
| `updatedAt` | `DateTime` | Non-null | Marca temporal de última modificación |

**Computed Properties**:
- `bool get isScheduled => status == MatchStatus.scheduled && scheduledStartTime != null;`
- `bool overlapsWith(DateTime otherStart, DateTime otherEnd)`: Comprueba si el intervalo $[scheduledStartTime, scheduledEndTime]$ se traslapa con $[otherStart, otherEnd]$.

---

### `MatchReferee` (`lib/domain/entities/match_referee.dart`)
Representa un árbitro oficial habilitado para dirigir encuentros.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Non-empty | Identificador único del árbitro |
| `fullName` | `String` | `>= 3` chars | Nombre completo del árbitro |
| `certificationLevel` | `String` | Non-empty | Nivel de certificación (p. ej. `"FIFA"`, `"Nacional"`, `"Regional"`) |
| `isActive` | `bool` | Default `true` | Estado activo para asignación de partidos |

---

### `MatchesCatalogState` (`lib/domain/entities/matches_catalog_state.dart`)
Estado inmutable para la gestión de partidos y fixture:
- `matches`: `List<ChampionshipMatch>`
- `referees`: `List<MatchReferee>`
- `selectedRound`: `int` (jornada activa seleccionada en la vista)
- `statusFilter`: `MatchStatus?` (filtro opcional por estado)
- `teamFilter`: `String?` (filtro opcional por equipo)
- `isLoading`: `bool`
- `isSaving`: `bool`
- `errorMessage`: `String?`

---

## 3. Domain Failures (`lib/domain/failures/app_failure.dart`)

Se extienden los códigos de error con `FixtureScheduleErrorCode` y `FixtureScheduleValidationFailure`:
- `unauthorizedRole`: Usuario sin permiso para generar fixture o programar partidos.
- `insufficientTeams`: El campeonato cuenta con menos de 2 equipos habilitados.
- `tournamentClosed`: El campeonato no permite modificaciones de fixture.
- `invalidScheduleTimes`: La hora de inicio es posterior a la hora de fin o en el pasado remoto.
- `pitchScheduleCollision`: La cancha seleccionada ya tiene un partido programado en ese intervalo.
- `refereeScheduleCollision`: El árbitro designado ya está asignado a otro partido en ese intervalo.
- `teamScheduleCollision`: Uno de los equipos ya disputa otro partido en ese horario.
