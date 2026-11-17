# Feature Specification: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico (HU 20.1)

**Feature Branch**: `044-coach-roster-eligibility`  
**Created**: 2026-11-17  
**Status**: Draft  
**Input**: User description: "Notion HU 20.1: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico"

## Clarifications

### Session 2026-11-17

- Q: ¿Qué alcance de permisos debe tener el entrenador (`coach`) frente al organizador al ejecutar la acción "Habilitar para Competiciones" cuando el equipo alcanza los 11 jugadores mínimos? → A: El entrenador (`coach`) puede habilitar directamente su equipo (`eligible`) cuando cumple `>= 11` jugadores; el organizador conserva su capacidad de gestión en torneos.
- Q: Al pulsar "Agregar Jugador" en la gestión de plantilla, ¿debe el entrenador únicamente registrar datos manualmente o también poder buscar y fichar jugadores libres ya registrados en la plataforma? → A: Debe enviar una solicitud de incorporación al jugador registrado con rol `player` para que este pueda decidir si acepta o rechaza unirse a ese equipo.
- Q: Cuando el entrenador envía una solicitud a un jugador con rol `player`, ¿en qué momento cuenta ese jugador para la cuota mínima de 11 jugadores y cómo se manejan los jugadores sin cuenta en la plataforma? → B: No se permite registro manual: todo jugador debe existir primero como usuario `player` y aceptar la solicitud antes de entrar en la plantilla y sumar a los 11.
- Q: ¿En qué pantalla debe visualizar y responder el usuario con rol `player` las solicitudes pendientes para unirse a un equipo? → C: En una pestaña o vista separada dentro de la sección de Perfil del usuario.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegación Funcional a Gestión de Planilla desde el Panel Técnico (Priority: P1)

Como entrenador de club (`UserRole.coach`), quiero que el botón "Gestionar Planilla" en mi Panel Técnico navegue directamente a la pantalla de gestión detallada de plantilla transfiriendo el contexto de mi equipo seleccionado, para administrar la nómina sin pasos intermedios ni mensajes provisionales.

**Why this priority**: Es el punto de entrada principal de la historia; sin navegación funcional desde el Panel Técnico, el entrenador no puede acceder a la gestión de su plantilla desde su flujo operativo habitual.

**Independent Test**: Se puede probar de forma independiente iniciando sesión con rol entrenador y al menos un equipo asignado, pulsando "Gestionar Planilla" en el Panel Técnico y verificando que se abre la pantalla de detalle de plantilla mostrando el nombre, escudo, estado y jugadores de ese equipo específico.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con rol entrenador (`coach`) que tiene al menos un club registrado, **When** pulsa el botón "Gestionar Planilla" en el Panel Técnico, **Then** el sistema selecciona el equipo correspondiente y navega a la pantalla de gestión detallada de plantilla (`/tournaments/teams/detail`) mostrando la información del club.
2. **Given** un entrenador que administra más de un equipo o tiene uno seleccionado en el selector del Panel Técnico, **When** pulsa "Gestionar Planilla", **Then** la pantalla de gestión de plantilla abre exactamente el equipo activo en ese momento.

---

### User Story 2 - Solicitud de Incorporación y Respuesta de Jugadores Registrados (Priority: P1)

Como entrenador, quiero buscar jugadores registrados en la plataforma con rol `player` desde la pantalla de gestión de plantilla y enviarles una solicitud de incorporación indicando dorsal y posición propuesta, para que cada jugador decida si acepta o rechaza unirse a mi club antes de quedar incorporado oficialmente en la nómina.

**Why this priority**: Es la operación central de construcción de plantilla que conecta al entrenador con los futbolistas registrados en la plataforma respetando el consentimiento del jugador.

**Independent Test**: Se puede probar abriendo la pantalla de gestión de plantilla de un equipo del entrenador, pulsando "Agregar Jugador", buscando un usuario con rol `player`, enviando la solicitud con dorsal y posición válidos, iniciando sesión con ese jugador para aceptar la invitación y verificando que ingresa a la nómina del equipo y actualiza el conteo hacia la cuota mínima.

**Acceptance Scenarios**:

