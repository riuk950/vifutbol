# Feature Specification: Programación Integral de Partido al Seleccionarlo en la Jornada (Árbitro, Fecha, Sede y Cancha) (HU 15.3)

**Feature Branch**: `026-matchday-integrated-scheduling`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "Notion [Épica 15] HU 15.3: Programación Integral de Partido al Seleccionarlo en la Jornada (Árbitro, Fecha, Sede y Cancha) (Page ID: 4138442e-3f49-8112-a658-e7cce4abd2f8)"

## Clarifications

### Session 2026-11-09

- Q: ¿La detección de colisiones de horario para una cancha o un árbitro debe validarse contra todos los partidos programados de cualquier competición activa o únicamente contra los partidos de la misma competición? → A: Validación global entre competiciones (comprobar conflictos de cancha y árbitro contra todos los partidos programados del catálogo, excluyendo el propio partido).
- Q: ¿Cómo debe acotarse el rango de fechas seleccionables en el selector de fecha (`DatePicker`) al programar un partido? → A: Rango del campeonato `[tournament.startDate, tournament.endDate]` con margen seguro (expandiendo `firstDate`/`lastDate` si la fecha inicial está fuera del intervalo).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Apertura del Formulario de Programación desde la Lista de Jornadas por Rol (Priority: P1) 🎯 MVP

Como **Organizador**, quiero seleccionar cualquier partido pendiente de programar (`pendingSchedule`) o programado (`scheduled`) dentro de la pestaña de **Partidos por Jornadas** en el detalle de una competición (`/competitions/:id`) para abrir el formulario de programación logística y configurar su fecha, hora, sede deportiva, cancha específica y árbitro oficial.

**Why this priority**: Es el punto de entrada esencial de la historia de usuario; sin la capacidad de interactuar con los partidos de cada jornada según el rol del usuario, el organizador no puede gestionar individualmente la logística de los encuentros del torneo.

**Independent Test**: Se puede probar de forma independiente iniciando sesión como `Organizador`, entrando al detalle de una competición editable con fixture generado, tocando un partido de la **Jornada 1** y comprobando que se despliega el formulario de programación con los selectores de Fecha, Hora, Sede, Cancha y Árbitro; mientras que para un rol no autorizado (ej. `Aficionado`) se muestra únicamente la vista informativa de solo lectura.

**Acceptance Scenarios**:

1. **Given** que el usuario con rol `Organizador` visualiza la pestaña de **Partidos** (jornadas) en el detalle de una competición editable (`openRegistration` o `inProgress`), **When** selecciona un partido de la jornada en estado `pendingSchedule` o `scheduled` (ej. *"Atlético Norte FC vs Real Sabana Club"*), **Then** se despliega el formulario de programación del partido mostrando los selectores de Fecha, Hora, Sede Deportiva, Cancha y Árbitro Oficial.
2. **Given** que el usuario con rol `Organizador` abre el formulario sobre un partido que ya tenía estado `scheduled`, **When** se carga el formulario, **Then** los selectores preseleccionan la fecha, hora, sede, cancha y árbitro actualmente asignados al encuentro para facilitar su reprogramación.
3. **Given** que el usuario activo tiene un rol distinto a `Organizador` (ej. `Aficionado`, `Jugador`, `Entrenador` o `Árbitro`) o el torneo se encuentra en estado `finished`, **When** selecciona cualquier partido de la jornada, **Then** se muestra únicamente la hoja informativa de solo lectura con los detalles del encuentro sin controles de edición logística.

---

### User Story 2 - Asignación Completa de Logística (Fecha, Hora, Sede, Cancha y Árbitro) y Sincronización Reactiva (Priority: P1)

Como **Organizador**, quiero elegir una fecha y hora válidas, seleccionar una sede deportiva que filtre dinámicamente sus canchas disponibles, designar un árbitro activo y guardar la programación para que el partido pase a estado **Programado** (`scheduled`), muestre sus datos logísticos en la jornada y aparezca automáticamente en el feed diario de **Partidos** en la fecha correspondiente.

**Why this priority**: Constituye el valor operativo central para completar la logística oficial del campeonato y alimentar la vista principal de partidos por fecha.

**Independent Test**: Se puede probar abriendo el formulario de programación de un partido en estado `pendingSchedule`, seleccionando Fecha, Hora, Sede, Cancha y Árbitro, pulsando **"Guardar Programación"** y verificando que el partido cambia a `scheduled`, exhibe la logística asignada en su jornada y aparece en la pestaña principal **Partidos** al consultar esa fecha.

**Acceptance Scenarios**:

