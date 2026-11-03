# Feature Specification: Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (HU 4.1)

**Feature Branch**: `004-tournaments-custom-rules`  
**Created**: 2026-04-17  
**Status**: Draft  
**Input**: User description: "Notion [Épica 4] HU 4.1: Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (Page ID: 4078442e-3f49-8108-9e3e-d6d4fd477b75)"

## Clarifications

### Session 2026-04-17

- Q: ¿Cómo debe validarse la relación entre la Fase de Grupos y la Fase Eliminatoria cuando el organizador elige el formato `Mixto`? → A: Option B — Permitir configurar libremente la cantidad de grupos (`2..8`) y clasificados por grupo (`1..4`) sin exigir que su producto coincida con el cupo de la ronda eliminatoria inicial.
- Q: ¿Qué datos debe solicitar el diálogo de confirmación administrativa cuando el `Organizador` altera el formato o el sistema de puntuación de un campeonato en estado `"En Curso"`? → A: Option A — Exigir un motivo de auditoría breve no vacío y confirmación explícita en el diálogo, guardando `recordedAt`, `summary` (valores anteriores → nuevos) y `reason` en el historial auditado del campeonato.
- Q: ¿Cómo debe funcionar el autoguardado de borrador local y el diálogo de salida entre la creación de un campeonato nuevo y la edición de uno existente? → A: Option A — Persistir borrador local recuperable para la creación de un campeonato nuevo, y proteger con diálogo de confirmación de cambios sin guardar tanto la creación como la edición de un campeonato existente.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creación de Campeonatos con Formatos de Liga, Copa Eliminatoria o Mixto y Reglas Personalizadas (Priority: P1)

Como `Organizador` de torneos, quiero crear y configurar campeonatos eligiendo entre los formatos admitidos (`Liga` a una o dos vueltas, `Copa Eliminatoria` con llaves directas y opción de penales, o `Mixto` con fase de grupos + fase eliminatoria) y definiendo sus reglas oficiales personalizadas (sistema de puntuación, orden de criterios de desempate, límite de acumulación de tarjetas amarillas para suspensión automática, cupo mínimo/máximo de jugadores por equipo y duración de cada tiempo reglamentario), para centralizar la normativa oficial del torneo y automatizar el cálculo posterior de puntos, desempates y sanciones disciplinarias.

**Why this priority**: Es la funcionalidad central de la HU 4.1 y constituye la fuente de verdad normativa para las épicas posteriores de inscripción de equipos, generación de calendario de partidos, tabla de posiciones y control disciplinario.

**Independent Test**: Se puede probar de extremo a extremo iniciando sesión con rol `Organizador` (`RoleCapability.manageTournaments`), abriendo el asistente de creación de campeonato desde el módulo de torneos/posiciones, completando un campeonato en formato `Liga` con puntuación personalizada y otro en formato `Copa Eliminatoria` con definición por penales, guardándolos y verificando su persistencia con estado inicial `"Inscripciones Abiertas"` y sus reglas como fuente de verdad.

**Acceptance Scenarios**:

