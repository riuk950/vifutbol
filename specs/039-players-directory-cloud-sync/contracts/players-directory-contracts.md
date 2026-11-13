# Contracts: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Feature**: `specs/039-players-directory-cloud-sync`  
**Status**: Completed  
**Date**: 2026-11-13  

---

## 1. Domain & Repository Contracts

### `TeamsRepository`
Ampliación de la interfaz en `lib/domain/repositories/teams_repository.dart`:

```dart
abstract interface class TeamsRepository {
  Future<List<TournamentTeam>> loadTeams();
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId);
  Future<void> saveTeam(TournamentTeam team);
  Future<void> saveTeamsForTournament(String tournamentId, List<TournamentTeam> teams);
  Future<void> deleteTeam(String teamId);

  /// Carga la nómina completa de futbolistas inscritos ordenados alfabéticamente A-Z.
  Future<List<PlayerDirectoryItem>> loadAllPlayers();
}
```

---

## 2. Infrastructure Contracts

### `TeamsRemoteDataSource`
Ampliación en `lib/infrastructure/repositories/hybrid_teams_repository.dart`:

```dart
abstract interface class TeamsRemoteDataSource {
  Future<List<TournamentTeam>> fetchAll();
  Future<List<TournamentTeam>> fetchForTournament(String tournamentId);
  Future<TournamentTeam> upsert(TournamentTeam team);
  Future<void> replaceForTournament(String tournamentId, List<TournamentTeam> teams);
  Future<void> deleteById(String teamId);

  /// Consulta directamente la tabla `players` con joins a `tournament_teams`, `teams` y `tournaments`.
  Future<List<PlayerDirectoryItem>> fetchAllPlayers();
}
```

### `HybridTeamsRepository`
Comportamiento de `loadAllPlayers()`:
```dart
@override
Future<List<PlayerDirectoryItem>> loadAllPlayers() async {
  if (networkStatus == NetworkConnectionStatus.connected) {
    try {
      final remotePlayers = await remoteDataSource.fetchAllPlayers();
      // Hidratar caché local y retornar ordenados
      return remotePlayers;
    } catch (_) {
      // Degradar silenciosamente a la caché local de Hive
    }
  }
  return localRepository.loadAllPlayers();
}
```

---

## 3. Application & Controller Contracts

### `PlayersDirectoryController`
Métodos públicos en `lib/application/controllers/players_directory_controller.dart`:

```dart
class PlayersDirectoryController extends StateNotifier<PlayersDirectoryState> {
  PlayersDirectoryController({
    required this.teamsRepository,
    List<PlayerDirectoryItem> initialPlayers = const [],
  });

  final TeamsRepository teamsRepository;

  /// Inicializa o recarga la nómina de futbolistas desde el repositorio (cloud o local).
  Future<void> loadPlayers();

  /// Acción invocada por el gesto Pull-to-Refresh.
  /// Si ocurre un fallo de red, preserva el estado actual y emite una notificación.
  Future<bool> refreshPlayers();

  /// Actualiza el query de búsqueda reactiva.
  void updateSearchQuery(String query);

  /// Limpia la búsqueda.
  void clearSearchQuery();
}
```

---

## 4. Presentation & UI Contracts

### `PlayersDirectoryScreen`
Contratos visuales y claves de widgets:

- **Buscador superior**: `Key('players_search_bar')` (`KickPulseSearchBar`).
- **Gesto de recarga**: `RefreshIndicator` envolviendo el listado o estado vacío.
- **Lista de futbolistas**: `ListView.builder` con `PlayerCard` o `KickPulseCard`.
- **Selector de torneos**: **ELIMINADO** (`Key('players_tournament_selector')` y `ChoiceChip`s no deben existir).
- **Acción contextual en AppBar**: `Key('register_player_from_directory_button')` (conservada para rol coach/organizer).
