# Research: Inscripción de Equipos mediante FAB Menu con Buscador (HU 18.4)

**Feature**: `035-competition-fab-team-search`  
**Date**: 2026-11-11  
**Branch**: `develop`

---

## 1. Reintroducción del Menú Flotante Expandible (FAB Menu) sin Dependencias Externas

- **Decision**: Implementar un widget nativo dedicado [`CompetitionDetailFabMenu`](../../../lib/presentation/tournaments/widgets/competition_detail_fab_menu.dart) usando animaciones nativas de Flutter (`AnimatedSwitcher` / `AnimatedSize` / `AnimatedOpacity` con duración de `120ms`, por debajo del objetivo SC-001 de `150ms`) integrado en `CompetitionDetailScreen`.
- **Rationale**:
  - `pubspec.yaml` no incluye paquetes externos de speed dial (como `flutter_speed_dial`) y mantener cero dependencias externas evita fricción en `pub get` y pruebas de widgets.
  - Un widget propio garantiza control exacto de `Key`s estables (`competition_detail_fab_menu`, `competition_detail_fab_generate_fixture`, `competition_detail_fab_add_team`), contraste con tokens KickPulse (`KickPulseColors`), colapso inmediato al seleccionar cualquier acción o tocar el backdrop y accesibilidad (`tooltip` y `Semantics`).
  - Reemplaza explícitamente la simplificación previa en `CompetitionDetailScreen._buildFloatingActionButton`, manteniendo la regla clarificada: visible solo para `RoleCapability.manageTournaments` (`UserRole.organizer`) mientras `tournament.status.isEditable` sea `true`; oculta `"Generar Fixture"` cuando `hasFixture == true` pero conserva `"Agregar Equipos"`.
- **Alternatives Considered**:
  - *Agregar `flutter_speed_dial` a `pubspec.yaml`*: Descartado por agregar una dependencia externa innecesaria para 2 acciones y dificultar pruebas precisas de `Key` y tiempos.
  - *Botón único en AppBar*: Descartado por no cumplir con el patrón visual de FAB Menu especificado en HU 18.4.

---

## 2. Buscador en Tiempo Real Insensible a Mayúsculas y Tildes (`diacritic-insensitive`)

- **Decision**: Reutilizar y ampliar ligeramente [`normalizeSearchText` y `matchesSearchQuery`](../../../lib/application/utils/search_utils.dart) en la capa de aplicación para normalizar texto eliminando tildes/diacríticos comunes y mayúsculas, aplicándolo al filtro en tiempo real sobre `name` y `shortCode` dentro del modal.
- **Rationale**:
  - `lib/application/utils/search_utils.dart` ya existe en el repositorio con funciones puras O(n) síncronas (`normalizeSearchText`, `matchesSearchQuery`), lo que cumple con el objetivo `< 50 ms` por pulsación de tecla (`SC-002`) sin necesidad de `Timer` ni debouncing complejo para catálogos locales en memoria.
  - Ampliar el mapa de reemplazo con vocales acentuadas adicionales (`àèìòùâêîôûãõç`) cubre variantes ortográficas frecuentes sin dependencias adicionales.
  - Reutilizar `KickPulseSearchBar` (`lib/presentation/design_system/widgets/kick_pulse_search_bar.dart`) asegura cumplimiento de `DESIGN.md`, área táctil mínima de `44px` (`KickPulseRadiiSpacing.minTouchTarget`) y botón rápido de limpiar filtro (`search_bar_clear_button`).
- **Alternatives Considered**:
  - *Agregar paquete `diacritic`*: Descartado por redundancia frente al helper puro ya existente y probado en `lib/application/utils/search_utils.dart`.

---

## 3. Catálogo Global Deduplicado, Copia de Plantilla Base y Resolución de Conflictos de Jugadores

