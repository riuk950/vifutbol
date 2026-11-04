# Contract: Digital Match Report & Offline Event Sync (HU 7.1)

**Date**: 2026-11-04  
**Layer Boundaries**: `domain` ↔ `application` ↔ `infrastructure` ↔ `presentation`

## 1. Repository Contract (`lib/domain/repositories/match_reports_repository.dart`)

```dart
abstract class MatchReportsRepository {
  /// Loads the digital match report for [matchId], or creates an initial report
  /// linked to the given [ChampionshipMatch] if none exists yet.
  Future<DigitalMatchReport> loadOrCreateReport(ChampionshipMatch match);

  /// Saves the updated [DigitalMatchReport] to local storage immediately.
  /// If [enqueuedEvent] is provided while offline, appends it to the pending sync queue.
  Future<DigitalMatchReport> saveReport(
    DigitalMatchReport report, {
    List<MatchEvent> newlyCreatedEvents = const [],
  });

  /// Returns all events currently waiting in the offline sync queue for [matchId].
  Future<List<MatchEvent>> loadPendingSyncQueue(String matchId);

  /// Idempotently synchronizes all queued offline events for [matchId] by `event.id`,
  /// marking all report events as `isSynced: true` and clearing the pending queue.
  Future<DigitalMatchReport> synchronizePendingEvents(String matchId);
}
```

---

## 2. Use Case Contract (`lib/application/use_cases/manage_digital_match_report_use_case.dart`)

### `transitionMatchPeriod`
- **Inputs**: `UserRole activeRole`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `MatchPeriod targetPeriod`, `bool isOffline`, `DateTime now`.
- **Preconditions**:
  1. `RolePermissionMatrix.hasCapability(activeRole, RoleCapability.recordMatchEvents)` o `RoleCapability.manageTournaments`.
  2. `!currentReport.isClosed` (lanza `MatchReportValidationFailure(MatchReportErrorCode.reportAlreadyClosed)` si ya está cerrada).
- **Behavior**:
  - Si el periodo anterior estaba corriendo (`firstHalf` o `secondHalf`), acumula `now.difference(periodStartedAt).inSeconds` en `elapsedSecondsBeforeCurrentPeriod`.
  - Si `targetPeriod.isRunning`, fija `periodStartedAt = now` y actualiza `ChampionshipMatch.status` a `MatchStatus.inProgress`.
  - Registra un `MatchEvent` de tipo `MatchEventType.periodTransition` con `isSynced: !isOffline`.
  - Persiste en `MatchReportsRepository` y `TournamentMatchesRepository`.

### `recordGoalEvent`
- **Inputs**: `UserRole activeRole`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `String teamId`, `RegisteredPlayer scorer`, `RegisteredPlayer? assistant`, `int minute`, `bool isOffline`, `DateTime now`.
- **Validations**:
  1. Permiso `recordMatchEvents` / `manageTournaments`.
  2. `!currentReport.isClosed` y `currentReport.currentPeriod.isOpenForEvents`.
  3. `!currentReport.isPlayerExpelled(scorer.id)` (lanza `playerAlreadyExpelled` si el anotador está expulsado).
  4. Si `assistant != null`: `assistant.id != scorer.id` y `!currentReport.isPlayerExpelled(assistant.id)`.
- **Postconditions**:
  - Crea `MatchEvent` con `type: MatchEventType.goal`, `isSynced: !isOffline`.
  - Recalcula determinísticamente `homeScore` y `awayScore`.
  - Actualiza el marcador en `ChampionshipMatch` y persiste inmediatamente.

### `recordDisciplinaryCard`
- **Inputs**: `UserRole activeRole`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `String teamId`, `RegisteredPlayer player`, `bool isDirectRed`, `int minute`, `bool isOffline`, `DateTime now`.
- **Validations**:
  1. Permiso `recordMatchEvents` / `manageTournaments`.
  2. `!currentReport.isClosed` y `currentReport.currentPeriod.isOpenForEvents`.
  3. `!currentReport.isPlayerExpelled(player.id)` (un jugador ya expulsado no puede recibir nuevas tarjetas en cancha).
