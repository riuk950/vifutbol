# Interface & Storage Contracts: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Feature**: `007-fixture-generation-assignment`  
**Date**: 2026-11-04

## 1. Repository Contract (`lib/domain/repositories/tournament_matches_repository.dart`)

```dart
abstract class TournamentMatchesRepository {
  /// Loads all matches associated with a tournament.
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  );

  /// Saves or updates a single championship match.
  Future<ChampionshipMatch> saveMatch(
    ChampionshipMatch match,
  );

  /// Saves or updates a batch of championship matches (e.g. newly generated fixture).
  Future<List<ChampionshipMatch>> saveMatchesBatch(
    List<ChampionshipMatch> matches,
  );

  /// Loads the catalog of active official referees.
  Future<List<MatchReferee>> loadOfficialReferees();
}
```

### Storage Keys & Seed Data (`LocalTournamentMatchesRepository`)
- Matches storage key: `'vifutbol.matches.v1'`
- Referees storage key: `'vifutbol.referees.v1'`
- Seed data in `AppEnvironment.development`:
  - Árbitros Oficiales:
    - `ref-seed-1`: `"Nicolás Gallo"`, categoría `"FIFA"`, `isActive: true`
    - `ref-seed-2`: `"Wilmar Roldán"`, categoría `"FIFA"`, `isActive: true`
    - `ref-seed-3`: `"Andrés Rojas"`, categoría `"Nacional"`, `isActive: true`
  - Partidos Semilla iniciales vinculados al torneo por defecto (`'tourn-seed-torneo-relampago-2026'` / `'tourn-seed-copa-navidad-2026'`):
    - Permiten probar visualización de fixture en `MatchdayTabView` sin obligar a generar uno nuevo cada vez.

---

## 2. Use Case Contract (`lib/application/use_cases/fixture_scheduling_use_case.dart`)

```dart
abstract class FixtureSchedulingUseCase {
  /// Generates a complete official fixture (Round-Robin for League / Group phase or Knockout pairings for Cup)
  /// for the given tournament and registered eligible teams.
  /// Validates organizer capabilities, minimum eligible team count (>= 2), and blocks regeneration
  /// if any match in the tournament is already inProgress or completed.
  Future<List<ChampionshipMatch>> generateRoundRobinFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  });

  /// Schedules or reschedules a match by assigning date, time, pitch, and official referee.
  /// Evaluates pitch, referee, and team schedule overlaps within the calculated match duration window.
  Future<ChampionshipMatch> scheduleMatch({
    required String matchId,
    required ChampionshipTournament tournament,
    required DateTime scheduledStartTime,
    required SportsVenue venue,
    required VenuePitch pitch,
    required MatchReferee referee,
    required UserRole userRole,
  });

  /// Detects whether the candidate scheduling window collides with existing matches.
  ScheduleCollisionResult detectCollisions({
    required String candidateMatchId,
    required String tournamentId,
    required DateTime startTime,
    required DateTime endTime,
    required String pitchId,
    required String refereeId,
    required String homeTeamId,
    required String awayTeamId,
    required List<ChampionshipMatch> existingMatches,
  });
}
```

### Reglas de Negocio en Casos de Uso:
1. **Generación Determinista de Fixture**:
   - Requiere `userRole == UserRole.organizer` o `userRole == UserRole.admin` (`RoleCapability.manageTournaments`).
   - Requiere al menos 2 equipos con `eligibilityStatus == TeamEligibilityStatus.eligible`.
   - Si el número de equipos es impar, se inserta equipo `bye` para descanso por fecha.
   - Crea todos los emparejamientos con `status: MatchStatus.pendingSchedule`.
2. **Cálculo de Ventana de Partido**:
   - $T_{end} = T_{start} + (2 \times \text{halfDurationMinutes} + 15\text{ minutos descanso})$.
3. **Validación de Colisiones Logísticas**:
   - `pitchConflict`: Si otro partido programado en `pitchId` se traslapa en $[T_{start}, T_{end}]$.
   - `refereeConflict`: Si el árbitro `refereeId` ya tiene asignado otro partido en el mismo intervalo.
   - `teamConflict`: Si `homeTeamId` o `awayTeamId` juegan otro partido en el mismo intervalo.
   - Si hay conflicto, lanza `FixtureScheduleValidationFailure` detallando el tipo de colisión y el partido conflictivo.

---

## 3. UI Integration Contract (`MatchdayTabView`)

- **Ruta de Acceso**: Pestaña 1 de `AppShellScreen` (`/` con índice 0).
- **Controlador**: `MatchesCatalogController` gestionado con `StateNotifier<MatchesCatalogState>`.
- **Selector de Jornadas**: Chips horizontales `Jornada 1`, `Jornada 2`... con scroll horizontal y selección reactiva.
- **Filtros**: `ChoiceChip` para estados (`Todos`, `Pendientes`, `Programados`, `Finalizados`).
- **Modal de Programación**: `ScheduleMatchDialog` con selectores accesibles de fecha/hora, sede, cancha y árbitro oficial con detección inmediata de colisiones.
