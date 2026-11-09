# Feature Specification: Pestaña de Calendario de Partidos del Equipo (Próximos e Historial) (HU 14.2)

**Feature Branch**: `022-team-matches-schedule`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "de Notion HU 14.2 en curso - [Épica 14] HU 14.2: Pestaña de Calendario de Partidos del Equipo (Próximos e Historial)"

---

## Clarifications

### Session 2026-11-09

- Q: ¿Cómo deben organizarse visualmente las secciones de "Próximos Partidos" y "Resultados Anteriores" dentro de la pestaña "Partidos" del equipo? (FR-003) → A: Listado vertical continuo con ambas secciones visibles ("Próximos Partidos" arriba y "Resultados Anteriores" debajo), cada una con su encabezado y estado vacío contextual si no tiene registros.
- Q: ¿Cómo deben presentarse los metadatos del encuentro (jornada, fecha y cancha) y el distintivo semántico de resultado (Victoria, Empate o Derrota) al reutilizar `MatchCenterCard` en la pestaña "Partidos"? (FR-005, FR-007) → A: Contenedor de partido con franja superior de metadatos (jornada, fecha y cancha) y badge semántico a la derecha (Victoria/Empate/Derrota en finalizados; Local/Visitante en próximos) sobre el widget `MatchCenterCard` reutilizado sin cambios invasivos.
- Q: ¿Qué vista de detalle o informe del partido debe abrirse cuando el usuario toca un partido del listado en la pestaña "Partidos"? (FR-008) → A: Abrir un `ModalBottomSheet` informativo de resumen/informe del encuentro (jornada, equipos, marcador/estado, resultado semántico, fecha/hora, cancha y árbitro) al tocar la tarjeta, mientras los escudos/nombres navegan al equipo rival.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualización de Próximos Partidos del Equipo en Orden Cronológico (Priority: P1) 🎯 MVP

Como aficionado, analista o integrante del club en ViFutbol, quiero ingresar a la pestaña "Partidos" dentro de la pantalla de detalle de un equipo (`/teams/:id`) y visualizar la sección de "Próximos Partidos" con todos los encuentros en curso, programados o pendientes de horario donde participa ese equipo (como local o visitante) ordenados cronológicamente de menor a mayor fecha, para planificar mi asistencia o seguimiento de la agenda futura de mi club en la competición.

**Why this priority**: Sustituye la vista de preparación de la pestaña "Partidos" en el detalle de equipo por el calendario activo del club, entregando valor inmediato sobre los próximos compromisos deportivos del equipo.

**Independent Test**: Abrir la pantalla de detalle de un equipo (`/teams/:id`), tocar la pestaña "Partidos", verificar que se despliega la sección "Próximos Partidos" listando únicamente encuentros donde el equipo participa (local o visitante) ordenados de menor a mayor fecha, y comprobar que cada tarjeta exhibe ambos equipos con su escudo, el rival, la jornada correspondiente, la fecha, la hora y la cancha/sede asignada.

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en la pantalla de detalle de un equipo con partidos futuros en el fixture, **When** pulsa la pestaña "Partidos", **Then** se muestra la sección "Próximos Partidos" con los encuentros futuros del equipo ordenados cronológicamente de menor a mayor fecha.
2. **Given** que se listan los próximos partidos del equipo en la pestaña "Partidos", **When** el usuario inspecciona cada elemento del listado, **Then** visualiza la tarjeta simétrica de partido indicando condición de local/visitante, el equipo rival, la jornada correspondiente, la fecha, la hora programada (o estado pendiente) y la cancha/sede.
3. **Given** que existen partidos de otros equipos en el mismo torneo, **When** el usuario consulta la pestaña "Partidos" del equipo seleccionado, **Then** el listado filtra y exhibe exclusivamente los partidos donde dicho equipo participa como local o visitante.

---

### User Story 2 - Historial de Resultados Anteriores con Distintivo Semántico (Victoria, Empate, Derrota) (Priority: P2)

Como aficionado, analista o jugador del equipo, quiero visualizar en la pestaña "Partidos" la sección de "Resultados Anteriores" con todos los partidos finalizados del equipo, su marcador definitivo y un distintivo semántico claro que indique si el resultado para el equipo fue Victoria, Empate o Derrota, para evaluar de un vistazo el rendimiento histórico del club a lo largo de la temporada.

