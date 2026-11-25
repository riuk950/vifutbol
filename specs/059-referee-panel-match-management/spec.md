# Especificación de Funcionalidad: Panel del Árbitro — Lista de Partidos Asignados y Gestión Completa hasta el Cierre

**Feature Branch**: `059-referee-panel-match-management`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 26.1: Panel del Árbitro: Lista de Partidos Asignados y Gestión Completa del Partido hasta el Cierre"

## Clarifications

### Session 2026-11-25

- Q: ¿Cómo deben ordenarse y presentarse los partidos asignados en el Panel del Árbitro cuando existen partidos `En juego`, `Programado` y `Finalizado`? → A: Orden operativo con filtros: `En juego` primero, luego `Programado` (ascendente por fecha/hora) y al final `Finalizado` (descendente), con chips de filtro (`Todos`, `En juego`, `Programados`, `Finalizados`).
- Q: ¿Debe poder el árbitro iniciar un partido `Programado` si uno o ambos entrenadores aún no han confirmado su convocatoria oficial? → A: Sí; permitir iniciar el partido usando la plantilla inscrita de cada equipo como respaldo y mostrar un aviso informativo no bloqueante cuando falte una convocatoria oficial.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lista actualizada de partidos asignados en el Panel del Árbitro (Priority: P1)

Como árbitro registrado en ViFutbol, quiero visualizar en mi Panel del Árbitro la lista actualizada y ordenada cronológicamente de todos los partidos que los organizadores me han asignado a través de todos los torneos, con información clara y legible de cada encuentro, para identificar rápidamente qué partidos debo dirigir, cuándo y dónde se juegan.

**Why this priority**: Es el punto de entrada operativo del árbitro; sin listar con precisión los partidos asignados y sus datos reales (equipos, sede, fecha/hora y estado), el árbitro no puede iniciar ni gestionar ningún encuentro.

**Independent Test**: Se puede probar de forma independiente asignando uno o más partidos de distintos torneos a un árbitro, iniciando sesión con esa cuenta, abriendo el Panel del Árbitro y verificando que todos los partidos aparecen ordenados cronológicamente con nombres reales de equipos, torneo, jornada, fecha/hora en horario de Colombia, sede/cancha, estado actual y soporte de actualización manual (deslizar para refrescar).

**Acceptance Scenarios**:

1. **Given** un árbitro autenticado al cual un organizador le ha programado y asignado uno o más partidos en uno o varios torneos, **When** abre el Panel del Árbitro, **Then** visualiza la lista de todos sus partidos asignados ordenados cronológicamente, sin mostrar partidos asignados a otros árbitros.
2. **Given** un partido asignado visible en el Panel del Árbitro, **When** se renderiza su tarjeta, **Then** muestra los nombres reales de los equipos (local vs visitante, nunca identificadores técnicos crudos), nombre del torneo y jornada, fecha y hora programada en horario de Colombia, sede/cancha y estado actual (`Programado`, `En juego` o `Finalizado`).
3. **Given** un árbitro autenticado que aún no tiene partidos asignados, **When** abre el Panel del Árbitro, **Then** visualiza un estado vacío claro en español indicando que todavía no tiene designaciones y la opción de actualizar la lista.
4. **Given** un árbitro en su Panel que realiza el gesto de actualizar, **When** el organizador acaba de asignarle un nuevo partido o actualizar un horario, **Then** la lista se refresca mostrando los cambios más recientes sin duplicar registros.

---

### User Story 2 - Inicio del partido y registro completo del desarrollo del juego (Priority: P1)

Como árbitro que selecciona un partido asignado en estado `Programado` desde mi Panel, quiero abrir su acta digital con las plantillas de ambos equipos cargadas, iniciar el partido y registrar todo el desarrollo del encuentro (goles, asistencias, tarjetas amarillas y rojas con control de doble amarilla, sustituciones, transiciones de periodo y observaciones arbitrales), para documentar en tiempo real cada incidencia oficial del juego.