1. **Given** que un usuario con rol `Organizador` accede al formulario de `"Crear Campeonato"`, **When** ingresa el nombre `"Torneo Clausura ViFutbol 2026"`, categoría `"Libre Masculino"`, fechas de inicio y fin válidas, selecciona el formato `"Liga"` (a una o dos vueltas), establece `3` puntos por victoria, `1` por empate, `0` por derrota, ordena los criterios de desempate (`Diferencia de Gol`, `Goles a Favor`, `Duelo Directo`, `Fair Play`), fija el límite de suspensión automática en `3` tarjetas amarillas acumuladas, define el cupo de jugadores (`mínimo 7`, `máximo 18`) y la duración por tiempo (`45` minutos) y presiona `"Crear Campeonato"`, **Then** el sistema valida y persiste el campeonato con estado inicial `"Inscripciones Abiertas"` y deja registradas todas las reglas personalizadas como fuente de verdad del torneo.
2. **Given** que el `Organizador` selecciona el formato `"Copa Eliminatoria"` o `"Mixto"`, **When** activa la opción `"Desempate directo por penales al finalizar el tiempo reglamentario"` y selecciona la ronda inicial de llaves (`Octavos de Final`, `Cuartos de Final`, `Semifinal` o `Final`), **Then** el sistema habilita y registra la estructura de llaves eliminatorias exigiendo un ganador en cada llave sin permitir empates globales en cruces eliminatorios.
3. **Given** que el `Organizador` intenta guardar un campeonato con datos inválidos (nombre vacío, fecha de fin anterior a la fecha de inicio, cupo mínimo mayor al cupo máximo, o puntos por victoria menores o iguales a los puntos por derrota), **When** presiona `"Guardar Campeonato"`, **Then** el sistema bloquea el guardado y muestra mensajes de validación claros en español junto a los campos afectados.

---

### User Story 2 - Consulta de Normativa Oficial e Inmutabilidad Auditada de Reglas Críticas (Priority: P2)

Como usuario de cualquier rol (`Aficionado`, `Jugador`, `Delegado de Equipo`, `Árbitro` u `Organizador`), quiero explorar el catálogo de campeonatos registrados y consultar la ficha oficial de normativa y reglas de cada torneo; además, como `Organizador`, quiero gestionar la transición de estado del campeonato (`Inscripciones Abiertas`, `En Curso`, `Finalizado`) garantizando que cuando el campeonato esté `"En Curso"`, el formato del torneo y el sistema de puntuación permanezcan protegidos contra alteraciones accidentales y requieran confirmación administrativa explícita con registro de auditoría/recálculo antes de modificarse.

**Why this priority**: Garantiza la transparencia reglamentaria para todos los participantes del torneo y cumple la regla de negocio crítica de inmutabilidad normativa una vez iniciado el campeonato.

**Independent Test**: Se puede probar cambiando el rol activo a cualquier rol no organizador para verificar que los controles de creación/edición no se renderizan y que la ficha de reglas oficiales es legible; luego, con rol `Organizador`, cambiar un campeonato a estado `"En Curso"` e intentar editar su formato o sistema de puntuación para comprobar el bloqueo por defecto y el flujo de confirmación administrativa explícita con registro de auditoría.

**Acceptance Scenarios**:

1. **Given** que existen campeonatos registrados en el catálogo, **When** cualquier usuario selecciona un campeonato para ver su detalle, **Then** el sistema presenta una ficha clara con su formato (`Liga`, `Copa Eliminatoria` o `Mixto`), estado actual, fechas, tabla de puntuación (`Victoria / Empate / Derrota`), orden numerado de criterios de desempate, límite de tarjetas amarillas para suspensión, cupos de plantilla, duración de tiempos y estructura de llaves eliminatorias.
2. **Given** que un usuario tiene rol `Aficionado`, `Jugador`, `Delegado de Equipo` o `Árbitro` (sin `RoleCapability.manageTournaments`), **When** navega por el listado y detalle de campeonatos, **Then** el sistema oculta por completo los botones de crear campeonato, editar reglas y cambiar estado del torneo.
3. **Given** que un campeonato se encuentra en estado `"En Curso"`, **When** el `Organizador` abre la edición del campeonato e intenta modificar el formato del torneo o el sistema de puntuación (`puntos por victoria/empate/derrota`), **Then** esos campos críticos se muestran protegidos por defecto y solo permiten su modificación si el `Organizador` acepta un diálogo de confirmación administrativa explícita que advierte del recálculo de tabla y registra una marca de auditoría con fecha/hora y motivo en el historial del campeonato.

---

### User Story 3 - Autoguardado de Borrador Móvil y Protección al Salir con Cambios sin Guardar (Priority: P3)

