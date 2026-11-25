# Especificación de Funcionalidad: Notificación en el AppBar al Árbitro al Asignarle un Partido

**Feature Branch**: `060-referee-match-assignment-notification`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 26.2: Notificación en el AppBar al Árbitro al Asignarle un Partido"

## Clarifications

### Session 2026-11-25

- Q: Al tocar una notificación de "Nuevo partido asignado" en la bandeja, ¿cuál debe ser el destino principal de navegación para el árbitro? → A: Abrir directamente el acta del partido asignado cuando el encuentro esté disponible, con respaldo automático al Panel del Árbitro si el partido no está cargado o ya no existe.
- Q: Cuando un organizador reasigna un partido del árbitro A al árbitro B, ¿debe notificarse únicamente al nuevo árbitro B o también enviar un aviso de desasignación al árbitro A? → A: Solo notificar al nuevo árbitro B con "Nuevo partido asignado"; no se genera notificación de desasignación al árbitro A.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generación de notificación e indicador numérico en el AppBar al asignar un partido (Priority: P1)

Como árbitro registrado en ViFutbol, quiero que se genere automáticamente una notificación dirigida a mi cuenta cuando un organizador me asigne o reasigne un partido, y ver el contador de notificaciones no leídas en el icono de campana de la barra superior, para enterarme oportunamente de mis nuevas designaciones arbitrales.

**Why this priority**: Es el disparador y la señal principal de visibilidad; sin la creación automática de la notificación dirigida al árbitro y el badge numérico en la barra superior, el árbitro no descubre sus nuevas designaciones sin revisar manualmente su panel.

**Independent Test**: Se puede probar de forma independiente haciendo que un organizador asigne un partido a un árbitro, iniciando sesión o actualizando la sesión con la cuenta de ese árbitro y verificando que el icono de notificaciones en la barra superior muestra el badge numérico incrementado con la nueva notificación no leída.

**Acceptance Scenarios**:

1. **Given** un organizador programa un partido y selecciona a un árbitro vinculado a una cuenta de usuario, **When** guarda la programación del partido, **Then** el sistema genera y persiste una notificación de tipo "Asignación de partido" dirigida exclusivamente a la cuenta de usuario de ese árbitro.
2. **Given** el árbitro destinatario abre o actualiza la aplicación autenticado con su rol de árbitro, **When** se carga la barra superior principal, **Then** el icono de notificaciones (campana) está visible y muestra un distintivo numérico con el total de notificaciones no leídas, incluyendo la nueva asignación.
3. **Given** el organizador cambia el árbitro asignado de un partido (del árbitro A al árbitro B), **When** guarda la reasignación, **Then** el árbitro B recibe una nueva notificación de partido asignado.

---

### User Story 2 - Visualización del detalle de la designación en la bandeja de notificaciones (Priority: P1)

Como árbitro con una o más notificaciones de partido asignado, quiero abrir la bandeja de notificaciones desde la campana de la barra superior y leer con claridad los datos esenciales del encuentro (equipos enfrentados, torneo, fecha/hora en horario de Colombia y sede/cancha), para conocer de inmediato los detalles de mi designación.

**Why this priority**: Una notificación sin contexto claro obliga al usuario a buscar manualmente el encuentro; mostrar los datos reales del partido dentro de la bandeja entrega valor inmediato.

**Independent Test**: Se puede probar de forma independiente tocando el icono de notificaciones en la barra superior de un árbitro con una asignación no leída y verificando que se despliega la bandeja mostrando el título "Nuevo partido asignado", los nombres reales de los equipos (local vs visitante), torneo, fecha/hora y cancha, junto con su estado visual de no leída.

**Acceptance Scenarios**:

1. **Given** un árbitro tiene una notificación no leída de partido asignado, **When** presiona el icono de notificaciones en la barra superior, **Then** se abre la bandeja de notificaciones mostrando el título "Nuevo partido asignado" y un mensaje claro en español con los equipos enfrentados (local vs visitante), nombre del torneo, fecha/hora en horario de Colombia y sede/cancha asignada.
2. **Given** un árbitro tiene varias notificaciones (leídas y no leídas), **When** abre la bandeja de notificaciones, **Then** las notificaciones aparecen ordenadas de la más reciente a la más antigua y las no leídas se distinguen visualmente sin depender únicamente del color.
3. **Given** un árbitro no tiene notificaciones registradas, **When** abre la bandeja de notificaciones, **Then** visualiza un estado vacío claro en español.

---

### User Story 3 - Marcado como leída y navegación directa al tocar la notificación (Priority: P1)

Como árbitro que revisa una notificación de partido asignado en la bandeja, quiero que al seleccionarla se marque automáticamente como leída, se actualice el contador de la campana y se me redirija al partido asignado o al Panel del Árbitro, para gestionar mi designación en un solo toque.

