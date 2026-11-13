# Contracts: Panel de Organización — Métricas Exclusivas por Organizador (HU 19.3)

**Feature**: `041-organizer-panel-metrics`  
**Date**: 2026-11-13

## 1. Riverpod Providers (`lib/application/providers/tournaments_providers.dart`)

### `organizerTournamentsProvider`
- **Type**: `Provider<List<ChampionshipTournament>>`
- **Behavior**: Retorna exclusivamente los torneos cuyo `organizerId` coincide con el `user.id` autenticado (o `'org-seed-1'` si no hay sesión activa).

### `organizerPanelMetricsProvider`
- **Type**: `Provider<OrganizerPanelData>`
- **Dependencies**: `organizerTournamentsProvider`, `matchesCatalogControllerProvider`
- **Behavior**: Calcula `OrganizerPanelData` exclusivamente sobre los torneos retornados por `organizerTournamentsProvider` y sus partidos asociados.

## 2. Pure Calculation Helper

```dart
OrganizerPanelData computeOrganizerPanelMetrics({
  required List<ChampionshipTournament> organizerTournaments,
  required List<ChampionshipMatch> allMatches,
});
```

- Garantiza 0 si `organizerTournaments` está vacío, sin importar cuántos torneos o partidos ajenos existan en `allMatches`.

## 3. Presentation Widget (`lib/presentation/panel/widgets/organizer_panel_content.dart`)

- `OrganizerPanelContent` consume `ref.watch(organizerPanelMetricsProvider)` para renderizar:
  - `Key('organizer_metric_active_tournaments')`
  - `Key('organizer_metric_pending_matches')`
  - `Key('organizer_metric_unseeded_tournaments')`
- `OrganizerCompetitionsSection` continúa consumiendo `ref.watch(organizerTournamentsProvider)`, asegurando paridad 1 a 1.
