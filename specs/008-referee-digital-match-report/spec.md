# Feature Specification: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)

**Feature Branch**: `008-referee-digital-match-report`  
**Created**: 2026-11-04  
**Status**: Draft  
**Input**: User description: "Notion [Épica 7] HU 7.1: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (Page ID: 4078442e-3f49-8153-92b9-cf76fe79fa33)"

## Clarifications

### Session 2026-11-04

- Q: ¿Cómo debe integrarse en la navegación móvil la pantalla del Acta Digital del Partido y sus controles en tiempo real? → A: Option A — Abrir desde `MatchCard` en `"Jornada"` una pantalla dedicada (`/matches/report`) con marcador tabular fijo, cronómetro resiliente, botonera de acción rápida exclusiva para `Árbitro`/`Organizador`, banner de estado offline y línea de tiempo en vivo (modo lectura para los demás roles).
- Q: ¿Cómo debe manejarse la corrección o anulación de una incidencia registrada por error antes de que el árbitro cierre el acta oficial? → A: Option A — Permitir al `Árbitro`/`Organizador` eliminar o deshacer incidencias erróneas mientras el acta esté abierta (`"En Juego"`), recalculando marcador y expulsiones, y bloquear de forma inmutable cualquier cambio al confirmar `"Cerrar Acta Oficial"`.
- Q: ¿Cómo debe gestionarse y visualizarse el estado de conexión y la sincronización de la cola de eventos del acta arbitral en cancha? → A: Option A — Estado de conectividad reactivo con indicador/conmutador en el acta que encola eventos localmente (`isSynced: false`) mostrando `"Modo sin conexión: cambios guardados en el dispositivo"`, y sincroniza automáticamente de forma idempotente al restablecer conexión.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Control del Encuentro y Registro en Vivo de Goles, Asistencias, Tarjetas y Sustituciones (Priority: P1)

Como `Árbitro` designado a un encuentro oficial (o `Organizador` en caso de contingencia justificada), quiero iniciar el partido cambiando su estado a `"En Juego"`, controlar los periodos de juego (primer tiempo, descanso, segundo tiempo) con un cronómetro exacto basado en marcas de tiempo, y registrar en tiempo real goles (con jugador anotador y asistente opcional de la nómina convocada), tarjetas (amarillas, doble amarilla con expulsión automática y roja directa) y sustituciones, para actualizar inmediatamente el marcador en vivo y la línea de tiempo oficial del partido.

**Why this priority**: Representa el núcleo operativo de la HU 7.1 (Fase 1 Gherkin). Sin el control del partido y el registro de incidencias en tiempo real con validación disciplinaria (doble amarilla = roja automática y bloqueo del jugador expulsado), no existe fuente de verdad para los resultados ni para las estadísticas del campeonato.

**Independent Test**: Se puede probar accediendo como `Árbitro` u `Organizador` a un partido programado desde la pestaña de `"Jornada"`, iniciando el encuentro (`"En Juego"`), registrando un gol con asistencia para el equipo local en el minuto 34 y dos tarjetas amarillas al jugador con dorsal `"5"` (la segunda en el minuto 68), verificando que el marcador se actualiza con números tabulares (`tabular-nums`), que el evento aparece en la línea de tiempo con señal semántica `"Accent Live"` (`#EF4444`), y que la segunda amarilla genera automáticamente la expulsión por tarjeta roja impidiendo registrar nuevos goles o asistencias para ese jugador expulsado.

**Acceptance Scenarios**:

1. **Given** que el `Árbitro` ha cambiado el estado del partido a `"En Juego"`, **When** selecciona la acción `"Registrar Gol"` para el equipo local en el minuto 34 y asigna al jugador anotador y opcionalmente al jugador asistente de la nómina convocada, **Then** el marcador en vivo se actualiza inmediatamente con tipografía tabular (`tabular-nums`) y el evento se publica en la línea de tiempo del partido con señal semántica `"Accent Live"` (`#EF4444`).
2. **Given** que el jugador con dorsal `"5"` ya tiene registrada una tarjeta amarilla en el partido actual, **When** el `Árbitro` registra una segunda tarjeta amarilla para el mismo jugador en el minuto 68, **Then** el sistema registra automáticamente la segunda amarilla seguida de tarjeta roja por acumulación y marca al jugador como expulsado, impidiendo que registre nuevos goles, asistencias o sustituciones en ese partido.
3. **Given** que un usuario con rol `Aficionado`, `Jugador` o `Entrenador` abre el detalle del partido en curso o finalizado, **When** consulta el acta y la línea de tiempo del encuentro, **Then** visualiza el marcador actualizado, el minuto y el detalle de cada incidencia en modo de solo lectura sin acceso a los botones de control arbitral.

