# Feature Specification: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Feature Branch**: `005-teams-players-eligibility`  
**Created**: 2026-04-17  
**Status**: Draft  
**Input**: User description: "Notion [Épica 5] HU 5.1: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (Page ID: 4078442e-3f49-81c4-8588-c3b324c765e3)"

## Clarifications

### Session 2026-04-17

- Q: ¿Cómo debe representarse y seleccionarse el escudo y los colores distintivos del equipo en el formulario móvil? → A: Option A — Escudo vectorial nativo configurable con sigla (`2..4` caracteres), forma de emblema (`TeamCrestShape`) y selector de colores primario y secundario (100% offline-first).
- Q: ¿Qué operaciones de inscripción de equipos y jugadores deben permitirse cuando el campeonato cambia su estado de `"Inscripciones Abiertas"` a `"En Curso"` o `"Finalizado"`? → A: Option A — Permitir registrar equipos y modificar plantillas de jugadores exclusivamente mientras el campeonato esté en `"Inscripciones Abiertas"`; bloquear altas/bajas de equipos y jugadores en `"En Curso"` y `"Finalizado"`.
- Q: ¿Cómo debe integrarse la navegación hacia el registro de equipos y la gestión de plantillas de jugadores dentro del campeonato seleccionado? → A: Option A — Mostrar tarjetas de equipos inscritos en `StandingsTabView` para el campeonato activo y abrir una vista dedicada de plantilla (`/tournaments/teams/detail`) para agregar jugadores y gestionar la habilitación del equipo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registro de Equipos e Inscripción de Plantilla Oficial en un Campeonato (Priority: P1)

Como `Organizador` o `Entrenador` (`RoleCapability.manageTournaments` / `RoleCapability.manageTeamRoster`), quiero inscribir un equipo en un campeonato que se encuentre en estado `"Inscripciones Abiertas"` definiendo su nombre oficial, sigla/escudo e identidad cromática (colores primario y secundario), y registrar su nómina de jugadores indicando nombre completo, documento de identidad único, posición en el campo (`Portero`, `Defensa`, `Mediocampista`, `Delantero`) y número de camiseta (dorsal), para vincular oficialmente la plantilla al campeonato y habilitar a sus jugadores para futuras convocatorias y estadísticas.

**Why this priority**: Es el flujo principal de la HU 5.1 y constituye el puente indispensable entre las reglas del campeonato (HU 4.1) y la programación de partidos, convocatorias y actas arbitrales de las siguientes épicas.

**Independent Test**: Se puede probar iniciando sesión como `Organizador` o `Entrenador`, seleccionando un campeonato con estado `"Inscripciones Abiertas"`, registrando un equipo nuevo con sus colores distintivos y agregando jugadores con documento, posición y dorsal con teclado numérico, verificando su persistencia y vinculación al campeonato.

**Acceptance Scenarios**:

1. **Given** que un campeonato se encuentra en estado `"Inscripciones Abiertas"`, **When** el `Organizador` o `Entrenador` registra un equipo con nombre `"Atlético Norte FC"`, escudo/monograma y colores distintivos, y agrega jugadores válidos con nombre completo, documento de identidad, posición y dorsal único, **Then** el sistema persiste el equipo y vincula su plantilla oficial al campeonato seleccionado.
2. **Given** que el usuario abre el formulario de inscripción de jugador desde un dispositivo móvil, **When** enfoca el campo de documento de identidad o el campo de número de camiseta (dorsal), **Then** el sistema despliega automáticamente el teclado numérico y protege el envío contra pulsaciones repetidas.
3. **Given** que un campeonato ya no está en estado `"Inscripciones Abiertas"` (por ejemplo, se encuentra `"Finalizado"`), **When** un usuario consulta los equipos de ese campeonato, **Then** el sistema bloquea el registro de nuevos equipos sobre dicho campeonato cerrado.

---

### User Story 2 - Validaciones de Integridad Deportiva y Unicidad de Equipo, Dorsal y Jugador por Torneo (Priority: P2)

