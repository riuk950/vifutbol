# Feature Specification: Rediseño de la Vista Partidos (Feed Diario por Competición, Selector de Calendario y Pestañas Ayer/Hoy/Mañana)

**Feature Branch**: `015-matches-daily-feed`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "[Épica 11] HU 11.1: Rediseño de Vista Partidos (Match Center Stitch, Selector de Fecha por Calendario y Pestañas Ayer/Hoy/Mañana) — Notion (En curso). La vista Partidos debe parecerse a la pantalla `vifutbol - Partidos` de Stitch, mostrar las competiciones y sus partidos del día, incluir un icono de calendario junto al icono de notificaciones para elegir una fecha, y tres pestañas bajo la barra superior (Ayer, Hoy, Mañana); al abrir la aplicación siempre se ven los partidos del día con la pestaña Hoy activa."

## Clarifications

### Session 2026-11-06
- Q: ¿Dónde deben quedar las acciones de "Generar calendario" y "Programar partidos pendientes" que hoy viven en la vista Partidos? → A: En el propio feed diario, como un aviso/acceso visible solo para el Organizador ("X partidos pendientes de programar").
- Q: ¿Qué competiciones deben aparecer en el feed diario según su estado? → A: Solo competiciones activas (en inscripción o en curso); las finalizadas o con temporada cerrada no aparecen nunca, en ninguna fecha.
- Q: ¿Las competiciones o equipos que el usuario marcó como favoritos deben aparecer primero en el feed diario? → A: No en esta fase; la priorización y destacados por favoritos quedan explícitamente fuera de alcance y se integrarán más adelante.
- Q: ¿Qué debe ocurrir al tocar el encabezado de una competición en el feed diario? → A: Navegar a la pantalla de detalle de la competición en el directorio (`/competitions/:id`), permitiendo consultar tabla, llaves y fixture completo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Feed diario de Hoy agrupado por competición (Priority: P1) 🎯 MVP

