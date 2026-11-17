# Research: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico (HU 20.1)

**Feature**: `044-coach-roster-eligibility`  
**Date**: 2026-11-17  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/044-coach-roster-eligibility/spec.md)

## Research Decisions

### 1. Navegación desde `CoachPanelContent` a `TeamRosterDetailScreen`
- **Decision**: Actualizar `_onManageRosterAction` en `CoachPanelContent` para invocar `ref.read(teamsControllerProvider.notifier).selectTeam(team.id)` y navegar mediante `Navigator.of(context).pushNamed('/tournaments/teams/detail')`.
- **Rationale**: `TeamRosterDetailScreen` ya consume `teamsControllerProvider.selectTeam` vía `teamsState.selectedTeam`, y la ruta `/tournaments/teams/detail` ya está registrada en `AppRouter`. Reutiliza la arquitectura de navegación existente sin duplicar rutas ni argumentos frágiles.
- **Alternatives Considered**: Pasar el objeto `TournamentTeam` por `RouteSettings.arguments` — rechazado porque impediría la actualización reactiva automática en `TeamRosterDetailScreen` al aceptar solicitudes o habilitar el equipo.

### 2. Solicitud de Incorporación (`TeamJoinRequest`) vs Registro Manual Directo
- **Decision**: Crear el agregado `TeamJoinRequest` con tabla `vifutboldev.team_join_requests`, política RLS dedicada y función RPC atómica `respond_team_join_request(p_request_id uuid, p_accept boolean)`. Al pulsar "Agregar Jugador", el entrenador abre un buscador de usuarios con rol `player` (sin formulario manual de alta), selecciona dorsal (1-99) y posición, y envía una solicitud `pending`. Solo al aceptar el jugador desde su sección de **Perfil**, el sistema lo incorpora oficialmente a la plantilla.
- **Rationale**: Garantiza el consentimiento explícito del jugador (`UserRole.player`), evita duplicación de cuentas/documentos y asegura atomicidad transaccional al pasar de `pending` a `accepted` (validando dorsal único y documento único dentro del equipo/torneo).
- **Alternatives Considered**: Permitir actualización directa desde el cliente sobre `vifutboldev.players` por parte del jugador — rechazado porque abriría brechas RLS en `players` y no garantizaría la verificación atómica de dorsal disponible.

### 3. Descubrimiento de Usuarios con Rol `player` por Entrenadores
- **Decision**: Exponer una función RPC segura `vifutboldev.search_registered_players(p_query text DEFAULT '')` (`SECURITY DEFINER`) accesible únicamente para usuarios autenticados con rol `coach`, que retorne `user_account_id`, `full_name`, `document_id` (enmascarado o normalizado) de cuentas que tengan `'player'` en `authorized_roles` o `active_role = 'player'`, excluyendo datos sensibles privados (como email completo o tokens).
- **Rationale**: En `vifutboldev.user_accounts`, la política `user_accounts_select_own_or_organizer` restringe el `SELECT` directo solo al propio usuario o al organizador. Un `coach` no puede consultar `user_accounts` directamente por PostgREST sin una RPC controlada que proteja la privacidad.
- **Alternatives Considered**: Relajar la política RLS de `user_accounts` para todos los `coach` — rechazado por violar el principio de mínimo privilegio y privacidad de datos personales.

### 4. Habilitación Directa por el Entrenador (`>= 11` jugadores) y Soporte de Clubes Base
- **Decision**: Extender `ManageTeamsEligibilityUseCase.approveTeamEligibility` (y el controlador `TeamsController`) para permitir que `UserRole.coach` (además de `UserRole.organizer`) habilite a `TeamEligibilityStatus.eligible` un equipo que cumpla `team.players.length >= max(11, tournament.rules.minPlayersPerTeam)`, soportando tanto inscripciones en torneo (`tournamentId.isNotEmpty`) como clubes base independientes (`tournamentId.isEmpty`). Además, en `PostgrestTeamsRemoteDataSource.upsert`, persistir el cambio de `eligibility_status` y jugadores incluso cuando se opera sobre clubes base o inscripciones asociadas.
- **Rationale**: Cumple exactamente con la aclaración de HU 20.1 (Opción A de Q1) y evita que el flujo se bloquee cuando el entrenador administra un club recién creado aún sin torneo asignado.
- **Alternatives Considered**: Mantener el bloqueo exclusivo para `RoleCapability.approveRegistrations` (Organizador) — descartado porque contradice el Gherkin y la decisión explícita de negocio de HU 20.1.

### 5. Ubicación de Respuesta a Solicitudes en el Perfil del Jugador (`ProfileTabView`)
- **Decision**: Agregar en `ProfileTabView` (visible cuando el usuario posee el rol `player`) una tarjeta/acceso directo **"Solicitudes de Equipos"** con contador de solicitudes pendientes que abre `PlayerTeamRequestsScreen` (ruta `/profile/team-requests` o navegación directa), permitiendo al jugador revisar el detalle de cada invitación y ejecutar "Aceptar" o "Rechazar".
- **Rationale**: Alinea directamente con la decisión de Q4 (Opción C: vista dedicada dentro de la sección de Perfil del usuario) manteniendo `ProfileTabView` limpio y escalable.
- **Alternatives Considered**: Mostrar la lista completa embebida en `PlayerPanelContent` — descartado por preferencia explícita del usuario hacia la sección de Perfil.
