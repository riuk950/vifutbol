# Feature Specification: Pestaña de Información y Reglas Oficiales de la Competición (HU 13.3)

**Feature Branch**: `020-competition-detail-rules`  
**Created**: 2026-11-06  
**Status**: Draft  
**Input**: User description: "[Épica 13] HU 13.3: Pestaña de Información y Reglas Oficiales de la Competición"

---

## Clarifications

### Session 2026-11-06

- Q: ¿La pestaña "Información" dentro del detalle debe ser exclusivamente de consulta normativa (solo lectura), o debe incluir los botones de acción para el rol `Organizador`? → A: Solo consulta informativa (solo lectura para todos los roles, sin botones de acción de gestión como editar reglas o cambiar estado).
- Q: ¿Cómo debe comportarse la sección de auditoría para organizadores si el torneo no tiene registros en su historial (`auditTrail.isEmpty`)? → A: Ocultar el bloque de auditoría por completo hasta que ocurra la primera modificación de reglas críticas.
- Q: ¿Debe incluirse en la pestaña "Información" una sección resumen con la sede principal del campeonato? → A: Sí, incluir una tarjeta informativa con el nombre de la sede principal y su dirección.
- Q: ¿De qué fuente debe resolverse la sede principal del campeonato para mostrarla en la pestaña "Información"? (FR-010) → A: Se resuelve a partir de las sedes registradas asociadas al campeonato o sus partidos en el catálogo de sedes (`venuesControllerProvider` / `matches`), mostrando la sede principal (nombre, dirección y canchas).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualización del Sistema de Puntuación y Normativa Deportiva (Priority: P1) 🎯 MVP

**User Journey**:
Como aficionado, entrenador, jugador u organizador, accedo a la pestaña "Información" dentro de la pantalla de detalle de una competición (`CompetitionDetailScreen`) para consultar de forma transparente el sistema de puntuación oficial (Puntos por Victoria, Empate y Derrota), los parámetros de partido (duración de mitades), las cuotas de plantilla (mínimo y máximo de jugadores) y el límite de acumulación de tarjetas amarillas para suspensión automática.

**Why this priority**:
Es la necesidad medular de transparencia deportiva en cualquier campeonato: que todos los actores conozcan con certeza las reglas de juego y cómo se puntúa y sanciona la competición.

**Independent Test**:
Navegar a `/competitions/:id`, pulsar la pestaña "Información", y verificar que se visualiza la tarjeta de reglas oficiales (`TournamentRulesSummaryCard`) con el sistema de puntuación (3 pts victoria, 1 pt empate, 0 pts derrota), duración de tiempo y límites de plantilla.

**Acceptance Scenarios**:
1. **Given** un torneo con reglas configuradas, **When** el usuario selecciona la pestaña "Información", **Then** se muestra el sistema de puntuación con los valores oficiales de puntos por victoria, empate y derrota.
2. **Given** la sección de parámetros de partido, **When** el usuario la revisa, **Then** se detalla la duración en minutos de cada mitad y el formato competitivo del campeonato.
3. **Given** las reglas de plantilla y disciplina, **When** se examinan, **Then** se visualizan el cupo mínimo y máximo de jugadores por equipo y el umbral de tarjetas amarillas que deriva en suspensión automática.

---

### User Story 2 - Criterios de Desempate Ordenados y Fechas Oficiales (Priority: P2)

**User Journey**:
Como aficionado o delegado de equipo, accedo a la pestaña "Información" para revisar el orden oficial de los criterios de desempate de la tabla de posiciones (Diferencia de gol, Goles a favor, Enfrentamiento directo, Fair Play) y el periodo oficial de vigencia del torneo (fecha de inicio y fecha de finalización).

**Why this priority**:
Resuelve disputas reglamentarias en la clasificación y permite planificar la participación conociendo los desempates y el calendario general.

