# Feature Specification: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Feature Branch**: `010-player-team-stats`

**Created**: 2026-11-04

**Status**: Draft

**Input**: User description: "de notion HU 8.2 en curso" (Notion Page ID: `4078442e-3f49-81e7-8fa5-fdad56a8898a`: "[Épica 8] HU 8.2: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo")

---

## Clarifications

### Session 2026-11-04
- Q: ¿Cómo deben contabilizarse los partidos jugados (`PJ`) y las titularidades de un jugador en cada partido oficial cerrado para su perfil de rendimiento e historial partido por partido? → A: Titulares + Ingresos / Incidencias Reales: suma `+1 Titularidad` y `+1 PJ` si figura como titular en la convocatoria del equipo (o participa sin haber entrado de cambio cuando no hay alineación previa), y suma `+1 PJ` como suplente si ingresa por sustitución o registra cualquier incidencia oficial en el acta cerrada, integrando el acumulado base si existiera (Opción A).
- Q: ¿Bajo qué criterios debe determinarse el estado disciplinario actual del jugador (`Habilitado` o `Suspendido`) en su perfil de rendimiento? → A: Evaluación integral de reglas y actas: se marca `Suspendido` si fue expulsado en el último partido oficial cerrado de su equipo, alcanzó el límite de acumulación de amarillas configurado en el torneo (`yellowCardSuspensionLimit`), tiene fechas de suspensión pendientes (`pendingSuspensionMatches > 0`) o está inhabilitado (`!isEligible`); de lo contrario, `Habilitado` (Opción A).
- Q: ¿Cómo deben integrarse en la navegación móvil los accesos a la Ficha de Estadísticas del Equipo y al Perfil de Rendimiento del Jugador sin alterar la barra de navegación inferior existente? → A: Drill-down contextual dentro de `StandingsTabView`: tocar una fila de equipo en `Posiciones` o `Fair Play` abre la Ficha de Estadísticas del Equipo; tocar un jugador en la plantilla del equipo o en `Rankings` abre el Perfil de Rendimiento del Jugador; e incluir un acceso rápido `"Mi Perfil Deportivo"` en la vista de estadísticas (Opción A).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Perfil Individual de Rendimiento e Historial Partido por Partido del Jugador (Priority: P1) 🎯 MVP

Como `Jugador` o `Entrenador` (o cualquier participante que consulte la ficha de un deportista desde un equipo o ranking), quiero visualizar el perfil individual de rendimiento del jugador con sus métricas consolidadas (partidos jugados, titularidades, goles anotados, asistencias, promedio de gol por partido, tarjetas amarillas, tarjetas rojas y estado disciplinario actual `Habilitado` o `Suspendido`) y el desglose histórico partido por partido donde tuvo participación o incidencias, para analizar su desempeño deportivo a lo largo del campeonato y llevar un registro transparente de logros y sanciones.

**Why this priority**: El perfil individual de rendimiento constituye el núcleo de valor para el jugador y cuerpo técnico, conectando directamente las convocatorias/alineaciones (HU 5.2) y las actas arbitrales cerradas (HU 7.1) en una ficha personal verificable y transparente.

**Independent Test**: Seleccionar un jugador desde la plantilla de un equipo, tabla de goleadores o desde el acceso directo de perfil deportivo, y verificar que las tarjetas de métricas muestran valores exactos en formato numérico tabular (`tabular-nums`), incluyendo el promedio de gol por partido y el estado disciplinario (`Habilitado` / `Suspendido`), seguidas de la lista cronológica de partidos oficiales en los que participó o registró incidencias.

**Acceptance Scenarios**:

1. **Given** que un usuario con rol `Jugador` accede a su perfil deportivo o un usuario selecciona un jugador desde un equipo o tabla de líderes, **When** se carga la vista de rendimiento del jugador, **Then** el sistema muestra sus tarjetas de métricas (`Partidos Jugados`, `Titularidades`, `Goles`, `Asistencias`, `Promedio de Gol`, `Tarjetas Amarillas`, `Tarjetas Rojas`) con formato `tabular-nums`, su insignia de estado disciplinario actual (`Habilitado` o `Suspendido`), y lista el desglose partido por partido donde tuvo participación o incidencias oficiales.
2. **Given** un jugador que ha disputado `4` partidos oficiales (`3` como titular y `1` como suplente) anotando `2` goles y dando `1` asistencia, **When** se calcula su perfil de rendimiento, **Then** el sistema muestra `PJ: 4`, `Titularidades: 3`, `Goles: 2`, `Asistencias: 1` y `Promedio de Gol: 0.50` sin errores de redondeo ni desbordamiento visual.
3. **Given** un jugador que recibió tarjeta roja o acumuló la sanción disciplinaria que lo inhabilita, **When** se consulta su perfil de rendimiento, **Then** el indicador de estado disciplinario muestra claramente la etiqueta `Suspendido` con semántica visual de alerta; en caso contrario, muestra `Habilitado`.

