# Feature Specification: Pestaña de Clasificación y Resultados de Equipos en el Detalle de Competición (HU 13.2)

**Feature Branch**: `019-competition-detail-standings`  
**Created**: 2026-11-06  
**Status**: Draft  
**Input**: User description: "[Épica 13] HU 13.2: Pestaña de Clasificación y Resultados de Equipos en el Detalle de Competición"

---

## Clarifications

### Session 2026-11-06

- Q: ¿Cuál debe ser la subvía competitiva activa por defecto al ingresar a la pestaña "Clasificación" en torneos con formato mixto (`mixedGroupsAndKnockout`)? (FR-005) → A: "Posiciones" (Fase de Grupos) por defecto siempre al ingresar.
- Q: ¿Qué métricas y secciones deben incluirse en la subvía de "Estadísticas" (`TournamentRankingsCard`) dentro del detalle de la competición? (FR-006) → A: Goleadores, Fair Play (Tarjetas) y Vallas Invictas (componente completo).
- Q: ¿Cómo debe comportarse la interfaz si una competición tiene partidos jugados pero aún no registra goles, tarjetas o estadísticas individuales para la subvía de "Estadísticas"? (FR-009) → A: Mostrar `KickPulseStateView` informativo ("Sin estadísticas registradas aún") en la subvía de Estadísticas, manteniendo los chips visibles.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualización de Tabla de Posiciones Oficial para Torneo Tipo Liga (Priority: P1) 🎯 MVP

**User Journey**:
Como aficionado, seguidor de equipo o miembro de club, accedo a la pestaña "Clasificación" dentro del detalle de una competición con formato de liga (`league`) para consultar la tabla de posiciones oficial completa, con ordenamiento estricto por puntos y criterios de desempate oficiales, visualizando escudo, nombre de equipo y métricas tabulares (`PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`).

**Why this priority**:
Es la necesidad central y más común en cualquier campeonato deportivo: conocer la tabla de posiciones oficial y la posición competitiva de cada equipo. Provee un MVP completamente funcional e independiente para competiciones en curso.

**Independent Test**:
Navegar a `/competitions/:id` de un torneo tipo liga con partidos finalizados, pulsar la pestaña "Clasificación", y verificar que se renderiza `StandingsTableCard` con todas las filas ordenadas por puntos y diferencia de gol con tipografía tabular.