1. **Given** que el `Organizador` tiene abierto el formulario de programación de un partido, **When** cambia la **Sede Deportiva** seleccionada en el desplegable, **Then** el selector de **Cancha** se actualiza dinámicamente para listar únicamente las canchas pertenecientes a dicha sede.
2. **Given** que el `Organizador` ha seleccionado una fecha y hora válidas, una Sede Deportiva, una Cancha disponible de esa sede y un Árbitro activo de la lista oficial, **When** pulsa en **"Guardar Programación"**, **Then** el partido actualiza su estado a `scheduled` (*Programado*), se cierra el formulario, se muestra una confirmación visual y en la jornada se visualizan la fecha, hora, sede, cancha y árbitro asignados.
3. **Given** que un partido acaba de ser programado exitosamente para una fecha determinada, **When** cualquier usuario consulta el feed diario de **Partidos** en esa fecha (*Ayer*, *Hoy*, *Mañana* o *Calendario*), **Then** el partido aparece listado automáticamente bajo el grupo de su competición con su horario y logística actualizados.

---

### User Story 3 - Validación y Bloqueo de Colisiones de Horario en Cancha y Árbitro (Priority: P1)

Como **Organizador**, quiero que el sistema valide al guardar que no exista otro partido programado en la misma cancha ni con el mismo árbitro en un horario superpuesto, mostrando una alerta clara dentro del formulario e impidiendo el guardado hasta resolver el conflicto.

**Why this priority**: Garantiza la integridad logística del campeonato (Principio II de la Constitución), evitando dobles asignaciones físicas de canchas o árbitros a la misma hora.

**Independent Test**: Se puede probar programando un primer partido en una cancha y árbitro a una fecha/hora específica, e intentando programar un segundo partido en la misma cancha (o con el mismo árbitro) a la misma hora, verificando que el sistema bloquea el guardado y muestra el mensaje de colisión correspondiente.

**Acceptance Scenarios**:

1. **Given** que ya existe otro partido programado en la misma **Sede y Cancha** en un horario que se solapa con la duración reglamentaria del encuentro, **When** el `Organizador` intenta guardar la programación con esa misma cancha, fecha y hora, **Then** el sistema muestra una alerta de colisión de horario en la cancha seleccionada dentro del formulario y no permite guardar hasta elegir otra hora u otra cancha disponible.
2. **Given** que ya existe otro partido programado en cualquier cancha con el mismo **Árbitro Oficial** en un horario superpuesto, **When** el `Organizador` intenta guardar la programación asignando a dicho árbitro en ese horario, **Then** el sistema muestra una alerta de colisión de horario para el árbitro seleccionado y bloquea el guardado hasta seleccionar otro árbitro u otro horario.
3. **Given** que el `Organizador` está reprogramando un partido ya existente, **When** guarda cambios manteniendo o ajustando su logística sin solaparse con *otros* partidos distintos, **Then** el sistema excluye al propio partido de la verificación de conflicto y permite guardar sin falsos positivos de colisión consigo mismo.

---

### Edge Cases

