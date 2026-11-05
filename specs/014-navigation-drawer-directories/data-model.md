# Data Model: Navigation Drawer y Páginas de Directorio con Buscador

**Feature**: `014-navigation-drawer-directories`
**Date**: 2026-11-05

## Domain Entities & View States

### 1. `DirectoryItem<T>` & Directorios Proyectados

Los directorios operan sobre entidades del dominio existentes (`ChampionshipTournament`, `TournamentTeam`, `RegisteredPlayer`, `SportsVenue`) y las proyectan en estados de consulta ligeros y reactivos.

```
┌────────────────────────────────┐
│   AppNavigationDrawer          │
│   - activeUserAccount          │
│   - activeUserRole             │
│   - navigationDestinations     │
└───────────────┬────────────────┘
                │
                ├──> CompetitionsDirectoryState
                │    ├── allTournaments: List<ChampionshipTournament>
                │    ├── searchQuery: String
                │    └── filteredTournaments: List<ChampionshipTournament>
                │
                ├──> TeamsDirectoryState
                │    ├── allTeams: List<TournamentTeam>
                │    ├── availableTournaments: List<ChampionshipTournament>
                │    ├── selectedTournamentId: String? (null = "Todos")
                │    ├── searchQuery: String
                │    └── filteredTeams: List<TournamentTeam>
                │
                └──> PlayersDirectoryState
                     ├── allPlayers: List<RegisteredPlayer>
                     ├── availableTournaments: List<ChampionshipTournament>
                     ├── selectedTournamentId: String? (null = "Todos")
                     ├── searchQuery: String
                     └── filteredPlayers: List<RegisteredPlayer>
```

---

### 2. `CompetitionsDirectoryState`

Estado inmutable administrado por `CompetitionsDirectoryController`.

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `tournaments` | `List<ChampionshipTournament>` | Catálogo completo de competiciones obtenido de la base de datos local. |
| `searchQuery` | `String` | Texto de búsqueda ingresado por el usuario (normalizado). |
| `viewState` | `UiViewState` | Estado de carga (`loading`, `content`, `empty`, `error`). |
| `filteredTournaments` | `List<ChampionshipTournament>` (getter) | Lista calculada de competiciones cuyo nombre o categoría contiene el término de búsqueda normalizado. |

**Reglas de Filtrado**:
- Si `searchQuery` está vacío: retorna todas las competiciones ordenadas por fecha de inicio más reciente.
- Si `searchQuery` tiene contenido: compara `normalize(tournament.name)` y `normalize(tournament.category)` con `normalize(searchQuery)`.

---

### 3. `TeamsDirectoryState`

Estado inmutable administrado por `TeamsDirectoryController`.

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `allTeams` | `List<TournamentTeam>` | Lista de todos los equipos registrados en el sistema. |
| `availableTournaments` | `List<ChampionshipTournament>` | Lista de torneos para poblar el selector horizontal de filtros. |
| `selectedTournamentId` | `String?` | Identificador del torneo filtrado (`null` representa "Todos los torneos"). |
| `searchQuery` | `String` | Término de búsqueda en minúsculas y sin acentos. |
| `viewState` | `UiViewState` | Estado de la vista (`loading`, `content`, `empty`, `error`). |
| `filteredTeams` | `List<TournamentTeam>` (getter) | Equipos que coinciden simultáneamente con el torneo seleccionado y el término de búsqueda. |

**Reglas de Filtrado**:
- Filtro de Torneo: Si `selectedTournamentId != null`, solo considera equipos donde `team.tournamentId == selectedTournamentId`.
- Filtro de Texto: Compara `normalize(team.name)`, `normalize(team.shortCode)` y `normalize(team.category ?? '')` contra `normalize(searchQuery)`.

---

### 4. `PlayersDirectoryState`

Estado inmutable administrado por `PlayersDirectoryController`.

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `allPlayers` | `List<RegisteredPlayer>` | Lista de todos los jugadores registrados en las plantillas. |
| `availableTournaments` | `List<ChampionshipTournament>` | Torneos para el selector horizontal de filtros. |
| `selectedTournamentId` | `String?` | Filtro de competición (`null` = todos los torneos). |
| `searchQuery` | `String` | Término de búsqueda normalizado. |
| `viewState` | `UiViewState` | Estado de visualización. |
| `filteredPlayers` | `List<RegisteredPlayer>` (getter) | Jugadores coincidentes con los filtros activos. |

**Reglas de Filtrado**:
- Filtro de Torneo: Si `selectedTournamentId != null`, solo considera jugadores donde `player.tournamentId == selectedTournamentId`.
- Filtro de Texto: Coincide si `normalize(player.fullName)`, `player.jerseyNumber.toString()`, `normalize(player.primaryPosition.name)` o `normalize(player.teamName)` contienen `normalize(searchQuery)`.

---

### 5. `AppDrawerDestination`

Enumeración de destinos de navegación expuestos por el menú lateral:

```dart
enum AppDrawerDestination {
  competitions,
  teams,
  players,
  venues,
}
```

Mapeo de Rutas:
- `competitions` → `/competitions`
- `teams` → `/teams`
- `players` → `/players`
- `venues` → `/venues`
