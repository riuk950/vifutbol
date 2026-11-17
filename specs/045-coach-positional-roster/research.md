# Research: Visualización de Plantilla Agrupada por Posición en el Panel Técnico (HU 20.2)

**Feature**: `045-coach-positional-roster`  
**Date**: 2026-11-17

## 1. Reutilización de Modelo y Provider Existentes

- **Hallazgo**: En el codebase ya existe `TeamSquadRoster` (`lib/presentation/teams/models/team_squad_roster.dart`) junto al provider reactivo `teamSquadRosterProvider(teamId)` (`lib/application/providers/teams_providers.dart`).
- **Comportamiento verificado de `TeamSquadRoster.fromCatalog`**:
  - Toma la lista de `RegisteredPlayer` del equipo activo.
  - Ordena internamente de menor a mayor por `shirtNumber` (con desempate por `fullName` e `id`).
  - Agrupa en 4 listas inmutables: `goalkeepers`, `defenders`, `midfielders`, `forwards`.
  - `teamSquadRosterProvider` observa reactivamente `teamsControllerProvider` y `teamsDirectoryControllerProvider`.
- **Decision**: Reutilizar `teamSquadRosterProvider(team.id)` directamente en `CoachPanelContent` / `CoachPositionalRosterSection` en lugar de reescribir la lógica de agrupación/ordenamiento.
- **Rationale**: Evita duplicación de código (Principio de calidad y Clean Architecture) y garantiza actualización reactiva automática cuando el entrenador agrega o modifica jugadores en `TeamRosterDetailScreen`.
- **Alternatives considered**: Crear un nuevo controlador o provider independiente para el panel técnico. Descartado por duplicar exactamente el cálculo que ya hace `teamSquadRosterProvider`.

## 2. Etiquetas Localizadas Exactas (HU 20.2)

- **Hallazgo**: En `lib/l10n/app_es.arb` existen `teamSquadGoalkeepersSectionTitle` ("Porteros"), `teamSquadDefendersSectionTitle` ("Defensas"), `teamSquadMidfieldersSectionTitle` ("Centrocampistas") y `teamSquadForwardsSectionTitle` ("Delanteros"), pero HU 20.2 especifica los textos:
  - Título de sección: `"Plantilla por Posición"`
  - Encabezados posicionales con conteo: `"Porteros (X)"`, `"Defensas (X)"`, `"Mediocampistas (X)"`, `"Delanteros (X)"`.
  - Estados de elegibilidad en panel técnico: `"Elegible"` e `"Inactivo / Sancionado"`.
  - Estado vacío por posición: `"Sin jugadores en esta posición"`.
  - Alerta táctica por falta de portero: `"Alerta táctica: El equipo no tiene porteros registrados."`.
- **Decision**: Agregar claves `l10n` dedicadas para el panel técnico (`coachRosterSectionTitle`, `coachRosterEmptyPosition`, `coachRosterNoGoalkeeperAlert`, `coachRosterPlayerEligible`, `coachRosterPlayerInactive`, `coachRosterPositionMidfielders`) sin alterar las claves existentes de `TeamSquadTabView` para evitar regresiones en otros tests.
- **Rationale**: Preserva compatibilidad con los tests existentes de directorios de equipos mientras cumple literalmente con los criterios de aceptación de HU 20.2.