**Why this priority**: Representa el núcleo funcional de la labor arbitral durante el encuentro y alimenta directamente el marcador oficial y las estadísticas deportivas del torneo.

**Independent Test**: Se puede probar de forma independiente seleccionando un partido `Programado` desde el Panel del Árbitro, iniciándolo, registrando al menos un gol con asistencia, una tarjeta amarilla, una doble amarilla o roja, una sustitución, transiciones de periodo (`Primer Tiempo` → `Entretiempo` → `Segundo Tiempo`) y observaciones arbitrales, verificando que el marcador y la línea de tiempo se actualizan de inmediato.

**Acceptance Scenarios**:

1. **Given** un árbitro que selecciona un partido asignado en estado `Programado` desde su Panel, **When** accede al acta digital del encuentro, **Then** visualiza las plantillas/convocatorias disponibles de ambos equipos y puede ejecutar la acción de iniciar partido.
2. **Given** el árbitro presiona iniciar partido en un encuentro `Programado`, **When** se procesa la transición, **Then** el partido pasa a estado `En juego` (`Primer Tiempo`) y se habilitan las acciones de registro de eventos del partido.
3. **Given** un partido en estado `En juego`, **When** el árbitro registra goles (con o sin asistencia), tarjetas amarillas, tarjetas rojas (incluyendo expulsión automática o validación por doble amarilla), sustituciones, cambios de periodo (`Entretiempo`, `Segundo Tiempo` y tiempo adicional si aplica) y observaciones arbitrales, **Then** cada evento queda registrado con su minuto y periodo, actualizando el marcador y la línea de tiempo en tiempo real.
4. **Given** un partido en estado `En juego`, **When** el árbitro pulsa repetidamente el botón de iniciar, registrar un evento o cambiar de periodo mientras la acción está en curso, **Then** el sistema bloquea envíos duplicados hasta completar la operación actual.

---

### User Story 3 - Finalización y cierre oficial del acta del partido (Priority: P1)

Como árbitro que ha terminado de dirigir un partido en curso y registró todas sus incidencias, quiero confirmar el cierre oficial del acta digital para que el encuentro pase a estado `Finalizado` con su marcador definitivo, quede protegido contra modificaciones posteriores y actualice la información oficial del campeonato.

**Why this priority**: Sin el cierre formal e inmutable del acta, el resultado no se consolida en el campeonato ni queda reflejado como finalizado en el Panel del Árbitro y las tablas de posiciones.

**Independent Test**: Se puede probar de forma independiente finalizando un partido en curso con eventos registrados, confirmando el diálogo de cierre, verificando que el acta pasa a modo solo lectura con el marcador definitivo, que no permite agregar ni alterar eventos posteriores y que al volver al Panel del Árbitro el partido aparece como `Finalizado`.

**Acceptance Scenarios**:

1. **Given** un partido en estado `En juego` con sus eventos registrados, **When** el árbitro selecciona finalizar partido y confirma el cierre oficial del acta, **Then** el partido cambia a estado `Finalizado` con el marcador definitivo persistido tanto en el dispositivo como en la nube, y se disparan las actualizaciones de clasificación correspondientes.
2. **Given** un partido cuyo cierre oficial fue confirmado, **When** el árbitro permanece en el acta o vuelve a abrirlo posteriormente desde su Panel, **Then** el acta se presenta en modo solo lectura impidiendo agregar, editar o eliminar eventos, o reiniciar el encuentro.
3. **Given** el árbitro confirma el cierre del partido y regresa al Panel del Árbitro, **When** observa la tarjeta de ese encuentro, **Then** el estado mostrado es `Finalizado` junto con el marcador final oficial.
4. **Given** el árbitro presiona finalizar partido pero cancela en el diálogo de confirmación, **When** vuelve al acta, **Then** el partido continúa `En juego` sin cerrarse ni perder ningún evento registrado.

---