---

### User Story 2 - Operación Offline-First en Cancha y Sincronización Idempotente sin Duplicados (Priority: P2)

Como `Árbitro` dirigiendo un encuentro en una cancha urbana con conectividad intermitente o nula, quiero que cada cambio de periodo y cada incidencia registrada (goles, asistencias, tarjetas, sustituciones) se guarde instantáneamente en el dispositivo con un identificador único sin bloquear la pantalla, mostrándome el aviso `"Modo sin conexión: cambios guardados en el dispositivo"`, y que al recuperar la conexión a internet la cola de eventos se sincronice automáticamente sin duplicar goles ni tarjetas.

**Why this priority**: Garantiza la resiliencia operativa en campo exigida por la Fase 2 Gherkin y el principio de capacidad Offline-First del proyecto, evitando pérdida de datos o duplicidad en el marcador oficial cuando falla la señal móvil en las sedes deportivas.

**Independent Test**: Se puede probar activando el modo sin conexión durante un partido `"En Juego"`, registrando un gol, una tarjeta amarilla y el cierre del primer tiempo, comprobando que aparece el aviso `"Modo sin conexión: cambios guardados en el dispositivo"`, que todos los eventos quedan persistidos localmente con estado pendiente de sincronización, y que al restablecer la conexión la cola se procesa de forma idempotente marcando los eventos como sincronizados sin duplicar registros.

**Acceptance Scenarios**:

1. **Given** que el `Árbitro` se encuentra dirigiendo un partido y el dispositivo pierde la conexión a internet, **When** registra un gol, una tarjeta amarilla y posteriormente el cierre del primer tiempo, **Then** la aplicación guarda todos los eventos localmente con identificadores únicos sin bloquear la pantalla y muestra un indicador claro en español: `"Modo sin conexión: cambios guardados en el dispositivo"`.
2. **Given** que existen eventos de partido almacenados localmente en la cola pendiente mientras no había conexión, **When** el dispositivo recupera la conexión a internet, **Then** el sistema sincroniza automáticamente la cola de eventos con el servidor/almacenamiento central utilizando sus identificadores únicos sin duplicar goles, tarjetas ni cambios de estado.

---

### User Story 3 - Cierre Oficial e Inmutable del Acta Arbitral (Priority: P3)

Como `Árbitro` del encuentro, quiero revisar el resumen consolidado de goles, asistencias, tarjetas y sustituciones al concluir el tiempo reglamentario y confirmar la acción `"Cerrar Acta Oficial"`, para que el partido cambie su estado a `"Finalizado"`, el acta quede firmada y bloqueada de forma inmutable frente a ediciones posteriores, y se actualicen las estadísticas disciplinarias e individuales de los jugadores participantes.

**Why this priority**: Completa el ciclo de vida oficial del partido (Fase 3 Gherkin), asegurando la integridad referencial e inmutabilidad del resultado oficial del encuentro.

**Independent Test**: Se puede probar en un partido `"En Juego"` con goles y tarjetas registrados, pulsando `"Cerrar Acta Oficial"`, revisando el resumen de incidencias en el diálogo de confirmación y confirmando el cierre, verificando que el partido pasa a estado `"Finalizado"`, que los controles de registro de eventos desaparecen o quedan bloqueados, y que cualquier intento posterior de agregar o modificar eventos en esa acta es rechazado.

**Acceptance Scenarios**:

1. **Given** que el tiempo reglamentario del partido ha concluido, **When** el `Árbitro` revisa el resumen de goles y tarjetas y confirma `"Cerrar Acta Oficial"`, **Then** el partido cambia su estado a `"Finalizado"` y el acta queda bloqueada frente a modificaciones posteriores no autorizadas.
2. **Given** que un partido ya tiene su acta cerrada en estado `"Finalizado"`, **When** cualquier usuario intenta registrar un nuevo gol, tarjeta o modificar el marcador en ese partido, **Then** el sistema rechaza la operación informando en español que el acta oficial ya fue cerrada de manera definitiva.

### Edge Cases