Como `Organizador` o `Entrenador`, quiero que el sistema valide en tiempo real y antes de persistir que no existan dos equipos con el mismo nombre dentro del mismo campeonato, que ningún número de camiseta (dorsal) se repita dentro de la misma plantilla y que ningún jugador (identificado por su documento de identidad) pueda inscribirse simultáneamente en dos equipos distintos del mismo campeonato, mostrando los mensajes reglamentarios exactos en español cuando ocurra una colisión.

**Why this priority**: Garantiza la integridad referencial y la transparencia competitiva del campeonato exigidas por el Principio II de la Constitución y los escenarios Gherkin de la Fase 2 de la HU 5.1.

**Independent Test**: Se puede probar intentando inscribir un jugador cuyo documento ya pertenece al `"Equipo A"` dentro del `"Equipo B"` del mismo campeonato y verificando el rechazo con el mensaje `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`, así como intentando registrar dos jugadores con el dorsal `"10"` en el mismo equipo y verificando el mensaje `"El número de camiseta 10 ya está en uso en este equipo."`.

**Acceptance Scenarios**:

1. **Given** que un jugador con documento `"10203040"` ya se encuentra inscrito oficialmente en el `"Equipo A"` del campeonato actual, **When** se intenta inscribir a un jugador con el mismo documento `"10203040"` en el `"Equipo B"` del mismo campeonato, **Then** el sistema rechaza el registro y muestra el mensaje de validación en español: `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`.
2. **Given** que el dorsal `"10"` ya está asignado a un jugador activo dentro de la plantilla del equipo, **When** el `Entrenador` u `Organizador` intenta asignar el dorsal `"10"` a otro jugador del mismo equipo, **Then** el sistema bloquea la acción y muestra el error: `"El número de camiseta 10 ya está en uso en este equipo."`.
3. **Given** que ya existe un equipo llamado `"Real Sabana"` en el campeonato actual, **When** se intenta registrar otro equipo con el mismo nombre (ignorando mayúsculas/minúsculas y espacios extremos) en el mismo campeonato, **Then** el sistema rechaza el registro e informa que el nombre del equipo ya está registrado en ese campeonato.

---

### User Story 3 - Validación de Cupos Reglamentarios y Habilitación Oficial del Equipo por el Organizador (Priority: P3)

Como `Organizador` (`RoleCapability.approveRegistrations` / `RoleCapability.manageTournaments`), quiero revisar el cumplimiento del cupo mínimo y máximo de jugadores definido en las reglas personalizadas del campeonato (`minPlayersPerTeam`..`maxPlayersPerTeam`) y aprobar o marcar al equipo como `"Habilitado"` únicamente cuando su plantilla cumpla el mínimo exigido, mientras que cualquier usuario (`Aficionado`, `Jugador`, `Árbitro`, `Entrenador`, `Organizador`) puede consultar el directorio de equipos inscritos, su estado de elegibilidad y su nómina oficial.

**Why this priority**: Conecta directamente las reglas personalizadas de la HU 4.1 (`minPlayersPerTeam` y `maxPlayersPerTeam`) con la elegibilidad oficial de los equipos para competir.

**Independent Test**: Se puede probar creando un equipo en un campeonato que exige mínimo `7` jugadores, intentando cambiar su estado a `"Habilitado"` con solo `5` jugadores (verificando que el dominio lo impide e indica cuántos jugadores faltan), completando los `7` jugadores y verificando que el `Organizador` puede marcarlo como `"Habilitado"`.

**Acceptance Scenarios**:

1. **Given** que un campeonato exige un mínimo de `7` jugadores y un máximo de `18` jugadores por equipo según su configuración normativa, **When** un equipo tiene menos de `7` jugadores inscritos y el `Organizador` intenta marcarlo como `"Habilitado"`, **Then** el sistema impide la habilitación y muestra un mensaje indicando que el equipo aún no alcanza el mínimo reglamentario de jugadores requerido por el campeonato.
2. **Given** que un equipo alcanza o supera el mínimo de jugadores exigido por el campeonato sin exceder el máximo permitido, **When** el `Organizador` ejecuta la acción `"Habilitar Equipo"`, **Then** el equipo cambia su estado de elegibilidad a `"Habilitado"` y todos sus jugadores quedan habilitados para convocatorias oficiales.
3. **Given** que un usuario tiene rol `Aficionado`, `Jugador` o `Árbitro`, **When** consulta los equipos de un campeonato, **Then** puede visualizar los equipos inscritos, su insignia de estado (`"En Inscripción"` o `"Habilitado"`) y la nómina de jugadores con sus dorsales y posiciones, sin visualizar controles de creación de equipo, adición de jugadores ni aprobación de elegibilidad.