- **Decision**:
  1. Construir la lista del catálogo global deduplicando todos los equipos de `teamsControllerProvider.teams` por `normalizeSearchText(team.name)`. Cuando un club aparece en múltiples torneos, priorizar la instancia con mayor cantidad de jugadores (y desempate por `updatedAt` más reciente) para aprovechar su plantilla más completa.
  2. Encapsular la lógica transaccional de inscripción desde catálogo en un nuevo método de caso de uso: `ManageTeamsEligibilityUseCase.enrollExistingTeamFromCatalog(...)` y su método coordinador en `TeamsController`.
  3. Al inscribir, copiar identidad (`name`, `shortCode`, `crestShape`, `primaryColorHex`, `secondaryColorHex`, `coachId`), asignar estado inicial `TeamEligibilityStatus.pendingVerification`, auto-asignar el grupo menos poblado si el formato es `TournamentFormat.mixedGroupsAndKnockout`, y copiar los jugadores de la plantilla base marcados con `isEligible: false` excluyendo aquellos cuyo `normalizedDocumentId` ya exista en otro equipo de la competición actual, devolviendo un `EnrollExistingTeamResult` con el equipo guardado y `skippedConflictingPlayersCount`.
- **Rationale**:
  - Cumple estrictamente las decisiones clarificadas en `spec.md` (copia de identidad + plantilla pendiente de validación + omisión con aviso de jugadores en conflicto) y los Principios II (Integridad referencial y unicidad de documento por torneo) y IV (Arquitectura Limpia: toda validación y balanceo de grupos en Use Case, no en widgets).
  - Usar `Uuid().v4()` (paquete `uuid` ya presente en `pubspec.yaml`) evita colisiones de ID si el organizador agrega varios equipos en menos de un milisegundo dentro del modal abierto.
  - Extraer un helper puro de asignación de grupo menos poblado permite reutilizarlo tanto en `enrollExistingTeamFromCatalog` como en `CompetitionEnrollTeamDialog` sin duplicar código.
- **Alternatives Considered**:
  - *Construir el nuevo `TournamentTeam` dentro del widget modal y llamar a `enrollTeamInCompetition`*: Descartado porque violaría la separación de capas (Principio IV), no devolvería el conteo de jugadores conflictivos omitidos y obligaría a la UI a filtrar documentos duplicados.

---

## 4. Modal Reactivo con Persistencia de Estado de Búsqueda y Protección Multi-Tap

- **Decision**: Implementar [`AddTeamsToCompetitionModal`](../../../lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart) usando `showModalBottomSheet` (`isScrollControlled: true`, `useSafeArea: true`, `KickPulseColors.surfaceElevated`), observando reactivamente `teamsControllerProvider` mediante `ref.watch`, manteniendo `_searchQuery` y un `Set<String>` de claves en proceso (`_enrollingTeamKeys`) en el estado del modal.
- **Rationale**:
  - Observar `teamsControllerProvider` hace que al completar `enrollExistingTeamFromCatalog`, tanto el modal (cambiando el botón del equipo a `"Inscrito"` deshabilitado) como `CompetitionTeamsTabView` detrás del modal se actualicen de forma instantánea y reactiva sin cerrar el modal ni limpiar la búsqueda actual (Clarificación Q3).
  - Mantener `_enrollingTeamKeys` junto con `teamsState.isSaving` protege contra pulsaciones rápidas repetidas (`FR-008`, Principio VII) y permite mostrar un indicador de carga localizado en la fila en progreso.
  - Mostrar `SnackBar` (o banner informativo dentro del modal / `ScaffoldMessenger`) notificando éxito o cuántos jugadores conflictivos se omitieron mantiene al organizador informado sin interrumpir inscripciones consecutivas.
- **Alternatives Considered**:
  - *`AlertDialog` fijo*: Descartado frente a `DraggableScrollableSheet` / `ModalBottomSheet` de altura adaptable (`maxHeight: 0.85 * screenHeight`), mucho más ergonómico en móvil para escribir con teclado virtual visible y desplazarse por un catálogo amplio.