---

### User Story 2 - Ficha de Estadísticas Detalladas, Racha Reciente e Historial del Equipo (Priority: P2)

Como `Entrenador`, `Jugador` o seguidor del campeonato, quiero abrir la ficha detallada de un equipo desde la tabla de posiciones, llaves o calendario para consultar su posición actual, resumen de goles a favor/en contra, racha de los últimos 5 partidos (`V`, `E`, `D`), historial de resultados disputados, próximos rivales programados y el listado completo de su plantilla con el aporte estadístico individual de cada jugador, para evaluar el rendimiento colectivo e individual del club en un solo lugar.

**Why this priority**: La ficha detallada del equipo complementa la tabla general de posiciones (HU 8.1) ofreciendo contexto táctico e histórico inmediato (racha reciente, calendario venidero y rendimiento de toda la plantilla) antes y después de cada jornada.

**Independent Test**: Tocar una fila de equipo en la tabla de posiciones (`StandingsTabView`) o seleccionar un club en la vista de estadísticas, y comprobar que se despliega la ficha del equipo con su posición actual, indicadores `PJ / PG / PE / PP / GF / GC / DG / PTS`, secuencia visual de racha de hasta 5 partidos (`V`, `E`, `D`), lista de resultados anteriores, próximos encuentros programados y tabla/lista de la plantilla con estadísticas por jugador (permitiendo tocar un jugador para ir a su perfil individual).

**Acceptance Scenarios**:

1. **Given** que un usuario selecciona un equipo desde la tabla de posiciones o el directorio del torneo, **When** abre la ficha detallada del equipo, **Then** visualiza su posición actual en el campeonato, la racha reciente de los últimos 5 partidos finalizados (`V` para victoria, `E` para empate, `D` para derrota), goles a favor y en contra, historial de resultados cerrados, próximos encuentros programados y el aporte estadístico de cada jugador inscrito en el plantel.
2. **Given** que el usuario visualiza el listado de plantilla dentro de la ficha detallada del equipo, **When** selecciona a cualquier jugador del plantel, **Then** navega directamente al perfil individual de rendimiento de dicho jugador (User Story 1).

---

### User Story 3 - Manejo de Estados Vacíos Sin Errores de División por Cero y Persistencia Offline (Priority: P3)

Como `Jugador` o `Entrenador` de un equipo recién inscrito o en un entorno de cancha con conectividad intermitente, quiero que el perfil del jugador y las estadísticas del equipo presenten métricas inicializadas en `0` (`0.00` en promedios) junto con mensajes informativos claros en español cuando aún no existen partidos disputados, y que la última información sincronizada del perfil deportivo esté disponible localmente sin conexión, para garantizar una experiencia confiable y libre de fallos en cualquier momento del torneo.

**Why this priority**: Previene fallos matemáticos (`NaN` / `Infinity` al calcular promedios con `0` partidos jugados) en las etapas iniciales del torneo o con jugadores suplentes sin debutar, y asegura disponibilidad inmediata en canchas sin cobertura móvil.

**Independent Test**: Consultar el perfil de un jugador recién inscrito con `0` partidos oficiales disputados y verificar que todos los contadores muestran `0`, el promedio de gol muestra `0.00`, no ocurre ningún error de división por cero y aparece exactamente el mensaje en español `"Aún no registras participaciones en partidos oficiales de este torneo."`; además, comprobar que en modo offline se conserva y muestra la caché local del perfil.

**Acceptance Scenarios**:

1. **Given** que un jugador acaba de ser inscrito en un torneo que aún no inicia o en el que aún no ha tenido participación oficial, **When** consulta su perfil de estadísticas, **Then** el sistema presenta todos los indicadores en `0` (y promedio de gol en `0.00`) sin errores de cálculo y muestra el mensaje en español: `"Aún no registras participaciones en partidos oficiales de este torneo."`
2. **Given** un equipo recién inscrito que aún no ha disputado partidos oficiales cerrados, **When** un usuario abre su ficha de estadísticas, **Then** las métricas se muestran en `0`, la sección de racha e historial de resultados muestra un estado vacío informativo en español sin errores visuales, y se listan sus próximos partidos programados (si existen) junto con su plantilla inscrita en `0`.
3. **Given** que el jugador autenticado consultó previamente su perfil o los datos del torneo ya fueron almacenados en el dispositivo, **When** abre su perfil de rendimiento sin conexión a internet, **Then** el sistema carga de inmediato la información desde el almacenamiento local sin pantallas de error bloqueantes.

