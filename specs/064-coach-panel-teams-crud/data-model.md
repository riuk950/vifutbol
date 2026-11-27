# Data Model: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

## Entities & State

### 1. `TournamentTeam` (entidad existente reutilizada)

Representa tanto equipos autónomos (`tournamentId == ''`) como inscritos (`tournamentId.isNotEmpty`):
- `id`: `String` (UUID de inscripción o maestro)
- `tournamentId`: `String` (`''` si es autónomo)
- `coachId`: `String?` (ID del entrenador propietario; debe coincidir con `authState.session?.user.id`)
- `name`: `String` (mínimo 3 caracteres)
- `normalizedName`: `String` (unicidad excluyendo `team.id` en edición)
- `shortCode`: `String` (2–4 caracteres en mayúsculas)
- `delegateName`: `String?`
- `foundedDate`: `DateTime?`
- `primaryColorHex`: `int`
- `secondaryColorHex`: `int` (distinto de `primaryColorHex`)
- `crestUrl`: `String?` (URL remota o ruta local pendiente de sincronización)
- `crestShape`: `TeamCrestShape` (`circle`)
- `players`: `List<TeamPlayer>`

### 2. `TeamsCatalogState` (estado existente en `TeamsController`)

- `teams`: `List<TournamentTeam>` — lista reactiva de equipos cargados.
- `selectedTeamId`: `String?` — identificador del equipo activo seleccionado en el Panel Técnico.
- `isSaving`: `bool` — bandera `single-flight` compartida para creación, edición y eliminación.
- `lastFailure`: `AppFailure?` — último error de validación o permiso para retroalimentación en español.

## Validation & State Transitions

1. **Filtrado de propiedad (`coachTeamsProvider`)**:
   - Con sesión autenticada (`user.id` no vacío): `team.coachId == user.id`.
   - Sin sesión autenticada (entorno de pruebas/invitado): `team.coachId == 'coach-seed-1'`.

2. **Edición de equipo (`registerOrUpdateTeam`)**:
   - Exige `actorRole == UserRole.coach || actorRole == UserRole.organizer`.
   - Si `actorRole == UserRole.coach` y `team.coachId != actorUserId` → `UnauthorizedRoleFailure`.
   - Unicidad de `normalizedName` excluyendo `team.id`.
   - Selector de torneo bloqueado si `existingTournament != null && existingTournament.status != TournamentStatus.openRegistration`.

3. **Eliminación de equipo (`deleteCoachTeam`)**:
   - Exige propiedad (`actorRole == UserRole.organizer || team.coachId == actorUserId`).
   - Bloquea si `tournament != null && tournament.status != TournamentStatus.openRegistration`.
   - Bloquea si existe algún partido donde `homeTeamId == team.id || awayTeamId == team.id`.
   - Elimina de `LocalTeamsRepository` inmediatamente y de `PostgrestTeamsRemoteDataSource` (o encola `SyncOutboxOperation.delete` si offline).
   - Ajusta `selectedTeamId` al primer equipo restante del entrenador (o `null` si queda vacío).
