# Feature Specification: Panel de Organización: Resumen y Métricas Exclusivas de Competiciones del Organizador Autenticado (HU 19.3)

**Feature Branch**: `041-organizer-panel-metrics`

**Created**: 2026-11-13

**Status**: Draft

**Input**: User description: "Notion HU 19.3: Panel de Organización: Resumen y Métricas Exclusivas de Competiciones del Organizador Autenticado"

## Clarifications

### Session 2026-11-13

- Q: When an organizer is authenticated with a real user ID, should `organizerTournamentsProvider` strictly exclude legacy seed tournaments (`org-seed-1`) so only `t.organizerId == currentUserId` is included? → A: Strictly filter `t.organizerId == currentUserId` when authenticated; fall back to `'org-seed-1'` only when no session exists.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Aislamiento de Métricas Superiores por Organizador Autenticado (Priority: P1)

Como organizador de torneos autenticado, quiero que las tarjetas de resumen del Panel Administrativo ("Torneos Activos", "Partidos por Programar" y "Torneos sin Fixture") calculen exclusivamente la información de las competiciones creadas por mi usuario, para evaluar con precisión el estado de mis torneos sin contaminación de datos de otros organizadores.

**Why this priority**: Evita que un organizador tome decisiones operativas erróneas basadas en métricas globales del ecosistema que incluyen torneos y partidos ajenos.

**Independent Test**: Iniciar sesión como un organizador específico cuando existen torneos y partidos de múltiples organizadores en el sistema, abrir el Panel Administrativo y verificar que los tres contadores reflejan únicamente los torneos y partidos pertenecientes al organizador en sesión.

**Acceptance Scenarios**:

1. **Given** que el usuario ha iniciado sesión con rol de Organizador y existen torneos propios y de otros organizadores en el sistema, **When** ingresa al Panel Administrativo, **Then** los contadores de "Torneos Activos", "Partidos por Programar" y "Torneos sin Fixture" se calculan exclusivamente sobre los torneos cuyo creador es el organizador autenticado.
2. **Given** que existen 10 torneos de otros organizadores y solo 2 torneos activos (en inscripción abierta o en curso) del organizador actual, **When** visualiza la tarjeta de "Torneos Activos", **Then** el contador muestra exactamente `2`.
3. **Given** que existen partidos pendientes de programar en torneos ajenos y propios, **When** consulta el indicador "Partidos por Programar", **Then** la métrica suma únicamente los partidos pendientes que pertenecen a sus propios torneos.

---

### User Story 2 - Consistencia entre Resumen de Métricas y Listado "Mis Competiciones" (Priority: P1)

Como organizador de torneos, quiero que el listado de "Mis Competiciones" y las tarjetas de métricas compartan exactamente el mismo subconjunto de torneos propios y reaccionen en tiempo real al crear o actualizar una competición, para mantener coherencia total entre los indicadores numéricos y las tarjetas que gestiono.

**Why this priority**: Garantiza integridad y transparencia entre lo que indican los KPIs del panel y las competiciones listadas debajo.

**Independent Test**: Crear un nuevo torneo desde el Panel Administrativo y verificar de inmediato que tanto la lista de "Mis Competiciones" como los contadores de "Torneos Activos" y "Torneos sin Fixture" se incrementan automáticamente sin recargar manualmente.

**Acceptance Scenarios**:

1. **Given** que el organizador visualiza su Panel Administrativo con métricas y el listado "Mis Competiciones", **When** crea un nuevo torneo, **Then** tanto el listado como los contadores de métricas (por ejemplo, "Torneos Activos" y "Torneos sin Fixture") se actualizan de inmediato reflejando el nuevo torneo.
2. **Given** que el organizador aún no ha creado ningún torneo, **When** abre el Panel Administrativo, **Then** todas las métricas muestran `0` y el listado muestra un estado vacío invitando a crear su primera competición, aun cuando existan torneos de otros organizadores.

---

### Edge Cases