**Acceptance Scenarios**:
1. **Given** un torneo con formato `league` y partidos registrados con marcador final, **When** el usuario selecciona la pestaña "Clasificación", **Then** se muestra la tabla de posiciones oficial con columnas `#`, Equipo, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG` y `PTS`.
2. **Given** dos o más equipos empatados en puntos, **When** se calcula la tabla, **Then** el desempate se resuelve conforme a las reglas configuradas del torneo (diferencia de goles, goles a favor, etc.) mostrando el orden correcto.
3. **Given** la tabla de posiciones desplegada, **When** se observan los valores numéricos de las columnas estadísticas, **Then** se visualizan con alineación numérica consistente y tipografía tabular (`FontFeature.tabularFigures()`).

---

### User Story 2 - Cuadro de Llaves Eliminatorias (Bracket) para Torneo de Copa (Priority: P2)

**User Journey**:
Como aficionado o coordinador deportivo, accedo a la pestaña "Clasificación" de una competición con formato de copa / eliminación directa (`knockoutCup`) para inspeccionar el árbol visual interactivo de llaves (`KnockoutBracketCard`), observando las diferentes rondas (Octavos, Cuartos, Semifinal, Final), los cruces y los equipos clasificados.

**Why this priority**:
En competiciones de eliminación directa no existe una tabla de puntos convencional; el usuario necesita ver el bracket visual interactivo para entender el progreso del campeonato y el camino hacia la final.

**Independent Test**:
Navegar a `/competitions/:id` de un torneo tipo copa eliminatoria, pulsar "Clasificación", y verificar que en lugar de una tabla vacía se renderiza el widget de llaves eliminatorias con sus rondas y emparejamientos.

**Acceptance Scenarios**:
1. **Given** un torneo con formato `knockoutCup`, **When** el usuario ingresa a la pestaña "Clasificación", **Then** la vista muestra el cuadro de llaves eliminatorias (`KnockoutBracketCard`) mostrando las rondas correspondientes.
2. **Given** un partido de eliminatoria concluido con ganador, **When** se actualiza el cuadro, **Then** el equipo vencedor se refleja automáticamente como clasificado a la siguiente ronda.

---

### User Story 3 - Alternancia entre Grupos y Llaves en Torneos Mixtos (Priority: P3)

**User Journey**:
Como usuario que consulta un torneo con formato mixto (`mixedGroupsAndKnockout`), puedo alternar de manera fluida entre la fase de grupos (tablas de posiciones por cada grupo) y la fase final de llaves eliminatorias mediante un selector de vista claro e intuitivo.

**Why this priority**:
Los torneos mixtos combinan ambas dinámicas competitivas; el usuario requiere alternar entre la fase clasificatoria de grupos y la fase de eliminación sin fricción.

**Independent Test**:
Navegar a `/competitions/:id` de un torneo mixto, verificar la presencia de un selector de vista, alternar entre "Grupos" y "Llaves", y comprobar que el contenido cambia preservando el estado sin recálculos innecesarios.

**Acceptance Scenarios**:
1. **Given** un torneo con formato `mixedGroupsAndKnockout`, **When** el usuario está en la pestaña "Clasificación", **Then** se presenta un selector que permite alternar entre las tablas de grupos y el cuadro de eliminación directa.
2. **Given** la selección de la fase de grupos, **When** existen múltiples grupos (Grupo A, Grupo B), **Then** se pueden consultar las posiciones de cada grupo respectivo.

---

### User Story 4 - Estadísticas Adicionales y Ranking de Goleadores (Priority: P4)

**User Journey**:
Como aficionado o seguidor, deseo consultar los rankings individuales y de equipo de la competición, incluyendo la tabla de máximos goleadores (`TournamentRankingsCard`), jugadores amonestados/expulsados y estadísticas de Fair Play acumuladas en el torneo.

**Why this priority**:
Complementa la información posicional con el reconocimiento al rendimiento individual de los jugadores y la disciplina deportiva.

**Independent Test**:
En la pestaña "Clasificación", acceder a la sección de estadísticas / rankings del torneo y verificar que se listan los máximos anotadores ordenados por número de goles, así como las tarjetas acumuladas.

**Acceptance Scenarios**:
1. **Given** un torneo con actas de partidos que incluyen goles registrados, **When** el usuario visualiza los rankings de la competición, **Then** se muestra la lista de máximos goleadores con su posición, jugador, equipo y total de goles.
2. **Given** tarjetas amarillas y rojas registradas, **When** se consultan las estadísticas disciplinarias, **Then** se visualiza el resumen de tarjetas por jugador o equipo.

---

### User Story 5 - Estados Vacíos y Resiliencia sin Partidos Jugados (Priority: P5)

**User Journey**:
Como usuario que ingresa al detalle de una competición que aún no ha iniciado o no tiene partidos completados con actas oficiales, visualizo un estado vacío informativo y amigable (`KickPulseStateView`) que me explica con claridad que la clasificación estará disponible tan pronto como se registren los primeros resultados.

**Why this priority**:
Garantiza robustez visual y previene pantallas en blanco, errores o bloqueos ante torneos recién creados.

**Independent Test**:
Navegar a un torneo en fase de registro sin partidos completados, pulsar "Clasificación", y verificar el mensaje amigable de estado vacío sin errores de renderizado.

**Acceptance Scenarios**:
1. **Given** un torneo sin actas de partidos finalizadas, **When** el usuario abre la pestaña "Clasificación", **Then** se muestra un `KickPulseStateView` indicando "Sin Clasificación Disponible" y una descripción explicativa.
2. **Given** la carga de datos en progreso, **When** el controlador procesa el snapshot competitivo, **Then** se muestra un indicador de carga sin bloquear la interfaz.

---

### Edge Cases

- **Empates triples o cuádruples en puntos**: El sistema debe aplicar de forma determinista la cascada de criterios de desempate (diferencia de gol, goles a favor, tarjetas Fair Play) sin alterar el orden arbitrariamente.
- **Cambio de pestaña rápido (Tab switching)**: La vista debe memorizar o reutilizar el snapshot ya calculado (`StandingsAndRankingsState`) para evitar cálculos repetitivos en cada cambio entre "Partidos", "Clasificación" e "Información".
- **Pantallas pequeñas ($320 \times 640\text{ px}$) y alto escalado ($130\%$)**: La tabla de posiciones debe permitir desplazamiento horizontal controlado en las columnas estadísticas sin causar desbordamientos `RenderFlex` en la pantalla vertical.
- **Torneo sin equipos asignados**: Si el torneo no tiene equipos registrados, debe presentar el estado vacío informativo correspondiente sin provocar excepciones por colecciones vacías.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE renderizar en la pestaña "Clasificación" de `CompetitionDetailScreen` la vista competitiva correspondiente al formato del torneo (`league`, `knockoutCup`, `mixedGroupsAndKnockout`).
- **FR-002**: Para torneos tipo `league`, el sistema DEBE mostrar la tabla de posiciones oficial reutilizando `StandingsTableCard`, incluyendo posición `#`, escudo del equipo, nombre, y las columnas numéricas `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG` y `PTS`.
- **FR-003**: Todas las métricas y columnas numéricas de la tabla de posiciones DEBEN renderizarse con alineación uniforme y tipografía con cifras tabulares (`FontFeature.tabularFigures()`).
- **FR-004**: Para torneos tipo `knockoutCup`, el sistema DEBE mostrar el árbol de llaves eliminatorias reutilizando `KnockoutBracketCard` con sus rondas y equipos clasificados.
- **FR-005**: Para torneos tipo `mixedGroupsAndKnockout`, el sistema DEBE permitir alternar entre las tablas de posiciones por grupos y el cuadro de llaves eliminatorias, mostrando la subvía "Posiciones" (Fase de Grupos) seleccionada por defecto al ingresar.
- **FR-006**: El sistema DEBE integrar los rankings del campeonato (`TournamentRankingsCard`) mostrando la tabla de máximos goleadores, el resumen disciplinario de Fair Play (tarjetas amarillas y rojas) y las vallas invictas, mediante chips de selección de subvistas en la cabecera de la pestaña ("Clasificación" / "Llaves" / "Estadísticas", según las capacidades del formato del torneo), permitiendo una navegación compacta y enfocada en dispositivos móviles sin desplazamiento vertical excesivo.
- **FR-007**: En la tabla de posiciones y el bracket de llaves eliminatorias, la visualización de los equipos DEBE ser de solo lectura informativa en esta fase, sin acciones táctiles o modales adicionales al pulsar sobre las filas o nodos de equipo.
- **FR-008**: Para torneos con formato mixto (`mixedGroupsAndKnockout`), la fase de grupos DEBE organizarse con un selector de pestañas/chips por grupo (Grupo A, Grupo B, etc.) dentro de la tarjeta de posiciones (`StandingsTableCard.groupTables`), permitiendo consultar cada grupo de forma aislada e interactiva.
- **FR-009**: Cuando no existan resultados oficiales o cuando una subvía específica (como "Estadísticas" o "Llaves") carezca aún de eventos o datos generados, el sistema DEBE mostrar un estado vacío informativo contextualizado (`KickPulseStateView`) con iconografía coherente y mensaje en español, manteniendo visibles los chips de selección de subvistas para permitir la navegación.
- **FR-010**: El estado de la clasificación DEBE conectarse mediante `standingsAndRankingsControllerProvider(tournamentId)` garantizando sincronización con el repositorio local offline.
- **FR-011**: Todos los textos de la interfaz DEBEN residir en `lib/l10n/app_es.arb` sin cadenas de texto codificadas directamente (*hardcoded*).

