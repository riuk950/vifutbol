# Contracts: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

## 1. Provider Contract (`coachTeamsProvider`)

- **Input**: `teamsControllerProvider`, `authControllerProvider`
- **Behavior**:
  - Si `authState.session?.user.id` está presente y no está vacío: retorna únicamente `teams` donde `team.coachId == currentCoachId`.
  - Si no hay sesión activa: retorna `teams` donde `team.coachId == 'coach-seed-1'`.

## 2. Use Case Contract (`ManageTeamsEligibilityUseCase`)

### `registerOrUpdateTeam` (existente, reforzado para edición)
- Verifica permiso de rol y propiedad cuando es actualización de un equipo existente.
- Excluye `team.id` en la validación de nombre duplicado (`normalizedName`).
- Si `tournament` está presente al editar un equipo, mantiene validación de `openRegistration` únicamente si se intenta cambiar/asignar torneo; si el equipo ya estaba inscrito en un torneo `inProgress`/`finished` y se editan solo sus datos de club (sin cambiar `tournamentId`), permite actualizar los datos institucionales en `teams`.

### `deleteCoachTeam` (nuevo / extendido)
- **Parameters**:
  - `required TournamentTeam team`
  - `ChampionshipTournament? tournament`
  - `required String actorUserId`
  - `required UserRole actorRole`
- **Validation Rules**:
  1. Rol autorizado (`coach` o `organizer`) y propiedad (`actorRole == UserRole.organizer || team.coachId == actorUserId`), o lanza `UnauthorizedRoleFailure`.
  2. Si `tournament != null && tournament.status != TournamentStatus.openRegistration`, lanza `TeamEligibilityValidationFailure` (`teamInActiveOrFinishedTournament`).
  3. Si `matchesRepository` tiene partidos donde `homeTeamId == team.id || awayTeamId == team.id`, lanza `TeamEligibilityValidationFailure` (`teamHasPlayedMatches` o código equivalente).
- **Execution**: Llama `_repository.deleteTeam(team.id)`.

## 3. Controller Contract (`TeamsController`)

### `updateTeam(...)` / `createTeam(...)`
- Protegido por `state.isSaving` (`single-flight`).
- Actualiza `teams` y mantiene `selectedTeamId` apuntando al equipo editado.

### `deleteCoachTeam(...)`
- Protegido por `state.isSaving` (`single-flight`).
- Ejecuta `manageTeamsEligibilityUseCase.deleteCoachTeam(...)`.
- Recarga `teams = await teamsRepository.loadTeams()` y ajusta `selectedTeamId` (al siguiente equipo del entrenador o `null`).
- Retorna `bool` (`true` si éxito, `false` guardando `lastFailure` si error).

## 4. UI Contracts

### `CoachPanelContent`
- Lista vertical/tarjetas de todos los equipos en `coachTeams` mostrando `KickPulseTeamCrest` circular, `name`, `shortCode`, `delegateName` (si existe), indicadores de colores distintivos y conteo de plantilla.
- Tarjeta activa resaltada visualmente; tocar una tarjeta llama `teamsControllerProvider.notifier.selectTeam(team.id)`.
- Cada tarjeta expone botones/acciones de **Editar** y **Eliminar** con área táctil ≥ 48×48 dp.
- Botón persistente para registrar un equipo adicional (`Navigator.pushNamed('/teams/create')`) tanto en estado vacío como cuando ya existen equipos.
- Al pulsar **Eliminar**, muestra `AlertDialog` en español con el nombre del equipo y advertencia de irreversibilidad, con botones **Cancelar** y **Eliminar**.

### `CreateTeamScreen`
- Acepta `TournamentTeam? initialTeam`.
- Título y botón principal dinámicos: crear vs editar (`Guardar cambios`).
- Precarga todos los campos y escudo existente (`_existingRemoteCrestUrl` / `_localCrestPath`).
- Selector de torneo deshabilitado en modo solo lectura si `initialTeam` pertenece a un torneo que no está en `openRegistration`.