**Why this priority**: Cierra el ciclo de acción de la notificación conectando directamente el aviso con el flujo operativo arbitral de HU 26.1.

**Independent Test**: Se puede probar tocando una notificación no leída de partido asignado en la bandeja y verificando que su estado cambia a leída, que el badge del icono de campana se decrementa (o desaparece si llega a cero) y que la navegación abre el acta/detalle del partido asignado (o el Panel del Árbitro si el partido no está cargado localmente).

**Acceptance Scenarios**:

1. **Given** el árbitro visualiza una notificación no leída de partido asignado en la bandeja, **When** selecciona dicha notificación, **Then** la notificación se marca como leída de inmediato, el contador del badge en la barra superior se decrementa y la bandeja se cierra navegando al partido asignado o al Panel del Árbitro.
2. **Given** el árbitro presiona "Marcar todas como leídas" en la bandeja cuando tiene varias notificaciones no leídas, **When** se confirma la acción, **Then** todas sus notificaciones pasan a estado leído y el contador del badge desaparece.
3. **Given** el árbitro vuelve a abrir la aplicación después de haber marcado una notificación como leída, **When** se sincroniza con la nube, **Then** la notificación permanece marcada como leída sin reaparecer como no leída.

---

### User Story 4 - Idempotencia, privacidad por usuario y resiliencia offline (Priority: P2)

Como organizador o árbitro operando en condiciones reales de red móvil, quiero que editar otros campos de un partido sin cambiar de árbitro no genere notificaciones duplicadas, que cada árbitro solo vea y gestione sus propias notificaciones y que las notificaciones sincronizadas permanezcan consultables sin conexión.

**Why this priority**: Evita fatiga por notificaciones duplicadas, protege la privacidad entre usuarios y garantiza disponibilidad offline consistente con las directrices móviles.

**Independent Test**: Se puede probar editando horario/cancha de un partido ya asignado al árbitro A sin cambiar de árbitro y verificando 0 notificaciones nuevas; validando que el árbitro B no ve las notificaciones del árbitro A; y verificando que las notificaciones ya recibidas pueden consultarse y marcarse como leídas offline con sincronización posterior.

**Acceptance Scenarios**:

1. **Given** un partido ya está asignado al árbitro A, **When** el organizador edita la fecha, hora o cancha del partido sin cambiar el árbitro asignado, **Then** el sistema no genera una notificación duplicada de asignación para el árbitro A.
2. **Given** el árbitro A recibió una notificación de partido asignado, **When** el árbitro B inicia sesión en la aplicación, **Then** el árbitro B no puede ver, leer ni modificar las notificaciones dirigidas al árbitro A.
3. **Given** un árbitro ya recibió una notificación y queda sin conexión a internet, **When** abre la bandeja de notificaciones y marca la notificación como leída, **Then** el cambio se refleja localmente de inmediato y se sincroniza con la nube al recuperar conectividad.

---

### Edge Cases