**Independent Test**:
En la pestaña "Información", verificar que los criterios de desempate se listan en orden jerárquico estricto numerado y que se presentan las fechas oficiales formateadas (`DD/MM/AAAA`).

**Acceptance Scenarios**:
1. **Given** una competición con criterios de desempate ordenados, **When** el usuario consulta los desempates, **Then** se enumeran en orden de prioridad estricto conforme a la configuración oficial.
2. **Given** las fechas del campeonato, **When** se visualiza la tarjeta, **Then** se presentan las fechas de inicio y fin en formato legible y el estado actual de la competición.

---

### User Story 3 - Auditoría de Reglas Críticas para Organizadores (Priority: P3)

**User Journey**:
Como usuario con rol `Organizador`, al consultar la pestaña "Información", deseo visualizar adicionalmente la sección de auditoría de reglas críticas (`auditTrail`), con el registro cronológico de modificaciones (fecha, reglas modificadas, motivo y responsable), mientras que para otros roles dicha sección se mantiene oculta para resguardar la gobernanza interna.

**Why this priority**:
Permite a los administradores del campeonato auditar cualquier ajuste en la normativa de puntuación o formato y respaldar la transparencia operativa.

**Independent Test**:
Acceder a la pestaña "Información" como `UserRole.organizer` y verificar la presencia del bloque de auditoría de reglas. Repetir la prueba con rol `UserRole.fan` o `UserRole.player` y verificar que el bloque de auditoría no se renderiza.

**Acceptance Scenarios**:
1. **Given** un usuario autenticado con rol `UserRole.organizer`, **When** ingresa a la pestaña "Información", **Then** se expone la sección de auditoría de reglas críticas con su historial de eventos.
2. **Given** un usuario con rol distinto a organizador (`coach`, `referee`, `player`, `fan`), **When** accede a la pestaña "Información", **Then** la sección de auditoría no está visible ni accesible.

---

### User Story 4 - Resiliencia y Manejo de Estados de Carga o No Encontrado (Priority: P4)

**User Journey**:
Como usuario que navega al detalle de una competición que está cargando o cuyo identificador no se encuentra en el catálogo local, visualizo un estado controlado y amigable (`KickPulseStateView` o indicador de carga) sin que la aplicación se bloquee ni falle.

**Why this priority**:
Garantiza robustez visual ante identificadores no válidos o transiciones asíncronas de base de datos local.

**Independent Test**:
Lanzar `CompetitionInfoTabView` con un identificador de torneo inexistente y verificar la presencia del estado vacío correspondiente.

**Acceptance Scenarios**:
1. **Given** un torneo inexistente, **When** se intenta desplegar la pestaña "Información", **Then** se renderiza un estado informativo indicando que la competición no fue encontrada.
2. **Given** el catálogo de torneos en estado de carga, **When** se abre la pestaña, **Then** se muestra un indicador de carga centrado.

---

### Edge Cases