### Edge Cases

- **Límite máximo de plantilla (`maxPlayersPerTeam`)**: Si un equipo ya alcanzó el cupo máximo de jugadores definido en las reglas del campeonato (`maxPlayersPerTeam`), el sistema impide agregar jugadores adicionales hasta que se libere un cupo.
- **Mismo jugador en campeonatos distintos**: Un jugador con el mismo documento de identidad SÍ puede estar inscrito en otro campeonato independiente; la restricción de exclusividad aplica por campeonato.
- **Normalización de documento de identidad y nombre de equipo**: Los documentos de identidad y nombres de equipo se normalizan (eliminando espacios extremos y comparando sin distinción de mayúsculas/minúsculas) para evitar evasión de unicidad mediante espacios o capitalización.
- **Remoción o edición de jugador mientras el equipo está `"Habilitado"`**: Si al remover un jugador de la plantilla el total cae por debajo de `minPlayersPerTeam`, el estado del equipo vuelve automáticamente a `"Pendiente de Cupo / En Inscripción"` para preservar la integridad de elegibilidad.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir a los roles autorizados (`Organizador` con `RoleCapability.manageTournaments` / `RoleCapability.approveRegistrations` y `Entrenador` con `RoleCapability.manageTeamRoster`) registrar equipos en un campeonato con estado `"Inscripciones Abiertas"`, especificando nombre del equipo, escudo vectorial nativo (sigla/monograma de `2..4` caracteres + estilo de emblema `TeamCrestShape`) y colores representativos (primario y secundario).
- **FR-002**: El sistema DEBE permitir a `Organizador` y `Entrenador` inscribir, editar y remover jugadores dentro de la plantilla de un equipo únicamente mientras el campeonato esté en estado `"Inscripciones Abiertas"`, especificando nombre completo, documento de identidad, posición táctica (`Portero`, `Defensa`, `Mediocampista`, `Delantero`) y número de camiseta (`dorsal` entero entre `1` y `99`); cuando el campeonato pase a `"En Curso"` o `"Finalizado"`, las altas y bajas de equipos y jugadores quedan bloqueadas.
- **FR-003**: El sistema DEBE garantizar la unicidad del nombre del equipo dentro de un mismo campeonato, rechazando nombres duplicados (comparación normalizada sin distinción de mayúsculas/minúsculas).
- **FR-004**: El sistema DEBE garantizar la unicidad del número de camiseta (`dorsal`) dentro de un mismo equipo, rechazando dorsales repetidos con el mensaje exacto en español: `"El número de camiseta {number} ya está en uso en este equipo."`.
- **FR-005**: El sistema DEBE garantizar la exclusividad de cada jugador por campeonato mediante su documento de identidad normalizado, impidiendo que un mismo documento se inscriba en dos equipos distintos del mismo campeonato y mostrando el mensaje exacto en español: `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`.
- **FR-006**: El sistema DEBE validar la plantilla de cada equipo frente a las reglas personalizadas del campeonato (`TournamentRulesConfig.minPlayersPerTeam` y `maxPlayersPerTeam`):
  - Impedir que se agreguen más jugadores cuando la plantilla alcance `maxPlayersPerTeam`.
  - Permitir exclusivamente al `Organizador` (`RoleCapability.approveRegistrations`) marcar un equipo como `"Habilitado"` solo cuando la cantidad de jugadores inscritos esté dentro del rango `[minPlayersPerTeam, maxPlayersPerTeam]`.
  - Revertir automáticamente el estado del equipo a `"Pendiente de Cupo"` si su plantilla queda por debajo de `minPlayersPerTeam`.
