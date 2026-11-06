# Feature Specification: Pantalla de Panel Administrativo Dinámico por Rol (Organizador, Entrenador, Árbitro y Jugador)

**Feature Branch**: `017-role-dynamic-panel`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "de Notion hu 12.2 en curso - [Épica 12] HU 12.2: Pantalla de Panel Administrativo Dinámico por Rol (Organizador, Entrenador, Árbitro y Jugador)"

---

## Clarifications

### Session 2026-11-06

- Q: ¿Cómo deben resolver los paneles de Entrenador y Jugador el equipo o jugador activo cuando no existe una vinculación explícita en la sesión del usuario? → A: Selección automática del primer equipo/jugador disponible del repositorio local sembrado para visualizar inmediatamente plantilla y estadísticas.
- Q: ¿Cómo deben comportarse los accesos rápidos del Organizador ("Generar Fixture" y "Programar Partidos") al ser pulsados desde `/panel`? → A: Apertura de diálogos modales existentes para resolver pendientes directamente desde el panel (o navegación contextual a `/matches` si todo está programado).
- Q: ¿Cómo deben obtenerse y mostrarse los partidos asignados para el Árbitro en el panel arbitral cuando no existen designaciones explícitas para su identificador de usuario? → A: Filtrado estricto con estado vacío: mostrar exclusivamente partidos asignados al árbitro activo; si no existen partidos asignados, exhibir una tarjeta de estado vacío informativa.
- Q: ¿Cómo debe resolverse la navegación al pulsar el botón "Volver a Partidos" en la vista restrictiva del rol Aficionado? → A: Navegación limpia a `/matches`: redirige a la ruta principal de partidos restableciendo la sección activa del Shell.
- Q: ¿Cómo deben estructurarse visualmente las acciones rápidas en los paneles de Entrenador y Jugador para garantizar accesibilidad y ergonomía táctil en pantallas móviles? → A: Lista vertical de botones destacados: acciones apiladas verticalmente con altura táctil >= 48 dp, icono temático y texto completo, garantizando legibilidad con texto al 130%.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Panel de Gestión para el Rol Organizador (Priority: P1) 🎯 MVP

Como usuario con rol activo de Organizador (`UserRole.organizer`), quiero acceder a un panel centralizado con métricas globales del campeonato y accesos directos de gestión deportiva, para supervisar el avance de los torneos, programar partidos pendientes y acceder rápidamente a la administración de copias de seguridad y fixtures.

**Why this priority**: El organizador es la autoridad principal de la plataforma; concentrar sus métricas de torneos en curso, pendientes de fixture y programación en un único centro de mando desbloquea la administración integral de los campeonatos deportivos.

**Independent Test**: Iniciar sesión o seleccionar el rol `Organizador`, navegar a `/panel`, verificar que el AppBar exhibe "Panel de Organización", constatar el resumen de torneos en curso y partidos pendientes, y validar la funcionalidad de los botones de acción rápida ("Generar Fixture", "Programar Partido", "Copia de Seguridad").

**Acceptance Scenarios**:

1. **Given** que el usuario activo tiene el rol `Organizador`, **When** ingresa a `/panel`, **Then** el título del AppBar exhibe "Panel de Organización", se visualizan tarjetas con el conteo de partidos pendientes de programar y torneos activos/en curso, y se muestran botones de acceso rápido para "Generar Fixture", "Programar Partido" y "Copia de Seguridad".
2. **Given** que existen torneos sin fixture o partidos sin horario asignado, **When** el organizador pulsa sobre la acción "Programar Partido" o "Generar Fixture", **Then** el sistema navega al flujo de programación correspondiente o abre el diálogo de gestión operativa sin excepciones visuales.

---

### User Story 2 - Panel Técnico para el Rol Entrenador (Priority: P2)

Como usuario con rol activo de Entrenador (`UserRole.coach`), quiero acceder a un panel técnico enfocado en la plantilla de mi equipo, para conocer el estado de elegibilidad de los jugadores (habilitados vs suspendidos) y acceder directamente a la gestión de convocatorias y alineaciones para el próximo encuentro.

**Why this priority**: Los directores técnicos necesitan visibilidad inmediata sobre la disponibilidad disciplinaria de sus futbolistas y un acceso rápido a la alineación antes de cada partido oficial.

**Independent Test**: Configurar el rol `Entrenador` con un equipo asignado, navegar a `/panel`, comprobar que el AppBar exhibe "Panel Técnico", constatar el desglose de jugadores habilitados y suspendidos por tarjetas, y verificar que el botón para gestionar la convocatoria o alineación del próximo partido está disponible y responde a la pulsación.

