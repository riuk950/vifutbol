# Feature Specification: Pantalla de Detalle de Competición con Pestañas y Partidos por Jornadas (Fixture Completo)

**Feature Branch**: `018-competition-detail-fixture`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "de Notion hu 13.1 en curso - [Épica 13] HU 13.1: Pantalla de Detalle de Competición con Pestañas y Partidos por Jornadas (Fixture Completo)"

---

## Clarifications

### Session 2026-11-06

- Q: ¿Cómo debe estructurarse la navegación y exploración de las jornadas en la pestaña de fixture? (FR-012) → A: Lista vertical continua: Desplazamiento vertical integral donde cada jornada se presenta en bloque con su encabezado descriptivo ("Jornada 1", "Jornada 2", etc.) y sus respectivos partidos, permitiendo visualizar todo el fixture del campeonato en una sola vista.
- Q: ¿Qué comportamiento debe tener la interacción al pulsar una tarjeta de partido dentro del fixture del campeonato? (FR-013) → A: Apertura de Match Center modal: Tocar cualquier tarjeta de partido en el fixture abre la hoja modal (`showMatchCenterSheet` / `MatchCenterCard`) con el detalle del encuentro, eventos y alineaciones.
- Q: ¿Qué contenido deben presentar las pestañas de "Clasificación" e "Información" en esta historia previa a su desarrollo en HU 13.2 y 13.3? (FR-014) → A: Conexión parcial anticipada: Reutilizar de inmediato la visualización de tabla de posiciones existente para la pestaña "Clasificación" cuando el torneo cuente con datos calculados (o su estado vacío correspondiente), y presentar una vista informativa de preparación (`KickPulseStateView`) para la pestaña "Información" de reglas oficiales.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegación al Detalle de Competición y Fixture Completo por Jornadas (Priority: P1) 🎯 MVP

Como aficionado, jugador, entrenador u organizador de ViFutbol, quiero acceder a la pantalla de detalle de una competición desde el directorio o enlace directo y ver de forma inmediata el calendario completo de partidos agrupados cronológicamente por jornadas, para consultar el fixture integral del torneo sin tener que navegar fecha por fecha.

**Why this priority**: Es el núcleo de la historia de usuario y el caso de uso primordial para cualquier participante del campeonato: conocer contra quién se juega en cada jornada (pasada, presente y futura) en un único lugar centralizado.

**Independent Test**: Abrir el directorio de competiciones, seleccionar cualquier torneo con fixture generado (ej. "Liga Clausura 2026"), comprobar la transición a la pantalla de detalle (`/competitions/:id`), constatar que el AppBar exhibe el nombre y estado del torneo, y verificar que en la pestaña por defecto "Partidos" se visualizan los bloques agrupados por jornada ("Jornada 1", "Jornada 2", etc.) con sus partidos correspondientes.

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en el directorio de "Competiciones", **When** pulsa sobre una tarjeta de torneo específica, **Then** el sistema navega a la pantalla de detalle de la competición (`/competitions/:id`), presentando un AppBar con el nombre del torneo, su categoría y la insignia de estado oficial (`openRegistration`, `inProgress`, `finished`).
2. **Given** que el usuario ingresa a la pantalla de detalle de la competición, **When** la pantalla se renderiza por primera vez, **Then** la pestaña "Partidos" se encuentra seleccionada por defecto exhibiendo el listado continuo de partidos agrupados por jornada cronológica con encabezados visuales distintivos para cada jornada.
3. **Given** un torneo con múltiples jornadas programadas, **When** el usuario se desplaza verticalmente por la lista de partidos, **Then** el desplazamiento es fluido y cada jornada expone sus partidos con sus respectivos equipos contendientes, horarios o estado pendiente.

---

### User Story 2 - Estructura de Pestañas Horizontales Fijas bajo el AppBar (Priority: P2)

Como usuario navegando el detalle de un torneo, quiero contar con una barra fija de tres pestañas horizontales ("Partidos", "Clasificación" e "Información") inmediatamente debajo del AppBar, para alternar de forma intuitiva entre las diferentes dimensiones del campeonato sin perder el contexto del torneo seleccionado.

**Why this priority**: Establece el contenedor estructural de la pantalla de detalle según las reglas de negocio de la Épica 13, preparando la arquitectura para la incorporación de la tabla de posiciones (HU 13.2) y el reglamento oficial (HU 13.3).

**Independent Test**: Navegar a la pantalla de detalle de cualquier competición, constatar la presencia de la barra de pestañas fija con "Partidos", "Clasificación" e "Información", alternar entre las pestañas comprobando el cambio de contenido y la conservación de la pestaña seleccionada durante la sesión activa.

**Acceptance Scenarios**:

1. **Given** la pantalla de detalle de competición, **When** se visualiza la barra de navegación superior, **Then** inmediatamente debajo del AppBar se presenta una barra de pestañas fija con 3 opciones localizadas en español: "Partidos", "Clasificación" e "Información".
2. **Given** que el usuario pulsa sobre la pestaña "Clasificación" o "Información", **When** se produce la transición, **Then** la pestaña activa se destaca visualmente mediante los indicadores del sistema de diseño y se presenta el contenido respectivo (o estado informativo en construcción para funcionalidades de historias subsecuentes).
3. **Given** que el usuario regresa a la pestaña "Partidos", **When** se reactiva dicha pestaña, **Then** la posición previa de scroll y el listado de jornadas se conservan sin parpadeos ni recargas innecesarias.

---

### User Story 3 - Visualización de Tarjetas de Partido con Estado, Horario, Sede y Marcador (Priority: P3)

Como aficionado o jugador consultando el fixture de una jornada, quiero ver en cada tarjeta de partido la información esencial del enfrentamiento (equipos contendientes, marcador si ya inició o finalizó, o fecha, hora y sede si está programado, o badge de pendiente), para informarme oportunamente sobre el estado de cada juego.

**Why this priority**: Proporciona el valor informativo tangible en cada partido, distinguiendo claramente entre partidos jugados, en curso, programados y pendientes de asignación de cancha/horario.

**Independent Test**: Consultar una jornada con partidos en diversos estados (finalizados con marcador, programados con sede/horario, y pendientes de programación), comprobando que cada tarjeta expone su información semántica sin desbordamientos visuales.

**Acceptance Scenarios**:

1. **Given** un partido de una jornada que ya ha finalizado o está en curso, **When** se visualiza su tarjeta, **Then** se muestran los nombres y códigos de ambos equipos y el marcador numérico registrado.
2. **Given** un partido programado para disputarse a futuro, **When** se visualiza en la jornada correspondiente, **Then** se exhiben la fecha, la hora estimada y el nombre de la sede/cancha asignada.
3. **Given** un partido generado en el fixture pero que aún no cuenta con fecha u horario asignado por el organizador, **When** se renderiza en la jornada, **Then** se exhibe una insignia distintiva indicando "Pendiente de programación" sin bloquear la navegación ni alterar el flujo de la lista.

---

### User Story 4 - Estado Vacío Informativo para Competiciones Sin Fixture Generado (Priority: P4)

Como usuario que accede al detalle de un torneo nuevo o en fase de inscripción que todavía no tiene partidos creados, quiero ver un estado vacío informativo y amigable en la pestaña "Partidos", para entender claramente que el calendario aún no ha sido publicado en lugar de percibir un error o una pantalla en blanco.

**Why this priority**: Garantiza resiliencia móvil y experiencia de usuario limpia (Principio VII) ante torneos recién creados o en fase preliminar de registro.

**Independent Test**: Navegar al detalle de un torneo con estado `openRegistration` y sin partidos creados, verificar que la pestaña "Partidos" muestra un estado vacío accesible con iconografía semántica y mensaje explicativo en español.

**Acceptance Scenarios**:

1. **Given** una competición en estado de registro abierto que aún no tiene fixture generado, **When** el usuario abre el detalle de la competición en la pestaña "Partidos", **Then** se despliega una vista de estado vacío informativa (`KickPulseStateView`) indicando que el calendario de partidos se encuentra en preparación.
2. **Given** la vista de estado vacío en la pestaña de partidos, **When** se visualiza en pantalla, **Then** no se generan errores de renderizado y el usuario puede alternar a las otras pestañas ("Información", "Clasificación") o regresar al directorio mediante el botón de retroceso.

---

### Edge Cases