Como `Organizador` editando o creando un campeonato desde el dispositivo móvil, quiero que el progreso del formulario se autoguarde temporalmente en almacenamiento local cuando la aplicación pase a segundo plano o ocurra un cierre inesperado, y recibir un diálogo de confirmación (`"¿Deseas descartar los cambios o guardar como borrador?"`) cuando intente retroceder con cambios sin guardar, para no perder configuraciones extensas de reglas y formatos.

**Why this priority**: Cumple las reglas de negocio 4 y Escenario 3 de la HU 4.1 orientadas a la experiencia móvil en cancha u oficina, evitando pérdida accidental de datos en formularios multipaso o detallados.

**Independent Test**: Se puede probar abriendo el formulario de creación de campeonato, ingresando nombre y reglas parciales, presionando el botón de retroceso y verificando que aparece el diálogo `"¿Deseas descartar los cambios o guardar como borrador?"`, guardando el borrador, cerrando y reabriendo el formulario para confirmar que los datos se restauran automáticamente.

**Acceptance Scenarios**:

1. **Given** que el `Organizador` ha ingresado datos parciales en el formulario de creación de campeonato y no ha presionado `"Guardar Campeonato"`, **When** presiona el botón de retroceso o intenta cerrar la vista, **Then** el sistema intercepta la navegación y muestra un diálogo de confirmación preguntando `"¿Deseas descartar los cambios o guardar como borrador?"` con opciones para `"Guardar borrador"`, `"Descartar cambios"` o `"Seguir editando"`.
2. **Given** que el `Organizador` guardó un borrador o la aplicación guardó automáticamente el estado en curso al cambiar el ciclo de vida de la app a segundo plano, **When** el `Organizador` vuelve a abrir el asistente de `"Crear Campeonato"`, **Then** el sistema restaura los valores del borrador local y muestra un aviso indicando que se recuperó un borrador guardado con opción de limpiarlo.
3. **Given** que el dispositivo pierde conectividad de red, **When** el `Organizador` consulta campeonatos existentes o guarda un nuevo campeonato/borrador, **Then** el catálogo local y el borrador funcionan sin bloqueos ni pérdida de información.

### Edge Cases

- **Cambio de formato durante la creación**: Si el `Organizador` cambia el formato de `"Copa Eliminatoria"` a `"Liga"` antes de guardar, las opciones exclusivas de llaves eliminatorias se desactivan en la validación activa sin corromper las reglas generales del torneo; si cambia a `"Mixto"`, se habilitan simultáneamente la configuración de fase de grupos (puntuación y criterios de desempate en tabla) y la configuración de llaves eliminatorias.
- **Orden de criterios de desempate sin duplicados**: El `Organizador` puede reordenar los criterios de desempate (`Diferencia de Gol`, `Goles a Favor`, `Duelo Directo`, `Fair Play`) subiendo o bajando su prioridad, garantizando que siempre exista una secuencia determinista sin criterios duplicados ni vacíos.
- **Intento de modificar reglas críticas en estado `Finalizado`**: Cuando un campeonato alcanza el estado `"Finalizado"`, la edición de formato y reglas queda bloqueada para preservar el registro histórico oficial del torneo.
- **Limpieza de borrador al publicar**: Cuando el `Organizador` completa y publica exitosamente un campeonato nuevo, cualquier borrador temporal almacenado localmente se elimina automáticamente para no reaparecer en la siguiente creación.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir a los usuarios con rol `Organizador` (`RoleCapability.manageTournaments`) crear y editar campeonatos especificando nombre oficial, categoría, fecha de inicio, fecha estimada de finalización, formato del torneo (`Liga`, `Copa Eliminatoria`, `Mixto`) y configuración completa de reglas personalizadas.
- **FR-002**: El sistema DEBE soportar los tres formatos oficiales de campeonato:
  - `Liga`: todos contra todos, permitiendo configurar `1` vuelta (solo ida) o `2` vueltas (ida y vuelta).
  - `Copa Eliminatoria`: llaves de eliminación directa seleccionando la ronda inicial (`Octavos de Final`, `Cuartos de Final`, `Semifinal` o `Final`), modalidad de cruce (partido único o ida y vuelta) y activación de definición directa desde el punto penal al finalizar el tiempo reglamentario en caso de empate.
  - `Mixto`: combinación de fase de grupos (permitiendo configurar libremente entre `2` y `8` grupos y entre `1` y `4` clasificados por grupo, por defecto `4` grupos y `2` clasificados, sin exigir que su producto coincida con el tamaño de la llave) seguida de fase final de llaves eliminatorias.