**Acceptance Scenarios**:

1. **Given** que el usuario activo tiene el rol `Entrenador`, **When** ingresa a `/panel`, **Then** el título del AppBar exhibe "Panel Técnico", se muestra la tarjeta de resumen de su equipo con el total de jugadores en plantilla distinguiendo habilitados y suspendidos, y se ofrece el acceso directo para gestionar la alineación del próximo partido.
2. **Given** que un equipo no tiene partidos programados inmediatamente, **When** el entrenador consulta su panel, **Then** el sistema presenta un estado informativo neutral indicando la ausencia de encuentros próximos sin generar bloqueos en la interfaz.

---

### User Story 3 - Panel Arbitral para el Rol Árbitro (Priority: P3)

Como usuario con rol activo de Árbitro (`UserRole.referee`), quiero acceder a un panel arbitral que liste los partidos designados a mi cargo (para la jornada de hoy o próximas fechas), para abrir rápidamente las actas digitales oficiales y registrar incidencias disciplinarias y goles en tiempo real.

**Why this priority**: Los colegiados arbitrales operan a pie de campo bajo condiciones de tiempo ajustadas; necesitan acceder con un solo toque al acta digital del partido que van a dirigir sin tener que navegar por calendarios globales.

**Independent Test**: Configurar el rol `Árbitro`, ingresar a `/panel`, comprobar que el AppBar exhibe "Panel Arbitral", validar la lista de partidos asignados al árbitro con sus equipos y horarios, y constatar que cada partido incluye un botón táctil para abrir el "Acta Digital".

**Acceptance Scenarios**:

1. **Given** que el usuario activo tiene el rol `Árbitro`, **When** ingresa a `/panel`, **Then** el título del AppBar exhibe "Panel Arbitral", se listan los partidos designados para la fecha o próximos a disputarse con sus equipos contendientes, y cada partido cuenta con un botón directo para abrir el "Acta Digital".
2. **Given** que el árbitro no cuenta con partidos asignados en la jornada, **When** abre su panel, **Then** se exhibe un estado vacío amigable con el mensaje localizado de disponibilidad arbitral.

---

### User Story 4 - Ficha Deportiva y Estadísticas para el Rol Jugador (Priority: P4)

Como usuario con rol activo de Jugador (`UserRole.player`), quiero acceder a mi ficha deportiva personalizada con mi estado de elegibilidad y estadísticas individuales acumuladas, para conocer mi disponibilidad para el siguiente partido y dar seguimiento a mi rendimiento en el torneo.

**Why this priority**: Empodera al deportista con transparencia sobre su historial de goles, asistencias, tarjetas y estatus disciplinario oficial.

**Independent Test**: Configurar el rol `Jugador`, navegar a `/panel`, verificar que el AppBar exhibe "Ficha del Jugador", comprobar la insignia de elegibilidad ("Habilitado" o "Sancionado"), constatar las tarjetas de métricas individuales (goles, asistencias, tarjetas amarillas/rojas, partidos jugados) y visualizar los datos del próximo partido de su equipo.

**Acceptance Scenarios**:

1. **Given** que el usuario activo tiene el rol `Jugador`, **When** ingresa a `/panel`, **Then** el título del AppBar exhibe "Ficha del Jugador", se presenta de forma destacada su estado de elegibilidad (Habilitado / Sancionado por acumulación de tarjetas o expulsión), se muestran sus estadísticas consolidadas (goles, asistencias, tarjetas amarillas/rojas, partidos jugados) y los datos del próximo encuentro de su club.

---

### User Story 5 - Restricción Informativa para Rol Aficionado (Priority: P5)

Como usuario con rol de Aficionado (`UserRole.fan`), si intento ingresar directamente a la ruta `/panel` (mediante enlace profundo o comando de navegación), quiero recibir un mensaje informativo claro sobre la exclusividad del panel para roles técnicos/organizadores y contar con un botón para regresar a la vista de partidos, para evitar desorientación o bloqueos.

**Why this priority**: Salvaguarda la segregación de roles (Principio V) y la resiliencia móvil (Principio VII), garantizando que el usuario general reciba una explicación amigable y una vía de retorno clara en lugar de un error 404 o pantalla en blanco.

