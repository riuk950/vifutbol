# Feature Specification: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Feature Branch**: `009-standings-brackets-rankings`

**Created**: 2026-11-04

**Status**: Draft

**Input**: User description: "de notion HU 8.1 en curso" (Notion Page ID: `4078442e-3f49-81b5-8b50-df02c5db9336`: "[Épica 8] HU 8.1: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos")

---

## Clarifications

### Session 2026-11-04
- Q: ¿Cómo deben estructurarse en la interfaz móvil las llaves eliminatorias (*bracket tree*) para garantizar una visualización clara y sin desbordamientos en pantallas compactas? → A: Vista por rondas individuales mediante pestañas/chips horizontales con tarjetas de cruces (`Vs`), acompañada de un visor panorámico desplazable en 2D (Opción A).
- Q: ¿Cómo debe resolverse el criterio de desempate por enfrentamiento directo (*Head-to-Head*) si los dos equipos empatados no se han enfrentado aún en el fixture o si empataron en su partido mutuo? → A: Evaluar resultado directo solo si hubo ganador definido en su duelo mutuo; si no jugaron aún o empataron, se evalúa inmediatamente el siguiente criterio jerárquico configurado (Opción A).
- Q: ¿Cómo deben ponderarse los puntos de penalización en la tabla de Fair Play por cada tipo de tarjeta oficial recibida? → A: -1 punto por amarilla, -3 puntos por segunda amarilla/roja y -3 puntos por roja directa; el equipo con menor penalización acumulada lidera la tabla de Fair Play (Opción A).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cálculo Determinista y Visualización de la Tabla de Posiciones de Liga con Desempate Jerárquico (Priority: P1) 🎯 MVP

Como participante o seguidor del campeonato (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), quiero que la tabla de clasificación general y por grupos se derive de forma determinista tras el cierre de cada partido oficial, evaluando en orden estricto los criterios de desempate configurados en el torneo (puntos, diferencia de goles, goles a favor, enfrentamiento directo y puntaje Fair Play), para consultar una clasificación transparente, indiscutible y perfectamente alineada en pantalla móvil.

**Why this priority**: La tabla de posiciones es el núcleo competitivo de ligas y fases de grupos. Proporciona el valor primario de la competición para todos los roles y debe actualizarse de forma reactiva e inmediata sin discrepancias manuales.

**Independent Test**: Registrar y cerrar actas oficiales de partidos de liga con resultados variados, abrir la pestaña de tabla de posiciones (`StandingsTabView`) y verificar que los partidos jugados (`PJ`), ganados (`PG`), empatados (`PE`), perdidos (`PP`), goles a favor (`GF`), goles en contra (`GC`), diferencia de gol (`DG`) y puntos (`PTS`) coinciden exactamente con las reglas de puntuación del torneo (`TournamentRulesConfig`), y que ante igualdad de puntos se aplica el desempate automático configurado (ej. diferencia de gol, goles a favor o Fair Play).

**Acceptance Scenarios**:

1. **Given** un campeonato de formato `Liga` con puntuación estándar (3 puntos por victoria, 1 por empate, 0 por derrota) y dos equipos sin partidos registrados, **When** el árbitro cierra el acta oficial del partido con resultado `Equipo Local 2 - 1 Equipo Visitante`, **Then** el sistema actualiza inmediatamente la tabla reflejando:
   - `Equipo Local`: `PJ: 1, PG: 1, PE: 0, PP: 0, GF: 2, GC: 1, DG: +1, PTS: 3`.
   - `Equipo Visitante`: `PJ: 1, PG: 0, PE: 0, PP: 1, GF: 1, GC: 2, DG: -1, PTS: 0`.
   - Las filas se ordenan con el `Equipo Local` en primer lugar y todas las columnas numéricas están renderizadas con alineación tabular fija (`tabular-nums`).

