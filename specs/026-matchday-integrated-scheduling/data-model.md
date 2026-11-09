# Phase 1 Data Model: Programación Integral de Partido al Seleccionarlo en la Jornada (HU 15.3)

**Feature**: `026-matchday-integrated-scheduling`  
**Date**: 2026-11-09

---

## 1. Domain Entities Involved

### `ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)
Representa un partido individual dentro de una jornada del campeonato:
- `id` (`String`): Identificador único inmutable del partido.
- `tournamentId` (`String`): Identificador de la competición a la que pertenece.
- `roundNumber` (`int`) & `roundName` (`String`): Número y etiqueta de la jornada (ej. `"Jornada 1"`).
- `homeTeamId` (`String`) & `awayTeamId` (`String`): Identificadores de los equipos local y visitante.
- `status` (`MatchStatus`): Estado del encuentro (`pendingSchedule`, `scheduled`, `inProgress`, `completed`, `cancelled`).
- `scheduledStartTime` (`DateTime?`): Fecha y hora de inicio programadas.
- `scheduledEndTime` (`DateTime?`): Fecha y hora de finalización estimadas (`scheduledStartTime + (halfDurationMinutes * 2 + 15) min`).
- `venueId` (`String?`): Identificador de la sede deportiva asignada.
- `pitchId` (`String?`): Identificador de la cancha específica dentro de la sede.
- `pitchName` (`String?`): Nombre descriptivo de la sede y cancha asignadas (formateado como `"${venue.name} - ${pitch.name}"` cuando `pitch.name` no contiene ya el nombre de la sede).
- `refereeId` (`String?`): Identificador del árbitro oficial designado.
- `refereeName` (`String?`): Nombre completo del árbitro oficial designado.

### `SportsVenue` & `VenuePitch` (`lib/domain/entities/sports_venue.dart`, `lib/domain/entities/venue_pitch.dart`)
- `SportsVenue`: Sede deportiva con `id`, `name`, `isEligibleForFixtures` y lista `pitches` (`List<VenuePitch>`).
- `VenuePitch`: Cancha específica perteneciente a una sede con `id`, `venueId`, `name` y `surfaceType`.

### `MatchReferee` (`lib/domain/entities/match_referee.dart`)
- Árbitro oficial con `id`, `fullName`, `certificationLevel` e `isActive`.

---

## 2. State Transitions & Validation Rules

### Match Scheduling State Transition
```text
[pendingSchedule] ──(scheduleMatch: Date + Time + Venue + Pitch + Referee)──► [scheduled]
[scheduled]       ──(scheduleMatch: Re-scheduling with valid non-colliding window)──► [scheduled]
```
- **Restricción de estado de partido**: Solo los partidos en estado `pendingSchedule` o `scheduled` dentro de un torneo editable (`openRegistration` o `inProgress`) pueden abrir `ScheduleMatchDialog` al ser seleccionados por el `Organizador`. Los partidos en `inProgress`, `completed` o `cancelled` son de solo lectura logística.

### Global Collision Detection Rules (`FixtureSchedulingUseCase.detectCollisions`)
Al evaluar un candidato `(candidateMatchId, startTime, endTime, pitchId, refereeId, homeTeamId, awayTeamId)` frente a **todos** los partidos programados en el catálogo (`matchesRepository.loadAllMatches()`):
1. **Exclusión propia**: Si `existingMatch.id == candidateMatchId`, se omite para permitir reprogramar el mismo partido sin conflicto consigo mismo.
2. **Solo partidos programados con ventana horaria**: Si `!existingMatch.isScheduled` o no hay solapamiento (`!existingMatch.overlapsWith(startTime, endTime)`), no existe colisión.
3. **Colisión de Cancha (`pitchConflict`)**: Si `existingMatch.pitchId == pitchId`, lanza `FixtureScheduleValidationFailure(FixtureScheduleErrorCode.pitchScheduleCollision, ...)`.
4. **Colisión de Árbitro (`refereeConflict`)**: Si `existingMatch.refereeId == refereeId`, lanza `FixtureScheduleValidationFailure(FixtureScheduleErrorCode.refereeScheduleCollision, ...)`.
5. **Colisión de Equipo (`teamConflict`)**: Si alguno de los equipos (`homeTeamId` o `awayTeamId`) coincide con los equipos de `existingMatch`, lanza `FixtureScheduleValidationFailure(FixtureScheduleErrorCode.teamScheduleCollision, ...)`.
