# Research: Panel de Organización — Métricas Exclusivas por Organizador (HU 19.3)

**Feature**: `041-organizer-panel-metrics`  
**Date**: 2026-11-13

## Decisions & Findings

### 1. Diagnóstico del Estado Actual

- En `lib/presentation/panel/widgets/organizer_panel_content.dart`, `OrganizerPanelContent.build()` lee directamente `tournamentsControllerProvider.tournaments` y `matchesCatalogControllerProvider.matches` sin filtrar por el organizador autenticado, provocando que las tarjetas superiores ("Torneos Activos", "Partidos por Programar", "Torneos sin Fixture") acumulen estadísticas globales de todos los organizadores del sistema.
- En `lib/application/providers/tournaments_providers.dart`, `organizerTournamentsProvider` contiene la condición `tOrgId == currentUserId || tOrgId == 'org-seed-1'`, filtrando datos semilla `'org-seed-1'` incluso cuando hay un organizador autenticado con otro `user.id`.

### 2. Aislamiento Estricto en `organizerTournamentsProvider`

- **Decision**: Actualizar `organizerTournamentsProvider` para evaluar:
  - Si existe `authState.session?.user.id` no vacío, usar ese `sessionUserId` como `effectiveUserId` y filtrar estrictamente `tOrgId == effectiveUserId`.
  - Únicamente cuando no exista sesión autenticada (por ejemplo, entorno de pruebas widget aisladas sin sesión), usar `'org-seed-1'` como `effectiveUserId`.
- **Rationale**: Garantiza aislamiento multiorganizador real en producción/DEV mientras preserva compatibilidad con pruebas aisladas de UI que no inyectan sesión Auth.
- **Alternatives considered**:
  - Retornar lista vacía cuando no hay sesión: Descartado en clarificación Q1 porque rompería pruebas de widgets sin sesión simulada.

### 3. Proveedor Reactivo `organizerPanelMetricsProvider`

- **Decision**: Exponer `organizerPanelMetricsProvider = Provider<OrganizerPanelData>` que observa `organizerTournamentsProvider` y `matchesCatalogControllerProvider`, delegando el cálculo puro en una función/constructor determinista `computeOrganizerPanelMetrics(List<ChampionshipTournament> organizerTournaments, List<ChampionshipMatch> allMatches)`:
  - `activeTournamentsCount`: torneos en `organizerTournaments` con estado `openRegistration` o `inProgress`.
  - `pendingScheduleMatchesCount`: partidos en `allMatches` cuyo `tournamentId` pertenezca al conjunto de IDs de `organizerTournaments` y `scheduledStartTime == null`.
  - `unseededTournamentsCount`: torneos en `organizerTournaments` en estado `openRegistration` o `inProgress` que no tienen ningún partido en `allMatches` con `m.tournamentId == t.id`.
- **Rationale**:
  - Garantiza coherencia matemática 1 a 1 entre las tarjetas de métricas y la sección "Mis Competiciones" (ambas derivan de `organizerTournamentsProvider`).
  - Permite probar la lógica de cálculo de métricas de forma unitaria y aislada sin montar widgets.
  - Mantiene reactividad inmediata ante creación/edición/eliminación de torneos o programación de partidos.