2. **Given** que dos equipos (`Equipo A` y `Equipo B`) tienen idéntica cantidad de puntos (`PTS = 12`), **When** el sistema evalúa la jerarquía de desempate del torneo:
   - Si el criterio prioritario es `Diferencia de Gol` y `Equipo A` tiene `+8` mientras `Equipo B` tiene `+5`, el sistema posiciona a `Equipo A` por encima de `Equipo B`.
   - Si la diferencia de gol es idéntica (`+5` vs `+5`) y el siguiente criterio es `Goles a Favor` (`14` vs `16`), el sistema posiciona a `Equipo B` por encima de `Equipo A`.
   - Si persiste empate en goles a favor y el siguiente criterio es `Fair Play` (menor cantidad de puntos de penalización por tarjetas: -1 por tarjeta amarilla, -3 por tarjeta roja directa o doble amarilla), el equipo con mejor conducta deportiva se ubica en la posición superior.

---

### User Story 2 - Cuadro Visual y Avance Automático de Llaves en Copas Eliminatorias (Priority: P2)

Como organizador, entrenador o aficionado de un torneo de eliminación directa (`Copa Eliminatoria` o fase final de grupos), quiero visualizar el cuadro interactivo de llaves (*bracket tree*) ordenado por rondas cronológicas (octavos, cuartos, semifinal, final) y que, al cerrarse el acta oficial de un partido eliminatorio (en tiempo reglamentario o definición por penales), el ganador avance automáticamente como participante de la llave de la siguiente fase, para seguir el progreso del campeonato sin asignaciones manuales ni retrasos.

**Why this priority**: Los campeonatos de copa requieren propagación estricta del ganador hacia la siguiente ronda eliminatoria. La automatización del emparejamiento previene inconsistencias humanas y permite a los hinchas y equipos proyectar sus siguientes cruces en tiempo real.

**Independent Test**: Configurar un torneo de eliminación directa (`KnockoutCup`), completar el partido de cuartos de final entre `Equipo 1` y `Equipo 2` con victoria de `Equipo 1`, verificar que en la pantalla de llaves eliminatorias la llave de semifinal correspondiente se actualiza inmediatamente mostrando a `Equipo 1` clasificado como local o visitante según la estructura de la llave.

**Acceptance Scenarios**:

1. **Given** un torneo de formato `Copa Eliminatoria` con llaves generadas desde cuartos de final, **When** el árbitro cierra el acta del partido `Cuartos 1` donde `Equipo Alfa` vence `3 - 1` a `Equipo Beta`, **Then** el sistema actualiza el estado de la llave `Cuartos 1` a finalizada, marca a `Equipo Alfa` como ganador y lo ubica automáticamente en la llave programada de `Semifinal 1`.
2. **Given** un partido eliminatorio empatado en tiempo reglamentario (`1 - 1`) cuya regla de torneo estipula definición por penales (`directPenaltyShootoutOnDraw: true`), **When** el árbitro registra el desempate por penales (`Penales: 5 - 4` a favor de `Equipo Gamma`) y cierra el acta, **Then** el sistema reconoce a `Equipo Gamma` como ganador de la serie y lo avanza a la siguiente ronda del cuadro.

---

### User Story 3 - Rankings Individuales y Colectivos Deportivos (Goleadores, Asistencias y Fair Play) (Priority: P3)

Como participante o aficionado, quiero consultar las tablas de líderes deportivos del campeonato (máximos goleadores, líderes en asistencias y ranking de Fair Play / tarjetas) calculadas de manera agregada y determinista a partir de los eventos oficiales de los partidos, para reconocer el rendimiento de los deportistas y la disciplina de los clubes.

**Why this priority**: Los premios individuales y el seguimiento del rendimiento deportivo fomentan la participación comunitaria, la visibilidad de los talentos locales y la transparencia deportiva del campeonato.

**Independent Test**: Cerrar actas de partidos que contengan múltiples goles, asistencias y tarjetas, abrir la sección de estadísticas y rankings deportivos (`RankingsTabView`), y comprobar que los jugadores están ordenados descendentemente por goles anotados, asistencias otorgadas y conducta deportiva (conteo de tarjetas amarillas y rojas).

