# Feature Specification: Aprobación de Equipos y Habilitación para Fixture con Mínimo 11 Jugadores en Detalle de Competición

**Feature Branch**: `030-team-approval-fixture-eligibility`  
**Created**: 2026-11-10  
**Status**: Draft  
**Input**: User description: "Notion HU 16.3 en curso: [Épica 16] HU 16.3: Aprobación de Equipos y Habilitación para Fixture con Mínimo 11 Jugadores en Detalle de Competición (4148442e-3f49-8153-8aa2-f12ec48e4d79)"

---

## Clarifications

### Session 2026-11-10
- Q: ¿Bajo qué condiciones puede el organizador inhabilitar (revertir la aprobación de) un equipo previamente habilitado? → A: Opción B: Permitida mientras no se haya disputado ningún partido oficial del torneo. Si ya existe un fixture generado con partidos en estado programado (`scheduled`), la inhabilitación revierte el estado del equipo a pendiente de verificación e invalida los partidos programados asociados al equipo, requiriendo la regeneración del fixture para conservar la coherencia del calendario.
- Q: ¿Cómo debe presentarse en la interfaz la advertencia reglamentaria cuando el organizador presiona "Habilitar Equipo" en un equipo con nómina insuficiente (< 11 jugadores)? → A: Opción A: Mostrar un diálogo modal de advertencia con el mensaje reglamentario canónico exacto ("El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})") y botón de confirmación ("Entendido") para asegurar que el organizador lea y reconozca la restricción sin alterar el estado del equipo.
- Q: ¿Cómo debe modelarse el ciclo de vida del estado de elegibilidad (`TeamEligibilityStatus`) en el dominio con respecto a "Pendiente de verificación" (`pendingVerification`)? → A: Opción A: Unificar a 2 estados canónicos: `pendingVerification` ("Pendiente de verificación") y `eligible` ("Habilitado"), deserializando de forma retrocompatible estados previos en JSON (`pendingQuota` y `readyForApproval` resuelven a `pendingVerification`).
- Q: ¿Qué debe suceder si un entrenador retira o elimina a un jugador de un equipo que ya se encuentra "Habilitado", dejando la plantilla con menos de 11 futbolistas? → A: Opción A: Reversión automática a `pendingVerification` tan pronto la nómina activa caiga por debajo de 11 jugadores, requiriendo una nueva aprobación formal del organizador una vez completada la plantilla.
- Q: ¿Cómo debe ubicarse visualmente la acción de "Habilitar Equipo" / "Inhabilitar" dentro de la tarjeta de equipo en la pestaña de competición? → A: Opción A: Fila inferior de acciones dentro de la tarjeta con botón adaptativo (icono + etiqueta "Habilitar Equipo" / "Inhabilitar") utilizando `Wrap` o distribución vertical segura, visible únicamente para el organizador y libre de RenderFlex overflows a 320 px con 130% de escala tipográfica.

---

## User Scenarios & Testing

### User Story 1 - Verificación de Cuota Reglamentaria y Aprobación de Equipos (Priority: P1)

Como **Organizador de la competición** (`UserRole.organizer`), quiero evaluar a cada equipo inscrito en mi torneo desde la pestaña de equipos y aprobar su habilitación oficial únicamente si cuenta con una nómina mínima reglamentaria de 11 futbolistas registrados, para asegurar la seriedad y competitividad del campeonato antes de iniciar partidos.

**Why this priority**: Es el núcleo de la gobernanza de elegibilidad de la Épica 16 y el requisito previo indispensable para que los equipos puedan ser considerados válidos para sorteo y fixture. Sin este control, se podrían programar partidos con plantillas vacías o incompletas.

**Independent Test**: Puede probarse de forma independiente registrando un equipo con 9 jugadores e intentando habilitarlo (el sistema debe rechazarlo con la advertencia reglamentaria exacta), y registrando un equipo con 11 jugadores e intentando habilitarlo (el sistema debe transicionar su estado a habilitado y reflejar el distintivo correspondiente).

**Acceptance Scenarios**:

