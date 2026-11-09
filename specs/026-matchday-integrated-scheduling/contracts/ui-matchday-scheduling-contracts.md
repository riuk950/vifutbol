# UI & Application Contracts: Programación Integral de Partido en la Jornada (HU 15.3)

**Feature**: `026-matchday-integrated-scheduling`  
**Date**: 2026-11-09

---

## 1. Widget Key Contracts

| Componente / Elemento | Widget Key | Ubicación | Comportamiento Esperado |
|-----------------------|------------|-----------|-------------------------|
| Lista de Jornadas | `Key('competition_detail_fixture_list')` | `CompetitionFixtureTabView` | Contenedor desplazable con las jornadas de la competición. |
| Encabezado de Jornada | `Key('fixture_round_header_${roundNumber}')` | `CompetitionFixtureTabView` | Encabezado de cada jornada con nombre y conteo de partidos. |
| Tarjeta de Partido en Jornada | `Key('fixture_match_item_${match.id}')` | `CompetitionFixtureTabView` | Al tocar: si `UserRole.organizer` + torneo editable + partido en `pendingSchedule`/`scheduled` → abre `ScheduleMatchDialog`; en caso contrario → abre hoja modal informativa de solo lectura. |
| Pie de Logística en Tarjeta | `Key('fixture_match_logistics_${match.id}')` | `CompetitionFixtureTabView` | Muestra `"Por programar"` cuando está `pendingSchedule`, o el resumen `"dd/MM/yyyy • Sede - Cancha • Árbitro"` cuando tiene programación asignada. |
| Selector de Fecha | `Key('pick_match_date_field')` | `ScheduleMatchDialog` | Abre `DatePicker` acotado a `[tournament.startDate, tournament.endDate]` con margen seguro. |
| Selector de Hora | `Key('pick_match_time_field')` | `ScheduleMatchDialog` | Abre `TimePicker`. |
| Desplegable de Sede | `Key('select_venue_dropdown')` | `ScheduleMatchDialog` | Lista las sedes elegibles (`SportsVenue`) y al cambiar actualiza el desplegable de canchas. |
| Desplegable de Cancha | `Key('select_pitch_dropdown')` | `ScheduleMatchDialog` | Lista las canchas (`VenuePitch`) pertenecientes a la sede seleccionada. |
| Desplegable de Árbitro | `Key('select_referee_dropdown')` | `ScheduleMatchDialog` | Lista los árbitros oficiales activos (`MatchReferee`). |
| Alerta de Colisión / Error | `Key('schedule_error_message')` | `ScheduleMatchDialog` | Muestra el mensaje de colisión de cancha, árbitro o equipo sin cerrar el diálogo. |
| Botón Guardar Programación | `Key('confirm_schedule_match_button')` | `ScheduleMatchDialog` | Valida colisiones globales, persiste la logística, actualiza el estado a `scheduled`, refresca el feed diario y cierra el diálogo. |
| Botón Cancelar | `Key('cancel_schedule_match_button')` | `ScheduleMatchDialog` | Cierra `ScheduleMatchDialog` sin guardar cambios. |

---

## 2. Repository & Use Case Contracts

### `TournamentMatchesRepository.loadAllMatches()`
```dart
/// Loads all persisted matches across all tournaments in the catalog.
Future<List<ChampionshipMatch>> loadAllMatches();
```

### `FixtureSchedulingUseCase.scheduleMatch(...)`
```dart
Future<ChampionshipMatch> scheduleMatch({
  required String matchId,
  required ChampionshipTournament tournament,
  required DateTime scheduledStartTime,
  required SportsVenue venue,
  required VenuePitch pitch,
  required MatchReferee referee,
  required UserRole userRole,
});
```
- **Precondiciones**:
  - `RolePermissionMatrix.hasCapability(userRole, RoleCapability.manageTournaments)` debe ser `true`.
  - `tournament.status != TournamentStatus.finished`.
- **Postcondiciones**:
  - Valida colisiones contra todos los partidos programados en `matchesRepository.loadAllMatches()` (excluyendo `matchId`).
  - Asigna `status: MatchStatus.scheduled`, `scheduledStartTime`, `scheduledEndTime`, `venueId: venue.id`, `pitchId: pitch.id`, `pitchName: pitch.name.contains(venue.name) ? pitch.name : '${venue.name} - ${pitch.name}'`, `refereeId: referee.id`, `refereeName: referee.fullName`.
  - Persiste mediante `matchesRepository.saveMatch(updatedMatch)`.

---

## 3. Localization Keys (`lib/l10n/app_es.arb`)

| Clave `l10n` | Valor en Español | Uso |
|--------------|------------------|-----|
| `fixtureMatchPendingLogistics` | `"Por programar — Toca para asignar fecha, cancha y árbitro"` (para Organizador) / `"Por programar"` | Pie de tarjeta en la lista de jornadas cuando el partido está en `pendingSchedule`. |
| `matchdayScheduleSavedSuccess` | `"Programación del partido guardada exitosamente."` | `SnackBar` de confirmación al guardar la programación desde la jornada. |
