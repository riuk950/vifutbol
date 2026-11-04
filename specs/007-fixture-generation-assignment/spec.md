# Feature Specification: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Feature Branch**: `007-fixture-generation-assignment`  
**Created**: 2026-11-04  
**Status**: Draft  
**Input**: User description: "Notion [Épica 6] HU 6.1: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (Page ID: 4078442e-3f49-81ff-885c-c101c8751f28)"

## Clarifications

### Session 2026-11-04

- Q: ¿Cómo debe estructurarse la interfaz de visualización y filtrado del calendario en la pestaña de Jornada (`MatchdayTabView`)? → A: Option A — En `MatchdayTabView`: selector horizontal de jornadas, filtros por estado/equipo, tarjetas de partidos con fecha, hora, cancha y árbitro, y acceso a generación de fixture y formulario de programación para el `Organizador`.
- Q: ¿De dónde debe obtenerse la lista de árbitros disponibles para asignar a los partidos de un campeonato? → A: Option A — Disponer de un catálogo de árbitros habilitados con rol `UserRole.referee`, precargando árbitros oficiales semilla en entorno `dev` para asignación inmediata.
- Q: ¿Qué debe ocurrir con el estado del campeonato cuando el organizador genera el fixture oficial por primera vez? → A: Option B — Permitir generar el fixture manteniendo el campeonato en su estado actual (o `"Inscripciones Abiertas"`), permitiendo al organizador transicionar manualmente el torneo a `"En Curso"` cuando lo considere oportuno antes de la disputa oficial.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generación Automática del Calendario de Jornadas (Round-Robin y Llaves) (Priority: P1)

Como `Organizador` del campeonato (`RoleCapability.manageTournaments`), quiero generar automáticamente el calendario oficial de partidos (fixture) para un campeonato con equipos oficialmente inscritos y habilitados, aplicando el algoritmo Round-Robin en modalidades de Liga o la conformación determinista de llaves eliminatorias en modalidades de Copa, para que cada jornada o fase quede estructurada sin repeticiones de equipos en la misma fecha y todos los participantes tengan su cronograma de enfrentamientos definido.

**Why this priority**: Es el núcleo funcional de la HU 6.1 (Fase 1 Gherkin). Sin un calendario generado no es posible programar canchas, designar árbitros, disputar partidos ni registrar actas arbitrales.

**Independent Test**: Se puede probar creando o seleccionando un campeonato con equipos habilitados (p. ej. 4 u 8 equipos), ejecutando la acción `"Generar Fixture Oficial"`, y verificando que el sistema crea todas las jornadas requeridas sin cruzar al mismo equipo dos veces en la misma jornada y enfrentando a todos los equipos entre sí.

**Acceptance Scenarios**:

1. **Given** que un campeonato tipo `"Liga"` cuenta con equipos oficialmente inscritos y habilitados (por ejemplo, 8 equipos), **When** el `Organizador` ejecuta la generación automática del fixture a una vuelta, **Then** el sistema crea las jornadas completas (7 jornadas para 8 equipos) garantizando que todos los equipos se enfrenten entre sí y ningún equipo se repita en la misma jornada.
2. **Given** que un campeonato tiene un número impar de equipos habilitados (por ejemplo, 7 equipos), **When** el `Organizador` genera el fixture, **Then** el sistema balancea automáticamente las jornadas asignando fecha libre (*bye*) por rotación a un equipo en cada jornada.
3. **Given** que un campeonato ya tiene partidos programados o con resultados en curso, **When** el `Organizador` intenta regenerar el fixture, **Then** el sistema solicita confirmación explícita advirtiendo que solo se regenerarán enfrentamientos que no hayan iniciado o bloquea la regeneración si ya existen actas disputadas.

---

### User Story 2 - Asignación de Fecha, Cancha, Horario y Designación de Árbitros (Priority: P2)

Como `Organizador` (`RoleCapability.manageTournaments` / `RoleCapability.assignReferees`), quiero asignar a cada partido una fecha, hora de inicio, sede deportiva, cancha específica y un `Árbitro` designado, para que el partido pase a estado `"Programado"`, esté disponible en el calendario público y se sincronice en la agenda operativa de los equipos y del árbitro asignado.

**Why this priority**: Completa la logística de campo requerida para que un partido pueda disputarse en una sede real y cuente con la autoridad arbitral correspondiente.

