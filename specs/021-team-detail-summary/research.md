# Research: Pantalla de Detalle de Equipo con Pestañas y Resumen (Último y Próximo Partido) (HU 14.1)

**Feature**: `021-team-detail-summary`  
**Date**: 2026-11-09

---

## 1. Technical Context & State Management

### 1.1 Resolución Reactiva de Equipo, Torneo y Resumen de Partidos
- **Decision**: Implementar un modelo puro e inmutable `TeamMatchSummary` junto con un provider parametrizado `teamMatchSummaryProvider(String teamId)` en `lib/application/providers/teams_providers.dart` que observe selectivamente `teamsControllerProvider`, `tournamentsControllerProvider` y `matchesCatalogControllerProvider`.
- **Rationale**: Garantiza que cualquier cambio en el catálogo de equipos o actas de partidos actualice reactivamente la vista de detalle del equipo en tiempo constante $O(N)$ sobre los partidos del torneo, cumpliendo la directriz de rendimiento de KickPulse sin bloquear el hilo de UI.
- **Alternatives considered**:
  - Filtrar y ordenar directamente dentro del método `build` del widget: descartado para mantener la lógica de selección determinista testeable de forma aislada y reutilizable entre widgets.
  - Crear un repositorio separado en almacenamiento local: descartado porque los partidos y equipos ya están hidratados en memoria por `matchesCatalogControllerProvider` y `teamsControllerProvider`.

---

## 2. Regla Determinista de Selección de "Último Partido" y "Próximo Partido"

### 2.1 Algoritmo `TeamMatchSummary.fromCatalog`
- **Decision**:
  1. Filtrar `matches` donde `match.homeTeamId == teamId || match.awayTeamId == teamId`.
  2. **Último Partido (`lastPlayedMatch`)**:
     - Filtrar por `match.status == MatchStatus.completed`.
     - Ordenar comparando primero `scheduledStartTime` descendente (si ambos tienen fecha asignada); en caso de empate o ausencia de fecha, comparar `roundNumber` descendente y finalmente `id` para determinismo total.
     - Tomar el primer elemento (`firstOrNull`).
  3. **Próximo Partido (`nextScheduledMatch`)**:
     - Filtrar por `match.status == MatchStatus.inProgress || match.status == MatchStatus.scheduled || match.status == MatchStatus.pendingSchedule` (excluyendo `completed` y `cancelled`).
     - Ordenar por prioridad de estado:
       1. `MatchStatus.inProgress` primero.
       2. `MatchStatus.scheduled` con `scheduledStartTime != null` ordenados por `scheduledStartTime` ascendente (desempate por menor `roundNumber`).
       3. Partidos sin `scheduledStartTime` o en `MatchStatus.pendingSchedule` ordenados por `roundNumber` ascendente.
     - Tomar el primer elemento (`firstOrNull`).
- **Rationale**: Satisface exactamente la clarificación acordada para `FR-006` y `FR-008`, manejando torneos tanto con horarios completos como con jornadas recién generadas pendientes de cancha/hora.
- **Alternatives considered**:
  - Ordenar únicamente por `DateTime.now()`: descartado porque en datos semilla o pruebas históricas un partido en estado `scheduled` sigue siendo un partido programado pendiente de disputarse hasta que su estado pase a `completed`.

---

## 3. Navegación y Coexistencia en `MatchCenterCard` y `TeamsDirectoryScreen`

### 3.1 Ruta `/teams/:id` y Preservación de `/tournaments/teams/detail`
- **Decision**:
  - Registrar `/teams/:id` en `AppRouter` construyendo `TeamDetailScreen(teamId: id)`.
  - En `TeamsDirectoryScreen._onTeamTapped`, actualizar la navegación para abrir `TeamDetailScreen(teamId: team.id)` con `RouteSettings(name: '/teams/${team.id}')` (además de mantener `selectTeam(team.id)` en el controlador).
  - Conservar intacta la ruta `/tournaments/teams/detail` (`TeamRosterDetailScreen`) para que todos los flujos administrativos de inscripción de jugadores y aprobación de elegibilidad sigan funcionando sin alteraciones.
- **Rationale**: Permite que `TeamsDirectoryScreen` lleve a la nueva experiencia de detalle de equipo con 3 pestañas sin romper las pruebas existentes de `TeamRosterDetailScreen`.

### 3.2 Zonas Táctiles Independientes en `MatchCenterCard` (FR-002)
- **Decision**:
  - En `MatchCenterCard`, envolver los bloques del equipo local y del equipo visitante en áreas táctiles independientes (`InkWell` / `GestureDetector` con claves `Key('match_card_home_team_${match.id}')` y `Key('match_card_away_team_${match.id}')`), agregando callbacks opcionales `onHomeTeamTap` / `onAwayTeamTap` y un flag `enableTeamNavigation` (activo por defecto cuando se dispone de `homeTeamId` / `awayTeamId`).
  - Al tocar el bloque de un equipo, si la ruta actual (`ModalRoute.of(context)?.settings.name`) ya corresponde a `/teams/$targetTeamId`, se ignora el toque para evitar apilar la misma pantalla; de lo contrario, se navega a `TeamDetailScreen(teamId: targetTeamId)` con `RouteSettings(name: '/teams/$targetTeamId')`.
  - El bloque central de marcador/horario y el contenedor general conservan el callback `onTap` original del partido.
- **Rationale**: Cumple el requerimiento de navegar al detalle del equipo desde el escudo/nombre en las tarjetas de partido sin interferir con la apertura del modal del Match Center al tocar el centro de la tarjeta.
- **Alternatives considered**:
  - Reemplazar el `onTap` de toda la tarjeta: descartado porque rompería la apertura del Match Center modal implementada en HU 13.1.

---

## 4. Identidad de Marca Dinámica y Resiliencia Móvil

### 4.1 Acentos de Color del Club (Primario y Secundario)
- **Decision**: Utilizar `Color(team.primaryColorHex)` y `Color(team.secondaryColorHex)` en bordes sutiles, indicadores de muestras de color (swatches con código hexadecimal legible) y acento superior en la "Tarjeta de Ficha del Club", manteniendo el fondo de superficie en `KickPulseColors.surfaceBase` y el texto en `KickPulseColors.textPrimary`.
- **Rationale**: Garantiza fidelidad a la directriz de "Identidad de Marca Dinámica" de KickPulse mientras asegura contraste óptimo WCAG AA independientemente de qué tan claro u oscuro sea el color del club.