- **FR-007**: Los formularios móviles de inscripción de jugadores DEBEN configurar teclado numérico automático (`TextInputType.number`) para los campos de documento de identidad y dorsal, validación en línea y protección contra envíos duplicados (`single-flight`).
- **FR-008**: El sistema DEBE mostrar la sección de equipos inscritos directamente en `StandingsTabView` para el campeonato seleccionado (con botón `"Inscribir Equipo"` para `Organizador` y `Entrenador`) y abrir una pantalla dedicada de detalle de plantilla (`/tournaments/teams/detail`) para gestionar la nómina de jugadores y la habilitación del equipo, precargando equipos y plantillas semilla en entorno `dev` para pruebas inmediatas.
- **FR-009**: Todos los textos visibles para el usuario, etiquetas de posiciones, estados de elegibilidad y mensajes de error reglamentarios DEBEN estar 100% en español en `lib/l10n/app_es.arb`, manteniendo todos los identificadores técnicos del código en inglés conforme a la Constitución del proyecto.

### Key Entities *(include if feature involves data)*

- **`TournamentTeam`**: Entidad de dominio que representa un equipo inscrito en un campeonato (`id`, `tournamentId`, `name`, `shortCode` de `2..4` caracteres, `crestShape`, `primaryColorHex`, `secondaryColorHex`, `eligibilityStatus`, `players`, `updatedAt`).
- **`TeamEligibilityStatus`**: Enumeración del estado oficial del equipo en el campeonato (`pendingQuota` / `"Pendiente de Cupo"`, `readyForReview` / `"Listo para Habilitar"`, `eligible` / `"Habilitado"`).
- **`RegisteredPlayer`**: Entidad de dominio que representa a un jugador inscrito en la nómina de un equipo (`id`, `fullName`, `documentId`, `shirtNumber`, `position`, `isEligible`).
- **`PlayerPosition`**: Enumeración de posiciones en el campo (`goalkeeper` / `"Portero"`, `defender` / `"Defensa"`, `midfielder` / `"Mediocampista"`, `forward` / `"Delantero"`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un `Organizador` o `Entrenador` puede registrar un equipo nuevo e inscribir un jugador en su plantilla en menos de 60 segundos desde el detalle del campeonato.
- **SC-002**: El 100% de los intentos de registrar un jugador con documento duplicado en otro equipo del mismo campeonato o con un dorsal repetido en el mismo equipo son rechazados determinísticamente mostrando los mensajes oficiales en español especificados en Gherkin.
- **SC-003**: El 100% de los intentos de habilitar un equipo cuya plantilla no alcance el `minPlayersPerTeam` del campeonato son bloqueados por la capa de dominio y la interfaz de usuario.
- **SC-004**: El 100% de los usuarios con roles de consulta (`Aficionado`, `Jugador`, `Árbitro`) pueden inspeccionar los equipos y nóminas del campeonato sin visualizar botones de registro o modificación, y solo el `Organizador` visualiza la acción de habilitar oficialmente al equipo.
- **SC-005**: La suite de pruebas automatizadas supera `flutter analyze` con 0 problemas, `dart format` sin diferencias y alcanza cobertura `>= 80%` en la lógica de dominio y casos de uso de equipos y elegibilidad.

## Assumptions

- Los documentos de identidad de los jugadores se ingresan mediante teclado numérico (dígitos numéricos, mínimo `5` dígitos) conforme al lineamiento móvil de la tarjeta Notion (*"Teclado numérico automático para documento y dorsal"*).
- Mientras un campeonato está en `"Inscripciones Abiertas"`, tanto el `Organizador` como el `Entrenador` pueden registrar equipos y gestionar sus plantillas; la acción de aprobación oficial (`"Habilitar Equipo"`) es exclusiva del `Organizador` (`RoleCapability.approveRegistrations`).
- La sección de Equipos y Plantillas se presenta integrada en la vista del campeonato seleccionado en `StandingsTabView`, permitiendo abrir el detalle de plantilla y el formulario de inscripción sin alterar las 4 pestañas principales del `AppShellScreen`.