---

### Key Entities *(include if feature involves data)*

- **ChampionshipTournament**: Entidad aggregate root que define el campeonato, su identificador único, nombre, categoría, estado y formato (`TournamentFormat`).
- **StandingsTable / StandingsRow**: Representa la tabla oficial de posiciones acumuladas del torneo o grupo, con filas de equipos (`teamId`, `teamName`, `crestShape`, `primaryColor`, `played`, `won`, `drawn`, `lost`, `goalsFor`, `goalsAgainst`, `goalDifference`, `points`).
- **KnockoutBracket / KnockoutRound**: Estructura de árbol de emparejamientos y llaves eliminatorias con rondas y clasificados.
- **TournamentRankings**: Agregado de estadísticas individuales y colectivas del torneo (máximos goleadores, amonestados, expulsados y porterías a cero).
- **TournamentCompetitiveSnapshot**: Contenedor inmutable que agrupa `mainStandingsTable`, `groupStandingsTables`, `knockoutBracket` y `rankings` para un torneo específico.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden visualizar la tabla de posiciones o el bracket de cualquier torneo en menos de 1 segundo tras seleccionar la pestaña "Clasificación".
- **SC-002**: El cálculo y renderizado de la tabla de posiciones es $100\%$ determinista y concuerda exactamente con los resultados de las actas oficiales de partido registradas.
- **SC-003**: Cero desbordamientos visuales (`RenderFlex` overflow) en pantallas compactas de $320 \times 640\text{ px}$ con factor de escala tipográfica del $130\%$.
- **SC-004**: La suite de pruebas automatizadas de widget y unidad para la pestaña de clasificación alcanza el $100\%$ de aprobación sin regresiones en la suite existente.

---

## Assumptions

- Se reutiliza la arquitectura existente de cálculo de posiciones y rankings provista por `CalculateTournamentStandingsAndRankingsUseCase` y `StandingsAndRankingsController`.
- Los widgets visuales base `StandingsTableCard`, `KnockoutBracketCard` y `TournamentRankingsCard` desarrollados en la Épica 9 están disponibles para ser integrados y adaptados en el contexto de `CompetitionDetailScreen`.
- La información mostrada opera de forma offline-first utilizando los datos almacenados en el repositorio local.