### User Story 4 - Operación offline-first, propiedad de acceso y resiliencia móvil (Priority: P2)

Como árbitro que dirige partidos en canchas urbanas con señal móvil intermitente o sin conexión a internet, quiero poder iniciar el partido, registrar todos los eventos y cerrar el acta sin conexión con sincronización automática al recuperar conectividad, sabiendo además que solo el árbitro asignado (o un organizador autorizado) puede modificar el acta.

**Why this priority**: En el contexto real de fútbol aficionado y canchas locales, la conectividad suele ser inestable; garantizar cero pérdida de datos offline y estricta segregación de permisos protege la integridad del campeonato.

**Independent Test**: Se puede probar desconectando la red antes de iniciar un partido asignado previamente cargado, ejecutando inicio, registro de eventos y cierre offline, verificando la persistencia local inmediata, reconectando para confirmar la sincronización automática sin duplicados, y validando que otro árbitro no asignado no puede editar ni cerrar el acta.

**Acceptance Scenarios**:

1. **Given** un árbitro autenticado sin conexión a internet que abre un partido asignado previamente disponible en el dispositivo, **When** inicia el partido, registra goles/tarjetas/sustituciones/periodos/observaciones y cierra el acta, **Then** todos los cambios se persisten localmente de inmediato sin bloqueos ni pérdida de datos y quedan pendientes de sincronización.
2. **Given** un partido gestionado y cerrado sin conexión, **When** el dispositivo recupera conectividad a internet, **Then** los eventos, transiciones de periodo y cierre final se sincronizan automáticamente con la nube de forma idempotente sin duplicar eventos ni alterar el marcador final.
3. **Given** un usuario autenticado con rol árbitro que NO es el árbitro asignado a un partido (ni organizador autorizado del torneo), **When** intenta iniciar, registrar eventos o cerrar ese partido, **Then** el sistema rechaza la operación con un mensaje claro en español y protege los datos del encuentro.
4. **Given** un árbitro en medio de un partido cuya aplicación pasa temporalmente a segundo plano (por ejemplo, al recibir una llamada), **When** regresa a la aplicación, **Then** el estado actual del partido, el periodo, el marcador y todos los eventos registrados se conservan intactos.

---

### Edge Cases