1. **Given** un organizador visualizando la pestaña "Equipos" en `CompetitionDetailScreen`, **When** presiona el botón "Habilitar Equipo" sobre un equipo con menos de 11 jugadores (por ejemplo, 9 jugadores), **Then** el sistema bloquea el cambio de estado, conserva el equipo en estado "Pendiente de verificación" (`pendingVerification`), y despliega un diálogo modal de advertencia reglamentaria con el texto exacto: `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: 9)"` y acción "Entendido".
2. **Given** un organizador visualizando la pestaña "Equipos", **When** presiona el botón "Habilitar Equipo" sobre un equipo con 11 o más jugadores registrados en su nómina, **Then** el estado del equipo transiciona exitosamente a "Habilitado" (`eligible`) y la tarjeta actualiza su indicador visual y textual a `"Habilitado para competir"` con variante positiva/verde.
3. **Given** un usuario autenticado con cualquier rol distinto a organizador (`coach`, `referee`, `player`, `fan`), **When** accede a la pestaña "Equipos" del torneo, **Then** los botones de acción de habilitar/inhabilitar no son visibles ni interactivos.

---

### User Story 2 - Indicadores Visuales de Nómina y Estado en Tarjetas de Equipos (Priority: P2)

Como **Usuario de la aplicación** (cualquier rol), quiero observar en la tarjeta de cada equipo dentro de la competición un indicador claro y textual del conteo de futbolistas registrados frente a la cuota mínima (ej. `"9/11 jugadores - Incompleto"` vs `"14 jugadores - Nómina válida"`), para conocer de manera inmediata la situación de cada plantel sin tener que abrir individualmente su detalle.

**Why this priority**: Brinda transparencia y retroalimentación inmediata tanto al organizador para tomar decisiones de habilitación, como a los entrenadores y aficionados para saber si un equipo está reglamentariamente completo.

**Independent Test**: Puede probarse renderizando la lista de equipos en la pestaña de competición con equipos de 0, 9, 11 y 15 jugadores y verificando que cada tarjeta muestre la etiqueta textual accesible y el formato de conteo reglamentario sin truncamientos en pantallas compactas ($320\text{ px}$).

**Acceptance Scenarios**:

1. **Given** un equipo con 9 jugadores inscritos, **When** se presenta en la lista de equipos del torneo, **Then** su tarjeta muestra el texto descriptivo `"9/11 jugadores - Incompleto"` con tipografía secundaria y distintivo de estado pendiente.
2. **Given** un equipo con 12 jugadores inscritos, **When** se presenta en la lista de equipos del torneo, **Then** su tarjeta muestra el texto descriptivo `"12 jugadores - Nómina válida"`.
3. **Given** una interfaz con escalado de texto al 130% en un dispositivo de $320\text{ px}$ de ancho, **When** se renderizan las tarjetas de equipo con sus badges y conteos, **Then** la información fluye verticalmente sin presentar RenderFlex overflows ni cortes de texto.

---

### User Story 3 - Inhabilitación de Equipos y Generación de Fixture Condicionada (Priority: P3)

Como **Organizador de la competición**, quiero poder revertir la habilitación ("Inhabilitar") de un equipo previamente aprobado si surge alguna irregularidad antes del sorteo, y asegurar que la acción "Generar Fixture" del FAB Menu tome única y exclusivamente a los equipos en estado "Habilitado", bloqueando la generación si hay menos de 2 equipos habilitados.

**Why this priority**: Cierra el ciclo de vida de la elegibilidad garantizando integridad deportiva estricta en el motor de fixture, impidiendo sorteos inválidos con plantillas irregulares.

**Independent Test**: Puede probarse habilitando 1 solo equipo e intentando generar fixture desde el FAB (debe mostrar error indicando que se requieren al menos dos equipos habilitados con nómina completa), y posteriormente inhabilitando un equipo habilitado (debe regresar a pendiente y ser excluido del conteo de fixture).

**Acceptance Scenarios**:

