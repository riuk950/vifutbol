# Phase 1 Data Model: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)

**Date**: 2026-11-04  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/spec.md)  
**Research**: [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/research.md)

## 1. Domain Enumerations (`lib/domain/entities/match_report_enums.dart`)

### `MatchPeriod`
Representa el periodo operativo del encuentro controlado por el árbitro:
- `notStarted`: Partido programado aún no iniciado (`"Por Iniciar"`).
- `firstHalf`: Primer tiempo en juego (`"Primer Tiempo"`).
- `halfTime`: Entretiempo / descanso reglamentario (`"Descanso"`).
- `secondHalf`: Segundo tiempo en juego (`"Segundo Tiempo"`).
- `fullTime`: Tiempo reglamentario concluido previo a la firma del acta (`"Tiempo Cumplido"`).
- `closed`: Acta oficial firmada y bloqueada de forma inmutable (`"Acta Cerrada"`).

Propiedades computadas:
- `bool get isRunning => this == MatchPeriod.firstHalf || this == MatchPeriod.secondHalf;`
- `bool get isOpenForEvents => this != MatchPeriod.notStarted && this != MatchPeriod.closed;`
- `bool get isClosed => this == MatchPeriod.closed;`

### `MatchEventType`
Tipos oficiales de incidencias registradas en la línea de tiempo del acta:
- `goal`: Gol oficial (con anotador obligatorio y asistente opcional).
- `yellowCard`: Tarjeta amarilla preventiva.
- `secondYellowRedCard`: Expulsión automática por acumulación de segunda tarjeta amarilla en el mismo encuentro.
- `directRedCard`: Expulsión por tarjeta roja directa.
- `substitution`: Cambio táctico (jugador que sale y jugador habilitado que ingresa).
- `periodTransition`: Hito de inicio o cierre de periodo (ej. inicio del partido, fin del primer tiempo, inicio del segundo tiempo, cierre del acta).

---

## 2. Domain Entities

### `MatchEvent` (`lib/domain/entities/match_event.dart`)
Representa una incidencia inmutable en la línea de tiempo oficial del partido.

| Field | Type | Required | Validation / Invariants |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Yes | No vacío. Identificador único determinista para garantizar idempotencia en sincronización offline/online. |
| `matchId` | `String` | Yes | No vacío. Referencia a `ChampionshipMatch.id`. |
| `type` | `MatchEventType` | Yes | Tipo de evento (`goal`, `yellowCard`, `secondYellowRedCard`, `directRedCard`, `substitution`, `periodTransition`). |
| `minute` | `int` | Yes | `minute >= 1 && minute <= 130`. Minuto oficial del encuentro. |
| `teamId` | `String` | Yes | Identificador del equipo (`homeTeamId` o `awayTeamId`, o `'match'` para transiciones de periodo). |
| `primaryPlayerId` | `String?` | No | Obligatorio en `goal` (anotador), `yellowCard`, `secondYellowRedCard`, `directRedCard` (sancionado) y `substitution` (jugador que sale). |
| `primaryPlayerName` | `String?` | No | Nombre completo del jugador principal para visualización inmediata. |
| `primaryPlayerShirtNumber` | `int?` | No | Dorsal del jugador principal (ej. `5`). |
| `secondaryPlayerId` | `String?` | No | Opcional en `goal` (jugador asistente, debe ser `!= primaryPlayerId`); obligatorio en `substitution` (jugador que ingresa, `!= primaryPlayerId`). |
| `secondaryPlayerName` | `String?` | No | Nombre del jugador secundario (asistente o jugador que entra). |
| `secondaryPlayerShirtNumber` | `int?` | No | Dorsal del jugador secundario. |
| `linkedParentEventId` | `String?` | No | En eventos `secondYellowRedCard`, referencia al `id` de la segunda amarilla que disparó la expulsión automática (para reversión atómica si se anula). |
| `description` | `String?` | No | Nota o etiqueta descriptiva opcional del evento. |
| `isSynced` | `bool` | Yes | `true` si ya fue sincronizado con el servidor central; `false` si fue guardado en cola offline. |
| `createdAt` | `DateTime` | Yes | Marca de tiempo UTC de creación del registro. |

---

### `DigitalMatchReport` (`lib/domain/entities/digital_match_report.dart`)
Agregado raíz que consolida el estado en tiempo real, el cronómetro basado en marcas de tiempo, el marcador y la línea de tiempo del encuentro.

