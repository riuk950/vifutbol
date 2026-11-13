# Research & Decisions: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Feature**: `specs/039-players-directory-cloud-sync`  
**Status**: Completed  
**Date**: 2026-11-13  

---

## 1. Estrategia de Consulta y Acceso a `vifutboldev.players`

### Contexto
En la arquitectura de KickPulse / vifutbol, `RegisteredPlayer` es un agregado gobernado dentro de los equipos (`TournamentTeam`). La pantalla de Directorio de Jugadores (`PlayersDirectoryScreen`) presenta una lista agregada de todos los jugadores de todas las competiciones y equipos. La tabla remota en Supabase DEV es `vifutboldev.players` y cuenta con claves foráneas a `vifutboldev.tournament_teams(id)` y `vifutboldev.tournaments(id)`.

### Decisión
Extender `TeamsRepository` con el método `Future<List<PlayerDirectoryItem>> loadAllPlayers()`, implementándolo en:
1. `LocalTeamsRepository`: Itera los equipos en Hive, extrae los jugadores y los mapea a `PlayerDirectoryItem` ordenados alfabéticamente A-Z.
2. `HybridTeamsRepository`:
   - Con conexión a internet: Consulta Supabase PostgREST a `vifutboldev.players` con select relacional:
     `client.schema(schema).from('players').select('*, tournament_teams(id, tournament_id, team_id, teams(id, name, short_code)), tournaments(id, name)')`
     o reutiliza `fetchAll()` / `loadTeams()` si sincroniza en lote la jerarquía de equipos e hidrata la caché Hive de `LocalTeamsRepository`.
   - Sin conexión o ante falla de red: Degrada de forma transparente y silenciosa a la caché local de `LocalTeamsRepository.loadAllPlayers()`.

### Alternativas Consideradas
- **Crear un nuevo repositorio `PlayersRepository`**: Descartado para no fragmentar el dominio ni crear cajas de Hive redundantes para jugadores cuando ya están integrados en `teams_box`.
- **Delegar el mapeo al controlador**: Descartado para cumplir con la Constitución (Arquitectura Limpia); la lógica de hidratación y acceso a datos debe permanecer en la capa de infraestructura.

---

## 2. Refactorización de Estado y Controlador del Directorio

### Contexto
Actualmente, `PlayersDirectoryState` y `PlayersDirectoryController` mantienen `availableTournaments`, `selectedTournamentId` y `selectTournament()`. Al eliminarse la segmentación por torneos, estas propiedades se convierten en código muerto y generan dependencias reactivas innecesarias con `tournamentsControllerProvider`.

### Decisión
1. Refactorizar `PlayersDirectoryState` para contener exclusivamente:
   - `allPlayers`: `List<PlayerDirectoryItem>`
   - `searchQuery`: `String`
   - `viewState`: `UiViewState<List<PlayerDirectoryItem>>`
2. Refactorizar `PlayersDirectoryController` para:
   - Eliminar `selectedTournamentId`, `availableTournaments` y `selectTournament()`.
   - Mantener `updateSearchQuery(String query)` y `clearSearchQuery()`.
   - Añadir `loadPlayers()` y `refreshPlayers()` invocando directamente a `teamsRepository.loadAllPlayers()`.
   - Ordenar la nómina por defecto de forma alfabética ascendente (A-Z) por `fullName` insensible a mayúsculas y acentos.
3. Actualizar `playersDirectoryControllerProvider` en `lib/application/providers/directory_providers.dart` para inyectar directamente `teamsRepositoryProvider` sin requerir `tournamentsControllerProvider`.

### Alternativas Consideradas
- **Mantener los campos opcionales en el estado**: Descartado para evitar estados inconsistentes y mantener la base de código limpia.

---

## 3. Remoción de Componentes Visuales en `PlayersDirectoryScreen`

### Contexto
La pantalla contiene actualmente un `SingleChildScrollView` horizontal con `Key('players_tournament_selector')` y múltiples `ChoiceChip`s (`Key('players_tournament_chip_all')`, `Key('players_tournament_chip_<id>')`).

### Decisión
1. Remover completamente el widget `SingleChildScrollView` y todos los `ChoiceChip`s de torneo.
2. Mantener `KickPulseSearchBar` en la parte superior con margen optimizado.
3. Envolver el cuerpo de la lista en un `RefreshIndicator` conectado a `directoryController.refreshPlayers()`.
4. Ante falla de recarga por desconexión en Pull-to-Refresh:
   - Capturar el error en el controlador.
   - Emitir un `SnackBar` informativo no intrusivo (`l10n.networkErrorOfflineFallback` o mensaje en español correspondiente).
   - Mantener intacta la lista local previa en pantalla.

### Alternativas Consideradas
- **Ocultar los chips condicionalmente con un booleano**: Descartado; el criterio de aceptación exige la remoción definitiva del selector horizontal de torneos.

---

## 4. Normalización de Búsqueda y Debounce

### Contexto
La barra de búsqueda debe filtrar reactivamente por nombre, apellido, dorsal, nombre de equipo, código corto y posición del jugador.

### Decisión
1. Preservar la función existente `matchesSearchQuery` de `lib/application/utils/search_utils.dart` que realiza normalización Unicode sin distinguir tildes ni mayúsculas.
2. Mantener el debounce de 300 ms en la entrada del usuario antes de recalcular la lista filtrada.
3. Si la búsqueda no produce resultados, desplegar `KickPulseStateView.empty` indicando que no se encontraron jugadores coincidentes.