- **Árbitro sin cuenta de usuario vinculada**: Si un organizador asigna un partido a un registro arbitral antiguo que aún no tiene una cuenta de usuario vinculada, la programación del partido debe completarse normalmente sin lanzar errores ni crear notificaciones huérfanas.
- **Reasignación de vuelta al mismo árbitro o cambios repetidos**: Si el organizador cambia del árbitro A al árbitro B y posteriormente vuelve a asignar el partido al árbitro A, cada cambio real de árbitro genera una notificación legítima al nuevo destinatario sin fallar por colisiones.
- **Partido cancelado o eliminado tras la notificación**: Si el árbitro toca una notificación cuyo partido ya no se encuentra disponible localmente, el sistema navega de forma segura al Panel del Árbitro mostrando la lista actualizada sin fallar ni cerrar la aplicación.
- **Contador alto de notificaciones**: Si el árbitro acumula más de 99 notificaciones no leídas, el badge de la campana muestra un indicador compacto (`99+`) sin desbordar la barra superior.
- **Doble toque rápido en la notificación**: Pulsar rápidamente dos veces una notificación en la bandeja debe abrir el destino una sola vez y marcarla como leída de forma idempotente (`single-flight`).
- **Accesibilidad y escalado de texto**: El icono de campana debe cumplir con área táctil mínima accesible, anunciar en lectores de pantalla la cantidad de notificaciones no leídas en español y la bandeja debe adaptarse al escalado de texto sin desbordamientos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Cuando un organizador asigne un árbitro a un partido (al crear la programación o al reasignar a un árbitro diferente), el sistema DEBE generar automáticamente una notificación de tipo "Asignación de partido" dirigida únicamente a la cuenta de usuario vinculada al nuevo árbitro asignado (sin generar aviso de desasignación al árbitro anterior).
- **FR-002**: Si un organizador edita otros campos de un partido ya programado (fecha, hora, cancha o sede) sin cambiar el árbitro asignado, el sistema NO DEBE generar una notificación duplicada de asignación para el mismo árbitro.
- **FR-003**: Si el árbitro asignado no tiene una cuenta de usuario vinculada, el sistema DEBE completar la programación del partido normalmente sin fallos y omitir la creación de notificación.
- **FR-004**: Las notificaciones de asignación arbitral DEBEN persistirse en la nube con aislamiento estricto por usuario destinatario (cada usuario solo puede leer y marcar como leídas sus propias notificaciones) y sincronizarse con el almacenamiento local para consulta offline.
- **FR-005**: El icono de notificaciones (campana) en la barra superior principal DEBE estar visible y habilitado para usuarios autenticados con rol activo `Árbitro`, mostrando un badge numérico con el total de notificaciones no leídas (o `99+` si supera 99).
- **FR-006**: Al abrir la bandeja de notificaciones, cada notificación de asignación arbitral DEBE mostrarse en español con el título "Nuevo partido asignado" y un resumen que incluya nombres reales de los equipos (local vs visitante), nombre del torneo, fecha/hora en horario de Colombia y sede/cancha (cuando esté definida), ordenada de la más reciente a la más antigua.
- **FR-007**: Al tocar una notificación de asignación arbitral en la bandeja, el sistema DEBE marcarla automáticamente como leída, actualizar inmediatamente el contador del badge en la barra superior, cerrar la bandeja y abrir directamente el acta del partido asignado cuando el encuentro esté disponible (o navegar al Panel del Árbitro como respaldo seguro si el partido no está cargado o ya no existe).
- **FR-008**: La bandeja de notificaciones DEBE permitir marcar todas las notificaciones del usuario como leídas y actualizar el estado tanto localmente como en la nube.
- **FR-009**: Las notificaciones ya sincronizadas DEBEN poder consultarse y marcarse como leídas sin conexión a internet, sincronizando el estado de lectura con la nube al recuperar conectividad.
- **FR-010**: La navegación y el marcado como leído al tocar una notificación DEBEN protegerse contra doble toque rápido (`single-flight`) para evitar aperturas duplicadas de pantallas.
- **FR-011**: Todos los textos visibles de la campana, el badge, la bandeja, títulos, descripciones, estados vacíos y etiquetas de accesibilidad DEBEN presentarse en español centralizado y adaptarse al escalado de texto del sistema.

### Key Entities *(include if feature involves data)*

- **Notificación de Asignación Arbitral**: Alerta persistente dirigida a un usuario destinatario específico (`destinatario`), vinculada al partido asignado y al torneo, con tipo `Asignación de partido`, título, mensaje descriptivo (equipos, torneo, fecha/hora, cancha), fecha de creación y estado de lectura (`leída` / `no leída`).
- **Partido Asignado**: Encuentro programado por un organizador con referencia al árbitro designado; el cambio de árbitro asignado actúa como evento disparador de la notificación.
- **Cuenta de Usuario del Árbitro**: Identidad autenticada vinculada al perfil arbitral que recibe, consulta y marca como leídas sus notificaciones desde la barra superior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las asignaciones y reasignaciones de partidos a árbitros con cuenta vinculada generan exactamente una notificación dirigida al nuevo árbitro asignado, y el 0% de las ediciones sin cambio de árbitro generan duplicados.
- **SC-002**: El árbitro visualiza el badge numérico actualizado en la barra superior al abrir o refrescar la aplicación y puede acceder al detalle completo de la designación en la bandeja en 1 toque.
- **SC-003**: Al seleccionar una notificación de partido asignado, el 100% de los casos decrementan el contador de no leídas inmediatamente y navegan al partido asignado o al Panel del Árbitro sin errores ni pantallas duplicadas.
- **SC-004**: El 100% de las notificaciones permanecen aisladas por destinatario (ningún otro usuario puede leer o alterar las notificaciones de un árbitro) y el estado de lectura se conserva tras recargar o reconectar después de operar sin conexión.

## Assumptions

- **Mecanismo de entrega dentro de la app**: Esta historia cubre notificaciones dentro de la aplicación (icono de campana con badge y bandeja en la barra superior, respaldadas por persistencia en nube y caché local); notificaciones push nativas del sistema operativo (FCM/APNs con la app cerrada) quedan fuera del alcance de HU 26.2.
- **Reasignación del árbitro anterior**: Cuando un organizador cambia un partido del árbitro A al árbitro B, el alcance de esta historia exige notificar al nuevo árbitro B; una notificación adicional de "desasignación" para el árbitro A no es requerida salvo que se defina en `/speckit-clarify`.
- **Reutilización de la bandeja de notificaciones del AppBar**: Se reutilizará y extenderá la experiencia existente de campana y bandeja de notificaciones en la barra superior para unificar alertas de la aplicación bajo un solo punto de acceso.
- **Zona horaria oficial**: La fecha y hora mostradas en el texto de la notificación se formatean en horario de Colombia (`America/Bogota`, UTC-5).
