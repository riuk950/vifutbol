# Feature Specification: Pantalla de Detalle de Equipo con Pestañas y Resumen (Último y Próximo Partido) (HU 14.1)

**Feature Branch**: `021-team-detail-summary`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "de Notion HU 14.1 en curso - [Épica 14] HU 14.1: Pantalla de Detalle de Equipo con Pestañas y Resumen (Último y Próximo Partido)"

---

## Clarifications

### Session 2026-11-09

- Q: ¿Qué contenido deben mostrar las pestañas "Partidos" y "Plantilla" dentro de `TeamDetailScreen` en esta historia (HU 14.1), previo al desarrollo detallado de las HU 14.2 y HU 14.3? (FR-011) → A: Mostrar vistas informativas de preparación (`KickPulseStateView`) en las pestañas "Partidos" y "Plantilla" de `TeamDetailScreen`, manteniendo `/tournaments/teams/detail` intacta para la gestión administrativa existente y dejando el desarrollo de ambas pestañas para HU 14.2 y HU 14.3.
- Q: ¿Cómo debe comportarse la navegación al tocar el escudo o nombre de un equipo dentro de las tarjetas de partido (`MatchCenterCard`) en coexistencia con el toque general de la tarjeta? (FR-002) → A: Zonas táctiles independientes por equipo en `MatchCenterCard` (local y visitante navegan a `/teams/:id` si no es el equipo actual en pantalla) y el bloque central mantiene la acción del partido (`onTap`).
- Q: ¿Qué estados de partido y criterio de desempate cronológico deben emplearse para determinar el "Último Partido" y el "Próximo Partido" del equipo en la pestaña "Información"? (FR-006) → A: "Último Partido" = `completed` más reciente por fecha/hora (respaldo: mayor `roundNumber`). "Próximo Partido" = `inProgress` > `scheduled` más cercano por fecha/hora > `pendingSchedule` de menor `roundNumber` (excluyendo `cancelled`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegación al Detalle de Equipo y Encabezado de Identidad del Club (Priority: P1) 🎯 MVP

Como aficionado, seguidor, jugador o entrenador de ViFutbol, quiero que al seleccionar un equipo en el directorio de equipos o al tocar su escudo/nombre en las tarjetas de partido se abra una pantalla dedicada de detalle del equipo (`/teams/:id`) con su identidad visual y tres pestañas horizontales ("Información", "Partidos" y "Plantilla"), teniendo la pestaña "Información" activa por defecto, para consultar de inmediato el contexto oficial del club.

**Why this priority**: Constituye la puerta de entrada y la estructura base de toda la Épica 14, permitiendo identificar el equipo, su competición y su estado de elegibilidad desde cualquier punto de consulta del torneo.

**Independent Test**: Abrir el directorio de equipos (`/teams`) o una tarjeta de partido, tocar un equipo registrado (ej. "Atlético Norte FC"), verificar que se navega a `/teams/:id`, comprobar que el encabezado exhibe el escudo vectorizado, el nombre oficial, el código corto ("ATN"), la insignia de elegibilidad y el nombre de la competición, y confirmar que debajo se presentan las 3 pestañas ("Información", "Partidos", "Plantilla") con "Información" seleccionada por defecto.

**Acceptance Scenarios**:

1. **Given** que el usuario navega en el directorio de "Equipos", **When** selecciona un equipo de la lista (ej. "Atlético Norte FC"), **Then** se abre la pantalla de detalle del equipo (`/teams/:id`) mostrando en el encabezado su escudo vectorizado, nombre oficial, código corto ("ATN"), insignia de elegibilidad y el nombre de la competición a la que pertenece.
2. **Given** que el usuario visualiza una tarjeta de partido, **When** toca el escudo o el nombre de uno de los equipos contendientes, **Then** el sistema navega a la pantalla de detalle de dicho equipo (`/teams/:id`).
3. **Given** que el usuario ingresa a la pantalla de detalle del equipo, **When** la pantalla se presenta por primera vez, **Then** debajo del encabezado superior se observan las 3 pestañas fijas: "Información", "Partidos" y "Plantilla", encontrándose la pestaña "Información" activa por defecto.

---

### User Story 2 - Ficha del Club y Resumen de Último y Próximo Partido en la Pestaña "Información" (Priority: P2)

Como aficionado, jugador o entrenador, quiero visualizar en la pestaña "Información" la tarjeta de ficha institucional del club junto con las tarjetas destacadas de "Último Partido" y "Próximo Partido", para conocer de un vistazo los datos distintivos del equipo, su resultado más reciente y cuándo vuelve a jugar.

**Why this priority**: Entrega el valor informativo principal de la historia de usuario: el resumen ejecutivo del presente competitivo del equipo sin obligar al usuario a recorrer todo el calendario de la competición.

**Independent Test**: Ingresar al detalle de un equipo que cuente con al menos un partido finalizado y un partido futuro programado en el fixture, y verificar que en la pestaña "Información" se despliegan la tarjeta de "Ficha del Club" (nombre oficial, código, colores distintivos y torneo), la tarjeta de "Último Partido" (rival, marcador final con estado finalizado, fecha y sede) y la tarjeta de "Próximo Partido" (rival, fecha, hora programada y cancha/sede).

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en la pestaña "Información" del detalle de un equipo, **When** revisa la ficha institucional del club, **Then** visualiza el nombre oficial del equipo, su código corto, sus colores distintivos (primario y secundario) y el nombre del torneo en el que participa.
2. **Given** que el equipo cuenta con historial de partidos finalizados y partidos futuros programados en el fixture, **When** el usuario visualiza la pestaña "Información", **Then** se presenta una tarjeta destacada de "Último Partido" exhibiendo el rival, el marcador final (`FT`), la fecha y la sede, y una tarjeta destacada de "Próximo Partido" exhibiendo el rival, la fecha, la hora fijada y la cancha/sede programada.
3. **Given** que el equipo tiene múltiples partidos finalizados y múltiples partidos futuros programados, **When** se calcula el resumen de la pestaña "Información", **Then** "Último Partido" selecciona determinísticamente el encuentro finalizado más reciente y "Próximo Partido" selecciona el encuentro programado o pendiente más cercano en el calendario.

---

### User Story 3 - Estados Informativos para Equipos Sin Partidos Previos o Sin Próximos Encuentros (Priority: P3)

Como usuario consultando un equipo recién inscrito que aún no ha debutado o un equipo que ya concluyó su participación en el calendario, quiero ver mensajes claros y amigables dentro de las tarjetas de "Último Partido" y "Próximo Partido", para comprender de inmediato la situación deportiva del club sin percibir errores ni bloques vacíos confusos.

**Why this priority**: Garantiza una experiencia consistente y resiliente durante todas las fases del torneo (pretemporada, inscripción abierta, competición en curso y cierre de temporada).

**Independent Test**: Consultar la pestaña "Información" de un equipo sin partidos finalizados y/o sin partidos futuros agendados, y comprobar que las tarjetas muestran explícitamente los mensajes localizados "Sin partidos previos disputados" y "Sin próximos partidos agendados" respectivamente.

**Acceptance Scenarios**:

1. **Given** que el equipo recién inicia su participación y no registra partidos finalizados, **When** el usuario visualiza la pestaña "Información", **Then** la tarjeta de "Último Partido" indica claramente el mensaje "Sin partidos previos disputados".
2. **Given** que el equipo no tiene encuentros futuros programados en la competición, **When** el usuario visualiza la pestaña "Información", **Then** la tarjeta de "Próximo Partido" indica claramente el mensaje "Sin próximos partidos agendados".

---

### User Story 4 - Alternancia de Pestañas Horizontales y Conservación de Contexto (Priority: P4)

Como usuario explorando el detalle de un equipo, quiero alternar entre las pestañas "Información", "Partidos" y "Plantilla" manteniendo el encabezado de identidad del club siempre visible, para cambiar de sección con fluidez y conservar el contexto del equipo seleccionado.

**Why this priority**: Asegura la coherencia estructural de la pantalla de detalle de equipo y deja listas las vistas contenedoras para el calendario completo del equipo (HU 14.2) y la nómina de jugadores (HU 14.3).

**Independent Test**: En la pantalla de detalle de un equipo (`/teams/:id`), pulsar sucesivamente las pestañas "Partidos", "Plantilla" e "Información", comprobando que el indicador activo cambia correctamente, que cada pestaña muestra su contenido o estado informativo correspondiente y que al volver a "Información" se conserva el estado sin recargas innecesarias.

**Acceptance Scenarios**:

1. **Given** que el usuario está en la pantalla de detalle del equipo, **When** pulsa sobre las pestañas "Partidos" o "Plantilla", **Then** la pestaña seleccionada se activa visualmente y presenta su vista informativa de preparación (`KickPulseStateView`) sin perder el encabezado superior del equipo.
2. **Given** que el usuario alterna hacia "Partidos" o "Plantilla" y luego regresa a "Información", **When** se reactiva la pestaña "Información", **Then** la ficha del club y las tarjetas de último y próximo partido permanecen sincronizadas con el catálogo local sin recargas innecesarias.

---

### Edge Cases

- **Navegación con identificador de equipo inexistente**: Si se accede a `/teams/:id` con un identificador que no existe en el catálogo local, la pantalla DEBE mostrar un estado informativo amigable indicando que el equipo no fue encontrado y permitir regresar de forma segura a la pantalla anterior.
- **Partidos futuros sin fecha u hora definitiva (`pendingSchedule`)**: Si el siguiente partido del equipo en el fixture aún se encuentra pendiente de programación horaria o de cancha, la tarjeta de "Próximo Partido" DEBE mostrar al rival y la jornada correspondiente indicando que el horario o la sede están pendientes de programación.
- **Equipos con colores primarios muy claros u oscuros**: El uso de los colores primarios y secundarios del club como acentos visuales sutiles en la ficha y encabezado DEBE preservar siempre el contraste de lectura sobre las superficies oscuras del sistema de diseño.
- **Operación sin conexión (Modo Offline) y Ciclo de Vida Móvil**: Al consultar el detalle de un equipo sin conectividad o al reanudar la aplicación desde segundo plano, la pantalla DEBE resolver el equipo, su torneo y sus partidos desde el almacenamiento local persistido, conservando la pestaña seleccionada.
- **Pantallas compactas (`320x640 px`) y escalado tipográfico al `130%`**: Los nombres largos de clubes, nombres de competiciones, etiquetas de pestañas y tarjetas de partido DEBEN ajustarse o truncarse limpiamente con elipsis, garantizando cero desbordamientos visuales.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE proveer una pantalla dedicada de Detalle de Equipo accesible mediante la ruta `/teams/:id`.
- **FR-002**: Al seleccionar un equipo en el directorio de equipos (`TeamsDirectoryScreen`) o al tocar la zona táctil independiente del escudo/nombre del equipo local o visitante en las tarjetas de partido (`MatchCenterCard`), el sistema DEBE navegar hacia `/teams/:id` pasando el identificador único del equipo (omitiendo la navegación redundante si ya se está visualizando el detalle de ese mismo equipo), mientras que el bloque central de la tarjeta mantiene su acción de partido (`onTap`).
- **FR-003**: El encabezado superior (`AppBar`) de la pantalla de detalle DEBE exhibir el escudo vectorizado del club, el nombre oficial del equipo, su código corto (ej. `ATN`), la insignia de estado de elegibilidad y el nombre de la competición a la que pertenece, además de un botón de retroceso accesible.
- **FR-004**: Inmediatamente debajo del encabezado superior, la pantalla DEBE presentar una barra fija de 3 pestañas horizontales: "Información", "Partidos" y "Plantilla", con la pestaña "Información" seleccionada por defecto al abrir la pantalla.
- **FR-005**: La pestaña "Información" DEBE mostrar una "Tarjeta de Ficha del Club" que presente el nombre oficial del equipo, su código corto, muestras e indicadores de sus colores distintivos (primario y secundario) con acentos visuales sutiles, el estado de elegibilidad y el nombre de la competición en la que participa.
- **FR-006**: La pestaña "Información" DEBE mostrar una tarjeta destacada de "Último Partido" que resuelva y exhiba el encuentro finalizado (`MatchStatus.completed`) más reciente disputado por el equipo (como local o visitante), ordenado por `scheduledStartTime` descendente (y mayor `roundNumber` como respaldo/desempate), mostrando el equipo rival, el marcador final con indicador de finalizado (`FT`), la fecha y la sede/cancha.
- **FR-007**: Si el equipo no registra ningún partido finalizado (`completed`) hasta el momento, la tarjeta de "Último Partido" DEBE mostrar el mensaje localizado: *"Sin partidos previos disputados"*.
- **FR-008**: La pestaña "Información" DEBE mostrar una tarjeta destacada de "Próximo Partido" que resuelva y exhiba el siguiente encuentro oficial del equipo (como local o visitante) entre los estados `inProgress`, `scheduled` o `pendingSchedule` (excluyendo `cancelled`), priorizando `inProgress`, luego `scheduled` con `scheduledStartTime` más cercano ascendente y finalmente `pendingSchedule` de menor `roundNumber`, mostrando el equipo rival, la fecha, la hora fijada y la cancha/sede (o indicador de pendiente de programación).
- **FR-009**: Si el equipo no tiene partidos futuros programados ni pendientes en el fixture, la tarjeta de "Próximo Partido" DEBE mostrar el mensaje localizado: *"Sin próximos partidos agendados"*.
- **FR-010**: La derivación del último partido disputado y del próximo partido en agenda DEBE calcularse de forma eficiente y determinista filtrando el catálogo de partidos por la participación del equipo (`homeTeamId == team.id` o `awayTeamId == team.id`) sin bloquear el hilo principal de la interfaz.
- **FR-011**: Las pestañas "Partidos" y "Plantilla" DEBEN estar operativas dentro de la barra de pestañas de `TeamDetailScreen` (`/teams/:id`), presentando vistas informativas de preparación (`KickPulseStateView`) hasta su desarrollo completo en las HU 14.2 y HU 14.3, mientras que la ruta administrativa existente (`/tournaments/teams/detail` - `TeamRosterDetailScreen`) se mantiene intacta para los flujos de inscripción y elegibilidad.
- **FR-012**: Todos los textos visibles para el usuario (títulos de pestañas, etiquetas de ficha del club, encabezados de último y próximo partido y estados vacíos) DEBEN estar centralizados en español dentro del archivo de localización (`l10n`), sin cadenas de texto codificadas directamente en los componentes visuales.
- **FR-013**: La interfaz DEBE adaptarse correctamente a pantallas móviles compactas (`320x640 px`) y tamaños de fuente escalados hasta el `130%`, manteniendo áreas táctiles mínimas de `48x48 dp` y cero desbordamientos de diseño.

---

### Key Entities *(include if feature involves data)*

- **TournamentTeam**: Entidad principal que representa al club inscrito en un campeonato, incluyendo identificador único, identificador de torneo, nombre oficial, código corto de 3 letras, forma de escudo, colores primario y secundario, estado de elegibilidad y lista de jugadores inscritos.
- **ChampionshipTournament**: Entidad de la competición a la que pertenece el equipo, utilizada para presentar el nombre del torneo, su categoría y las reglas de cupo aplicables.
- **ChampionshipMatch**: Entidad que representa cada partido oficial del torneo, a partir de la cual se filtran los encuentros donde el equipo actúa como local o visitante para determinar su último resultado y su próximo compromiso.
- **TeamMatchSummary**: Proyección de datos de presentación para el equipo que agrupa de forma inmutable el último partido finalizado (`lastPlayedMatch`) y el próximo partido agendado (`nextScheduledMatch`) junto con la información resuelta de los equipos rivales.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden abrir la pantalla de detalle de un equipo desde el directorio y visualizar su identidad, ficha del club, último partido y próximo partido en menos de 500 ms.
- **SC-002**: El 100% de las consultas a equipos con historial de partidos y agenda futura identifican de manera exacta y determinista el encuentro finalizado más reciente y el compromiso futuro más próximo.
- **SC-003**: El 100% de los equipos sin partidos previos o sin encuentros futuros exhiben los estados informativos *"Sin partidos previos disputados"* y *"Sin próximos partidos agendados"* sin errores ni contenedores rotos.
- **SC-004**: Cero errores de desbordamiento visual en resoluciones móviles compactas (`320x640 px`) con factor de escala de texto al `130%`.

---

## Assumptions

- **A-001**: Los datos de equipos, torneos y partidos se encuentran disponibles en los catálogos locales persistidos del dispositivo, permitiendo consulta inmediata en modo offline.
- **A-002**: La ruta administrativa existente `/tournaments/teams/detail` (`TeamRosterDetailScreen`) y `/tournaments/teams/lineup` (`CoachLineupTrackingScreen`) permanecen intactas para los flujos de gestión de inscripción, aprobación de elegibilidad y seguimiento táctico (Épicas 5 y 6), mientras que `/teams/:id` (`TeamDetailScreen`) actúa como la pantalla de detalle de equipo con pestañas introducida en la Épica 14.
- **A-003**: El detalle exhaustivo del historial completo de partidos en la pestaña "Partidos" y los filtros por posición táctica en la pestaña "Plantilla" se profundizarán en las historias subsecuentes HU 14.2 y HU 14.3 respectivamente.