- ¿Qué ocurre si el usuario autenticado no tiene un identificador de sesión válido o cambia de cuenta? Los contadores deben reiniciarse a `0` o recalcularse inmediatamente para el nuevo organizador autenticado sin arrastrar valores de la sesión anterior.
- ¿Qué ocurre si un torneo propio ya finalizó (`finished`)? No debe sumarse al contador de "Torneos Activos" ni a "Torneos sin Fixture", pero sí debe mantenerse consistente con las reglas de estado del panel.
- ¿Qué ocurre cuando la aplicación opera sin conexión con datos cacheados localmente? Las métricas deben seguir filtrándose estrictamente por el identificador del organizador autenticado sobre los datos disponibles en caché.
- ¿Qué ocurre si un torneo tiene partidos asignados a múltiples jornadas, algunos ya programados con fecha/cancha y otros pendientes? Solo los partidos pendientes pertenecientes a torneos propios deben contabilizarse en "Partidos por Programar".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema MUST filtrar los torneos utilizados para calcular las métricas y el listado del Panel Administrativo estrictamente por el identificador del organizador autenticado en sesión (`t.organizerId == currentUserId`), excluyendo datos semilla de otros organizadores cuando exista sesión activa y usando el respaldo local únicamente cuando no exista sesión autenticada.
- **FR-002**: El indicador "Torneos Activos" MUST contabilizar únicamente los torneos propios del organizador autenticado que se encuentren activos (inscripción abierta o en curso).
- **FR-003**: El indicador "Partidos por Programar" MUST sumar únicamente los partidos pendientes de programación (sin fecha/horario o cancha asignada según la regla vigente) pertenecientes a los torneos propios del organizador autenticado.
- **FR-004**: El indicador "Torneos sin Fixture" MUST contabilizar únicamente los torneos propios del organizador autenticado que aún no tienen un calendario/fixture generado.
- **FR-005**: El listado "Mis Competiciones" y las tarjetas de métricas del Panel Administrativo MUST operar sobre la misma fuente filtrada por el organizador en sesión, garantizando coherencia 1 a 1.
- **FR-006**: Las métricas del Panel Administrativo MUST actualizarse de forma reactiva e inmediata cuando el organizador cree, edite, elimine o genere el fixture de un torneo propio, así como al programar partidos.
- **FR-007**: Cuando el organizador autenticado no posea torneos propios, todos los contadores de métricas MUST mostrar `0`, independientemente de la cantidad de torneos de otros organizadores existentes en el sistema.
- **FR-008**: El cálculo aislado de métricas MUST mantenerse consistente tanto en modo conectado como en modo sin conexión sobre los datos almacenados localmente.

### Key Entities

- **Métricas del Organizador (Organizer Panel Metrics)**: Resumen calculado de manera determinista a partir del subconjunto de torneos cuyo propietario es el organizador autenticado y sus partidos asociados (`activeTournamentsCount`, `unscheduledMatchesCount`, `tournamentsWithoutFixtureCount`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% de las métricas del Panel Administrativo ("Torneos Activos", "Partidos por Programar" y "Torneos sin Fixture") excluyen torneos y partidos pertenecientes a otros organizadores.
- **SC-002**: 100% de consistencia numérica entre los contadores mostrados en el resumen superior y los torneos listados en "Mis Competiciones".
- **SC-003**: Al crear un nuevo torneo o programar un partido propio, las métricas del panel reflejan el cambio en menos de 200 ms sin requerir reinicio ni navegación manual.
- **SC-004**: 100% de las pruebas unitarias de cálculo de métricas aisladas y pruebas de widgets del panel aprueban sin regresiones ni advertencias de análisis estático.

## Assumptions

- Se asume que todo torneo creado por un organizador almacena su identificador de usuario creador (`organizerId`) de forma consistente.
- Se asume que las definiciones vigentes de "Torneo Activo", "Partido por Programar" y "Torneo sin Fixture" ya existentes en la lógica de negocio del panel se conservan intactas, aplicando estrictamente el filtro de propiedad por organizador autenticado.
- Se asume que el acceso al Panel Administrativo continúa restringido por rol (`UserRole.organizer`) según la matriz de permisos vigente.