**Acceptance Scenarios**:

1. **Given** partidos oficiales completados con goles y asistencias registrados, **When** un usuario consulta la tabla de `Goleadores`, **Then** visualiza la lista de jugadores con nombre completo, equipo, dorsal y número de goles anotados, ordenados de mayor a menor; ante empate en goles, se ubica primero quien tenga mayor cantidad de asistencias o menor cantidad de minutos jugados.
2. **Given** un usuario que selecciona la pestaña `Fair Play`, **When** consulta la clasificación de conducta por equipos, **Then** visualiza a los equipos ordenados de menor a mayor penalización por sanciones disciplinarias acumuladas.

---

### Edge Cases

- **Empate absoluto en todos los criterios configurados**: Si dos equipos empatan en puntos, diferencia de goles, goles a favor, duelo directo y tarjetas Fair Play, el sistema aplica un criterio determinista reproducible (orden alfabético por nombre oficial de equipo) e indica visualmente el empate técnico.
- **Partidos suspendidos o sin acta cerrada**: Partidos en estado programado o en juego no modifican los puntos ni las estadísticas acumuladas en la tabla de posiciones ni el avance de llaves eliminatorias.
- **Torneo mixto (grupos y eliminación directa)**: Cada grupo calcula su propia tabla de posiciones independiente y, al finalizar la fase de grupos, los clasificados según la configuración del torneo (`advancingPerGroup`) se siembran automáticamente en las llaves de la fase eliminatoria.
- **Visualización en pantallas estrechas (320px - 375px)**: La tabla de posiciones debe soportar desplazamiento horizontal suave o modo condensado sin desbordamientos de texto ni solapamiento de cifras numéricas.
- **Modo sin conexión (Offline)**: Si el usuario pierde conexión a internet, las tablas de posiciones y llaves ya sincronizadas deben ser consultables localmente desde la caché del dispositivo sin pantallas de error bloqueantes.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE calcular las estadísticas de la tabla de posiciones (`PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`) de forma determinista y exclusiva a partir de las actas de partidos oficiales cerradas (`MatchPeriod.closed` / `MatchStatus.completed`).
- **FR-002**: El sistema DEBE aplicar las reglas de puntuación específicas configuradas en el torneo (`TournamentRulesConfig.pointsForWin`, `pointsForDraw`, `pointsForLoss`).
- **FR-003**: El sistema DEBE ordenar las posiciones de los equipos resolviendo desempates según la lista jerárquica de criterios configurada en el torneo (`tiebreakerOrder`: `goalDifference`, `goalsFor`, `headToHead`, `fairPlay`). En el criterio `headToHead`, si los equipos empatados aún no se han enfrentado o empataron en su partido mutuo, el criterio se declara igualado y se procede inmediatamente al siguiente criterio jerárquico.
- **FR-004**: En torneos con fase de grupos (`TournamentFormat.mixedGroupsAndKnockout`), el sistema DEBE generar y mostrar tablas de posiciones independientes por cada grupo configurado.
- **FR-005**: En torneos de eliminación directa (`TournamentFormat.knockoutCup` o fase final de grupos), el sistema DEBE construir y desplegar el cuadro de llaves eliminatorias (*bracket tree*) estructurado con navegación por rondas individuales mediante pestañas/chips horizontales con tarjetas de cruces (`Vs`), junto con un visor panorámico desplazable en 2D adaptado a pantallas móviles compactas.
- **FR-006**: Al cerrarse el acta oficial de un partido eliminatorio, el sistema DEBE marcar automáticamente al equipo ganador y sembrarlo en el casillero correspondiente de la ronda siguiente sin requerir intervención manual.
- **FR-007**: El sistema DEBE generar el ranking de máximos goleadores listando jugador, dorsal, equipo y goles oficiales acumulados.
- **FR-008**: El sistema DEBE generar el ranking de asistencias listando jugador, dorsal, equipo y asistencias oficiales acumuladas.
- **FR-009**: El sistema DEBE generar la tabla disciplinaria / Fair Play consolidando tarjetas oficiales con penalizaciones exactas: -1 punto por tarjeta amarilla, -3 puntos por segunda amarilla/roja y -3 puntos por roja directa, ordenando de menor a mayor penalización acumulada por equipo y por jugador.
- **FR-010**: Todas las columnas numéricas de la tabla de posiciones y de los rankings individuales DEBEN formatearse con cifras monoespaciadas/tabulares (`tabular-nums`) para garantizar perfecta alineación vertical en dispositivos móviles.
- **FR-011**: Los datos de tablas de posiciones, llaves y rankings DEBEN estar disponibles para consulta sin conexión mediante persistencia local offline.
- **FR-012**: Todos los textos de interfaz, encabezados de columnas, nombres de rondas y mensajes informativos DEBEN estar centralizados en español en los archivos de localización del proyecto (`app_es.arb`).