- **Competición sin historial de auditoría**: Si un torneo nunca ha modificado sus reglas críticas (`auditTrail.isEmpty`), el bloque de auditoría no se muestra, ahorrando espacio vertical en pantalla.
- **Solo lectura normativa**: La pestaña "Información" opera en modo de solo lectura para todos los usuarios, prescindiendo de botones de edición, cambio de estado o respaldos en esta vista.
- **Sede principal asignada**: Si el campeonato cuenta con una sede principal asociada, se visualiza una tarjeta dedicada con su nombre y dirección. Si no cuenta con sede configurada, la tarjeta se omite sin generar errores visuales.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE integrar en la pestaña "Información" de `CompetitionDetailScreen` el componente de resumen oficial de reglas y normativa de la competición reutilizando [`TournamentRulesSummaryCard`] en modo solo lectura informativa (sin botones de edición o transición de estado).
- **FR-002**: El sistema DEBE mostrar el bloque del sistema de puntuación detallando los puntos otorgados por victoria (`pointsForWin`), empate (`pointsForDraw`) y derrota (`pointsForLoss`).
- **FR-003**: El sistema DEBE mostrar los parámetros oficiales de partido incluyendo la duración de cada tiempo en minutos (`matchDurationMinutes`), formato de competición (`TournamentFormat`) y número de vueltas.
- **FR-004**: El sistema DEBE exponer los límites de plantilla deportiva: cantidad mínima de jugadores requeridos (`minPlayersPerTeam`) y cupo máximo admitido (`maxPlayersPerTeam`).
- **FR-005**: El sistema DEBE presentar la política disciplinaria, indicando el límite de tarjetas amarillas acumuladas (`yellowCardsLimitForSuspension`) que activa una sanción de suspensión por un partido.
- **FR-006**: El sistema DEBE enumerar en orden jerárquico de prioridad estricto los criterios de desempate oficiales (`tiebreakerCriteria`) configurados para el campeonato.
- **FR-007**: El sistema DEBE presentar las fechas oficiales de vigencia del torneo (fecha de inicio y fecha de finalización) formateadas en formato legible (`DD/MM/AAAA`).
- **FR-008**: El sistema DEBE condicionar la visibilidad de la sección de auditoría de reglas críticas (`auditTrail`) basándose en el rol activo (`activeUserRoleProvider`), mostrándola exclusivamente para usuarios con rol `UserRole.organizer` cuando existan registros (`auditTrail.isNotEmpty`).
- **FR-009**: Para usuarios con roles no organizadores (`coach`, `referee`, `player`, `fan`), o cuando no existan modificaciones registradas, el sistema DEBE ocultar completamente la sección de auditoría de reglas sin dejar espacios vacíos o controles deshabilitados.
- **FR-010**: El sistema DEBE mostrar una tarjeta informativa con el nombre y dirección de la sede principal del campeonato si se encuentra registrada en el sistema.
- **FR-011**: Todos los textos, etiquetas y descripciones de la pestaña "Información" DEBEN estar centralizados en `lib/l10n/app_es.arb` sin cadenas de texto codificadas directamente (*hardcoded*).
- **FR-012**: La visualización DEBE adaptarse a pantallas compactas ($320 \times 640\text{ px}$) con hasta un $130\%$ de escalado de texto, garantizando cero desbordamientos visuales (`RenderFlex` overflow).

---

### Key Entities *(include if feature involves data)*

- **ChampionshipTournament**: Entidad aggregate root que define el campeonato, fechas oficiales, formato, estado, reglas y trazabilidad de auditoría.
- **TournamentRulesConfig**: Objeto de valor inmutable con el sistema de puntuación, duración de partidos, límites de plantilla, política disciplinaria y criterios de desempate.
- **RuleAuditEntry**: Registro inmutable de auditoría que documenta la fecha, reglas modificadas, motivo y autor de un cambio en reglas críticas.
- **UserRole**: Enumeración del rol activo (`organizer`, `coach`, `referee`, `player`, `fan`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden consultar el reglamento completo del torneo en menos de 500 ms tras pulsar la pestaña "Información".
- **SC-002**: El bloque de auditoría se oculta al $100\%$ para todos los roles no organizadores en las pruebas de verificación.
- **SC-003**: Cero desbordamientos visuales (`RenderFlex` overflow) en pantallas compactas de $320 \times 640\text{ px}$ con factor de escala tipográfica del $130\%$.
- **SC-004**: La suite de pruebas de widget para la pestaña de información alcanza el $100\%$ de aprobación sin regresiones.

---

## Assumptions

- Se reutiliza la estructura visual provista por `TournamentRulesSummaryCard` (`lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart`), adaptada para operar dentro del contenedor con scroll de `CompetitionInfoTabView`.
- Los datos del torneo se resuelven a partir de `tournamentsControllerProvider`.
- El rol del usuario se obtiene a través de `activeUserRoleProvider`.
