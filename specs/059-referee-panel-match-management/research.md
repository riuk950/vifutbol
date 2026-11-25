# Phase 0 Research: Panel del Árbitro y Gestión Completa del Partido

**Feature**: `059-referee-panel-match-management` (HU 26.1)
**Date**: 2026-11-25

## Decision 1: Resolución de partidos asignados mediante `linkedRefereeId` + `userId` y carga multi-torneo

- **Decision**: Crear el servicio puro de dominio `RefereeAssignedMatchesService` que empareja un `ChampionshipMatch` con el árbitro autenticado cuando `match.refereeId` (trim, no vacío) coincide con `user.roleProfile?.linkedRefereeId` o con `user.id`. En `RefereePanelContent` (convertido a `ConsumerStatefulWidget`), invocar en `initState` y en `RefreshIndicator` la carga multi-torneo (`matchesCatalogControllerProvider.notifier.loadAllMatches()`) junto con la carga de torneos y equipos para resolver nombres reales de equipos y torneos.
- **Rationale**:
  - `HybridTournamentMatchesRepository.loadAllMatches()` ya consulta `vifutboldev.matches` a través de todos los torneos con fallback automático a `local.loadAllMatches()`.
  - El código actual de `RefereePanelContent` solo comparaba `m.refereeId == authState.session?.user.id`, dejando invisibles los partidos asignados por `match_referees.id` (`linkedRefereeId`), y mostraba `match.homeTeamId.toUpperCase()`.
- **Alternatives considered**:
  - Agregar un nuevo método RPC en Supabase solo para `matches_by_referee`: innecesario porque `HybridTournamentMatchesRepository.loadAllMatches()` ya soporta lectura híbrida + caché offline-first y el volumen de partidos por entorno móvil es manejable.

## Decision 2: Ordenamiento operativo y filtros por estado en `RefereePanelContent`

- **Decision**: Implementar en `RefereeAssignedMatchesService.filterAndSort(...)`:
  - Filtros soportados (`RefereeMatchFilter`): `all` (`Todos`), `inProgress` (`En juego`), `scheduled` (`Programados`), `completed` (`Finalizados`).
  - Ordenamiento operativo (`all`):
    1. `MatchStatus.inProgress` primero (ascendente por `scheduledStartTime`).
    2. `MatchStatus.scheduled` y `MatchStatus.pending` segundo (ascendente por `scheduledStartTime`, nulos al final).
    3. `MatchStatus.completed` y `MatchStatus.cancelled` al final (descendente por `scheduledStartTime` / `updatedAt` más reciente).
- **Rationale**:
  - Responde directamente a la Clarificación Q1 (`2026-11-25`) para que el árbitro vea inmediatamente su partido en curso o el próximo por dirigir.
- **Alternatives considered**:
  - Orden cronológico ascendente puro: descartado porque enterraría partidos en curso o futuros debajo de partidos finalizados de semanas anteriores.

## Decision 3: Control de propiedad arbitral (`FR-009`) compatible con pruebas existentes

- **Decision**: En `ManageDigitalMatchReportUseCase._assertAuthorizedForEvents` y `_assertAuthorizedForClose`, añadir parámetros opcionales `ChampionshipMatch? match`, `String? actorUserId`, `String? actorRefereeId`. Si `activeRole == UserRole.referee` y `match?.refereeId != null` y se suministran credenciales del actor (`actorUserId` o `actorRefereeId`), exigir que `match.refereeId == actorRefereeId || match.refereeId == actorUserId`. `UserRole.organizer` mantiene autorización total. En `DigitalMatchReportScreen`, calcular `isAssignedOrOrganizer` y deshabilitar controles de edición con un banner informativo en español cuando otro árbitro abra el partido.
- **Rationale**:
  - Cumple estrictamente `FR-009` sin romper la compatibilidad de llamadas existentes en tests unitarios previos que invocan el caso de uso solo con `activeRole`.
- **Alternatives considered**:
  - Hacer obligatorios `actorUserId` y `actorRefereeId` en todas las firmas: descartado para evitar cambios masivos innecesarios en tests legacy de HU 6.1.

## Decision 4: Observaciones arbitrales y respaldo de plantilla sin convocatoria

- **Decision**:
  - Añadir el campo opcional `String? refereeObservations` a `DigitalMatchReport` (serializado en JSON local y en columna idempotente `referee_observations text` de `vifutboldev.match_reports` vía `202611250004_match_report_referee_observations.sql`), con método `updateObservations` en `ManageDigitalMatchReportUseCase` y `DigitalMatchReportController`, y tarjeta editable/solo-lectura en `DigitalMatchReportScreen`.
  - En `DigitalMatchReportController.loadReportForMatch`, registrar `homeConvocationConfirmed` y `awayConvocationConfirmed` en `DigitalMatchReportState` (manteniendo el respaldo existente de `_resolveRosterPlayers` hacia la plantilla inscrita) para mostrar un aviso informativo no bloqueante en `DigitalMatchReportScreen` (Clarificación Q2).
- **Rationale**:
  - Cubre al 100% `FR-005` y `FR-006` (incluyendo observaciones arbitrales de partido además de notas por evento) preservando la resiliencia offline-first.
- **Alternatives considered**:
  - Guardar observaciones solo como un `MatchEvent` de texto: descartado porque una observación general del acta (estado de cancha, incidencias post-partido) tiene semántica distinta a un evento cronológico por minuto y debe visualizarse de forma fija en el resumen del acta.