1. **Given** que el entrenador se encuentra en la pantalla de gestión de plantilla de su equipo, **When** pulsa "Agregar Jugador", selecciona un jugador registrado con rol `player`, asigna un dorsal disponible (1-99) y posición, y envía la solicitud, **Then** la solicitud queda registrada en estado pendiente (`pending`) y visible como invitación enviada sin sumar todavía a la cuota mínima de 11 jugadores.
2. **Given** que un usuario con rol `player` tiene una o más solicitudes de incorporación pendientes, **When** consulta sus solicitudes y decide **Aceptar** una invitación, **Then** el jugador se incorpora oficialmente a la plantilla del equipo con el dorsal y posición acordados, se persiste el cambio en la nube y localmente, y el contador del equipo se actualiza inmediatamente.
3. **Given** que el usuario con rol `player` decide **Rechazar** la solicitud de incorporación, **When** confirma el rechazo, **Then** la solicitud cambia a estado rechazado (`rejected`), el jugador no ingresa a la plantilla y el dorsal propuesto vuelve a quedar disponible.
4. **Given** que el entrenador intenta enviar una solicitud con un número de dorsal ya ocupado (en plantilla o en otra solicitud pendiente del mismo equipo) o a un jugador que ya pertenece o tiene solicitud pendiente en el equipo, **When** intenta confirmar, **Then** el sistema rechaza la operación y muestra un mensaje claro en español evitando duplicados.
5. **Given** que un usuario con un rol distinto a entrenador (`coach`) visualiza la pantalla de gestión de plantilla, **When** revisa las acciones disponibles, **Then** no puede enviar solicitudes ni mutar la nómina del club (autoridad exclusiva del entrenador).

---

### User Story 3 - Validación de Cuota Mínima y Habilitación del Equipo para Competiciones (Priority: P1)

Como entrenador, quiero consultar el estado de habilitación de mi equipo con respecto a la cuota mínima reglamentaria de 11 jugadores y poder habilitarlo para competiciones una vez alcanzada dicha cuota, para dejar a mi club apto para participar en los torneos y en el sorteo de fixture.

**Why this priority**: Garantiza el cumplimiento de la regla reglamentaria innegociable de 11 jugadores mínimos antes de que un equipo entre en competencia oficial.

**Independent Test**: Se puede probar evaluando un equipo con menos de 11 jugadores (verificando el indicador "No elegible / Faltan jugadores" y el bloqueo de habilitación) y luego un equipo con 11 o más jugadores (verificando que al pulsar "Habilitar para Competiciones" transiciona a estado elegible `eligible`).

**Acceptance Scenarios**:

1. **Given** que el equipo del entrenador cuenta con menos de 11 jugadores registrados (por ejemplo, 8 jugadores), **When** consulta la sección de habilitación en la pantalla de gestión de plantilla, **Then** el sistema muestra el indicador "No elegible / Faltan jugadores" junto con el progreso reglamentario (ej. `8/11 jugadores mínimos`) y bloquea la confirmación de habilitación informando la cuota faltante.
2. **Given** que el equipo alcanza o supera los 11 jugadores debidamente registrados (`>= 11`), **When** el entrenador pulsa la acción "Habilitar para Competiciones", **Then** el equipo transiciona a estado elegible (`eligible`), se persiste el cambio local y remotamente, y el club queda apto para el sorteo de fixture y partidos en los torneos donde esté inscrito.

---

### Edge Cases