- **Cronómetro resiliente al bloqueo de pantalla y segundo plano**: El tiempo transcurrido del partido se calcula por diferencia entre la marca de tiempo actual y la marca de tiempo de inicio del periodo activo (más el tiempo acumulado de periodos previos), garantizando que no se pierdan segundos cuando el árbitro bloquea el teléfono o la aplicación pasa a segundo plano durante el encuentro.
- **Jugador expulsado (roja directa o doble amarilla)**: Una vez que un jugador recibe tarjeta roja directa o acumula su segunda amarilla en el partido, queda inmediatamente inhabilitado durante el resto del encuentro para ser seleccionado como autor de gol, asistente, receptor de nuevas tarjetas o participante en una sustitución.
- **Asistente distinto al anotador**: Al registrar un gol con asistencia, el jugador asistente debe pertenecer al mismo equipo que anota el gol y no puede ser el mismo jugador seleccionado como anotador ni un jugador ya expulsado.
- **Respaldo de nómina cuando no existe convocatoria previa confirmada**: Si un equipo aún no tiene una convocatoria específica confirmada por el entrenador para ese encuentro, el acta arbitral permite seleccionar jugadores a partir de la plantilla oficial habilitada del equipo inscrito en el campeonato (excluyendo jugadores suspendidos), garantizando que el árbitro nunca quede bloqueado en cancha.
- **Protección contra pulsaciones dobles y áreas táctiles**: Todos los botones de acción rápida en cancha (`"Registrar Gol"`, `"Tarjeta Amarilla"`, `"Tarjeta Roja"`, `"Sustitución"`, `"Cerrar Acta Oficial"`) cuentan con área táctil mínima de `44x44px` y bloqueo de envío en vuelo (*single-flight lock*) para evitar registros duplicados por toques involuntarios.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir abrir desde cada tarjeta de partido (`MatchCard`) en la pestaña `"Jornada"` una vista dedicada del acta digital (`/matches/report`) con cabecera fija de marcador tabular y cronómetro por marcas de tiempo, restringiendo las acciones de iniciar partido, controlar periodos de juego, registrar incidencias y cerrar el acta oficial exclusivamente al `Árbitro` asignado al partido (`RoleCapability.recordMatchEvents` y `RoleCapability.closeMatchReport`) o al `Organizador` del campeonato (`RoleCapability.manageTournaments`) en caso de contingencia justificada; los demás roles (`Entrenador`, `Jugador`, `Aficionado`) solo tendrán acceso de lectura al marcador y a la línea de tiempo en vivo.
- **FR-002**: El sistema DEBE permitir controlar el ciclo de vida y periodos del partido desde `"Programado"` hacia `"En Juego"` (incluyendo `"Primer Tiempo"`, `"Descanso"`, `"Segundo Tiempo"` y `"Tiempo Cumplido"`) calculando el minuto y tiempo de juego mediante marcas de tiempo persistidas para conservar la exactitud del cronómetro cuando la aplicación pasa a segundo plano o se bloquea la pantalla.
- **FR-003**: El sistema DEBE permitir al `Árbitro` registrar en tiempo real eventos de `"Gol"` para el equipo local o visitante, indicando el minuto de juego, el jugador anotador obligatorio y un jugador asistente opcional (distinto al anotador) dentro de la nómina habilitada del equipo, actualizando de inmediato el marcador en vivo con tipografía tabular (`tabular-nums`) y publicando el evento en la línea de tiempo con la señal semántica `"Accent Live"` (`#EF4444`).
- **FR-004**: El sistema DEBE permitir registrar tarjetas disciplinarias (`"Tarjeta Amarilla"` y `"Tarjeta Roja"`) asociadas a un equipo, jugador y minuto del partido, aplicando automáticamente la **Regla de Doble Amarilla**: cuando se registra una segunda tarjeta amarilla al mismo jugador dentro del mismo encuentro, el sistema DEBE generar automáticamente el evento de expulsión por tarjeta roja indirecta (acumulación) y marcar al jugador como expulsado en el partido.
- **FR-005**: El sistema DEBE impedir que un jugador expulsado en el partido actual (por tarjeta roja directa o por doble amarilla) sea seleccionado para registrar nuevos goles, asistencias, tarjetas adicionales o sustituciones posteriores dentro del mismo encuentro.
- **FR-006**: El sistema DEBE permitir registrar eventos de `"Sustitución"` durante el partido indicando el equipo, el minuto, el jugador que sale y el jugador habilitado que ingresa.
- **FR-007**: El sistema DEBE operar bajo un esquema **Offline-First e Idempotente** con estado de conectividad reactivo (incluyendo indicador/conmutador en el acta para contingencia y validación en cancha): cada evento o cambio de estado del acta DEBE poseer un identificador único inmutable, guardarse inmediatamente en el almacenamiento local del dispositivo sin bloquear la interfaz y, cuando el dispositivo se encuentre sin conexión, encolarse con `isSynced: false` mostrando el indicador explícito en español `"Modo sin conexión: cambios guardados en el dispositivo"`, sincronizando automáticamente de forma idempotente la cola de eventos pendientes al recuperar conectividad sin generar registros duplicados.
- **FR-008**: El sistema DEBE permitir al `Árbitro` (u `Organizador`) anular o eliminar una incidencia registrada por error en la línea de tiempo únicamente mientras el acta permanezca abierta (`"En Juego"`), recalculando automáticamente el marcador en vivo y el estado de expulsión del jugador (incluyendo revertir la tarjeta roja automática si se anula la segunda amarilla); y al revisar el resumen oficial del encuentro y ejecutar `"Cerrar Acta Oficial"`, DEBE cambiar el estado del partido a `"Finalizado"`, bloqueando de forma inmutable cualquier edición o eliminación posterior sobre el acta y actualizando las métricas individuales y disciplinarias de los jugadores en el campeonato.
- **FR-009**: En entorno de desarrollo (`dev`), el sistema DEBE precargar datos semilla que permitan abrir y probar de inmediato el acta digital sobre partidos programados o en juego con sus nóminas de jugadores y dorsal correspondiente (incluyendo un jugador con dorsal `"5"`).
- **FR-010**: Todos los textos visibles para el usuario, etiquetas de cronómetro, tipos de incidencias, banners de estado sin conexión y diálogos de cierre de acta DEBEN estar 100% en español centralizados en el sistema de localización, manteniendo todos los identificadores técnicos en inglés.

