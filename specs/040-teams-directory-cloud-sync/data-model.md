# Data Model: Directorio de Equipos — Carga Dinámica desde Supabase Cloud (HU 19.2)

**Feature**: `040-teams-directory-cloud-sync`  
**Date**: 2026-11-13

## Domain Entities

### `TeamDirectoryItem` (`lib/domain/entities/team_directory_item.dart`)

Entidad de dominio pura que representa un club único en el catálogo global del Directorio de Equipos.

| Field | Type | Constraints / Notes |
|-------|------|---------------------|
| `id` | `String` | UUID único del club (`teams.id`) |
| `name` | `String` | Nombre oficial del club (`teams.name`) |
| `shortCode` | `String` | Sigla corta de 2-3 caracteres (`teams.short_code`) |
| `crestShape` | `CrestShape` | Forma del escudo (`teams.crest_shape`), default `shield` |
| `primaryColorHex` | `String` | Color primario hexadecimal (`teams.primary_color_hex`) |
| `secondaryColorHex` | `String` | Color secundario hexadecimal (`teams.secondary_color_hex`) |
| `categoryLabel` | `String?` | Categoría/torneo si tiene 1 inscripción; `null` o indicador multi-torneo manejado en UI/l10n según `tournamentCount` |
| `tournamentCount` | `int` | Número de inscripciones activas en `tournament_teams` (>= 0) |
| `playerCount` | `int` | Cantidad total consolidada de jugadores registrados (>= 0) |
| `eligibilityStatus` | `TeamEligibilityStatus` | Estado consolidado (`eligible` si al menos una inscripción es elegible, o `pendingVerification`) |
| `coachId` | `String?` | Identificador del entrenador propietario (`teams.coach_id`) |
| `updatedAt` | `DateTime` | Marca temporal de última actualización |

#### Category Display Rules (Presentation / l10n)
- Si `tournamentCount == 0`: mostrar `l10n.teamsDirectoryNoTournamentAssigned` (`"Sin torneo asignado"`).
- Si `tournamentCount == 1` y `categoryLabel != null`: mostrar `categoryLabel` (ej. `"Libre"` o nombre del torneo).
- Si `tournamentCount > 1`: mostrar `l10n.teamsDirectoryMultipleTournaments` (`"Múltiples torneos"`).

## State Model

### `TeamsDirectoryState` (`lib/application/controllers/teams_directory_controller.dart`)

Se eliminan los campos obsoletos `availableTournaments`, `selectedTournamentId` y el parámetro `clearTournamentFilter`.

| Field | Type | Description |
|-------|------|-------------|
| `allTeams` | `List<TeamDirectoryItem>` | Lista completa de clubes únicos ordenados A-Z por `name` |
| `searchQuery` | `String` | Consulta actual del buscador |
| `viewState` | `UiViewState<List<TeamDirectoryItem>>` | Estado reactivo (`UiLoadingState`, `UiContentState`, `UiEmptyState`, `UiErrorState`) |

#### Derived Getter: `filteredTeams`
1. Toma `allTeams` (ya ordenado A-Z).
2. Si `searchQuery.trim().isEmpty`, retorna `allTeams`.
3. Si hay texto, filtra con `matchesSearchQuery` (insensible a tildes y mayúsculas) contra:
   - `team.name`
   - `team.shortCode`
   - `team.categoryLabel ?? ''`

## Remote Schema Mapping (`vifutboldev.teams`)

Consulta PostgREST en `PostgrestTeamsRemoteDataSource.fetchAllTeams()`:
```sql
teams.select(
  'id, coach_id, name, short_code, crest_shape, primary_color_hex, secondary_color_hex, updated_at, '
  'tournament_teams(id, tournament_id, eligibility_status, tournaments(name, category), players(id))'
).order('name', ascending: true)
```

### Local Cache Mapping (Hive)
- Se persiste la lista consolidada de `TeamDirectoryItem` en almacenamiento local Hive (`LocalTeamsRepository`) bajo clave dedicada para garantizar disponibilidad offline inmediata incluso de clubes sin torneo.
- Ante fallo de red en `HybridTeamsRepository.loadAllTeams()`, se lee automáticamente desde `LocalTeamsRepository.loadAllTeams()`.