- **Double Yellow Rule (Regla de Doble Amarilla)**:
  - Si `!isDirectRed` y `currentReport.yellowCardCountForPlayer(player.id) == 1`:
    1. Crea el segundo evento `MatchEventType.yellowCard` (`id: 'evt-yc2-...'`).
    2. Crea automáticamente el evento consecutivo `MatchEventType.secondYellowRedCard` en el mismo `minute`, con `linkedParentEventId` apuntando a la segunda amarilla.
    3. El jugador queda inmediatamente incluido en `currentReport.expelledPlayerIds`.

### `recordSubstitution`
- **Inputs**: `UserRole activeRole`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `String teamId`, `RegisteredPlayer playerOut`, `RegisteredPlayer playerIn`, `int minute`, `bool isOffline`, `DateTime now`.
- **Validations**:
  - Permiso arbitral, acta abierta, `playerOut.id != playerIn.id`, y ninguno de los dos jugadores está expulsado (`!isPlayerExpelled`).

### `removeMatchEvent` (Corrección en vivo antes del cierre)
- **Inputs**: `UserRole activeRole`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `String eventId`.
- **Validations**:
  - Solo permitido mientras `!currentReport.isClosed`. Si el acta ya fue cerrada (`MatchPeriod.closed`), lanza `MatchReportValidationFailure(MatchReportErrorCode.reportAlreadyClosed)`.
- **Behavior**:
  - Elimina el evento con `id == eventId` y cualquier evento automático vinculado (`linkedParentEventId == eventId`, como la roja automática por doble amarilla), recalculando el marcador (`homeScore`, `awayScore`) y las expulsiones activas.

### `closeOfficialMatchReport`
- **Inputs**: `UserRole activeRole`, ` String userId`, `ChampionshipMatch match`, `DigitalMatchReport currentReport`, `bool isOffline`, `DateTime now`.
- **Validations**:
  - `RolePermissionMatrix.hasCapability(activeRole, RoleCapability.closeMatchReport)` o `RoleCapability.manageTournaments`.
  - `!currentReport.isClosed`.
- **Postconditions**:
  1. Cambia `currentPeriod` a `MatchPeriod.closed`, fija `closedAt = now`, `closedByUserId = userId` y detiene el cronómetro.
  2. Actualiza `ChampionshipMatch` a `status: MatchStatus.completed` con `homeScore` y `awayScore` definitivos.
  3. Actualiza las métricas acumuladas en `LineupsTrackingRepository` para los jugadores participantes (goles, asistencias, tarjetas amarillas, tarjetas rojas y fechas de suspensión si hubo expulsión o si alcanzó `yellowCardsSuspensionThreshold`).

---

## 3. UI & Navigation Contract (`lib/presentation/matches/digital_match_report_screen.dart`)

- **Route**: `/matches/report` registrada en `AppRouter` recibiendo el `ChampionshipMatch` (o su `matchId`).
- **Entry Point en `MatchCard`**:
  - Si `activeRole` tiene `RoleCapability.recordMatchEvents` y el partido está `scheduled` o `inProgress`: botón primario `"Acta Arbitral"` / `"Dirigir Partido"`.
  - Para cualquier rol cuando el partido está `scheduled`, `inProgress` o `completed`: acción `"Ver Acta"` para consultar marcador y línea de tiempo en vivo.
- **Visual Design (`DESIGN.md`)**:
  - Cabecera de marcador en vivo con números tabulares (`KickPulseTypography.displayHero` / `tabularFigures`) y badge pulsante `"EN JUEGO"` en color `KickPulseColors.accentLive` (`#EF4444`).
  - Cronómetro exacto `MM:SS` calculado por diferencia de *timestamps* y selector de transición de periodo (`"Iniciar Partido"`, `"Fin 1er Tiempo"`, `"Iniciar 2do Tiempo"`, `"Cerrar Acta Oficial"`).
  - Banner reactivo de modo sin conexión: `"Modo sin conexión: cambios guardados en el dispositivo"` con conmutador de conectividad para pruebas y contingencia en cancha, y sincronización automática al volver en línea.
  - Botones de acción rápida con altura mínima de `48px` (`>= 44x44px`) y bloqueo *single-flight*: `"Registrar Gol"`, `"Tarjeta Amarilla"`, `"Tarjeta Roja"`, `"Sustitución"`.
  - Línea de tiempo cronológica inversa con tarjetas de incidencia de `16px`, señal semántica `"Accent Live"` (`#EF4444`) en eventos de gol y roja, dorsal del jugador (`#5`), nombre del anotador/asistente y botón de anular evento visible únicamente mientras el acta esté abierta.