---

### Key Entities *(include if feature involves data)*

- **`StandingsTable` / `StandingsRow`**: Agregado que representa la tabla de posiciones oficial. Contiene la lista ordenada de filas con: `teamId`, `teamName`, `teamShortCode`, `teamCrest`, `played (PJ)`, `won (PG)`, `drawn (PE)`, `lost (PP)`, `goalsFor (GF)`, `goalsAgainst (GC)`, `goalDifference (DG)`, `points (PTS)`, `fairPlayScore` y posición en la tabla.
- **`KnockoutBracket` / `KnockoutMatchNode`**: Agregado que modela el árbol de llaves eliminatorias. Cada nodo representa una serie head-to-head con: `matchId`, `round` (`KnockoutRound`), `homeTeam`, `awayTeam`, `homeScore`, `awayScore`, `winnerTeamId`, `nextMatchId` y estado del cruce.
- **`PlayerPerformanceRanking` / `RankingEntry`**: Entidad para clasificaciones individuales deportivas: `playerId`, `playerName`, `shirtNumber`, `teamId`, `teamName`, `metricValue` (goles o asistencias), y métricas secundarias de desempate.
- **`TeamFairPlayRow`**: Entidad de disciplina colectiva: `teamId`, `teamName`, `yellowCards`, `secondYellowRedCards`, `directRedCards` y `penaltyPointsTotal`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El recálculo y reordenamiento de la tabla de posiciones tras el cierre oficial de un partido se ejecuta en menos de 50 milisegundos en el dispositivo móvil.
- **SC-002**: El 100% de los empates en puntos se resuelven de forma determinista y reproducible respetando la jerarquía de desempate configurada en el torneo.
- **SC-003**: En torneos eliminatorios, el 100% de los ganadores de llaves cerradas avanzan automáticamente a la siguiente ronda sin intervención del organizador.
- **SC-004**: Todas las columnas numéricas de la tabla se visualizan sin desbordamientos de píxeles (`0 RenderFlex overflows`) en pantallas con factor de escala de texto de hasta 130%.
- **SC-005**: Las tablas y llaves se muestran de manera instantánea (0 segundos de espera percibida) mediante la caché local cuando no hay conexión de datos.

---

## Assumptions

- Se reutiliza la arquitectura existente de repositorios de partidos (`TournamentMatchesRepository`), equipos (`TeamsRepository`) y actas oficiales (`MatchReportsRepository`).
- Los puntos para victoria, empate y derrota, así como los criterios de desempate y la estructura de llaves, se leen directamente de la configuración oficial del torneo (`TournamentRulesConfig`).
- El cálculo se ejecuta localmente mediante casos de uso en el dispositivo móvil, asegurando funcionamiento resiliente e instantáneo sin depender de latencia de red.
- La navegación principal permite alternar fluidamente entre la tabla de posiciones, las llaves eliminatorias y los rankings de estadísticas dentro del módulo de campeonatos.
