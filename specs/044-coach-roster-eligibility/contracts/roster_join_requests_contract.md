# Contracts: Planilla del Entrenador, Solicitudes de Jugador y Habilitación (HU 20.1)

**Feature**: `044-coach-roster-eligibility`

## 1. Repository Contract (`TeamJoinRequestsRepository`)

Ubicación: `lib/domain/repositories/team_join_requests_repository.dart`

- `Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({String query = ''})`
  - Consulta usuarios con rol `player` disponibles en la plataforma.
- `Future<List<TeamJoinRequest>> loadRequestsForTeam(String teamId)`
  - Carga solicitudes enviadas por el equipo (pendientes e historial reciente).
- `Future<List<TeamJoinRequest>> loadRequestsForCurrentPlayer()`
  - Carga solicitudes recibidas por el usuario autenticado con rol `player`.
- `Future<TeamJoinRequest> sendJoinRequest({required TournamentTeam team, required AvailablePlayerCandidate candidate, required int shirtNumber, required PlayerPosition position})`
  - Valida dorsal no repetido (en plantilla o solicitudes pendientes) y jugador no duplicado; persiste localmente y en `vifutboldev.team_join_requests`.
- `Future<TeamJoinRequest> respondToJoinRequest({required String requestId, required bool accept})`
  - Ejecuta `respond_team_join_request` en Supabase (o actualización local offline encolada) retornando la solicitud actualizada.
- `Future<void> cancelJoinRequest(String requestId)`
  - Marca la solicitud pendiente como `cancelled`.

## 2. Supabase RPC Contracts (`vifutboldev`)

### 2.1 `vifutboldev.search_registered_players(p_query text DEFAULT '')`
- **Security**: `SECURITY DEFINER`, `GRANT EXECUTE TO authenticated`.
- **Auth Check**: Requiere que el invocador tenga rol `'coach'` (`vifutboldev.current_user_has_role(ARRAY['coach'])`).
- **Returns**: Tabla `(user_account_id uuid, full_name text, document_id text, normalized_document_id text)` de cuentas donde `'player' = ANY(authorized_roles) OR active_role = 'player'`, filtradas por nombre o documento (case/accent-insensitive).

### 2.2 `vifutboldev.respond_team_join_request(p_request_id uuid, p_accept boolean)`
- **Security**: `SECURITY DEFINER`, `GRANT EXECUTE TO authenticated`.
- **Auth Check**: Verifica que `player_account_id = vifutboldev.current_user_account_id()` y que `status = 'pending'`.
- **Behavior**:
  - Si `p_accept = false`: actualiza `status = 'rejected'`.
  - Si `p_accept = true`:
    - Verifica que el dorsal `shirt_number` no esté ocupado en `vifutboldev.players` para ese `tournament_team_id` (o club).
    - Inserta o actualiza el registro del jugador en `vifutboldev.players` con `tournament_team_id`, `tournament_id`, `user_account_id`, `shirt_number`, `position`, `is_eligible = false`.
    - Actualiza `status = 'accepted'`.
  - Retorna JSONB con la fila actualizada de `team_join_requests`.

## 3. UI & Navigation Contracts

1. **`CoachPanelContent` → `TeamRosterDetailScreen`**:
   - Key botón: `coach_manage_roster_button` (existente).
   - Al pulsar: selecciona `team.id` en `teamsControllerProvider` y navega a `/tournaments/teams/detail`.
2. **`TeamRosterDetailScreen`**:
   - Botón **"Agregar Jugador"** (`enroll_player_button`): visible únicamente si `activeRole == UserRole.coach`. Abre `InvitePlayerToTeamModal` (buscador de jugadores `player` + dorsal + posición, cero creación manual).
   - Sección **"Solicitudes Enviadas"** (visible para `coach` cuando hay solicitudes `pending` para ese equipo, con opción de cancelar).
   - Indicador de cuota: `"No elegible / Faltan jugadores"` con progreso `X/11 jugadores mínimos` cuando `players.length < 11`.
   - Botón **"Habilitar para Competiciones"** (`approve_team_eligibility_button`): visible para `coach` (y `organizer`), habilitado únicamente si `players.length >= 11` y `<= maxPlayersPerTeam` y el equipo aún no está en estado `eligible`.
3. **`ProfileTabView` → `PlayerTeamRequestsScreen`**:
   - Entrada **"Solicitudes de Equipos"** (`profile_team_requests_tile`) en `ProfileTabView` cuando el usuario tiene rol `player`.
   - En `PlayerTeamRequestsScreen`: tarjetas por cada solicitud `pending` con botones **"Aceptar"** (`accept_join_request_<id>`) y **"Rechazar"** (`reject_join_request_<id>`).