**Independent Test**: Seleccionar un partido en estado `"Pendiente de Programación"`, asignar fecha, hora (p. ej. sábado a las 14:00), una sede/cancha urbana válida y designar un árbitro oficial, verificando que el partido pasa a `"Programado"` con su horario de finalización estimado (basado en la duración del partido del torneo).

**Acceptance Scenarios**:

1. **Given** que existe un partido pendiente de programación en una jornada del campeonato, **When** el `Organizador` selecciona fecha, hora de inicio, sede, cancha disponible y designa a un `Árbitro` oficial, **Then** el partido pasa a estado `"Programado"`, calcula su hora de finalización y aparece reflejado en el calendario público y en la agenda del árbitro y de los equipos.
2. **Given** que un usuario con rol `Aficionado`, `Jugador` o `Entrenador` consulta el calendario, **When** visualiza los partidos de una jornada, **Then** puede ver la fecha, hora, sede, cancha y árbitro designado sin tener controles de edición o asignación logística.

---

### User Story 3 - Detección y Bloqueo de Conflictos Logísticos y de Horario (Priority: P3)

Como `Organizador`, quiero que el sistema valide en tiempo real y bloquee cualquier intento de programar dos partidos en la misma cancha con horarios superpuestos, o asignar al mismo `Árbitro` o equipo a dos encuentros en el mismo rango horario, mostrando una alerta descriptiva en español para evitar colisiones logísticas en las sedes urbanas.

**Why this priority**: Garantiza la integridad logística del torneo (Fase 2 Gherkin), impidiendo cruces de cancha o dobles asignaciones de árbitros y equipos en el mismo horario.

**Independent Test**: Programar un partido el sábado de 14:00 a 16:00 en la `"Cancha Sintética Norte"` con el `"Árbitro A"`, e intentar programar otro partido a las 15:00 del mismo día en la misma cancha o con el mismo árbitro, verificando el rechazo con un mensaje explícito en español.

**Acceptance Scenarios**:

1. **Given** que la `"Cancha Sintética Norte"` ya tiene un partido programado el sábado de 14:00 a 16:00 con el `"Árbitro A"`, **When** el `Organizador` intenta programar otro partido en la misma cancha a las 15:00 del mismo día, **Then** el sistema rechaza la asignación e informa que la cancha se encuentra ocupada en ese intervalo de horario.
2. **Given** que el `"Árbitro A"` ya tiene un partido asignado el sábado de 14:00 a 16:00, **When** el `Organizador` intenta designar al `"Árbitro A"` para otro partido que inicia a las 15:00 del mismo día en cualquier sede, **Then** el sistema rechaza la designación e informa el conflicto de horario del árbitro.
3. **Given** que un equipo ya tiene un partido programado en un horario determinado, **When** se intenta programar otro partido con el mismo equipo en un horario superpuesto, **Then** el sistema bloquea la programación alertando sobre la colisión de horario del equipo.

### Edge Cases

- **Intervalo de duración de partido**: La duración del encuentro se calcula determinísticamente a partir de `TournamentRulesConfig.halfDurationMinutes` (`duración = halfDurationMinutes * 2 + descanso (15 min)`). Dos partidos se consideran superpuestos en una cancha si sus intervalos `[inicio, fin]` se traslapan.
- **Diferencia de zonas horarias y formato regional**: Las fechas y horas se almacenan en UTC/ISO-8601 y se muestran formateadas en español (`"dd/MM/yyyy HH:mm"` o `"Sábado 15 de Noviembre · 14:00"`).
- **Equipo no habilitado**: Si un equipo no tiene estado `"Habilitado"` (`TeamEligibilityStatus.eligible`), el sistema advierte o exige que los equipos estén habilitados antes de generar el fixture oficial.
- **Filtros rápidos de jornada y cancha**: La vista de calendario permite filtrar por jornada (`Jornada 1`, `Jornada 2`, etc.), por equipo y por sede deportiva.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir al `Organizador` (`RoleCapability.manageTournaments`) generar automáticamente el fixture oficial de partidos para un campeonato sin forzar una transición inmediata de estado del torneo (manteniendo el estado actual a criterio del organizador):
  - En campeonatos tipo `Liga`: implementar el algoritmo determinista Round-Robin para generar todas las jornadas (`n - 1` jornadas para `n` equipos pares, o `n` jornadas con descanso rotativo para `n` equipos impares), multiplicadas por `leagueRounds`.
  - En campeonatos tipo `Copa`: generar las llaves eliminatorias correspondientes a la ronda inicial configurada (`KnockoutRound`).
