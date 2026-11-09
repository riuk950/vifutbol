# Research & Technical Decisions: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Feature**: `023-team-squad-roster`  
**Date**: 2026-11-09

---

## 1. Derivación Reactiva y Agrupación Táctica de la Plantilla (`TeamSquadRoster`)

- **Decision**: Crear el modelo inmutable `TeamSquadRoster` (junto con `TeamSquadPlayerItem`) en `lib/presentation/teams/models/team_squad_roster.dart` y exponerlo mediante `teamSquadRosterProvider = Provider.family<TeamSquadRoster, String>` en `lib/application/providers/teams_providers.dart`.
- **Rationale**:
  - Sigue el mismo patrón arquitectónico de `TeamMatchSummary` (HU 14.1) y `TeamMatchesSchedule` (HU 14.2).
  - Toma el equipo desde `teamsControllerProvider`, extrae `team.players` (`List<RegisteredPlayer>`), garantiza el ordenamiento ascendente por `shirtNumber` (con desempate alfabético por `fullName`) y agrupa los jugadores en las 4 colecciones inmutables de línea táctica: `goalkeepers`, `defenders`, `midfielders` y `forwards`.
  - Pre-construye para cada jugador su proyección `PlayerPerformanceProfile` sincronizada con `isSuspended: !player.isEligible` y expone `allProfiles` para alimentar el selector rápido dentro del modal de perfil de rendimiento.
- **Alternatives considered**:
  - *Filtrar y ordenar `team.players` directamente en el `build` del widget*: Descartado porque dificulta las pruebas unitarias aisladas del modelo y mezcla transformación de datos con renderizado declarativo.

---

## 2. Organización Visual en 4 Bloques Verticales Fijos y Diseño Compacto (`320x640` @ `130%`)

- **Decision**:
  - Estructurar `TeamSquadTabView` como un `ListView` continuo con `PageStorageKey('team_squad_tab_view')` en el widget raíz que presenta secuencialmente los 4 bloques fijos: **Porteros**, **Defensas**, **Centrocampistas** y **Delanteros**.
  - Cada tarjeta de jugador utiliza `KickPulseCard` con altura mínima garantizada ($\ge 48\text{ dp}$), un contenedor circular/tabular para el dorsal (`#${player.shirtNumber}`) con `FontFeature.tabularFigures()`, una columna central expandida con el nombre completo del jugador y una fila/wrap de `KickPulseBadge` para la posición táctica (*Portero*, *Defensa*, *Centrocampista*, *Delantero*) y el estatus de habilitación (**Habilitado** con `KickPulseBadgeVariant.success` / **Suspendido** con `KickPulseBadgeVariant.live`).
- **Rationale**:
  - Cumple la clarificación Q3 (Opción C) y mantiene coherencia visual con la pestaña "Partidos" (`TeamMatchesTabView`, HU 14.2).
  - Usar `Wrap` para los badges de posición y elegibilidad debajo del nombre del jugador evita cualquier desbordamiento horizontal (`RenderFlex overflow`) en pantallas de `320 px` de ancho con escalado de fuente al `130%`.
- **Alternatives considered**:
  - *Colocar nombre, badge de posición y badge de elegibilidad en un único `Row` horizontal rígido*: Descartado porque en `320 px` con texto al `130%` los textos *"Centrocampista"* + *"Suspendido"* junto con el dorsal y el nombre exceden los `254 px` disponibles.

---

## 3. Apertura del Perfil de Rendimiento del Jugador (`PlayerPerformanceProfileCard`)

- **Decision**: Al tocar una tarjeta de jugador en `TeamSquadTabView`, abrir un `ModalBottomSheet` reutilizando `PlayerPerformanceProfileCard` (con soporte de cambio de jugador activo entre `roster.allProfiles` mediante `StatefulBuilder`), tal como se emplea en `PlayersDirectoryScreen` y `StandingsTabView`.
- **Rationale**:
  - Cumple la clarificación Q2 (Opción A), reutiliza el componente oficial del sistema de diseño KickPulse y permite al usuario consultar las métricas y cambiar rápidamente entre los compañeros de plantilla sin cerrar el modal.
- **Alternatives considered**:
  - *Crear un modal nuevo exclusivo para la pestaña Plantilla*: Descartado por duplicación innecesaria frente a `PlayerPerformanceProfileCard`.
