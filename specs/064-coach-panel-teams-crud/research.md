# Research: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

## 1. Filtrado estricto en `coachTeamsProvider`

- **Decision**: Actualizar `coachTeamsProvider` en `lib/application/providers/teams_providers.dart` para que cuando `authState.session?.user.id` sea no nulo y no vacío, filtre estrictamente por `team.coachId == currentCoachId` (sin incluir `'coach-seed-1'`). Solo cuando no haya sesión activa (`currentCoachId == null`), conservar compatibilidad con equipos semilla si existen tests sin sesión.
- **Rationale**: Actualmente `coachTeamsProvider` devuelve `true` para `team.coachId == 'coach-seed-1'` incluso cuando hay un entrenador autenticado real, provocando que un entrenador nuevo vea equipos semilla que no creó.
- **Alternatives considered**: Eliminar por completo `'coach-seed-1'` incluso sin sesión; descartado para no romper pruebas unitarias/widget existentes en modo invitado/seed cuando no hay usuario autenticado.

## 2. Selección del equipo activo en `CoachPanelContent`

- **Decision**: Usar `teamsState.selectedTeamId` (ya existente en `TeamsCatalogState` y `TeamsController.selectTeam(teamId)`) como fuente de verdad del equipo activo en `CoachPanelContent`, haciendo fallback automático a `coachTeams.first` cuando `selectedTeamId` sea nulo o ya no pertenezca a `coachTeams` (por ejemplo, tras eliminar el equipo activo).
- **Rationale**: `TeamsController` ya expone `selectedTeamId` y `selectTeam(id)`. Al reutilizarlo, la selección sobrevive reconstrucciones de pestaña y se sincroniza limpiamente tras crear, editar o eliminar un equipo.
- **Alternatives considered**: Estado local efímero dentro de `CoachPanelContent`; descartado porque se perdería al cambiar de pestaña en la shell principal.

## 3. Reutilización de `CreateTeamScreen` para modo edición

- **Decision**: Extender `CreateTeamScreen` con un parámetro opcional `TournamentTeam? initialTeam` (y registrar la ruta `/teams/edit` o pasar `initialTeam` por `RouteSettings.arguments` / `MaterialPageRoute`). Cuando `initialTeam != null`, precargar `name`, `shortCode`, `delegateName`, `foundedDate`, `primaryColorHex`, `secondaryColorHex`, `selectedTournamentId` y `crestUrl` (mostrando el escudo remoto o local existente).
- **Rationale**: Evita duplicar validaciones de formulario, paleta de colores, selector de fecha, picker circular de escudo y lógica offline-first ya probados en HU 27.2 y HU 27.3.
- **Alternatives considered**: Crear una pantalla `EditTeamScreen` separada; descartado por duplicación de lógica y mantenimiento doble.

## 4. Regla de bloqueo del selector de campeonato en edición (`FR-006`)

- **Decision**: En modo edición (`initialTeam != null`), si el equipo pertenece a un campeonato cuyo estado actual es `inProgress` o `finished` (o si el torneo no está en `openRegistration`), el selector de campeonato se muestra en modo solo lectura con el nombre del campeonato actual. Si el equipo es autónomo (`tournamentId.isEmpty`) o su campeonato actual está en `openRegistration`, el selector permanece editable.
- **Rationale**: Coincide con la aclaración confirmada por el usuario y con la política RLS de `vifutboldev.tournament_teams`, que solo permite a `coach` insertar/actualizar inscripciones mientras `tr.status = 'openRegistration'`.

## 5. Eliminación segura (`FR-008`, `FR-009`, `FR-010`) y soporte en `HybridTeamsRepository`

- **Decision**:
  1. Agregar un método `deleteCoachTeam({required TournamentTeam team, required ChampionshipTournament? tournament, required String actorUserId, required UserRole actorRole})` (o extender `deleteTeam` en `ManageTeamsEligibilityUseCase` y `TeamsController`) que valide:
     - Permiso de rol (`coach` o `organizer`) y propiedad (`actorRole == UserRole.organizer || team.coachId == actorUserId`).
     - Si `tournament != null && tournament.status != TournamentStatus.openRegistration`, lanzar `TeamEligibilityValidationFailure` con mensaje claro en español.
     - Si existen partidos en `matchesRepository` donde `m.homeTeamId == team.id || m.awayTeamId == team.id`, lanzar `TeamEligibilityValidationFailure` con mensaje claro en español.
  2. Proteger `TeamsController.deleteTeam(...)` con `state.isSaving` (`single-flight`) y actualizar `selectedTeamId` al eliminar.
  3. Actualizar `PostgrestTeamsRemoteDataSource.deleteById(String teamId)` en `hybrid_teams_repository.dart` para eliminar tanto la inscripción en `tournament_teams` (si existe) como el registro maestro en `teams` (cuando corresponda al `id` o no queden otras inscripciones asociadas), garantizando que equipos autónomos e inscritos se borren efectivamente en Supabase.
- **Rationale**: Actualmente `deleteById` solo ejecuta `.from('tournament_teams').delete().eq('id', safeTeamId)`, lo cual deja intacta la fila de `vifutboldev.teams` (y en equipos autónomos no borra nada en remoto).
- **Verification of RLS**: En `supabase/migrations/202611110003_enable_rls_and_policies.sql`, `teams_update_coach_or_organizer`, `teams_delete_coach_or_organizer`, `tournament_teams_update_organizer_or_coach` y `tournament_teams_delete_organizer_or_coach` ya permiten `UPDATE` y `DELETE` al entrenador propietario (`coach_id = current_user_account_id()`). No se requiere nueva migración SQL.