### Key Entities *(include if feature involves data)*

- **`DigitalMatchReport` (Acta Digital del Partido)**: Representa el estado oficial consolidado de un encuentro (`matchId`, `tournamentId`, `homeScore`, `awayScore`, `currentPeriod`, `periodStartedAt`, `elapsedSecondsBeforeCurrentPeriod`, `events`, `isOfflineMode`, `pendingSyncCount`, `closedAt`, `closedByUserId`).
- **`MatchEvent` (Evento de Partido)**: Incidencia oficial registrada en la línea de tiempo con identificador único inmutable para idempotencia (`id`, `matchId`, `type` [gol, tarjeta amarilla, segunda amarilla + roja por acumulación, tarjeta roja directa, sustitución, inicio/fin de periodo], `minute`, `teamId`, `primaryPlayerId`, `primaryPlayerName`, `primaryPlayerShirtNumber`, `secondaryPlayerId`, `secondaryPlayerName`, `notes`, `createdAt`, `isSynced`).
- **`MatchPeriod` (Periodo del Encuentro)**: Etapa operativa del partido (`notStarted` / `"Por Iniciar"`, `firstHalf` / `"Primer Tiempo"`, `halfTime` / `"Descanso"`, `secondHalf` / `"Segundo Tiempo"`, `fullTime` / `"Tiempo Reglamentario"`, `closed` / `"Acta Cerrada"`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El `Árbitro` puede registrar un gol (con anotador y asistente) o una tarjeta disciplinaria en menos de 10 segundos y máximo 3 toques desde la pantalla del acta en vivo.
- **SC-002**: El 100% de las segundas tarjetas amarillas registradas a un mismo jugador en el mismo partido disparan automáticamente la expulsión por tarjeta roja y bloquean al jugador para nuevos goles o asistencias en ese encuentro.
- **SC-003**: El 100% de los eventos registrados sin conexión a internet se guardan localmente en menos de 100 milisegundos mostrando el aviso `"Modo sin conexión: cambios guardados en el dispositivo"` y se sincronizan al recuperar red con 0 eventos duplicados.
- **SC-004**: El cronómetro del partido mantiene una precisión exacta (0 segundos de desfase por suspensión de pantalla) tras pasar la aplicación a segundo plano y reanudarla.
- **SC-005**: Una vez ejecutado `"Cerrar Acta Oficial"`, el 100% de los intentos de agregar o modificar eventos sobre el partido `"Finalizado"` son rechazados de forma determinista.

## Assumptions

- El acceso al Acta Digital del Partido se realiza directamente desde la tarjeta de cada encuentro (`MatchCard`) en la pestaña `"Jornada"` (`MatchdayTabView`): para el `Árbitro` designado (o el `Organizador`) se habilita el botón de control `"Abrir Acta Arbitral"` / `"Dirigir Partido"`, y para los demás roles se ofrece `"Ver Acta / En Vivo"` en modo lectura.
- Cuando un equipo tiene una convocatoria oficial confirmada (HU 5.2), el selector de jugadores del acta utiliza esa nómina de titulares y suplentes; si un equipo aún no confirmó convocatoria previa para ese partido, el sistema carga como respaldo a los jugadores habilitados de la plantilla oficial del equipo (HU 5.1) para no bloquear el arbitraje en cancha.
- Al cerrarse el acta oficial (`"Finalizado"`), además de actualizar el estado y marcador en el catálogo de partidos (HU 6.1), se actualizan automáticamente las métricas acumuladas de goles, asistencias, tarjetas y suspensiones en el seguimiento de los jugadores del campeonato, dejando lista la fuente de verdad para el cálculo de tablas de posiciones y rankings de la Épica 8.