**Why this priority**: Complementa la agenda futura con la trayectoria histórica del equipo, permitiendo distinguir inmediatamente el desenlace deportivo desde la perspectiva del club consultado sin tener que comparar manualmente los goles de local y visitante en cada fila.

**Independent Test**: Ingresar a la pestaña "Partidos" de un equipo con partidos finalizados que incluyan al menos una victoria, un empate y una derrota (tanto de local como de visitante), y verificar que la sección "Resultados Anteriores" muestra cada partido con su marcador definitivo y su insignia de resultado semántico correspondiente: verde para Victoria, gris/amarillo para Empate y rojo sutil para Derrota.

**Acceptance Scenarios**:

1. **Given** que el equipo ha disputado partidos finalizados en la temporada, **When** el usuario revisa la pestaña "Partidos", **Then** se muestra la sección "Resultados Anteriores" listando los encuentros finalizados ordenados del más reciente al más antiguo con sus marcadores definitivos.
2. **Given** un partido finalizado donde el equipo consultado anotó más goles que su rival (como local o como visitante), **When** se presenta en "Resultados Anteriores", **Then** el encuentro exhibe un distintivo semántico de **Victoria** en tono verde junto con su etiqueta legible.
3. **Given** un partido finalizado donde ambos equipos anotaron la misma cantidad de goles, **When** se presenta en "Resultados Anteriores", **Then** el encuentro exhibe un distintivo semántico de **Empate** en tono gris/amarillo de advertencia junto con su etiqueta legible.
4. **Given** un partido finalizado donde el equipo consultado anotó menos goles que su rival (como local o como visitante), **When** se presenta en "Resultados Anteriores", **Then** el encuentro exhibe un distintivo semántico de **Derrota** en tono rojo sutil junto con su etiqueta legible.

---

### User Story 3 - Acceso al Detalle / Informe del Partido y Estados Vacíos Informativos (Priority: P3)

Como usuario consultando la pestaña "Partidos" de un equipo, quiero poder tocar cualquier partido de la lista para consultar su detalle o informe del encuentro, y ver estados vacíos claros cuando el equipo no tenga partidos programados o disputados, para profundizar en la información de cada encuentro o entender por qué una sección no contiene registros.

**Why this priority**: Cierra el flujo interactivo del calendario del equipo conectándolo con la vista de detalle de cada encuentro y garantiza resiliencia visual para equipos recién creados o al cierre del torneo.

**Independent Test**: En la pestaña "Partidos", tocar una tarjeta de partido próximo o finalizado y comprobar que se abre el detalle/informe informativo del partido (con jornada, enfrentamiento, marcador/estado, fecha, cancha y árbitro); asimismo, probar con un equipo sin partidos registrados y verificar que se despliega el estado vacío informativo.

**Acceptance Scenarios**:

1. **Given** que el usuario visualiza un partido en "Próximos Partidos" o en "Resultados Anteriores", **When** toca el bloque central o la tarjeta del partido, **Then** se abre la vista o modal de detalle/informe del partido mostrando la jornada, los equipos contendientes, el marcador o estado, la fecha/hora, la cancha/sede y el árbitro asignado.
2. **Given** que el usuario toca el escudo o nombre del equipo rival dentro de una tarjeta de partido en la pestaña "Partidos", **When** se procesa la interacción, **Then** el sistema navega al detalle del equipo rival (`/teams/:rivalId`), mientras que tocar el equipo actual no duplica la pantalla en la pila de navegación.
3. **Given** que un equipo no registra ningún partido en todo el calendario (ni próximos ni finalizados), **When** el usuario abre la pestaña "Partidos", **Then** se muestra un estado vacío informativo general indicando que el equipo aún no tiene partidos registrados en el calendario.
4. **Given** que un equipo tiene únicamente partidos próximos pero ningún partido finalizado (o viceversa), **When** el usuario consulta la pestaña "Partidos", **Then** la sección sin registros muestra un mensaje informativo contextual indicando la ausencia de partidos en dicho bloque sin ocultar la otra sección.

---

### Edge Cases