---

### Edge Cases

- **División por cero en promedio de goles (`PJ == 0`)**: Si un jugador tiene `0` partidos jugados (o incluso si registró una tarjeta desde el banco de suplentes sin sumar partido jugado de campo, o aún no debuta), el promedio de gol por partido debe evaluarse de forma segura como `0.00` (nunca `NaN` ni `Infinity`).
- **Equipos con menos de 5 partidos disputados**: Si un equipo solo ha jugado `N < 5` partidos oficiales cerrados, la racha reciente debe mostrar únicamente los `N` indicadores correspondientes (`V`, `E`, `D`) ordenados cronológicamente sin rellenar con resultados falsos.
- **Nombres largos de jugadores o clubes en pantallas compactas (`320px - 375px`) y escalado de texto (`130%`)**: Los encabezados de perfil, tarjetas de métricas y filas de plantilla deben adaptarse responsivamente (usando salto de línea controlado o distribución flexible) sin truncar de forma ilegible los nombres ni provocar desbordamientos (`0 RenderFlex overflows`).
- **Incidencias en partidos no cerrados**: Los eventos de partidos en curso o programados no deben alterar las estadísticas consolidadas oficiales hasta que el acta arbitral sea cerrada (`MatchPeriod.closed` / `MatchStatus.completed`), manteniendo consistencia total con la tabla de posiciones (HU 8.1).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar la vista de Perfil Personal de Rendimiento del Jugador con las siguientes métricas oficiales: partidos jugados (`PJ`), titularidades, goles anotados, asistencias, promedio de gol por partido (formateado a 2 decimales, ej. `0.50`), tarjetas amarillas, tarjetas rojas y estado disciplinario actual (`Habilitado` o `Suspendido`). El estado disciplinario se determina como `Suspendido` cuando el jugador fue expulsado en el último partido oficial cerrado de su equipo, alcanzó el límite de acumulación de tarjetas amarillas del torneo (`yellowCardSuspensionLimit`), posee fechas de suspensión pendientes (`pendingSuspensionMatches > 0`) o se encuentra inhabilitado (`!isEligible`); en caso contrario se muestra `Habilitado`.
- **FR-002**: El sistema DEBE mostrar en el Perfil del Jugador el desglose histórico partido por partido en los que tuvo participación o registró incidencias (goles, asistencias, tarjetas), indicando rival, marcador final, fecha/jornada y las métricas del jugador en ese encuentro. Para cada partido oficial cerrado, el jugador suma `+1 Titularidad` y `+1 PJ` si figura como titular en la convocatoria (`MatchLineupConvocation`) o si participa sin haber entrado de cambio cuando no existe alineación previa; y suma `+1 PJ` como suplente si ingresa mediante evento de sustitución (`MatchEventType.substitution`) o registra cualquier incidencia oficial en el acta cerrada (`DigitalMatchReport`), integrando el seguimiento base cuando corresponda.
- **FR-003**: El sistema DEBE calcular el promedio de gol por partido de forma segura (`goles / partidosJugados`), retornando `0.00` cuando `partidosJugados == 0` para evitar errores de división por cero.
- **FR-004**: El sistema DEBE mostrar la Ficha de Estadísticas Detalladas del Equipo incluyendo: posición actual en la tabla, resumen estadístico (`PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`), racha de los últimos 5 partidos oficiales cerrados (`V`, `E`, `D`), historial de resultados disputados, próximos rivales/encuentros programados y el listado completo de su plantilla con las estadísticas individuales de cada jugador.
- **FR-005**: El sistema DEBE permitir navegación contextual (*drill-down*) dentro de `StandingsTabView` sin exceder las 5 pestañas de la barra inferior: tocar una fila de equipo en `Posiciones` o `Fair Play` abre la Ficha de Estadísticas Detalladas del Equipo; tocar un jugador en la plantilla del equipo o en las tablas de `Rankings` (`Goleadores`/`Asistencias`) abre el Perfil de Rendimiento del Jugador; e incluir un botón de acceso directo `"Mi Perfil Deportivo"` en la cabecera de estadísticas para consultar el perfil del jugador activo.
- **FR-006**: Cuando un jugador aún no registra participaciones en partidos oficiales cerrados del torneo, el sistema DEBE presentar todas sus métricas en `0` (`0.00` para promedio) y mostrar el mensaje exacto en español: `"Aún no registras participaciones en partidos oficiales de este torneo."`
- **FR-007**: Cuando un equipo aún no ha disputado partidos oficiales cerrados, el sistema DEBE mostrar sus métricas numéricas en `0` y presentar estados vacíos informativos en español para su racha e historial de resultados.
- **FR-008**: Todas las cifras y métricas numéricas tanto del perfil del jugador como de la ficha del equipo DEBEN renderizarse utilizando alineación numérica tabular (`tabular-nums`).
- **FR-009**: El sistema DEBE persistir localmente en caché el perfil de rendimiento del jugador y los datos estadísticos consultados para permitir su visualización inmediata sin conexión (modo offline).
- **FR-010**: Todos los textos visibles para el usuario (etiquetas de métricas, estados disciplinarios `Habilitado`/`Suspendido`, indicadores de racha `V`/`E`/`D`, encabezados de sección y mensajes de estado vacío) DEBEN estar en español y centralizados en `app_es.arb`.