Como usuario de cualquiera de los cinco roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`), al abrir la aplicación o entrar a la pestaña **Partidos** quiero ver de inmediato los partidos del día actual, organizados en bloques por competición (torneo), cada uno con su encabezado, para saber de un vistazo qué se juega hoy y en qué competición.

**Why this priority**: Es el núcleo de la HU: reemplaza la vista actual (centrada en un único torneo seleccionado) por un feed diario multi-competición. Sin esto, el resto de controles (pestañas, calendario) no tiene contenido que filtrar.

**Independent Test**: Con datos de prueba que contengan partidos de hoy en al menos dos competiciones y partidos en otros días, abrir la aplicación y verificar que la pestaña "Hoy" está activa, que solo aparecen partidos de hoy, agrupados bajo el encabezado de su competición, y que las competiciones sin partidos hoy no aparecen.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado que abre la aplicación, **When** se carga la pestaña "Partidos", **Then** la pestaña "Hoy" aparece seleccionada y la lista muestra únicamente los partidos cuya fecha programada corresponde al día actual en la zona horaria del dispositivo.
2. **Given** que hoy hay partidos en las competiciones "Liga Clausura" y "Copa Ciudad", **When** el usuario visualiza el feed, **Then** cada competición se presenta como un bloque independiente con un encabezado que muestra su nombre, su categoría y la fase/jornada del día, y bajo cada encabezado se listan solo los partidos de esa competición.
3. **Given** una competición activa sin partidos programados hoy, **When** el usuario visualiza el feed de "Hoy", **Then** esa competición no aparece en la lista.
4. **Given** el usuario había navegado a otra fecha y cierra completamente la aplicación, **When** vuelve a abrirla, **Then** la vista Partidos se presenta de nuevo con la pestaña "Hoy" activa y los partidos del día actual.
5. **Given** que no existe ningún partido programado hoy en ninguna competición, **When** se carga la vista, **Then** se muestra un estado vacío con el mensaje "No hay partidos programados para esta fecha" y una sugerencia para consultar otra fecha.

---

### User Story 2 - Tarjetas de partido estilo Match Center (Priority: P1)

Como usuario, quiero que cada partido del feed se muestre con el diseño simétrico del Match Center definido en Stitch (`vifutbol - Partidos`): equipo local con su escudo a la izquierda, bloque central con la hora o el marcador y equipo visitante con su escudo a la derecha, destacando claramente los partidos en vivo y los finalizados.

**Why this priority**: Es la parte visual explícita de la HU y lo que el usuario percibe primero; se entrega junto con la Historia 1 para que el MVP ya tenga el aspecto objetivo.

**Independent Test**: Con partidos de hoy en los estados programado, en juego, finalizado y cancelado, verificar que cada fila muestra la información correcta en el bloque central y que el estado es distinguible sin depender solo del color.

**Acceptance Scenarios**:

1. **Given** un partido programado para hoy, **When** se muestra en el feed, **Then** el bloque central presenta la hora de inicio (formato de 24 h según la región) y, como información secundaria, la sede o cancha si está asignada.
2. **Given** un partido en estado "En Juego", **When** se muestra en el feed, **Then** el bloque central presenta el marcador actual y una insignia "EN VIVO" con indicador pulsante en el color de acento en vivo, y el marcador se actualiza sin que el usuario recargue manualmente.
3. **Given** un partido finalizado, **When** se muestra en el feed, **Then** el bloque central presenta el marcador final con la etiqueta "Final" y el equipo ganador se resalta tipográficamente frente al perdedor.
4. **Given** un partido cancelado, **When** se muestra en el feed, **Then** el bloque central presenta la etiqueta "Cancelado" en lugar de hora o marcador.
5. **Given** cualquier partido del feed, **When** el usuario lo toca, **Then** se abre el detalle/acta del partido existente, respetando los permisos del rol (solo el `Árbitro` asignado o roles autorizados pueden editar el acta).

---

### User Story 3 - Pestañas rápidas Ayer / Hoy / Mañana (Priority: P2)

Como usuario, quiero tres pestañas fijas debajo de la barra superior —**Ayer**, **Hoy** y **Mañana**— para cambiar con un toque entre los resultados del día anterior, la jornada actual y la programación del día siguiente.

**Why this priority**: Es la navegación de fecha más frecuente (consultar resultados de ayer y la agenda de mañana); depende del feed de la Historia 1.

**Independent Test**: Con partidos en ayer, hoy y mañana, tocar cada pestaña y verificar que la lista se actualiza solo con los partidos de ese día, agrupados por competición, y que la pestaña tocada queda marcada como activa.

**Acceptance Scenarios**:

1. **Given** la vista Partidos con "Hoy" activa, **When** el usuario toca "Ayer", **Then** "Ayer" queda marcada como activa y el feed muestra las competiciones y partidos del día anterior, con sus marcadores finales.
2. **Given** la vista Partidos, **When** el usuario toca "Mañana", **Then** "Mañana" queda marcada como activa y el feed muestra las competiciones y partidos agendados para el día siguiente con su hora y sede.
3. **Given** las tres pestañas, **When** el usuario las observa, **Then** cada una muestra su etiqueta ("Ayer", "Hoy", "Mañana") junto con el día y mes abreviado correspondiente (ej. "Hoy · 6 nov").
4. **Given** el usuario está en la pestaña "Mañana" con la lista desplazada, **When** cambia a "Hoy" y regresa a "Mañana" en la misma sesión, **Then** la lista de "Mañana" se muestra sin perder los datos ya cargados.

---

### User Story 4 - Selección de cualquier fecha desde el calendario (Priority: P2)

Como usuario, quiero un icono de calendario en la barra superior, junto al icono de notificaciones, que me permita abrir un calendario, elegir cualquier fecha y ver las competiciones y partidos de ese día.

**Why this priority**: Amplía la consulta más allá de los tres días contiguos (ej. revisar una jornada pasada o planificar asistencia a un partido futuro).

**Independent Test**: Tocar el icono de calendario, elegir una fecha con partidos fuera del rango ayer/hoy/mañana y verificar que el feed muestra los partidos de esa fecha y que la barra de pestañas indica la fecha personalizada; luego elegir la fecha de hoy y verificar que se reactiva la pestaña "Hoy".

**Acceptance Scenarios**:

1. **Given** el usuario está en la vista Partidos, **When** observa la barra superior, **Then** ve un botón con icono de calendario ubicado inmediatamente al lado del icono de notificaciones, con una descripción accesible "Seleccionar fecha".
2. **Given** el usuario toca el icono de calendario, **When** se abre el selector, **Then** el selector se posiciona en la fecha actualmente visualizada y resalta el día de hoy.
3. **Given** el selector abierto, **When** el usuario elige una fecha distinta de ayer, hoy o mañana y confirma, **Then** el selector se cierra, el feed muestra las competiciones y partidos de esa fecha y la barra de pestañas indica visualmente la fecha personalizada elegida (ej. "Sáb 15 nov") sin marcar como activa ninguna de las tres pestañas.
4. **Given** el selector abierto, **When** el usuario elige la fecha de ayer, hoy o mañana, **Then** se activa automáticamente la pestaña correspondiente.
5. **Given** el selector abierto, **When** el usuario lo cancela o cierra sin confirmar, **Then** la fecha visualizada y el feed permanecen sin cambios.
6. **Given** el usuario está viendo una fecha personalizada, **When** toca cualquiera de las pestañas "Ayer", "Hoy" o "Mañana", **Then** el indicador de fecha personalizada desaparece y el feed muestra el día de la pestaña tocada.

---

### User Story 5 - Gestión de partidos sin fecha para el Organizador (Priority: P3)

Como `Organizador`, quiero conservar el acceso a las acciones de gestión que hoy existen en la vista Partidos (generar el calendario de un torneo y programar partidos pendientes), ya que los partidos sin fecha asignada no pueden aparecer en un feed organizado por días.

**Why this priority**: Evita una regresión funcional para el rol `Organizador`, pero no es parte del objetivo visual principal de la HU.

**Independent Test**: Iniciar sesión como `Organizador` con un torneo que tenga partidos pendientes de programar, y verificar que puede acceder a ellos y programarlos desde la ubicación acordada; con un rol sin permisos, verificar que esas acciones no se muestran.

**Acceptance Scenarios**:

1. **Given** un `Organizador` y al menos un partido pendiente de programar en cualquier competición, **When** visualiza la vista Partidos (en cualquier fecha), **Then** ve en la parte superior del feed, antes de los bloques de competición, un aviso destacado con el texto "X partidos pendientes de programar" y una acción para gestionarlos.
2. **Given** el aviso de partidos pendientes visible, **When** el `Organizador` lo toca, **Then** se abre la lista de partidos pendientes agrupados por competición, desde la cual puede programar cada uno (fecha, hora, sede/cancha y árbitro) con el flujo de programación existente.
3. **Given** un `Organizador` con una competición que aún no tiene calendario generado, **When** visualiza la vista Partidos, **Then** el aviso incluye también la acción "Generar calendario" para esa competición, con confirmación previa antes de ejecutarse.
4. **Given** un `Organizador` sin partidos pendientes ni competiciones sin calendario, **When** visualiza la vista Partidos, **Then** el aviso no se muestra.
5. **Given** un usuario con rol distinto de `Organizador`, **When** visualiza la vista Partidos, **Then** no ve el aviso ni ninguna acción de generación o programación de partidos.
6. **Given** un `Organizador` que programa un partido para una fecha, **When** consulta esa fecha en el feed, **Then** el partido aparece dentro del bloque de su competición y el contador del aviso disminuye en uno.

---

### Edge Cases

- **Partidos sin fecha programada** (estado pendiente de programación): no se muestran en ningún día del feed.
- **Competiciones finalizadas o con temporada cerrada**: sus partidos no aparecen en el feed, aunque se consulte desde el calendario una fecha en la que se jugaron; si esa fecha solo tenía partidos de competiciones no activas, se muestra el estado vacío.
- **Partidos cerca de la medianoche**: un partido se asigna al día según la fecha de inicio programada en la zona horaria del dispositivo; un partido que empieza a las 23:30 y termina después de medianoche aparece solo en el día de inicio.
- **Cambio de día con la aplicación abierta o en segundo plano**: al volver a primer plano tras la medianoche, si la pestaña activa era "Hoy", el feed pasa a mostrar el nuevo día actual y las etiquetas de las pestañas se recalculan.
- **Muchas competiciones o partidos en un mismo día**: el desplazamiento debe seguir siendo fluido y los encabezados de competición deben permanecer legibles.
- **Orden dentro del día**: las competiciones con partidos en vivo aparecen primero; luego el resto en orden alfabético por nombre de competición. Dentro de cada competición, los partidos en vivo primero, luego programados por hora de inicio ascendente, luego finalizados y por último cancelados.
- **Sin conexión**: el feed muestra los últimos datos disponibles localmente para la fecha seleccionada con un aviso de conexión (banner de conectividad existente); si no hay datos locales para esa fecha, se muestra un estado de error con opción de reintentar.
- **Error al cargar datos**: se muestra un estado de error con mensaje en español y botón "Reintentar", sin perder la fecha seleccionada.
- **Equipo sin escudo o datos incompletos**: se muestra un escudo genérico con las iniciales del equipo.
- **Escalado de texto grande**: los nombres de equipo largos se truncan con puntos suspensivos sin desplazar ni ocultar el bloque central de hora/marcador.
- **Pulsaciones repetidas** en pestañas o en el icono de calendario: no deben abrir múltiples selectores ni disparar cargas duplicadas.

## Requirements *(mandatory)*

### Functional Requirements

**Feed diario y agrupación**

- **FR-001**: La vista Partidos MUST mostrar los partidos de una única fecha seleccionada, considerando todas las competiciones **activas** (en inscripción o en curso), no solo una competición preseleccionada. Las competiciones en borrador, finalizadas o con temporada cerrada MUST excluirse del feed en cualquier fecha.
- **FR-002**: Al abrir la aplicación o al iniciarse la vista Partidos en una nueva sesión, la fecha seleccionada MUST ser el día actual y la pestaña "Hoy" MUST aparecer activa.
- **FR-003**: El feed MUST agrupar los partidos por competición, mostrando un encabezado por competición con: nombre, categoría y fase/jornada correspondiente a los partidos del día. Al tocar el encabezado de la competición o su icono de navegación, el sistema MUST navegar al detalle de la competición en el directorio (`/competitions/:id`).
- **FR-004**: El feed MUST mostrar únicamente las competiciones que tengan al menos un partido en la fecha seleccionada.
- **FR-005**: Un partido MUST asignarse a un día según la fecha de su hora de inicio programada en la zona horaria del dispositivo; los partidos sin hora de inicio programada MUST excluirse del feed.
- **FR-006**: El feed MUST ordenar las competiciones y los partidos según las reglas descritas en Edge Cases (en vivo primero; luego por hora; finalizados y cancelados al final).
- **FR-007**: Cuando no haya partidos en la fecha seleccionada, el sistema MUST mostrar un estado vacío con un mensaje en español y una sugerencia para consultar otra fecha.
- **FR-008**: El sistema MUST mostrar estados explícitos de carga, contenido, vacío y error (con opción de reintentar) para el feed.

**Tarjetas de partido**

- **FR-009**: Cada partido MUST mostrarse con disposición simétrica: escudo y nombre del local a la izquierda, bloque central de estado y escudo y nombre del visitante a la derecha.
- **FR-010**: El bloque central MUST mostrar: la hora de inicio para partidos programados; el marcador e insignia "EN VIVO" para partidos en juego; el marcador y la etiqueta "Final" para partidos finalizados; la etiqueta "Cancelado" para partidos cancelados.
- **FR-011**: Los estados del partido MUST distinguirse mediante texto o iconografía además del color.
- **FR-012**: El marcador de los partidos en juego MUST actualizarse en el feed sin recarga manual por parte del usuario.
- **FR-013**: Al tocar un partido, el sistema MUST abrir su detalle/acta, respetando los permisos de edición del rol activo.

**Pestañas Ayer / Hoy / Mañana**

- **FR-014**: Debajo de la barra superior, la vista MUST presentar exactamente tres pestañas fijas: "Ayer", "Hoy" y "Mañana", cada una con su día y mes abreviados.
- **FR-015**: Al tocar una pestaña, el sistema MUST marcarla como activa y actualizar el feed con los partidos de ese día.
- **FR-016**: Las pestañas MUST calcularse siempre relativas al día actual del dispositivo y recalcularse si cambia el día mientras la aplicación está abierta o en segundo plano.

**Selector de calendario**

- **FR-017**: La barra superior de la vista Partidos MUST incluir un botón con icono de calendario, ubicado inmediatamente al lado del icono de notificaciones, con etiqueta accesible "Seleccionar fecha".
- **FR-018**: Al tocar el botón de calendario, el sistema MUST abrir un selector de fecha posicionado en la fecha visualizada actualmente, resaltando el día de hoy.
- **FR-019**: Al confirmar una fecha, el sistema MUST actualizar el feed con los partidos de esa fecha; si la fecha coincide con ayer, hoy o mañana, MUST activar la pestaña correspondiente; en caso contrario, MUST mostrar un indicador de fecha personalizada en la barra de pestañas sin marcar ninguna de las tres como activa.
- **FR-020**: Al cancelar el selector, el sistema MUST mantener la fecha y el feed sin cambios.
- **FR-021**: El selector MUST permitir fechas pasadas y futuras, sin restringirse al rango de un único torneo.

**Roles, idioma y diseño**

- **FR-022**: La vista Partidos, sus pestañas y el selector de calendario MUST estar disponibles con el mismo comportamiento para los cinco roles.
- **FR-023**: Las acciones de gestión (generar calendario, programar partidos pendientes) MUST mostrarse únicamente a roles con permiso de gestión de torneos, mediante un aviso destacado en la parte superior del feed diario que indique la cantidad de partidos pendientes de programar; el aviso MUST ocultarse cuando no haya pendientes ni competiciones sin calendario.
- **FR-027**: Al tocar el aviso, el sistema MUST mostrar los partidos pendientes agrupados por competición y permitir programarlos con el flujo existente; la acción "Generar calendario" MUST solicitar confirmación y protegerse contra pulsaciones repetidas.
- **FR-024**: Todos los textos visibles (pestañas, etiquetas de estado, mensajes de vacío y error, descripciones accesibles) MUST estar en español y centralizados en el mecanismo de localización del proyecto; las fechas y horas MUST formatearse según la configuración regional en español.
- **FR-025**: La interfaz MUST seguir los tokens del sistema de diseño KickPulse (`DESIGN.md`) y tomar como referencia visual la pantalla `vifutbol - Partidos` del proyecto Stitch: superficies oscuras, encabezados de competición sobre superficie elevada, tarjetas con esquinas redondeadas de 16 px, acento verde para la selección y acento rojo para lo que está en vivo.
- **FR-026**: Todos los controles interactivos (pestañas, botón de calendario, filas de partido) MUST tener áreas táctiles de al menos 48×48 dp y etiquetas para lectores de pantalla.

### Key Entities

- **Fecha seleccionada**: Día calendario que se está consultando; estado temporal de la sesión, siempre reiniciado al día actual al abrir la aplicación. Puede corresponder a una pestaña (Ayer/Hoy/Mañana) o ser una fecha personalizada.
- **Competición (Torneo)**: Liga o copa registrada; aporta nombre, categoría y formato al encabezado del bloque. Solo participan en el feed las competiciones en estado activo (en inscripción o en curso).
- **Partido**: Encuentro entre local y visitante de una competición; aporta fecha/hora de inicio, estado (pendiente de programación, programado, en juego, finalizado, cancelado), marcador, jornada/fase, sede/cancha.
- **Grupo de competición del día**: Agrupación de presentación que reúne, para una fecha, una competición y la lista ordenada de sus partidos de ese día.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: En el 100% de los arranques de la aplicación, la vista Partidos se presenta con la pestaña "Hoy" activa y los partidos del día actual.
- **SC-002**: Los usuarios pueden pasar de "Hoy" a "Ayer" o "Mañana" con un solo toque y ver la lista actualizada en menos de 1 segundo con datos disponibles localmente.
- **SC-003**: Los usuarios pueden consultar los partidos de cualquier fecha arbitraria en 3 toques o menos (calendario → fecha → confirmar).
- **SC-004**: En pruebas con usuarios, al menos el 90% identifica correctamente la competición de un partido y si está en vivo, programado o finalizado en menos de 5 segundos.
- **SC-005**: Ningún partido aparece en un día distinto al de su fecha de inicio programada ni bajo una competición que no le corresponde (0 errores de agrupación en las pruebas de aceptación).
- **SC-006**: El marcador de un partido en vivo se refleja en el feed en menos de 5 segundos tras ser registrado, sin acción del usuario.
- **SC-007**: El desplazamiento del feed se mantiene fluido con al menos 10 competiciones y 60 partidos en un mismo día.

## Assumptions

- La referencia visual principal es la pantalla `vifutbol - Partidos` (Match Center – KickPulse Clean Hybrid) del proyecto Stitch `vifutbol`; la tira de fechas del diseño se sustituye por las tres pestañas fijas pedidas por el usuario y el botón de calendario se ubica en la barra superior en lugar de dentro de la tira.
- Los filtros rápidos por categoría del diseño Stitch (chips "Todos", "En Curso", "Mis Ligas", etc.), las cuotas de apuestas, xG y estadísticas de posesión quedan **fuera de alcance** de esta HU.
- La priorización, ordenamiento especial o secciones de equipos/competiciones marcados como **Favoritos** quedan **fuera de alcance** de esta fase y se integrarán más adelante.
- La barra superior conserva el menú lateral (drawer) y el icono de notificaciones existentes (HU 10.1 y 10.2); el icono de calendario se muestra solo cuando la pestaña inferior activa es "Partidos".
- La fecha seleccionada no se persiste entre aperturas de la aplicación; dentro de una misma sesión se conserva al cambiar de pestaña inferior y volver.
- Se reutilizan los datos existentes de competiciones, equipos (escudos, colores, abreviaturas) y partidos, así como la actualización en tiempo real y el detalle/acta de partido ya implementados en HUs anteriores.
- El encabezado de competición incluye un acceso al detalle de la competición solo si dicho detalle ya existe; añadir nuevas pantallas de detalle no forma parte de esta HU.
- Si una competición tiene en un mismo día partidos de distintas jornadas, el encabezado muestra la jornada del primer partido del día.
