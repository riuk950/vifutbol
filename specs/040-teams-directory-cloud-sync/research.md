# Research: Directorio de Equipos — Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.2)

**Feature**: `040-teams-directory-cloud-sync`  
**Date**: 2026-11-13

## Decisions & Findings

### 1. Consulta Remota en `vifutboldev.teams` con Consolidación de Inscripciones y Jugadores

- **Decision**: Implementar `TeamsRemoteDataSource.fetchAllTeams()` en `PostgrestTeamsRemoteDataSource` consultando directamente la tabla `vifutboldev.teams` con left join relacional hacia `tournament_teams(id, tournament_id, eligibility_status, tournaments(name, category), players(id))`.
- **Rationale**:
  - Hasta ahora, `PostgrestTeamsRemoteDataSource.fetchAll()` consultaba `tournament_teams`, lo cual omitía clubes creados por entrenadores sin inscripción activa en un torneo y duplicaba clubes inscritos en múltiples torneos.
  - Al consultar desde `teams` (tabla maestra de clubes), cada club aparece exactamente una vez (unicidad de equipos), se incluyen clubes recién creados sin torneo asignado, se calcula el total consolidado de jugadores (`players(id)`) entre sus inscripciones y se deriva la categoría/estado de torneo de forma determinista.
- **Alternatives considered**:
  - Modificar `fetchAll()` de `tournament_teams` para dedup: Descartado porque seguiría excluyendo clubes sin filas en `tournament_teams`.
  - Crear un nuevo repositorio `TeamsDirectoryRepository`: Descartado para mantener la cohesión del `TeamsRepository` existente y reutilizar la infraestructura de `HybridTeamsRepository` y `LocalTeamsRepository` (patrón validado en HU 19.1 con `loadAllPlayers()`).

### 2. Entidad de Dominio Pura `TeamDirectoryItem` y Contrato `loadAllTeams()`

- **Decision**: Crear `TeamDirectoryItem` en `lib/domain/entities/team_directory_item.dart` y agregar `Future<List<TeamDirectoryItem>> loadAllTeams()` en `TeamsRepository` (`lib/domain/repositories/teams_repository.dart`).
- **Rationale**:
  - Mantiene la capa de dominio 100% desacoplada de Supabase, Hive y Riverpod (Principio IV).
  - Permite representar el club global con `id`, `name`, `shortCode`, `crestShape`, `primaryColorHex`, `secondaryColorHex`, `categoryLabel`, `playerCount`, `tournamentCount`, `eligibilityStatus`, `coachId` y `updatedAt`, sin forzar un único `tournamentId` cuando un club tiene 0 o múltiples torneos.
- **Alternatives considered**:
  - Reutilizar `TournamentTeam` con `tournamentId: ''`: Descartado porque `TournamentTeam` modela una inscripción específica en un torneo (requiere `tournamentId`), lo que introduce ambigüedad semántica al consolidar múltiples torneos.

### 3. Estrategia Offline-First con Hive y Pull-to-Refresh

- **Decision**:
  - En `HybridTeamsRepository.loadAllTeams()`: intentar `remoteDataSource.fetchAllTeams()`. Si responde con éxito, hidratar la caché local de Hive (guardando los ítems serializados en una caja/clave dedicada de directorio de equipos dentro de `LocalStorage` o `LocalTeamsRepository` para preservar también clubes sin torneo) y devolver la lista ordenada A-Z. Si falla por red/excepción, retornar `localRepository.loadAllTeams()`.
  - En `TeamsDirectoryController`: agregar `loadTeams()` y `Future<bool> refreshTeams()`, retornando `true` si la sincronización remota tuvo éxito y `false` si se sirvió respaldo offline o falló la red.
  - En `TeamsDirectoryScreen`: envolver la lista (y el estado vacío tras búsqueda) en `RefreshIndicator` con `AlwaysScrollableScrollPhysics`, mostrando un `SnackBar` no intrusivo (`teamsDirectoryOfflineRefreshWarning`) cuando `refreshTeams()` retorne `false`.
- **Rationale**: Garantiza experiencia Offline-First real incluso para clubes recién creados sin torneo y mantiene paridad exacta de UX con `PlayersDirectoryScreen` (HU 19.1).
- **Alternatives considered**:
  - Mostrar `UiErrorState` pantalla completa ante fallo en Pull-to-Refresh: Descartado porque borraría los equipos cacheados ya visibles en pantalla.

### 4. Navegación Segura a `TeamDetailScreen` para Clubes sin Torneo

- **Decision**: Permitir que `TeamDetailScreen` (o `teamMatchSummaryProvider`) resuelva los datos básicos del club a partir del `TeamDirectoryItem` cuando el club aún no tenga inscripción en `tournament_teams`, mostrando su cabecera (escudo, nombre, sigla) y estados vacíos amigables en las pestañas de Partidos y Plantilla en lugar de la pantalla de error "Equipo no encontrado".
- **Rationale**: Cumple la clarificación Q3: todo club visible en el directorio debe poder abrirse al tocar su tarjeta sin mostrar error de entidad inexistente.
- **Alternatives considered**:
  - Bloquear el tap en clubes sin torneo: Descartado en la clarificación Q3 porque degrada la experiencia de exploración.

### 5. Ordenamiento Alfabético A-Z, Etiqueta de Categoría y Búsqueda Reactiva

- **Decision**:
  - Ordenamiento predeterminado A-Z por `name` (`a.name.toLowerCase().compareTo(b.name.toLowerCase())`).
  - Derivación determinista de `categoryLabel`:
    - 0 inscripciones: texto localizado `"Sin torneo asignado"`.
    - 1 inscripción: categoría o nombre del torneo asociado.
    - >1 inscripciones: texto localizado `"Múltiples torneos"` (o resumen).
  - Búsqueda multi-campo con `matchesSearchQuery` (insensible a mayúsculas y tildes) sobre `name`, `shortCode` y `categoryLabel`.
- **Rationale**: Mantiene consistencia con `search_utils.dart` y `KickPulseSearchBar` (debounce 300 ms).
