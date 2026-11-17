# Contracts: Carga y Selección del Catálogo Global en Competición (HU 18.5)

**Feature**: `043-competition-fab-catalog-enrollment`  
**Date**: 2026-11-17

## 1. Contrato de Datos Remotos: `PostgrestTeamsRemoteDataSource.fetchAll()`

### Consultas PostgREST (`vifutboldev`)
1. **Inscripciones existentes en torneos**:
   ```text
   FROM vifutboldev.tournament_teams
   SELECT *, teams(*, user_accounts(full_name)), tournaments(name, category), players(*)
   ORDER BY updated_at DESC
   ```
2. **Catálogo global maestro de clubes**:
   ```text
   FROM vifutboldev.teams
   SELECT *, user_accounts(full_name)
   ORDER BY updated_at DESC
   ```

### Regla de Fusión
- Cada fila de `tournament_teams` produce un `TournamentTeam` con su `tournamentId`, `players`, `categoryLabel` (de `tournaments.category` o `tournaments.name`) y `coachName` (de `teams.user_accounts.full_name`).
- Todo club en `vifutboldev.teams` que aún no posea ninguna fila en `tournament_teams` (y cuyo nombre normalizado no esté ya representado) se incluye como un `TournamentTeam` autónomo (`tournamentId: ''`, `players: const []`, `categoryLabel: null`, `coachName` resuelto si existe).
- Si la consulta secundaria o el join opcional de `user_accounts` no está disponible en un esquema legado, hace fallback seguro a la consulta base sin fallar.

---

## 2. Contrato de UI: `AddTeamsToCompetitionModal`

### Ciclo de Vida
- **`initState()`**: Invoca `Future.microtask(() => ref.read(teamsControllerProvider.notifier).loadTeams())` para asegurar que el catálogo global esté sincronizado al abrir el modal desde `CompetitionDetailFabMenu`.
- **Restricción RBAC de Creación**:
  - Cero botones o formularios de `"Crear Nuevo Equipo"` / `"Registrar Club"` en todo el árbol de widgets del modal.
- **Elementos por tarjeta de club (`add_teams_catalog_item_<id>`)**:
  - Escudo (`KickPulseTeamCrest`)
  - Nombre oficial (`team.name`)
  - Línea de metadatos: `${team.shortCode} · ${categoryLabel ?? l10n.addTeamsDefaultCategoryLabel} · ${l10n.addTeamsPlayersCountMeta(team.players.length)}`
  - Línea opcional de entrenador (solo cuando `team.coachName` no es nulo ni vacío): `l10n.addTeamsCoachMeta(team.coachName!)` (`"DT: <Nombre>"`)
  - Estado de inscripción:
    - Inscrito: `KickPulseBadge` verde `"Inscrito"` + botón deshabilitado.
    - No inscrito: botón activo `"Inscribir"`.
- **Estado vacío global (`add_teams_empty_catalog_state`)**:
  - Título: `l10n.addTeamsEmptyCatalogTitle`
  - Mensaje: `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."`