- **FR-003**: El sistema DEBE permitir configurar y validar las reglas personalizadas del campeonato con valores predeterminados reglamentarios:
  - Puntos por victoria (por defecto `3`), puntos por empate (por defecto `1`) y puntos por derrota (por defecto `0`), validando que `victoria > empate >= derrota >= 0`.
  - Orden determinista de criterios de desempate en tabla: `Diferencia de Gol`, `Goles a Favor`, `Duelo Directo` y `Fair Play`.
  - Límite de acumulación de tarjetas amarillas para suspensión automática de un partido (por defecto `3`, configurable en el rango `2..10`).
  - Cantidad mínima y máxima de jugadores inscritos por equipo (por defecto mínimo `7`, máximo `18`, validando `5 <= mínimo <= máximo <= 35`).
  - Duración reglamentaria de cada tiempo de juego en minutos (por defecto `45` minutos por tiempo, configurable en el rango `10..60`).
- **FR-004**: El sistema DEBE asignar el estado inicial `"Inscripciones Abiertas"` a todo campeonato recién creado y permitir al `Organizador` transicionar su estado a `"En Curso"` y posteriormente a `"Finalizado"`.
- **FR-005**: Cuando un campeonato se encuentre en estado `"En Curso"`, el sistema DEBE proteger como inmutables por defecto el formato del torneo y el sistema de puntuación (`puntos por victoria/empate/derrota`), exigiendo una confirmación administrativa explícita del `Organizador` con un motivo de auditoría no vacío antes de desbloquear y aplicar cambios en dichas reglas críticas, y registrando un `RuleAuditEntry` (`recordedAt`, `summary` con transición de valores anteriores a nuevos, `reason` y `recalculationConfirmed`) en el historial del campeonato.
- **FR-006**: El sistema DEBE conservar automáticamente en almacenamiento local un borrador temporal del asistente de creación de campeonato nuevo cuando la aplicación pase a segundo plano o cuando el `Organizador` elija `"Guardar borrador"` en el diálogo de salida `"¿Deseas descartar los cambios o guardar como borrador?"`, limpiando dicho borrador tras publicar el campeonato o descartar explícitamente los cambios; asimismo, DEBE proteger con diálogo de confirmación de salida con cambios sin guardar tanto la creación de un campeonato nuevo como la edición de uno existente.
- **FR-007**: El sistema DEBE exponer el catálogo y detalle normativo de campeonatos en la pestaña de `Posiciones` (`StandingsTabView` / módulo de Campeonatos del shell principal) con estados explícitos (`loading`, `empty`, `content`, `error`), precargando campeonatos semilla representativos en entorno `dev` (incluyendo al menos una `Liga` y una `Copa Eliminatoria` / `Mixto`) para facilitar pruebas inmediatas.
- **FR-008**: El sistema DEBE restringir todas las acciones de creación, edición de reglas y cambio de estado exclusivamente al rol `Organizador` mediante `RoleCapability.manageTournaments`, ocultando los controles de mutación para `Aficionado`, `Jugador`, `Delegado de Equipo` y `Árbitro`.
- **FR-009**: Toda la interfaz de usuario, etiquetas de formatos, reglas, criterios de desempate, estados del campeonato y diálogos de confirmación DEBEN presentarse 100% en español mediante `AppLocalizations` (`lib/l10n/app_es.arb`), manteniendo todos los identificadores de código en inglés conforme a la Constitución del proyecto.