- **Árbitro vinculado por identidad arbitral o cuenta**: Si un partido fue asignado por el organizador usando el registro arbitral vinculado a la cuenta del usuario (o su identificador de usuario como respaldo), el partido debe aparecer correctamente en su Panel sin quedar oculto por desajuste de identificadores.
- **Partidos sin convocatoria confirmada por los entrenadores**: Si un equipo aún no confirmó convocatoria formal pero tiene jugadores inscritos en su plantilla del torneo, el acta digital permite consultar la plantilla disponible del equipo o mostrar un aviso claro en español si el equipo no tiene jugadores registrados.
- **Doble tarjeta amarilla**: Al registrar una segunda tarjeta amarilla al mismo jugador en el mismo partido, el sistema debe reflejar la expulsión correspondiente de forma consistente y no permitir registrar eventos incompatibles según las reglas vigentes del acta.
- **Nombres de equipos o sedes no cacheados inicialmente**: Si al cargar los partidos aún no está en caché el catálogo de equipos o sedes, el sistema resuelve los nombres reales antes o durante la carga y, solo ante fallo extremo irrecuperable, muestra una etiqueta legible en español (nunca UUIDs crudos).
- **Ordenamiento y filtros cronológicos**: Cuando un árbitro tiene partidos pasados (`Finalizado`), en curso (`En juego`) y futuros (`Programado`), el ordenamiento debe priorizar la visibilidad operativa clara (por fecha/hora programada en zona horaria de Colombia) y reflejar de inmediato cualquier transición de estado.
- **Cancelación y recuperación ante error de red al refrescar**: Si el árbitro intenta refrescar la lista sin conexión, el Panel conserva los partidos previamente cargados en caché local y muestra un aviso no bloqueante en español.
- **Accesibilidad y escalado de texto**: Las tarjetas del Panel del Árbitro y los controles del acta digital deben adaptarse a distintos tamaños de pantalla y escalado de texto del sistema sin desbordamientos, con etiquetas claras en español y contraste legible (sin depender únicamente del color para distinguir estados).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El Panel del Árbitro DEBE consultar y listar todos los partidos asignados al árbitro autenticado a través de todos los torneos (tanto desde el origen remoto como desde el almacenamiento local), emparejando por su identificador arbitral vinculado y usando el identificador de cuenta como respaldo.
- **FR-002**: Cada tarjeta de partido en el Panel del Árbitro DEBE mostrar: nombres reales del equipo local y visitante (nunca identificadores técnicos crudos), nombre del torneo y número de jornada, fecha y hora programada en horario de Colombia, sede/cancha asignada y estado actual del partido (`Programado`, `En juego`, `Finalizado`), además del marcador cuando aplique.
- **FR-003**: El Panel del Árbitro DEBE ordenar los partidos asignados priorizando `En juego` primero, luego `Programado` en orden ascendente por fecha/hora y finalmente `Finalizado` en orden descendente, ofrecer chips de filtro por estado (`Todos`, `En juego`, `Programados`, `Finalizados`), soportar actualización manual mediante gesto de refresco y mostrar estados claros de carga, contenido, vacío y error en español.
- **FR-004**: Al seleccionar una tarjeta de partido o su acción principal en el Panel del Árbitro, el sistema DEBE abrir el acta digital de ese encuentro con la información del partido y las plantillas/convocatorias disponibles de ambos equipos cargadas.
- **FR-005**: Desde el acta digital de un partido en estado `Programado`, el árbitro asignado DEBE poder iniciar el encuentro, transicionando su estado a `En juego` (`Primer Tiempo`) y habilitando el registro de eventos; si algún equipo aún no confirmó convocatoria oficial, el acta DEBE permitir el inicio cargando como respaldo la plantilla inscrita de ese equipo y mostrando un aviso informativo no bloqueante en español.
- **FR-006**: Durante un partido `En juego`, el árbitro asignado DEBE poder registrar goles, asistencias, tarjetas amarillas, tarjetas rojas (incluyendo gestión de doble amarilla), sustituciones, transiciones de periodo (`Primer Tiempo`, `Entretiempo`, `Segundo Tiempo` y tiempo adicional si aplica) y observaciones arbitrales, actualizando en tiempo real el marcador y la línea de tiempo.
- **FR-007**: El árbitro asignado DEBE poder finalizar el encuentro mediante una confirmación explícita de cierre oficial que marque el partido como `Finalizado`, consolide el marcador definitivo, actualice las estadísticas y tablas de clasificación derivadas y bloquee toda edición posterior (modo solo lectura).
- **FR-008**: Al regresar al Panel del Árbitro después de iniciar o finalizar un partido, la lista DEBE reflejar de inmediato el nuevo estado y el marcador actualizado del encuentro.
- **FR-009**: El sistema DEBE hacer cumplir la segregación de roles y propiedad: únicamente el árbitro asignado al partido o un organizador autorizado puede iniciar el encuentro, registrar/modificar eventos, cambiar periodos y cerrar el acta oficial.
- **FR-010**: Todas las transiciones de estado del partido, eventos registrados y el cierre del acta DEBEN operar bajo enfoque offline-first: guardarse localmente de inmediato y sincronizarse automáticamente con la nube al existir o recuperarse la conectividad, garantizando idempotencia sin duplicados.
- **FR-011**: Las acciones críticas del flujo (refresco del panel, inicio del partido, registro de eventos, cambio de periodo y cierre del acta) DEBEN implementar protección contra envíos duplicados (`single-flight`) mientras una operación está en curso.
- **FR-012**: El estado del partido en curso (periodo, marcador, eventos y observaciones guardadas) DEBE preservarse ante cambios al segundo plano o reapertura de la pantalla sin pérdida de información.
- **FR-013**: Todos los textos visibles de la interfaz, estados de partido, etiquetas de eventos, diálogos de confirmación y mensajes de error DEBEN presentarse en español centralizado y cumplir con accesibilidad básica (contraste legible, etiquetas descriptivas y adaptación al escalado de texto).