1. **Given** un equipo que se encuentra en estado "Habilitado" (`eligible`), **When** el organizador presiona el botón "Inhabilitar", **Then** el estado del equipo transiciona a "Pendiente de verificación" (`pendingVerification`) y su distintivo visual refleja el cambio.
2. **Given** un torneo con 4 equipos inscritos de los cuales solo 1 está "Habilitado" y los otros 3 están "Pendiente de verificación", **When** el organizador pulsa el FAB "Generar Fixture" y confirma el diálogo, **Then** la acción se bloquea mostrando el mensaje de error: `"Se requieren al menos dos equipos habilitados con nómina completa"` y ningún partido es creado.
3. **Given** un torneo con al menos 2 equipos en estado "Habilitado", **When** el organizador pulsa "Generar Fixture", **Then** el motor compila los emparejamientos tomando exclusivamente los equipos habilitados e ignorando los pendientes de verificación.

---

### Edge Cases

- **Intento de habilitar o inhabilitar en torneo finalizado**: Si el campeonato se encuentra en estado `finished`, las acciones de habilitación/inhabilitación quedan deshabilitadas y cualquier intento a nivel de dominio arroja fallo por campeonato en modo solo lectura.
- **Fixture ya generado previamente**: Si el torneo ya cuenta con partidos generados en calendario en estado programado (`scheduled`), la inhabilitación del equipo participante está permitida pero invalida los partidos programados del equipo y habilita nuevamente la acción de "Generar Fixture" para reconstruir el calendario sin el equipo inhabilitado. Si ya se inició o disputó al menos un partido (`inProgress` o `completed`), la inhabilitación directa queda completamente bloqueada.
- **Pérdida de conectividad durante la habilitación**: Si la operación asíncrona de actualización de estado falla o no responde, la UI retiene el estado previo y despliega un SnackBar de error recuperable con estilo KickPulse.
- **Doble pulsación rápida en "Habilitar"**: El botón debe deshabilitarse o mostrar indicador de procesamiento durante la llamada asíncrona para evitar ejecuciones concurrentes redundantes.

---

## Requirements

### Functional Requirements

- **FR-001**: El modelo `TournamentTeam` y su enumeración de estado de elegibilidad (`TeamEligibilityStatus`) DEBEN unificarse en 2 estados canónicos: `pendingVerification` ("Pendiente de verificación") y `eligible` ("Habilitado"), deserializando de forma retrocompatible estados previos en JSON (`pendingQuota` y `readyForApproval` resuelven a `pendingVerification`).
- **FR-002**: La capa de dominio (`ManageTeamsEligibilityUseCase.approveTeamEligibility`) DEBE validar estrictamente que la cantidad de jugadores en la nómina del equipo sea mayor o igual a 11 (`team.players.length >= 11`).
- **FR-003**: Si un equipo tiene menos de 11 jugadores (`team.players.length < 11`), el caso de uso de habilitación DEBE rechazar la operación lanzando una excepción de validación con el mensaje canónico exacto: `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})"`.
- **FR-004**: El caso de uso DEBE proveer un método para revertir la habilitación (`revokeTeamEligibility` o equivalente) que devuelva el equipo a `TeamEligibilityStatus.pendingVerification`, restringido al rol `UserRole.organizer`.
- **FR-005**: Solo los usuarios con capacidad `RoleCapability.approveRegistrations` (exclusivo del rol `UserRole.organizer`) DEBEN tener autorización para ejecutar la habilitación e inhabilitación de equipos en una competición.
- **FR-006**: La pestaña "Equipos" (`CompetitionTeamsTabView` en `CompetitionDetailScreen`) DEBE renderizar en cada tarjeta de equipo un indicador de conteo de nómina:
  - Si `team.players.length < 11`: texto `"X/11 jugadores - Incompleto"`.
  - Si `team.players.length >= 11`: texto `"X jugadores - Nómina válida"`.
- **FR-007**: La tarjeta de equipo en la competición DEBE presentar una fila inferior de acciones adaptativa (usando `Wrap` o disposición responsiva) para el organizador:
  - Botón "Habilitar Equipo" con icono cuando el equipo no está habilitado (`pendingVerification`).
  - Botón "Inhabilitar" con icono cuando el equipo ya está habilitado (`eligible`).