**Independent Test**: Navegar con rol `Fan` a `/panel`, constatar que no se expone información administrativa sensible, verificar el mensaje descriptivo y pulsar el botón "Volver a Partidos" comprobando el retorno a `/matches`.

**Acceptance Scenarios**:

1. **Given** que el usuario activo tiene el rol `Aficionado`, **When** intenta navegar a la pantalla `/panel`, **Then** se presenta una vista ilustrada informando que el panel es exclusivo para miembros registrados con rol de organización, cuerpo técnico, arbitraje o jugadores federados, y se ofrece un botón accesible para retornar a la vista principal de "Partidos".
2. **Given** la pantalla restrictiva para aficionados, **When** el usuario pulsa "Volver a Partidos", **Then** el sistema navega fluidamente a `/matches`.

---

### Edge Cases

- **Ausencia de datos o primer uso**: Si no existen torneos creados para el Organizador, equipos para el Entrenador o partidos para el Árbitro, cada subpanel DEBE mostrar un estado vacío informativo (`KickPulseStateView`) con iconografía semántica y sugerencia de acción, evitando pantallas en blanco o indicadores infinitos.
- **Transición entre segundo plano y primer plano (Ciclo de Vida)**: Si la aplicación pasa a segundo plano mientras el usuario visualiza su panel, al retornar debe conservar el rol activo, la posición de scroll y los datos previamente cargados sin parpadeos ni reinicio abrupto.
- **Pérdida de conectividad (Modo Offline)**: Si el dispositivo pierde la conexión a internet, el panel DEBE consultar la fuente local de verdad persistida y mostrar las métricas disponibles acompañadas de un indicador no intrusivo de conectividad.
- **Acciones concurrentes o pulsaciones repetidas**: Todos los botones de acción rápida (ej. "Generar Fixture", "Programar Partido", "Acta Digital", "Volver a Partidos") DEBEN contar con bloqueo de pulsación única (*single-flight lock*) para impedir navegaciones duplicadas o generación concurrente de eventos.
- **Visualización en pantallas compactas y escalado de texto**: En dispositivos de $320 \times 640\text{ px}$ con tamaño de fuente escalado al $130\%$, los textos, insignias y tarjetas de métricas no deben desbordar la pantalla (`RenderFlex` overflow) ni truncar valores numéricos esenciales.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE ofrecer una pantalla unificada en la ruta `/panel` cuyo contenido y título de `AppBar` se adapten de forma reactiva según el `activeRole` del usuario.
- **FR-002**: Para el rol `Organizador`, el `AppBar` DEBE exhibir el título "Panel de Organización" y el cuerpo DEBE estructurarse mediante un subwidget desacoplado `OrganizerPanelContent`.
- **FR-003**: `OrganizerPanelContent` DEBE mostrar métricas cuantitativas clave: total de torneos activos/en curso, cantidad de partidos pendientes de programación y torneos sin fixture generado.
- **FR-004**: `OrganizerPanelContent` DEBE proveer accesos rápidos accesibles para: "Generar Fixture" y "Programar Partidos" (abriendo directamente los diálogos modales existentes si existen torneos o partidos pendientes, o navegando contextualmente a `/matches` si todo está al día), y "Copia de Seguridad" (abriendo el diálogo o flujo de backup/restore).
- **FR-005**: Para el rol `Entrenador`, el `AppBar` DEBE exhibir el título "Panel Técnico" y el cuerpo DEBE estructurarse mediante un subwidget desacoplado `CoachPanelContent`.
- **FR-006**: `CoachPanelContent` DEBE exhibir la ficha del equipo asignado, el conteo total de jugadores en plantilla distinguiendo entre futbolistas habilitados y suspendidos, y la información del próximo partido a disputar.
- **FR-007**: `CoachPanelContent` DEBE incluir un acceso directo para gestionar la convocatoria y alineación del próximo partido.
- **FR-008**: Para el rol `Árbitro`, el `AppBar` DEBE exhibir el título "Panel Arbitral" y el cuerpo DEBE estructurarse mediante un subwidget desacoplado `RefereePanelContent`.
- **FR-009**: `RefereePanelContent` DEBE filtrar estrictamente los partidos asignados al árbitro activo (`refereeId == userId`), indicando fecha, horario, sede y equipos contendientes; si no existen encuentros asignados, DEBE exhibir un estado vacío informativo que certifique la ausencia de partidos designados.
- **FR-010**: Cada partido listado en `RefereePanelContent` DEBE contener una acción directa accesible para ingresar al flujo del "Acta Digital".
- **FR-011**: Para el rol `Jugador`, el `AppBar` DEBE exhibir el título "Ficha del Jugador" y el cuerpo DEBE estructurarse mediante un subwidget desacoplado `PlayerPanelContent`.
- **FR-012**: `PlayerPanelContent` DEBE presentar de forma destacada el estatus disciplinario y de elegibilidad ("Habilitado" o "Sancionado"), la información del próximo partido del club y el resumen numérico de estadísticas acumuladas (goles, asistencias, tarjetas amarillas, tarjetas rojas y partidos jugados).
- **FR-013**: Si un usuario con rol `Aficionado` accede a `/panel`, el sistema DEBE restringir el acceso a herramientas administrativas mediante una vista informativa dedicada que explique la exclusividad del panel y provea un botón accesible "Volver a Partidos" que navegue limpiamente a `/matches`, restableciendo la sección activa del Shell en Partidos.
- **FR-014**: Todos los textos de usuario, títulos, descripciones, etiquetas de botones y estados vacíos DEBEN estar centralizados en español en `app_es.arb` bajo la convención internacional `l10n`.
- **FR-015**: Toda tarjeta táctil y botón de acción en los distintos paneles DEBE cumplir con un área de contacto mínima de $48 \times 48\text{ dp}$ (organizados como botones prominentes apilados verticalmente con iconografía semántica) y soporte accesible de foco para lectores de pantalla.