- **FR-002**: El sistema DEBE permitir al `Organizador` asignar y reprogramar partidos individuales especificando fecha de inicio, hora, sede deportiva, cancha específica y designando a un `Árbitro` oficial (`RoleCapability.assignReferees`) seleccionado a partir del catálogo de árbitros habilitados del sistema con rol `UserRole.referee`.
- **FR-003**: El sistema DEBE calcular automáticamente la hora estimada de finalización de cada partido en función de las reglas del campeonato (`halfDurationMinutes * 2 + 15` minutos de entretiempo).
- **FR-004**: El sistema DEBE detectar colisiones de horario y bloquear la asignación cuando:
  - Exista otro partido en la misma cancha cuyo intervalo de horario se superponga con el propuesto.
  - El mismo árbitro esté designado en otro partido en un horario superpuesto.
  - Cualquiera de los dos equipos tenga otro partido programado en un horario superpuesto.
- **FR-005**: El sistema DEBE presentar la lista de partidos organizados en la pestaña principal de `"Jornada"` (`MatchdayTabView`), incorporando un selector horizontal de jornadas (`Jornada 1`, `Jornada 2`...), filtros rápidos por equipo y estado del partido (`Pendiente`, `Programado`, `Finalizado`), tarjetas de partido estructuradas con diseño KickPulse de `16px`, y botones de acción exclusivos para el `Organizador` para `"Generar Fixture"` y `"Programar Partido"`.
- **FR-006**: Los formularios de programación y asignación de partidos DEBEN incluir selectores nativos de fecha y hora, validaciones en línea y protección contra envíos repetidos.
- **FR-007**: En entorno de desarrollo (`dev`), el sistema DEBE precargar un fixture semilla realista con al menos 2 jornadas y partidos programados sobre las sedes y canchas semilla para validación inmediata.
- **FR-008**: Todos los textos visibles para el usuario, nombres de estados de partidos, encabezados de jornadas y mensajes de colisión DEBEN estar 100% en español en `lib/l10n/app_es.arb`, manteniendo los identificadores técnicos en inglés.

### Key Entities *(include if feature involves data)*

- **`ChampionshipMatch`**: Entidad que representa un partido del campeonato (`id`, `tournamentId`, `roundNumber`, `roundName`, `homeTeamId`, `awayTeamId`, `scheduledStartTime`, `scheduledEndTime`, `venueId`, `pitchId`, `refereeId`, `status`, `updatedAt`).
- **`MatchStatus`**: Enumeración del estado del partido (`pendingSchedule` / `"Pendiente"`, `scheduled` / `"Programado"`, `inProgress` / `"En Juego"`, `completed` / `"Finalizado"`, `cancelled` / `"Cancelado"`).
- **`FixtureScheduleCollision`**: Objeto de valor o fallo que describe un conflicto logístico detectado (`collisionType`: cancha, árbitro o equipo; mensaje descriptivo en español y detalles del partido en conflicto).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La generación automática de un fixture Round-Robin completo de 8 equipos se ejecuta en menos de 100 milisegundos sin congelar la interfaz de usuario.
- **SC-002**: El 100% de los intentos de programar partidos superpuestos en la misma cancha, con el mismo árbitro o con el mismo equipo son bloqueados determinísticamente mostrando una alerta descriptiva en español.
- **SC-003**: Cualquier usuario puede visualizar y filtrar los partidos de la jornada en menos de 2 toques desde la pestaña de `"Jornada"`.
- **SC-004**: La suite de pruebas automatizadas supera `flutter analyze` con 0 problemas, `dart format` sin diferencias y cobertura `>= 80%` en la lógica de generación de fixture y detección de colisiones horarias.

## Assumptions

- La duración estándar del entretiempo entre tiempos reglamentarios es de 15 minutos para efectos del cálculo de finalización estimada del partido.
- Los árbitros disponibles se seleccionan a partir de la lista de usuarios registrados o un catálogo de árbitros oficiales del sistema.
- Los partidos se muestran integrados en `MatchdayTabView` (la primera pestaña de `AppShellScreen`), conectando el calendario público con la gestión logística del torneo.
