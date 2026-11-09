# Research & Technical Decisions: Pestaña de Calendario de Partidos del Equipo (HU 14.2)

**Feature**: `022-team-matches-schedule`  
**Date**: 2026-11-09

---

## 1. Derivación Reactiva del Calendario Completo del Equipo

- **Decision**: Crear el modelo inmutable `TeamMatchesSchedule` (con ítems enriquecidos `TeamScheduledMatchItem` y enum `TeamMatchOutcome`) y exponerlo mediante `teamMatchesScheduleProvider = Provider.family<TeamMatchesSchedule, String>` en `lib/application/providers/teams_providers.dart`.
- **Rationale**:
  - Sigue exactamente el patrón arquitectónico establecido por `TeamMatchSummary` y `teamMatchSummaryProvider` en la HU 14.1.
  - Resuelve en una sola pasada $O(N \log N)$ sobre el catálogo local de partidos todos los encuentros donde `homeTeamId == teamId || awayTeamId == teamId`, separándolos en `upcomingMatches` (`inProgress`, `scheduled`, `pendingSchedule`) y `completedMatches` (`completed`), resolviendo además los objetos `TournamentTeam` de local/visitante y el `TeamMatchOutcome` (`win`, `draw`, `loss`) desde la perspectiva de `teamId`.
- **Alternatives considered**:
  - *Filtrar y ordenar dentro del método `build` del widget*: Descartado porque mezcla lógica de negocio deportiva (cálculo de Victoria/Empate/Derrota según localía y desempates cronológicos) con código declarativo de UI y dificulta las pruebas unitarias aisladas.

---

## 2. Reutilización de `MatchCenterCard` y Distintivos Semánticos KickPulse

- **Decision**:
  1. Extender `KickPulseBadgeVariant` en `lib/presentation/design_system/widgets/kick_pulse_badge.dart` añadiendo la variante `success` basada en `KickPulseColors.accentPrimary` (`#22C55E`, verde cancha) para representar **Victoria**, usando `warning` (`#F59E0B`, amarillo/ámbar) para **Empate** y `live` (`#EF4444`, rojo sutil con `withAlpha(40)`) para **Derrota**.
  2. En `TeamMatchesTabView`, componer cada partido mediante un contenedor `KickPulseCard` (o tarjeta estilizada con borde sutil) que incluya una franja superior responsiva (`Wrap` / `Row` flexible) con metadatos de jornada (`roundName`), fecha y cancha/sede a la izquierda, y el `KickPulseBadge` semántico a la derecha, situando debajo el widget `MatchCenterCard` reutilizado.
- **Rationale**:
  - Cumple fielmente el acuerdo de clarificación (Q2: Opción A) y el requerimiento de reutilizar la tarjeta simétrica de partido sin alterar su diseño interno de 94 px ni afectar el feed diario o el fixture de competición.
  - Garantiza accesibilidad visual al combinar color semántico con etiqueta textual explícita (*"Victoria"*, *"Empate"*, *"Derrota"*) y previene desbordamientos en pantallas de `320 px` con texto al `130%`.
- **Alternatives considered**:
  - *Modificar `MatchCenterCard` para inyectar badges de resultado*: Descartado porque acoplaría un componente transversal de partido a la perspectiva de un equipo específico y comprometería el espacio horizontal en pantallas de `320 px`.

---

## 3. Detalle / Informe Informativo del Partido (`ModalBottomSheet`)

- **Decision**: Al tocar un partido en `TeamMatchesTabView`, abrir un `ModalBottomSheet` informativo (`Key('team_match_detail_modal')`) alineado con el diseño de `CompetitionFixtureTabView` (HU 13.1), enriquecido además con el marcador final (si está completado o en juego), el badge de resultado para el equipo consultado (si está completado), la fecha/hora programada, la cancha/sede y el árbitro designado.
- **Rationale**:
  - Cumple la clarificación Q3 (Opción A), manteniendo consistencia en toda la aplicación y respetando la segregación de roles (Principio V de la Constitución).
  - Mientras tanto, los toques sobre el escudo o nombre de los equipos dentro de `MatchCenterCard` continúan navegando directamente a `/teams/:rivalId` (ignorando el toque si es el mismo `teamId` actual).
- **Alternatives considered**:
  - *Navegar a `RefereeMatchReportScreen`*: Descartado porque esa pantalla pertenece al flujo operativo de arbitraje y requiere permisos de edición de acta.