- **Reprogramación de partido consigo mismo**: Al editar un partido ya programado (`scheduled`), la validación de colisión no debe detectar conflicto contra el horario previo del mismo `match.id`.
- **Sede sin canchas registradas o sin árbitros activos**: Si no existen sedes elegibles con canchas o no hay árbitros activos en el catálogo, el formulario muestra un aviso claro de validación e impide enviar datos incompletos.
- **Partidos en curso, finalizados o cancelados (`inProgress`, `completed`, `cancelled`)**: Si el `Organizador` toca un partido que ya inició o finalizó en la jornada, no se debe permitir alterar su programación logística; se muestra únicamente el resumen informativo del encuentro.
- **Protección contra envíos duplicados (*Single-Flight*)**: Pulsaciones rápidas repetidas sobre **"Guardar Programación"** deben procesarse una única vez mientras la operación está en curso.
- **Pantallas compactas y escalado tipográfico ($320 \times 640\text{ px}$ al $130\%$ de texto)**: Tanto las tarjetas de partido en la jornada (con su información de fecha, sede, cancha y árbitro) como el diálogo de programación deben adaptarse mediante desplazamiento o ajuste flexible sin producir errores de desbordamiento visual (`RenderFlex overflow`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir al rol `Organizador` abrir directamente el diálogo de programación integral (`ScheduleMatchDialog`) al tocar cualquier partido en estado `pendingSchedule` o `scheduled` dentro de la pestaña de **Partidos por Jornadas** (`CompetitionFixtureTabView`) de una competición editable (`openRegistration` o `inProgress`).
- **FR-002**: Para los roles `Aficionado`, `Jugador`, `Entrenador` y `Árbitro` —o cuando el partido esté en estado `inProgress`, `completed` o `cancelled`, o el torneo esté `finished`—, tocar un partido de la jornada DEBE mostrar únicamente el resumen informativo de solo lectura del encuentro (`_openMatchDetailModal`).
- **FR-003**: El formulario de programación (`ScheduleMatchDialog`) DEBE incluir selectores obligatorios para:
  1. **Fecha** (`DatePicker`, acotado al rango `[tournament.startDate, tournament.endDate]` del campeonato y expandiendo automáticamente los bordes `firstDate`/`lastDate` si la fecha inicial está fuera del intervalo) y **Hora** (`TimePicker`).
  2. **Sede Deportiva** (`SportsVenue`), listando las sedes habilitadas para fixtures.
  3. **Cancha Específica** (`VenuePitch`), actualizándose dinámicamente según la sede deportiva seleccionada.
  4. **Árbitro Oficial** (`MatchReferee`), listando los árbitros activos habilitados.
- **FR-004**: Cuando se abra el formulario sobre un partido que ya cuenta con datos de programación previos (`scheduled`), el formulario DEBE pre-cargar su fecha, hora, sede, cancha y árbitro actuales; si el partido está en `pendingSchedule`, DEBE inicializar una fecha predeterminada válida ajustada dentro del rango `[tournament.startDate, tournament.endDate]`.
- **FR-005**: Al confirmar en **"Guardar Programación"**, el sistema DEBE validar de forma global contra todos los partidos programados del catálogo (incluyendo otras competiciones activas) que no exista colisión de horario en la misma cancha (`pitchId`) ni para el mismo árbitro (`refereeId`) considerando la ventana de duración del partido, excluyendo al propio partido en caso de reprogramación.
- **FR-006**: Si se detecta una colisión de cancha o de árbitro, el formulario DEBE permanecer abierto mostrando un mensaje de alerta en español indicando el motivo del conflicto y bloqueando la persistencia hasta que el organizador modifique la selección.
- **FR-007**: Al guardarse sin conflictos, el partido DEBE actualizar su estado a `MatchStatus.scheduled`, persistir `scheduledStartTime`, `scheduledEndTime`, `venueId`, `pitchId`, `pitchName`, `refereeId` y `refereeName`, y sincronizar reactivamente tanto la lista de jornadas de la competición como el feed diario de `DailyMatchesFeedController`.
- **FR-008**: En la vista de jornadas de la competición (`CompetitionFixtureTabView`), cada tarjeta de partido DEBE mostrar directamente una fila/pie de metadatos logísticos con la **Fecha**, **Sede/Cancha** y **Árbitro** asignados cuando el partido está programado (o el indicador **"Por programar"** cuando está en estado `pendingSchedule`), además de reflejarlos en el modal de detalle.
- **FR-009**: El botón de acción rápida **"Programar Partido"** en el Panel del Organizador (`/panel`) DEBE mantener su comportamiento directo abriendo `ScheduleMatchDialog` para el primer partido pendiente de programación (o informando mediante `SnackBar` si no existen partidos pendientes).
- **FR-010**: Todos los textos visibles al usuario (etiquetas de formulario, estados, alertas de colisión y confirmaciones) DEBEN presentarse 100% en español mediante el sistema de localización (`app_es.arb`), manteniendo los identificadores técnicos en inglés.

### Key Entities *(include if feature involves data)*

- **`ChampionshipMatch`**: Entidad que representa un encuentro del campeonato con su jornada (`roundNumber`, `roundName`), equipos (`homeTeamId`, `awayTeamId`), estado (`pendingSchedule`, `scheduled`, `inProgress`, `completed`, `cancelled`), ventana horaria (`scheduledStartTime`, `scheduledEndTime`), ubicación (`venueId`, `pitchId`, `pitchName`) y designación arbitral (`refereeId`, `refereeName`).
- **`SportsVenue` & `VenuePitch`**: Entidades de infraestructura deportiva que representan la sede y sus canchas específicas asociadas.
- **`MatchReferee`**: Entidad que representa al árbitro oficial activo habilitado para dirigir encuentros.
- **`ChampionshipTournament`**: Competición a la que pertenece el partido, cuyas fechas (`startDate`, `endDate`), reglas de duración (`halfDurationMinutes`) y estado (`openRegistration`, `inProgress`, `finished`) rigen la programación.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los partidos en estado `pendingSchedule` o `scheduled` dentro de una competición editable pueden ser programados o reprogramados por el `Organizador` asignando fecha, hora, sede, cancha y árbitro en menos de 4 pasos desde la pestaña de Jornadas.
- **SC-002**: El 100% de los intentos de guardar una programación con cruce de horario en la misma cancha o con el mismo árbitro son detectados y bloqueados antes de persistir, mostrando el mensaje de conflicto correspondiente.
- **SC-003**: El 100% de los partidos programados exitosamente actualizan de inmediato su visualización en la lista de jornadas y aparecen en el feed diario de la pestaña **Partidos** para la fecha asignada sin necesidad de reiniciar la aplicación.
- **SC-004**: Cero desbordamientos visuales (`RenderFlex overflow`) en la vista de jornadas y en el diálogo de programación al renderizarse en pantallas compactas de $320 \times 640\text{ px}$ con escalado de texto al $130\%$.

## Assumptions

- La duración total estimada de un encuentro para el cálculo de colisiones de horario se deriva de la configuración reglamentaria del campeonato (`halfDurationMinutes * 2` más el tiempo de descanso estándar gestionado por el caso de uso de programación).
- Los catálogos de sedes deportivas (`venuesRepositoryProvider`) y árbitros oficiales (`tournamentMatchesRepositoryProvider`) están disponibles localmente con soporte offline-first.
