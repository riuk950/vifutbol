# Data Model: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Feature**: `specs/039-players-directory-cloud-sync`  
**Status**: Completed  
**Date**: 2026-11-13  

---

## 1. Domain Entities & Presentation Projections

### `RegisteredPlayer` (Domain Entity)
Representa a un futbolista inscrito en un equipo dentro de una competición.

| Campo | Tipo | Requerido | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `String` (UUID v4) | Sí | Identificador único RFC4122 del futbolista |
| `tournamentTeamId` | `String` (UUID v4) | Sí | Clave foránea al registro de inscripción del equipo |
| `tournamentId` | `String` (UUID v4) | Sí | Clave foránea al torneo o competición |
| `fullName` | `String` | Sí | Nombre completo (mínimo 3 caracteres) |
| `documentId` | `String` | Sí | Documento de identidad oficial |
| `shirtNumber` | `int` | Sí | Número de dorsal reglamentario (1 a 99) |
| `position` | `PlayerPosition` | Sí | `goalkeeper`, `defender`, `midfielder`, `forward` |
| `isEligible` | `bool` | Sí | Habilitación administrativa para jugar |

### `PlayerDirectoryItem` (Presentation Projection)
Proyección aplanada optimizada para la visualización en el directorio y modales de rendimiento.

```dart
class PlayerDirectoryItem {
  final RegisteredPlayer player;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final String tournamentId;
  final String tournamentName;

  const PlayerDirectoryItem({
    required this.player,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.tournamentId,
    required this.tournamentName,
  });

  PlayerPerformanceProfile toPerformanceProfile() { ... }
}
```

---

## 2. Application State Model

### `PlayersDirectoryState` (Refactored)
Estado inmutable de la pantalla de directorio de jugadores (sin variables de torneo).

```dart
class PlayersDirectoryState {
  final List<PlayerDirectoryItem> allPlayers;
  final String searchQuery;
  final UiViewState<List<PlayerDirectoryItem>> viewState;

  const PlayersDirectoryState({
    required this.allPlayers,
    required this.searchQuery,
    required this.viewState,
  });

  /// Lista filtrada basada exclusivamente en la consulta de búsqueda multi-campo.
  List<PlayerDirectoryItem> get filteredPlayers {
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isEmpty) return allPlayers;

    return allPlayers.where((item) {
      final p = item.player;
      return matchesSearchQuery(p.fullName, trimmedQuery) ||
          p.shirtNumber.toString() == trimmedQuery ||
          matchesSearchQuery(item.teamName, trimmedQuery) ||
          matchesSearchQuery(item.teamShortCode, trimmedQuery) ||
          matchesSearchQuery(p.position.name, trimmedQuery) ||
          matchesPositionSpanish(p.position, trimmedQuery);
    }).toList();
  }
}
```

---

## 3. Remote Database Schema (`vifutboldev.players`)

Esquema PostgreSQL en Supabase DEV (`oracle-free-tier-docker`):

```sql
CREATE TABLE IF NOT EXISTS vifutboldev.players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  user_account_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  full_name text NOT NULL CHECK (char_length(trim(full_name)) >= 3),
  document_id text NOT NULL CHECK (char_length(trim(document_id)) >= 5),
  normalized_document_id text NOT NULL,
  shirt_number integer NOT NULL CHECK (shirt_number BETWEEN 1 AND 99),
  position text NOT NULL
    CHECK (position IN ('goalkeeper', 'defender', 'midfielder', 'forward')),
  is_eligible boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (tournament_team_id, shirt_number),
  UNIQUE (tournament_id, normalized_document_id)
);
```

### Relaciones Relacionales utilizadas en la Consulta
- `players.tournament_team_id` → `tournament_teams.id`
- `tournament_teams.team_id` → `teams.id` (`name`, `short_code`)
- `players.tournament_id` → `tournaments.id` (`name`)

---

## 4. Local Persistence Model (Hive)

- **Caja de Almacenamiento**: `vifutbol_dev_teams_box` gestionada por `LocalTeamsRepository`.
- **Estructura almacenada**: Lista de `TournamentTeam` con su nómina interna `players: List<RegisteredPlayer>`.
- **Estrategia de hidratación**: Toda consulta remota a `loadAllPlayers()` o `loadTeams()` en `HybridTeamsRepository` actualiza la caja local en Hive, permitiendo que `LocalTeamsRepository.loadAllPlayers()` recupere la nómina completa aun sin conexión a internet.