- **FR-008**: Si el usuario activo NO es organizador (`UserRole.organizer`), los botones de habilitación e inhabilitación DEBEN ocultarse completamente de la interfaz.
- **FR-009**: Al presionar "Habilitar Equipo" sobre un equipo incompleto (`team.players.length < 11`), la interfaz DEBE desplegar un diálogo modal de advertencia reglamentaria informando el incumplimiento de la cuota mínima con el texto exacto `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})"` y botón "Entendido", sin alterar el estado del equipo.
- **FR-010**: El motor de generación de fixture (`FixtureSchedulingUseCase.generateRoundRobinFixture`) DEBE filtrar única y exclusivamente los equipos con `team.tournamentId == tournament.id` y `team.isEligible == true`.
- **FR-011**: Si la cantidad de equipos habilitados en el torneo es menor a 2 (`eligibleTeams.length < 2`), la generación de fixture DEBE detenerse arrojando un fallo que informe que se requieren al menos dos equipos habilitados con nómina completa.
- **FR-012**: Todos los textos, etiquetas y mensajes de retroalimentación DEBEN gestionarse en `lib/l10n/app_es.arb` y presentarse en español de acuerdo con el principio VI de la Constitución.
- **FR-013**: Si un equipo previamente en estado `eligible` sufre la remoción de jugadores y su nómina desciende por debajo de 11 (`team.players.length < 11`), el sistema DEBE revertir automáticamente su estado a `TeamEligibilityStatus.pendingVerification`.

---

### Key Entities

- **TournamentTeam**:
  - `id: String`: Identificador único del equipo.
  - `tournamentId: String`: Identificador de la competición vinculada.
  - `name: String` & `shortCode: String`: Datos de identidad del club.
  - `players: List<TournamentPlayer>`: Lista de futbolistas inscritos en plantilla.
  - `eligibilityStatus: TeamEligibilityStatus`: Estado reglamentario (`pendingVerification`, `readyForApproval`, `eligible`).
  - `isEligible: bool`: Getter que verifica si `eligibilityStatus == TeamEligibilityStatus.eligible`.
- **ChampionshipTournament**:
  - `id: String`: Identificador del torneo.
  - `rules: TournamentRules`: Reglas que estipulan la cuota reglamentaria (`minPlayersPerTeam` con valor mínimo 11).
  - `status: TournamentStatus`: Estado del torneo (`draft`, `openRegistration`, `inProgress`, `finished`).
- **TeamEligibilityStatus**:
  - `pendingVerification`: Nómina aún no verificada, incompleta o revertida para competir.
  - `eligible`: Aprobado oficialmente por el organizador con $\ge 11$ jugadores para competir y entrar al fixture.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: El 100% de los intentos de habilitar equipos con menos de 11 jugadores son bloqueados deterministamente tanto en la interfaz como en el núcleo de dominio.
- **SC-002**: El organizador puede habilitar o inhabilitar un equipo apto en menos de 2 toques desde la pestaña de equipos de la competición.
- **SC-003**: El 100% de los fixtures generados contienen exclusivamente equipos con estatus `eligible` e impiden emparejamientos cuando existen menos de 2 equipos habilitados.
- **SC-004**: Cero incidencias de RenderFlex overflow o elementos inaccesibles en pantallas móviles de $320 \times 640\text{ px}$ con escala tipográfica al 130%.

---

## Assumptions

- Se asume que el mínimo reglamentario estándar para fútbol 11 en torneos competitivos de la plataforma es de 11 jugadores (`minPlayersPerTeam = 11`).
- Se asume que la reversión de estado ("Inhabilitar") solo está permitida mientras el campeonato no haya iniciado partidos (`matches.none(m => m.tournamentId == tournament.id && m.status != MatchStatus.scheduled)`).
- La visualización del conteo de jugadores y el estado de habilitación está disponible públicamente para todos los roles en modo solo lectura, mientras que las acciones de cambio de estado están protegidas por el control de acceso del organizador.
