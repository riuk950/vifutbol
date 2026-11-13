# Contracts: Directorio de Equipos (HU 19.2)

**Feature**: `040-teams-directory-cloud-sync`  
**Date**: 2026-11-13

## 1. Domain Repository Contract (`TeamsRepository`)

Archivo: `lib/domain/repositories/teams_repository.dart`

```dart
/// Loads all unique clubs for the global Teams Directory.
///
/// Online implementations fetch from `vifutboldev.teams`, hydrate the local
/// cache, and fall back to local cache when offline.
/// Results are sorted alphabetically (A-Z) by club name.
Future<List<TeamDirectoryItem>> loadAllTeams();
```

## 2. Remote Data Source Contract (`TeamsRemoteDataSource`)

Archivo: `lib/infrastructure/repositories/hybrid_teams_repository.dart`

```dart
/// Fetches all unique clubs from `vifutboldev.teams` with relational
/// tournament enrollments and player counts.
Future<List<TeamDirectoryItem>> fetchAllTeams();
```

### Expected Sync Behavior (`HybridTeamsRepository.loadAllTeams()`)
1. Intenta `await remoteDataSource.fetchAllTeams()`.
2. Si tiene éxito:
   - Ordena alfabéticamente A-Z por `name`.
   - Persiste en caché local mediante `localRepository.cacheDirectoryTeams(teams)`.
   - Retorna la lista actualizada.
3. Si lanza excepción (error de red, timeout o fallo remoto):
   - Lee y retorna `await localRepository.loadAllTeams()` ordenado A-Z.

## 3. Application Controller Contract (`TeamsDirectoryController`)

Archivo: `lib/application/controllers/teams_directory_controller.dart`

- Se elimina `selectTournamentFilter(String? tournamentId)`.
- Se mantienen `setSearchQuery(String query)` y `clearSearchQuery()`.
- Se agregan:
  - `Future<void> loadTeams()`: carga inicial desde `teamsRepository.loadAllTeams()` actualizando `viewState` (`UiLoadingState` → `UiContentState` / `UiEmptyState` / `UiErrorState`).
  - `Future<bool> refreshTeams()`: ejecuta recarga manual (Pull-to-Refresh). Retorna `true` si completó con éxito desde red/repositorio, o `false` si ocurrió fallo de red conservando los datos cacheados en pantalla.

## 4. Presentation UI Contract (`TeamsDirectoryScreen`)

Archivo: `lib/presentation/directories/teams_directory_screen.dart`

- **Removido**: `Key('teams_tournament_selector')`, `Key('teams_tournament_chip_all')`, `Key('teams_tournament_chip_<id>')` y todo `ChoiceChip`.
- **Preservado**:
  - `Key('teams_directory_screen')`
  - `Key('teams_search_bar')` (`KickPulseSearchBar` con debounce de 300 ms)
  - `Key('create_team_from_directory_button')` (visibilidad basada en rol `coach` / `organizer`)
  - `Key('team_directory_card_<id>')`
- **Agregado**:
  - `RefreshIndicator` envolviendo el listado de equipos y el estado vacío tras búsqueda, invocando `controller.refreshTeams()` y mostrando `SnackBar` con `l10n.teamsDirectoryOfflineRefreshWarning` cuando retorna `false`.