---

### Key Entities *(include if feature involves data)*

- **RoleDashboardSummary**: Agregado de presentación que unifica las métricas y resúmenes operativos que requiere el panel según el rol activo.
- **OrganizerDashboardMetrics**: Entidad de métricas del organizador que consolida conteos de torneos activos, partidos pendientes de fijar fecha/hora y torneos pendientes de generación de emparejamientos.
- **CoachTeamSummary**: Modelo representativo del estado del equipo a cargo del entrenador, incluyendo totales de plantilla, jugadores aptos, jugadores sancionados y referencia al próximo partido.
- **RefereeAssignedMatch**: Proyección de partido asignado al árbitro con fecha de programación, identificadores de equipos, estado de acta y sede de juego.
- **PlayerSeasonStats**: Resumen de rendimiento disciplinario y deportivo del jugador en el torneo vigente (goles, asistencias, amonestaciones, expulsiones y partidos disputados).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los 5 roles del sistema experimentan una interfaz adaptada a sus responsabilidades funcionales sin que ningún rol no autorizado visualice acciones de gestión restringidas.
- **SC-002**: La carga inicial y renderizado del panel dinámico se completa en menos de 200 milisegundos tras ingresar a la ruta `/panel` en modo local/offline.
- **SC-003**: En viewports compactos de $320 \times 640\text{ px}$ con escalado tipográfico al $130\%$, los 4 paneles especializados y la vista restrictiva presentan 0 errores de desbordamiento (`RenderFlex` overflow).
- **SC-004**: Los usuarios con rol de Aficionado disponen de un camino de retorno garantizado con una sola pulsación hacia `/matches` sin quedar atrapados en la pantalla restringida.
- **SC-005**: La totalidad de textos de interfaz en los paneles cuenta con clave semántica en `app_es.arb` y 0 cadenas de texto en inglés o *hardcoded* en los componentes visuales.

---

## Assumptions

- **A-001**: Los datos de torneos, partidos, equipos y jugadores provienen de los repositorios y controladores de estado preexistentes en la arquitectura (`tournamentsControllerProvider`, `matchesCatalogControllerProvider`, `teamsControllerProvider`, `activeUserRoleProvider`).
- **A-002**: Para los roles de Entrenador y Jugador, en caso de no existir una sesión vinculada a un equipo específico en modo invitado, el panel seleccionará de forma predeterminada el primer equipo y jugador disponibles del catálogo para brindar una experiencia inmediata.
- **A-003**: Para el rol de Árbitro, el panel filtra estrictamente por el identificador de usuario (`refereeId`); los fixtures de prueba o semillas incluirán partidos con `refereeId` asociado para la validación de actas, o se presentará el estado vacío correspondiente.
- **A-004**: La navegación hacia flujos existentes ("Generar Fixture", "Programar Partidos", "Copias de Seguridad", "Acta Digital") reutilizará las rutas y diálogos modales ya implementados en el sistema.
- **A-005**: No se alteran los esquemas de persistencia ni los contratos de base de datos; la funcionalidad se enfoca en la capa de presentación y orquestación reactiva por rol.