### Key Entities *(include if feature involves data)*

- **Partido Asignado (Designación Arbitral)**: Encuentro perteneciente a un campeonato y jornada específicos, vinculado a un equipo local, un equipo visitante, una sede/cancha, una fecha/hora programada, un árbitro asignado (mediante su registro arbitral), un estado de ciclo de vida (`Programado`, `En juego`, `Finalizado`) y un marcador oficial.
- **Acta Digital del Partido**: Registro oficial asociado uno a uno a un partido, compuesto por su periodo actual, línea de tiempo de eventos deportivos (goles, asistencias, tarjetas amarillas/rojas, sustituciones), observaciones arbitrales y bandera de cierre inmutable.
- **Árbitro (Identidad Arbitral Vinculada)**: Perfil del usuario con rol activo de árbitro vinculado a su registro arbitral oficial en los torneos, utilizado para resolver qué partidos tiene designados y autorizar la gestión de sus actas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los partidos asignados a un árbitro en cualquier torneo aparecen en su Panel del Árbitro con nombres reales de equipos, sede, fecha/hora de Colombia y estado correcto en menos de 2 segundos bajo conectividad estándar (o de forma inmediata desde caché local).
- **SC-002**: Un árbitro puede ejecutar el ciclo completo de un partido (seleccionar partido asignado → iniciar → registrar goles, asistencias, tarjetas, sustituciones, periodos y observaciones → confirmar cierre) en un flujo continuo sin errores bloqueantes ni necesidad de salir a otras pantallas.
- **SC-003**: El 100% de los partidos cerrados oficialmente pasan a modo solo lectura impidiendo modificaciones posteriores y reflejan inmediatamente el estado `Finalizado` y el marcador definitivo al regresar al Panel del Árbitro.
- **SC-004**: El 100% de las acciones ejecutadas sin conexión (inicio, registro de eventos y cierre de acta) se conservan localmente sin pérdida de datos y se sincronizan sin duplicados al recuperar conectividad.
- **SC-005**: Cero operaciones duplicadas ante pulsaciones repetidas sobre iniciar partido, registrar evento o finalizar acta, y 100% de bloqueo de edición frente a usuarios que no sean el árbitro asignado ni un organizador autorizado.

## Assumptions

- **Dependencia de infraestructura existente de actas y partidos**: La aplicación ya dispone de un flujo base de acta digital, registro de eventos y sincronización offline-first; esta historia garantiza su integración completa de extremo a extremo desde el Panel del Árbitro (resolución de designaciones multi-torneo, datos legibles en tarjetas, ciclo completo hasta cierre y sincronización).
- **Alcance de notificaciones**: Las notificaciones en la barra superior al asignar un partido a un árbitro pertenecen a la historia siguiente (HU 26.2) y quedan fuera del alcance de esta especificación.
- **Zona horaria oficial**: Todas las fechas y horas de partidos se presentan al usuario en zona horaria de Colombia (`America/Bogota`, UTC-5), consistente con el resto de la plataforma ViFutbol.
- **Irreversibilidad del cierre arbitral**: Una vez cerrado oficialmente el acta por el árbitro, el acta es de solo lectura para el árbitro; cualquier eventual reapertura administrativa extraordinaria (si existiera) queda fuera del flujo arbitral estándar.
- **Requisito de perfil completo**: Esta historia no introduce bloqueos adicionales sobre el estado de completitud del perfil del árbitro (cubierto en HU 25.1 y HU 25.2); cualquier árbitro con partidos asignados puede visualizarlos y gestionarlos desde su Panel.
