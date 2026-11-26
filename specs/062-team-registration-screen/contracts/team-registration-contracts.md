# Contratos de Interfaz (Phase 1): Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Funcionalidad**: `specs/062-team-registration-screen`  
**Fecha**: 2026-11-26

## 1. Contrato de Persistencia Remota (`HybridTeamsRepository` ↔ `vifutboldev.teams`)

- **Upsert en `vifutboldev.teams`**:
  - Campos existentes: `id`, `coach_id`, `name`, `normalized_name`, `short_code`, `crest_shape`, `primary_color_hex`, `secondary_color_hex`, `updated_at`.
  - Nuevos campos:
    - `'delegate_name'`: `team.delegateName?.trim().isEmpty == true ? null : team.delegateName?.trim()`
    - `'founded_date'`: `YYYY-MM-DD` cuando `team.foundedDate != null`, `null` en caso contrario.
- **Select / Hidratación**:
  - Todas las consultas a `teams` (catálogo global y enrolamientos `tournament_teams(..., teams(...))`) seleccionan `delegate_name` y `founded_date` y los hidratan en `TournamentTeam` y `TeamDirectoryItem`.
- **Offline-First**:
  - `LocalTeamsRepository` (Hive) persiste inmediatamente `delegateName`, `foundedDate`, `primaryColorHex` y `secondaryColorHex`; `HybridTeamsRepository` sincroniza a Supabase o encola la operación pendiente si no hay red.

## 2. Contrato de Aplicación (`TeamsController` & `ManageTeamsEligibilityUseCase`)

- **`TeamsController.createTeam`**:
  ```dart
  Future<bool> createTeam({
    required String name,
    required String shortCode,
    String? delegateName,
    DateTime? foundedDate,
    int primaryColorHex = 0xFF00E676,
    int secondaryColorHex = 0xFF0A0E17,
    ChampionshipTournament? tournament,
    String coachId = 'coach-seed-1',
    UserRole actorRole = UserRole.coach,
  })
  ```
- **`ManageTeamsEligibilityUseCase.registerOrUpdateTeam`**:
  - Valida rol autorizado, estado de torneo (si aplica), `name` (≥ 3 chars, único normalizado), `shortCode` (2–4 chars), `foundedDate` (si no es nula, no posterior a hoy) y `primaryColorHex != secondaryColorHex`.
  - Recorta `delegateName` si viene presente.

## 3. Contrato de Rutas (`AppRouter`)

| Ruta | Pantalla | Puntos de Entrada |
|------|----------|-------------------|
| `/teams/create` | `CreateTeamScreen` | Botón "Crear equipo" en `CoachPanelContent` y botón/FAB "Crear equipo" en `TeamsDirectoryScreen`. |

## 4. Contrato de UI y Claves de Widget (`CreateTeamScreen` y `TeamInfoTabView`)

- **`CreateTeamScreen`**:
  - Contenedor principal: `Key('create_team_screen')`
  - Tarjeta de vista previa en vivo: `Key('create_team_identity_preview')`
  - Campos: `Key('create_team_name_input')`, `Key('create_team_short_code_input')`, `Key('create_team_delegate_input')`, `Key('create_team_founded_date_field')`, `Key('create_team_tournament_dropdown')`
  - Selectores de color: `Key('create_team_primary_color_<hex>')`, `Key('create_team_secondary_color_<hex>')`
  - Botón guardar: `Key('create_team_submit_button')` (con estado de carga `single-flight`)
- **`TeamInfoTabView`**:
  - Fila delegado: `Key('team_info_delegate_row')`
  - Fila fecha de creación: `Key('team_info_founded_date_row')`
  - Muestras de colores existentes: `Key('team_primary_color_swatch')`, `Key('team_secondary_color_swatch')`