- **Navegación mediante enlace directo con identificador inexistente o eliminado**: Si el usuario intenta abrir `/competitions/:id` con un ID de torneo que no existe en la base local, la pantalla DEBE presentar un estado de error informativo amigable con botón para regresar al directorio de competiciones.
- **Competiciones con elevado número de jornadas y partidos (rendimiento)**: En torneos largos (ej. 38 jornadas con 10 partidos por jornada), la lista de partidos DEBE construirse mediante renderizado perezoso (*lazy slivers* o `ListView.builder`) para evitar consumo excesivo de memoria o bloqueos en la tasa de refresco.
- **Pérdida de conectividad durante la consulta (Modo Offline)**: Si el dispositivo no tiene conexión a internet al abrir el detalle del torneo, la pantalla DEBE consultar inmediatamente la fuente local persistida y desplegar las jornadas y partidos guardados en el dispositivo.
- **Transición de segundo plano a primer plano (Ciclo de Vida Móvil)**: Si la aplicación pasa a segundo plano mientras el usuario revisa una jornada específica, al reanudar la app DEBE conservar la pestaña activa ("Partidos", "Clasificación" o "Información") y la posición de scroll sin reinicios abruptos.
- **Visualización en pantallas compactas ($320 \times 640\text{ px}$) y texto al $130\%$**: Los nombres de equipos largos, insignias de estado y encabezados de jornada DEBEN contar con control estricto de truncamiento o ajuste dinámico, previniendo desbordamientos (`RenderFlex` overflow).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE proveer una pantalla dedicada de Detalle de Competición en la ruta `/competitions/:id` (`CompetitionDetailScreen`).
- **FR-002**: Al pulsar sobre cualquier tarjeta de torneo en `CompetitionsDirectoryScreen`, el sistema DEBE navegar a `/competitions/:id` pasando el identificador del torneo seleccionado.
- **FR-003**: El `AppBar` superior de la pantalla de detalle DEBE exhibir el nombre de la competición, su categoría deportiva y una insignia visual que refleje su estado oficial (`openRegistration`, `inProgress` o `finished`).
- **FR-004**: El `AppBar` DEBE incluir un botón accesible de retroceso (`Key('competition_detail_back_button')`) que retorne a la pantalla previa.
- **FR-005**: Inmediatamente debajo del `AppBar`, la pantalla DEBE presentar una barra fija de 3 pestañas horizontales (`TabBar`): "Partidos", "Clasificación" e "Información", con "Partidos" seleccionada por defecto.
- **FR-006**: La pestaña "Partidos" DEBE exhibir la totalidad de los partidos del campeonato agrupados cronológicamente por jornada (ej. "Jornada 1", "Jornada 2", o etapas eliminatorias).
- **FR-007**: Cada bloque de jornada DEBE contar con un encabezado descriptivo claramente visible (`Key('fixture_round_header_${roundNumber}')`) que identifique el número o nombre de la jornada.
- **FR-008**: Cada tarjeta de partido en el fixture DEBE mostrar los equipos participantes con sus respectivos nombres y códigos cortos, junto con el horario/fecha asignado o una insignia de "Pendiente de programación".
- **FR-009**: Para partidos que ya cuentan con resultado o están en disputa, la tarjeta de partido DEBE mostrar el marcador correspondiente.
- **FR-010**: Si la competición no tiene partidos generados, la pestaña "Partidos" DEBE exhibir un estado vacío informativo (`Key('fixture_empty_matches_state')`) informando que el calendario aún no ha sido publicado.
- **FR-011**: Las pestañas "Clasificación" e "Información" DEBEN existir en la barra de navegación; en HU 13.1, DEBEN mostrar vistas descriptivas acordes a sus contratos correspondientes preparando la integración de las HU 13.2 y 13.3.
- **FR-012**: La exploración del fixture DEBE implementarse mediante una lista vertical continua estructurada por bloques de jornada (`SliverList` / `ListView.builder`), donde cada jornada exhibe su encabezado descriptivo y todos sus partidos correspondientes en orden cronológico.
- **FR-013**: Al pulsar sobre cualquier tarjeta de partido en el fixture, el sistema DEBE abrir la hoja modal interactiva del Match Center (`showMatchCenterSheet`) presentando el detalle del encuentro, los eventos oficiales y las alineaciones correspondientes.
- **FR-014**: La pestaña "Clasificación" DEBE conectar con la tabla de posiciones y resultados calculados para la competición (o exhibir su estado vacío si no existen partidos disputados), mientras que la pestaña "Información" DEBE presentar una vista informativa de preparación (`KickPulseStateView`) sobre el reglamento oficial hasta su formalización en HU 13.3.
- **FR-015**: Todos los textos visibles, títulos de pestañas, etiquetas de estado y mensajes vacíos DEBEN estar centralizados en español en `app_es.arb` bajo la convención `l10n`.

---

### Key Entities *(include if feature involves data)*

- **CompetitionDetailHeader**: Entidad de presentación que encapsula el nombre del torneo, su categoría deportiva, la fecha de vigencia y el estado operativo (`openRegistration`, `inProgress`, `finished`).
- **MatchdayFixtureGroup**: Agrupación cronológica de partidos pertenecientes a una misma jornada o fase (`roundNumber`, `roundName`, lista de encuentros).
- **FixtureMatchCardData**: Proyección de datos para la tarjeta individual de partido en el fixture (equipos locales y visitantes, horarios, sede asignada, estado de programación y marcadores).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden acceder al detalle de cualquier torneo desde el directorio de competiciones en menos de 1 segundo tras la pulsación.
- **SC-002**: El 100% de los partidos del campeonato son visibles agrupados por jornada en una única vista navegable sin requerir cambios manuales de fecha.
- **SC-003**: En competiciones con más de 20 jornadas y 100 partidos, la lista mantiene un desplazamiento constante a 60 fps sin desbordamientos de memoria ni congelamientos de UI.
- **SC-004**: Cero desbordamientos de interfaz (`RenderFlex` overflow) en pantallas móviles compactas de $320 \times 640\text{ px}$ con tamaño de fuente escalado al $130\%$.

---

## Assumptions

- **A-001**: Los torneos y partidos ya persistidos en el almacenamiento local mediante las épicas previas (HU 4.1 y HU 6.1) proveen las relaciones referenciales `tournamentId`, `roundNumber` y `roundName`.
- **A-002**: La pantalla se integra en la estructura de navegación existente mediante la ruta declarativa `/competitions/:id`.
- **A-003**: Las pestañas de Clasificación (HU 13.2) e Información (HU 13.3) contarán con su implementación completa en sus respectivas historias de usuario subsecuentes.