- **Cálculo de resultado según condición de Local o Visitante**: El resultado (Victoria, Empate, Derrota) DEBE calcularse siempre desde la perspectiva del equipo cuyo detalle se está consultando (`teamId`). Por ejemplo, un marcador `1 - 3` es Derrota para el equipo local pero Victoria para el equipo visitante.
- **Partidos pendientes de programación (`pendingSchedule`) o en curso (`inProgress`)**: Los encuentros en estado `inProgress` DEBEN ubicarse al inicio de "Próximos Partidos" (destacados como en juego), seguidos de los `scheduled` ordenados por fecha/hora ascendente y finalmente los `pendingSchedule` ordenados por número de jornada ascendente.
- **Partidos cancelados (`cancelled`)**: Los encuentros cancelados no deben distorsionar el cálculo de Victoria/Empate/Derrota; si existen, se excluyen del cómputo de resultados o se identifican claramente como cancelados sin adjudicar resultado deportivo.
- **Accesibilidad sin dependencia exclusiva del color**: El distintivo de Victoria, Empate y Derrota DEBE incluir texto explícito o abreviatura localizada (ej. "Victoria" / "V", "Empate" / "E", "Derrota" / "D") además del color semántico, garantizando comprensión para usuarios con daltonismo o lectores de pantalla.
- **Conservación de desplazamiento y modo Offline**: Al alternar entre las pestañas "Información", "Partidos" y "Plantilla" o al operar sin conexión a internet, la pestaña "Partidos" DEBE conservar su posición de desplazamiento y resolver todos los encuentros desde el catálogo local persistido.
- **Pantallas compactas (`320x640 px`) y escalado de texto al `130%`**: Los encabezados de jornada, metadatos de fecha/cancha, tarjetas simétricas de partido e insignias de resultado DEBEN adaptarse sin producir desbordamientos visuales (`RenderFlex overflow`).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La pestaña "Partidos" dentro de `TeamDetailScreen` (`/teams/:id`) DEBE reemplazar la vista de preparación actual por una vista de calendario completo del equipo (`TeamMatchesTabView`).
- **FR-002**: El sistema DEBE filtrar exclusivamente los partidos del catálogo donde el equipo consultado participe como equipo local (`homeTeamId == teamId`) o como equipo visitante (`awayTeamId == teamId`), excluyendo encuentros cancelados (`MatchStatus.cancelled`) de las listas activas de próximos partidos y resultados.
- **FR-003**: La vista DEBE estructurarse en un único listado vertical continuo con dos secciones visibles en orden secuencial: **"Próximos Partidos"** en la parte superior y **"Resultados Anteriores"** debajo, cada una con su encabezado de sección y estado vacío contextual cuando no tenga encuentros en ese bloque.
- **FR-004**: La sección **"Próximos Partidos"** DEBE listar todos los encuentros del equipo en estado `inProgress`, `scheduled` o `pendingSchedule`, ordenados cronológicamente priorizando `inProgress`, luego `scheduled` de menor a mayor fecha/hora (`scheduledStartTime` ascendente) y finalmente `pendingSchedule` por menor número de jornada (`roundNumber` ascendente).
- **FR-005**: Cada elemento en **"Próximos Partidos"** DEBE componerse de una franja superior de metadatos (jornada `roundName`, fecha, cancha/sede `pitchName` o sede por asignar, y badge de condición Local/Visitante) seguida del widget reutilizado `MatchCenterCard` (que exhibe ambos clubes con sus escudos y la hora programada o estado pendiente en el bloque central).
- **FR-006**: La sección **"Resultados Anteriores"** DEBE listar todos los encuentros finalizados (`MatchStatus.completed`) del equipo, ordenados cronológicamente del más reciente al más antiguo (`scheduledStartTime` descendente y `roundNumber` descendente como desempate).
- **FR-007**: Cada elemento en **"Resultados Anteriores"** DEBE componerse de una franja superior de metadatos (jornada, fecha y cancha/sede) junto con un badge semántico de resultado a la derecha sobre el widget reutilizado `MatchCenterCard` (con marcador final definitivo), calculado desde la perspectiva del equipo consultado:
  - **Victoria**: Cuando los goles a favor del equipo superan a los del rival (indicador visual verde de éxito + etiqueta localizada).
  - **Empate**: Cuando los goles a favor del equipo igualan a los del rival (indicador visual gris/amarillo de advertencia + etiqueta localizada).
  - **Derrota**: Cuando los goles a favor del equipo son inferiores a los del rival (indicador visual rojo sutil de error/alerta + etiqueta localizada).