---

### Key Entities *(include if feature involves data)*

- **`PlayerPerformanceProfile`**: Agregado que consolida el rendimiento individual de un jugador en un campeonato: datos del jugador (`playerId`, `fullName`, `shirtNumber`, `position`, `teamId`, `teamName`), estado disciplinario (`isSuspended` / `disciplinaryStatus`: `Habilitado` | `Suspendido`), métricas acumuladas (`matchesPlayed`, `startsCount`, `goals`, `assists`, `goalsPerMatchAverage`, `yellowCards`, `redCards`) y lista cronológica de participaciones por partido (`matchParticipations`).
- **`PlayerMatchParticipation`**: Registro del desempeño de un jugador en un partido oficial cerrado: `matchId`, `roundNumber`, `scheduledAt`, `opponentTeamId`, `opponentTeamName`, `teamScore`, `opponentScore`, `wasStarter`, `goals`, `assists`, `yellowCards`, `redCards`.
- **`TeamDetailedStats`**: Agregado que consolida la ficha estadística de un equipo en el torneo: identificación del club (`teamId`, `teamName`, `shortCode`, `primaryColorHex`, `category`), `currentPosition`, métricas de clasificación (`StandingsRow`), `recentForm` (lista de hasta 5 resultados `TeamFormResult`: `win`, `draw`, `loss` representados en UI como `V`, `E`, `D`), `completedMatches` (historial de resultados), `upcomingMatches` (próximos rivales programados) y `squadStats` (lista de perfiles resumidos de todos los jugadores inscritos en el equipo).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El cálculo del perfil de rendimiento de un jugador y de la ficha detallada de un equipo se completa en menos de 50 milisegundos en el dispositivo móvil a partir de los datos locales del torneo.
- **SC-002**: El 100% de las consultas de jugadores o equipos con `0` partidos disputados se renderizan con métricas en `0` / `0.00` y su mensaje informativo en español sin producir excepciones ni valores `NaN`/`Infinity`.
- **SC-003**: El 100% de las métricas individuales (`PJ`, goles, asistencias, tarjetas) mostradas en el perfil del jugador coinciden de manera determinista con los eventos de las actas oficiales cerradas y las alineaciones registradas del torneo.
- **SC-004**: Las pantallas de perfil del jugador y ficha detallada del equipo se visualizan sin desbordamientos de interfaz (`0 RenderFlex overflows`) en pantallas móviles desde `320px` de ancho y con escalado tipográfico del sistema de hasta `130%`.
- **SC-005**: El perfil deportivo del jugador autenticado y las estadísticas locales del torneo se cargan de forma instantánea (0 segundos de bloqueo de red) cuando el dispositivo se encuentra sin conexión.

---

## Assumptions

- Las participaciones y titularidades de un jugador en cada partido se determinan combinando las alineaciones/convocatorias registradas para el encuentro (`TeamLineup` de HU 5.2: titulares y suplentes) y las incidencias oficiales registradas en el acta arbitral cerrada (`DigitalMatchReport` de HU 7.1: goles, asistencias y tarjetas). Si un jugador registra una incidencia oficial en el acta cerrada de un partido en el que no se guardó alineación previa, igualmente se contabiliza su participación en dicho partido.
- El estado disciplinario actual del jugador (`Habilitado` vs `Suspendido`) se determina a partir de su elegibilidad vigente en el plantel (`RegisteredPlayer.isEligible`) y/o si recibió una expulsión (tarjeta roja directa o doble amarilla) en el último partido oficial disputado por su equipo.
- La racha de los últimos 5 partidos (`V`, `E`, `D`) se calcula sobre los últimos 5 partidos con acta cerrada del equipo ordenados cronológicamente por fecha/jornada.