- **Doble pulsación rápida**: Si el entrenador pulsa repetidamente "Agregar Jugador" o "Habilitar para Competiciones" mientras una operación está en curso, el sistema bloquea envíos duplicados mostrando estado de carga hasta recibir respuesta.
- **Club independiente sin torneo asignado**: Si el club del entrenador aún no está inscrito en un torneo específico (`tournamentId` vacío), el registro de jugadores y la habilitación deben funcionar igualmente sin fallar por ausencia de torneo, manteniendo persistencia local y sincronización en nube.
- **Conectividad intermitente u offline**: Si la red falla o no hay conexión al registrar un jugador o habilitar el equipo, la operación se conserva de forma segura en almacenamiento local y queda pendiente de sincronización, informando al usuario sin pérdida de datos.
- **Validación de campos de solicitud**: Dorsales fuera del rango 1-99 o selección vacía de jugador/posición deben ser rechazados en el formulario con mensajes claros en español antes de intentar enviar la solicitud.
- **Cancelación o expiración de solicitud pendiente**: El entrenador puede visualizar solicitudes enviadas aún pendientes y cancelarlas si desea liberar el dorsal propuesto antes de que el jugador responda.
- **Salida con cambios sin guardar / navegación**: Al volver desde `TeamRosterDetailScreen` al Panel Técnico, las métricas y contadores de jugadores/elegibilidad del Panel Técnico deben reflejar inmediatamente las actualizaciones realizadas.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El botón "Gestionar Planilla" en `CoachPanelContent` DEBE seleccionar el equipo activo del entrenador y navegar hacia la ruta de detalle de plantilla (`/tournaments/teams/detail` -> `TeamRosterDetailScreen`), reemplazando cualquier notificación provisional.
- **FR-002**: `TeamRosterDetailScreen` DEBE recibir y mostrar la información completa del equipo seleccionado (nombre, código, escudo, estado de elegibilidad, progreso de cuota y lista de jugadores).
- **FR-003**: Solo los usuarios con rol activo `coach` DEBEN poder agregar futbolistas y mutar la plantilla de su equipo en este flujo, restringiendo la mutación de nómina para otros roles.
- **FR-004**: El sistema DEBE permitir al entrenador buscar jugadores registrados en la plataforma con rol `player` y enviarles una solicitud de incorporación al equipo (indicando número de dorsal 1-99 y posición propuesta: `portero`, `defensa`, `mediocampista`, `delantero`), sin permitir el registro manual de jugadores sin cuenta `player`.
- **FR-004b**: El sistema DEBE habilitar una vista o pestaña dedicada dentro de la sección de **Perfil** del usuario con rol `player` donde pueda visualizar sus solicitudes de equipo pendientes y decidir si **acepta** o **rechaza** unirse al club; únicamente al **aceptar** el jugador pasa a formar parte oficial de la plantilla del equipo y suma al conteo de la cuota mínima de 11 jugadores.
- **FR-005**: El sistema DEBE validar que no existan dos jugadores (o solicitudes pendientes) con el mismo número de dorsal ni duplicidad de jugador/documento dentro del mismo equipo.
- **FR-006**: Cada solicitud enviada, respuesta del jugador (`accepted` / `rejected`), incorporación oficial y cambio de habilitación DEBE persistirse localmente (Hive) y sincronizarse con la base de datos remota (`vifutboldev`), soportando tanto clubes inscritos en torneos como clubes base independientes sin torneo asignado.
- **FR-007**: El sistema DEBE evaluar continuamente la cuota reglamentaria mínima de **11 jugadores** (`players.length >= 11`).
- **FR-008**: Cuando el equipo tenga menos de 11 jugadores, el sistema DEBE mostrar un indicador visual claro de estado no elegible ("No elegible / Faltan jugadores", con el conteo actual frente al mínimo, ej. `8/11 jugadores mínimos`) y bloquear la confirmación de la acción "Habilitar para Competiciones".
- **FR-009**: Cuando el equipo tenga 11 o más jugadores registrados, el sistema DEBE habilitar la acción "Habilitar para Competiciones" para el entrenador (`coach`) y permitirle transicionar directamente el estado de su equipo a elegible (`eligible`), conservando el organizador su capacidad de gestión en torneos.
- **FR-010**: Todos los textos visibles, etiquetas, validaciones y retroalimentación al usuario DEBEN estar en español y gestionados mediante localización (`l10n`), cumpliendo con las protecciones móviles de `docs/MOBILE_GUIDELINES.md` (estados de carga/error/vacío, protección contra pulsaciones repetidas y diseño adaptable sin desbordamientos).

### Key Entities

- **Equipo (`TournamentTeam`)**: Representa el club o inscripción del entrenador, incluyendo identificador, torneo asociado (opcional para clubes base), nombre, sigla, estado de elegibilidad (`pendingVerification`, `incompleteRoster`, `eligible`) y la lista inmutable de jugadores registrados.
- **Jugador Registrado (`RegisteredPlayer`)**: Miembro de la plantilla con identificador único, nombre completo, documento de identidad (y su versión normalizada), número de dorsal (1-99), posición táctica y estado de elegibilidad individual.
- **Solicitud de Incorporación (`TeamJoinRequest`)**: Invitación enviada por un entrenador a un jugador con rol `player` para unirse a un equipo específico, incluyendo equipo origen, jugador destino, dorsal propuesto, posición propuesta, estado (`pending`, `accepted`, `rejected`, `cancelled`) y marcas de tiempo.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las pulsaciones sobre "Gestionar Planilla" en el Panel Técnico navegan exitosamente en menos de 300 ms a la vista de gestión de plantilla con el equipo correcto cargado.
- **SC-002**: El entrenador puede completar el registro de un nuevo jugador válido en menos de 30 segundos, reflejando el nuevo conteo en la interfaz inmediatamente tras confirmar.
- **SC-003**: El 100% de los intentos de habilitación con menos de 11 jugadores son bloqueados antes de modificar el estado del equipo, mostrando el conteo exacto de jugadores faltantes.
- **SC-004**: El 100% de los intentos de registro con dorsal o documento duplicado dentro del mismo equipo son rechazados sin corromper la nómina ni generar registros huérfanos.
- **SC-005**: Todas las mutaciones de plantilla y habilitación permanecen consistentes tras reiniciar la aplicación o sincronizar con la nube.

## Assumptions

- El rol `coach` ya cuenta con un flujo previo para crear o tener asignado al menos un equipo (cuando no tiene equipo, `CoachPanelContent` ya muestra la tarjeta correspondiente).
- La cuota mínima reglamentaria para habilitación de equipos en competiciones es fija en 11 jugadores, en línea con la Regla de Negocio 2 de la HU 20.1 y HU 16.3.
- El cálculo de elegibilidad individual de jugadores y las reglas de fixture consumen el estado `eligible` del equipo una vez habilitado.