- **FR-008**: Al tocar la tarjeta de un partido en cualquiera de las dos secciones, el sistema DEBE abrir una hoja modal informativa (`ModalBottomSheet`) con el detalle/informe del encuentro (mostrando jornada, equipos contendientes, marcador o estado actual, distintivo de resultado si ya finalizó, fecha/hora, cancha/sede y árbitro asignado), manteniendo a su vez la navegación directa al detalle del equipo rival (`/teams/:rivalId`) al tocar su escudo o nombre.
- **FR-009**: Si el equipo no posee ningún partido próximo ni ningún resultado anterior en el catálogo, la pestaña "Partidos" DEBE mostrar un estado vacío general mediante `KickPulseStateView`. Si solo una de las dos secciones carece de partidos, dicha sección DEBE mostrar su mensaje informativo vacío localizado sin ocultar los partidos de la otra sección.
- **FR-010**: Todos los textos visibles (encabezados de sección, etiquetas de Victoria/Empate/Derrota, textos de detalle de partido y estados vacíos) DEBEN estar centralizados en español mediante localización (`l10n` en `app_es.arb`), sin cadenas quemadas en código.
- **FR-011**: La pestaña "Partidos" DEBE preservar su posición de desplazamiento al cambiar entre pestañas (`PageStorageKey`) y renderizarse sin desbordamientos en viewports compactos (`320x640 px`) con escalado tipográfico de hasta el `130%`.

---

### Key Entities *(include if feature involves data)*

- **ChampionshipMatch**: Entidad de dominio que representa un partido del campeonato (`id`, `tournamentId`, `homeTeamId`, `awayTeamId`, `homeScore`, `awayScore`, `scheduledStartTime`, `pitchName`, `refereeName`, `status`, `roundNumber`, `roundName`).
- **TournamentTeam**: Entidad de dominio del club consultado y de sus equipos rivales, utilizada para resolver nombres, códigos cortos, escudos y colores.
- **TeamMatchOutcome**: Clasificación semántica del resultado de un partido finalizado desde la perspectiva del equipo consultado (`win`, `draw`, `loss`).
- **TeamMatchesSchedule**: Modelo inmutable de presentación para la pestaña "Partidos" que agrupa la lista ordenada de próximos encuentros (`upcomingMatches`) y la lista ordenada de resultados anteriores con su desenlace (`completedMatches`), derivado de forma reactiva desde el catálogo de partidos.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden cambiar a la pestaña "Partidos" en el detalle de un equipo y visualizar su calendario de próximos encuentros e historial de resultados en menos de 300 ms.
- **SC-002**: El 100% de los partidos listados en la pestaña "Partidos" corresponden exclusivamente a encuentros donde el equipo consultado participa como local o visitante, respetando el orden cronológico ascendente para próximos partidos y descendente para resultados anteriores.
- **SC-003**: El 100% de los partidos finalizados muestran de forma exacta su distintivo semántico (Victoria, Empate o Derrota) calculado desde la perspectiva del equipo consultado, tanto cuando actúa de local como cuando actúa de visitante.
- **SC-004**: Cero errores de desbordamiento visual (`RenderFlex overflow`) en resoluciones móviles compactas (`320x640 px`) con factor de escala de texto al `130%`.

---

## Assumptions

- **A-001**: Los partidos y equipos se consultan directamente desde los catálogos locales en memoria/almacenamiento local gestionados por estado reactivo, garantizando funcionamiento offline inmediato.
- **A-002**: La visualización del informe o detalle de partido al tocar un encuentro sigue el patrón de hoja modal informativa (`ModalBottomSheet`) establecido en el fixture del detalle de competición (HU 13.1), presentando jornada, equipos, marcador/estado, fecha/hora, sede/cancha y árbitro designado.
- **A-003**: La pestaña "Plantilla" dentro de `TeamDetailScreen` conserva su vista de preparación actual hasta ser implementada en la siguiente historia de usuario (HU 14.3).
