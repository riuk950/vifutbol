# Feature Specification: Visualización de Plantilla Agrupada por Posición en el Panel Técnico (HU 20.2)

**Feature Branch**: `045-coach-positional-roster`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Notion HU 20.2 en curso: [Épica 20] HU 20.2: Visualización de Plantilla Agrupada por Posición en el Panel Técnico (ID Notion: 41b8442e-3f49-8192-8d54-f1a9fe32d517)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Nómina Agrupada por Líneas Tácticas en el Panel Técnico (Priority: P1)

Como entrenador de club (`UserRole.coach`), quiero que en mi Panel Técnico se visualice la nómina de mi equipo organizada y categorizada estrictamente por las cuatro líneas de juego (Porteros, Defensas, Mediocampistas y Delanteros), con conteo dinámico por bloque y orden interno por dorsal, para evaluar con claridad la composición táctica de mi escuadra.

**Why this priority**: Es la funcionalidad central de la historia HU 20.2; permite al entrenador tener una lectura táctica inmediata de su plantilla sin navegar fuera del panel principal.

**Independent Test**: Renderizar el Panel Técnico como entrenador con un club que posea jugadores en distintas posiciones y dorsales desordenados; verificar que se renderizan los 4 bloques en el orden estándar (Porteros -> Defensas -> Mediocampistas -> Delanteros), con el conteo exacto en cada encabezado y ordenados internamente de menor a mayor dorsal.

**Acceptance Scenarios**:

1. **Given** el entrenador visualiza el Panel Técnico de su club con futbolistas inscritos en múltiples posiciones, **When** se despliega la sección de plantilla, **Then** los futbolistas se presentan agrupados estrictamente en cuatro bloques posicionales en orden inmutable: 1) Porteros, 2) Defensas, 3) Mediocampistas, 4) Delanteros.
2. **Given** cada bloque posicional renderizado, **When** existen jugadores asignados a esa línea, **Then** el encabezado del bloque muestra el nombre de la posición junto al conteo dinámico de jugadores (ejemplo: `"Defensas (6)"`).
3. **Given** múltiples futbolistas dentro de una misma categoría posicional, **When** se lista la línea táctica, **Then** los futbolistas se muestran ordenados de menor a mayor según su número de camiseta (dorsal).

---

### User Story 2 - Detalle Visual por Futbolista y Balance Táctico / Posiciones Vacías (Priority: P1)

Como entrenador, quiero ver en cada futbolista su dorsal destacado, nombre completo y estado de elegibilidad (`"Elegible"` o `"Inactivo / Sancionado"`), así como recibir una alerta táctica preventiva cuando falte algún jugador en una posición (especialmente cuando no hay al menos 1 portero registrado).

**Why this priority**: Permite identificar de un vistazo qué jugadores están disponibles para competir y qué líneas presentan déficit crítico (ej. ausencia de arquero) antes de preparar convocatorias.

**Independent Test**: Renderizar el Panel Técnico con un club que tenga jugadores elegibles e inactivos/sancionados y sin porteros registrados; verificar que cada ítem muestra dorsal, nombre y badge de elegibilidad, que el bloque sin jugadores muestra `"Sin jugadores en esta posición"`, y que aparece la alerta táctica preventiva por ausencia de porteros.

**Acceptance Scenarios**:

1. **Given** un bloque posicional con futbolistas en el Panel Técnico, **When** se renderiza cada ítem de futbolista, **Then** muestra un badge numérico con el dorsal, el nombre completo del futbolista y un indicador visual de su estado (`"Elegible"` o `"Inactivo / Sancionado"`).
2. **Given** que el entrenador aún no tiene jugadores registrados en una posición específica (por ejemplo, Mediocampistas o Delanteros vacíos), **When** se renderiza dicho bloque posicional, **Then** se muestra un estado vacío sutil con el mensaje `"Sin jugadores en esta posición"`.
3. **Given** que el equipo no cuenta con al menos 1 portero registrado, **When** se renderiza la sección posicional en el Panel Técnico, **Then** la interfaz muestra una alerta táctica preventiva destacada indicando que el equipo necesita al menos un portero.

---

### User Story 3 - Actualización Reactiva de la Nómina Posicional (Priority: P2)

Como entrenador, quiero que la vista agrupada por posición en el Panel Técnico se actualice automáticamente cuando se incorporen nuevos jugadores o se modifique la plantilla desde la gestión de planilla.

**Why this priority**: Garantiza consistencia en tiempo real entre las acciones de gestión de plantilla (HU 20.1) y la vista táctica en el panel (HU 20.2).

**Independent Test**: Actualizar el estado de la plantilla del equipo activo (agregando un jugador o cambiando su estado de elegibilidad/posición) y verificar que el Panel Técnico refleja inmediatamente los cambios en el bloque y orden correspondiente.

**Acceptance Scenarios**:

1. **Given** el entrenador visualiza el Panel Técnico, **When** se incorpora un nuevo futbolista a su equipo o cambia la posición/elegibilidad de un integrante, **Then** la lista posicional refleja instantáneamente al futbolista en su bloque correspondiente, actualiza el conteo del encabezado y recalcula las alertas tácticas.

---

### Edge Cases

- **Plantilla completamente vacía (0 jugadores)**: Los 4 bloques posicionales se muestran con conteo `(0)`, cada uno con el estado `"Sin jugadores en esta posición"`, y se muestra la alerta táctica preventiva por falta de porteros sin provocar desbordamientos ni errores de renderizado.
- **Nombres largos de futbolistas**: Los nombres extensos deben truncarse con elipsis sin romper el badge del dorsal ni el badge de elegibilidad en pantallas móviles estrechas (`320px`-`360px`).
- **Escalado de fuente y accesibilidad**: Todos los textos e indicadores de estado deben incluir etiqueta textual explícita (`"Elegible"` / `"Inactivo / Sancionado"`) sin depender únicamente del color, cumpliendo contraste adecuado en tema oscuro.
- **Persistencia local / offline**: La agrupación y el ordenamiento deben funcionar sobre los datos ya cargados en el estado de la aplicación sin requerir conexión adicional a red.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El Panel Técnico del entrenador (`CoachPanelContent`) DEBE mostrar una sección de plantilla agrupada estrictamente en cuatro bloques posicionales en orden táctico estándar e inmutable: `Porteros` (`goalkeeper`), `Defensas` (`defender`), `Mediocampistas` (`midfielder`) y `Delanteros` (`forward`).
- **FR-002**: Cada encabezado de bloque posicional DEBE mostrar el nombre de la posición y el conteo dinámico de jugadores asignados a dicha posición (ejemplo: `Porteros (2)`).
- **FR-003**: Dentro de cada bloque posicional, los jugadores DEBEN ordenarse de menor a mayor por su número de dorsal (`shirtNumber`).
- **FR-004**: Cada fila o tarjeta de jugador DEBE mostrar: el dorsal dentro de un badge numérico destacado, el nombre completo del futbolista y un badge textual de su estado de elegibilidad (`"Elegible"` cuando está habilitado o `"Inactivo / Sancionado"` cuando no es elegible).
- **FR-005**: Cuando una posición no tenga futbolistas registrados, el bloque correspondiente DEBE mostrar el mensaje sutil `"Sin jugadores en esta posición"`.
- **FR-006**: Cuando el equipo no cuente con al menos 1 portero registrado (`goalkeepers.isEmpty`), la interfaz DEBE mostrar una alerta táctica preventiva destacada (con icono y texto claro, no solo color).
- **FR-007**: La vista posicional DEBE actualizarse de forma reactiva ante cualquier cambio en la nómina del equipo activo (altas, bajas, edición o habilitación).
- **FR-008**: Todos los textos visibles al usuario DEBEN centralizarse en español mediante localización (`l10n`), sin cadenas hardcodeadas en los widgets, manteniendo identificadores y pruebas en inglés.

### Key Entities *(include if feature involves data)*

- **PositionalRosterGroup**: Agrupación lógica derivada de la plantilla de un equipo que contiene la posición (`PlayerPosition`), la lista de jugadores pertenecientes a esa posición ordenados por `shirtNumber` ascendente, y el conteo total.
- **RegisteredPlayer**: Entidad existente que representa a cada futbolista inscrito con `id`, `fullName`, `documentId`, `shirtNumber`, `position` y `isEligible`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los jugadores de un equipo se renderizan en el bloque posicional correspondiente en el orden táctico estricto (Porteros -> Defensas -> Mediocampistas -> Delanteros) y ordenados por dorsal ascendente.
- **SC-002**: Cuando un equipo tiene 0 porteros, la alerta táctica preventiva es visible inmediatamente en el Panel Técnico en el 100% de los casos.
- **SC-003**: Cero errores de desbordamiento (*overflow*) en pantallas móviles desde `320px` de ancho con nombres largos y cualquier combinación de posiciones llenas o vacías.
- **SC-004**: Las pruebas unitarias de agrupación/ordenamiento posicional y las pruebas de widget del Panel Técnico superan el 100% de ejecución junto con cero advertencias de análisis estático.

## Assumptions

- El club activo del entrenador se resuelve mediante el proveedor existente de equipos del entrenador (`coachTeamsProvider`).
- No se requieren cambios de esquema de base de datos ni nuevas llamadas de red, ya que la plantilla del equipo activo ya incluye `RegisteredPlayer` con `position`, `shirtNumber` e `isEligible`.
- La edición o invitación de jugadores continúa realizándose desde `TeamRosterDetailScreen` (HU 20.1), accesible desde el botón `"Gestionar Planilla"`.