| Field | Type | Required | Validation / Invariants |
| :--- | :--- | :--- | :--- |
| `matchId` | `String` | Yes | No vacío. Clave primaria 1:1 con `ChampionshipMatch.id`. |
| `tournamentId` | `String` | Yes | No vacío. Referencia a `ChampionshipTournament.id`. |
| `homeTeamId` | `String` | Yes | No vacío. |
| `awayTeamId` | `String` | Yes | No vacío (`!= homeTeamId`). |
| `homeScore` | `int` | Yes | `>= 0`. Calculado determinísticamente como el conteo de eventos `MatchEventType.goal` donde `teamId == homeTeamId`. |
| `awayScore` | `int` | Yes | `>= 0`. Calculado determinísticamente como el conteo de eventos `MatchEventType.goal` donde `teamId == awayTeamId`. |
| `currentPeriod` | `MatchPeriod` | Yes | Estado del periodo actual (por defecto `MatchPeriod.notStarted`). |
| `periodStartedAt` | `DateTime?` | No | Marca de tiempo UTC en que inició el periodo en curso (`firstHalf` o `secondHalf`). `null` cuando el reloj está pausado (`notStarted`, `halfTime`, `fullTime`, `closed`). |
| `elapsedSecondsBeforeCurrentPeriod` | `int` | Yes | `>= 0`. Segundos acumulados antes del inicio del segmento activo actual. |
| `events` | `List<MatchEvent>` | Yes | Lista cronológica de incidencias del encuentro. |
| `closedAt` | `DateTime?` | No | Marca de tiempo UTC en que se firmó y cerró el acta oficial. |
| `closedByUserId` | `String?` | No | Identificador del `Árbitro` u `Organizador` que cerró el acta. |
| `updatedAt` | `DateTime` | Yes | Última actualización del acta. |

#### Propiedades y Métodos Computados de `DigitalMatchReport`:
- `bool get isClosed => currentPeriod == MatchPeriod.closed || closedAt != null;`
- `int totalElapsedSecondsAt(DateTime now)`:
  - Si `currentPeriod.isRunning && periodStartedAt != null`, retorna `elapsedSecondsBeforeCurrentPeriod + max(0, now.difference(periodStartedAt!).inSeconds)`.
  - En caso contrario, retorna `elapsedSecondsBeforeCurrentPeriod`.
- `int currentMatchMinuteAt(DateTime now)`:
  - Retorna `((totalElapsedSecondsAt(now) ~/ 60) + 1).clamp(1, 130)`.
- `int yellowCardCountForPlayer(String playerId)`:
  - Cuenta cuántos eventos `MatchEventType.yellowCard` tiene `primaryPlayerId == playerId`.
- `Set<String> get expelledPlayerIds`:
  - Conjunto de `primaryPlayerId` presentes en eventos `MatchEventType.directRedCard` o `MatchEventType.secondYellowRedCard`.
- `bool isPlayerExpelled(String playerId) => expelledPlayerIds.contains(playerId);`
- `int get pendingSyncCount => events.where((e) => !e.isSynced).length;`

---

### Extensión de `ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)
Se añaden dos campos opcionales retrocompatibles (`homeScore` y `awayScore`, por defecto `null` cuando está `pendingSchedule` o `scheduled`, y enteros `>= 0` cuando está `inProgress` o `completed`) para que `MatchCard` en `MatchdayTabView` muestre el marcador en vivo y el resultado final con tipografía tabular.

---

### `DigitalMatchReportState` (`lib/domain/entities/digital_match_report_state.dart`)
Estado inmutable gestionado por `DigitalMatchReportController`:
- `match`: `ChampionshipMatch?`
- `report`: `DigitalMatchReport?`
- `homeTeam`: `TournamentTeam?`
- `awayTeam`: `TournamentTeam?`
- `homeEligiblePlayers`: `List<RegisteredPlayer>` (jugadores convocados en HU 5.2 o respaldo de plantilla habilitada en HU 5.1)
- `awayEligiblePlayers`: `List<RegisteredPlayer>`
- `isOfflineMode`: `bool`
- `pendingSyncEventsCount`: `int`
- `isLoading`: `bool`
- `isSubmitting`: `bool` (bloqueo *single-flight* contra pulsaciones dobles)
- `errorMessage`: `String?`
- `lastActionFeedback`: `String?`

---

## 3. Domain Failures (`lib/domain/failures/app_failure.dart`)

Se añade `MatchReportErrorCode` y `MatchReportValidationFailure extends AppFailure`:
- `unauthorizedRole`: Solo el `Árbitro` asignado o el `Organizador` pueden controlar el partido y modificar el acta.
- `reportAlreadyClosed`: El acta oficial ya fue cerrada (`Finalizado`) y es inmutable.
- `matchNotInProgress`: El partido debe estar `"En Juego"` para registrar goles, tarjetas o sustituciones.
- `invalidMinute`: El minuto indicado no es válido (`1..130`).
- `playerAlreadyExpelled`: El jugador seleccionado ya fue expulsado en este partido y no puede registrar nuevos goles, asistencias, tarjetas ni sustituciones.
- `invalidAssistantPlayer`: El jugador asistente no puede ser el mismo jugador anotador ni pertenecer al equipo contrario.
- `invalidSubstitutionPlayers`: El jugador que sale y el que entra deben ser distintos y estar habilitados.