### Key Entities *(include if feature involves data)*

- **`ChampionshipTournament`**: Entidad raíz de dominio que representa un campeonato oficial (`id`, `name`, `category`, `startDate`, `endDate`, `format`, `status`, `rules`, `auditTrail`, `updatedAt`).
- **`TournamentFormat`**: Enumeración de formatos admitidos (`league`, `knockoutCup`, `mixedGroupsAndKnockout`).
- **`TournamentStatus`**: Enumeración de la máquina de estados del campeonato (`openRegistration` / `"Inscripciones Abiertas"`, `inProgress` / `"En Curso"`, `finished` / `"Finalizado"`).
- **`TournamentRulesConfig`**: Objeto de valor inmutable que encapsula las reglas oficiales del campeonato (`pointsForWin`, `pointsForDraw`, `pointsForLoss`, `tiebreakerOrder`, `yellowCardSuspensionLimit`, `minPlayersPerTeam`, `maxPlayersPerTeam`, `halfDurationMinutes`, `leagueRounds`, `knockoutConfig`, `groupStageConfig`).
- **`TiebreakerCriterion`**: Enumeración de criterios de desempate en tabla (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`).
- **`KnockoutStageConfig`**: Configuración de llaves eliminatorias (`startingRound`: `roundOf16`, `quarterFinals`, `semiFinals`, `finalMatch`; `twoLeggedTies`: `bool`; `directPenaltyShootoutOnDraw`: `bool`).
- **`RuleAuditEntry`**: Registro de auditoría cuando se modifica una regla crítica estando el campeonato `En Curso` (`recordedAt`, `summary`, `reason`, `recalculationConfirmed`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un `Organizador` puede crear y persistir un campeonato completo (en formato `Liga`, `Copa Eliminatoria` o `Mixto` con reglas personalizadas) en menos de 90 segundos desde la pestaña de campeonatos/posiciones.
- **SC-002**: El 100% de los intentos de modificar el formato o el sistema de puntuación de un campeonato en estado `"En Curso"` sin confirmación administrativa explícita son bloqueados por la capa de dominio y la interfaz de usuario, y el 100% de los cambios confirmados generan un registro de auditoría verificable.
- **SC-003**: El 100% de las salidas accidentales del formulario de creación con cambios pendientes presentan el diálogo `"¿Deseas descartar los cambios o guardar como borrador?"` y permiten recuperar el borrador íntegro al reabrir el asistente.
- **SC-004**: El 100% de los usuarios con roles sin capacidad `RoleCapability.manageTournaments` (`Aficionado`, `Jugador`, `Delegado de Equipo`, `Árbitro`) pueden consultar la normativa oficial de cualquier campeonato sin visualizar controles de creación o edición.
- **SC-005**: La suite automatizada alcanza 0 errores en `flutter analyze`, formato limpio en `dart format` y cobertura `>= 80%` en la lógica de dominio y aplicación del módulo de campeonatos y reglas personalizadas.

## Assumptions

- El acceso principal al catálogo y creación de campeonatos se integra en la pestaña existente de `Posiciones` (`StandingsTabView`, que actúa como el centro de Campeonatos, Tablas y Llaves en el shell actual de 4 pestañas), manteniendo una ruta dedicada (`/tournaments/form`) para el asistente de creación/edición de campeonatos.
- En esta HU 4.1 se define y persiste la estructura normativa del campeonato (formatos, puntuación, desempates, llaves eliminatorias, límites disciplinarios y cupos) junto con la visualización de su estructura de tabla/llaves inicial; la inscripción efectiva de equipos específicos y la generación automática de partidos se conectarán sobre esta fuente de verdad en las siguientes historias de usuario de la Épica 4 y Épica 5.
- El almacenamiento local (`LocalStorageRepository` / `SharedPreferences`) actúa como fuente de persistencia offline-first para el catálogo de campeonatos y para el borrador temporal del asistente de creación.
