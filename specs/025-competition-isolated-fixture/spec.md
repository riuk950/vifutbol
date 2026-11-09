# Feature Specification: Generación de Fixture Independiente por Competición (FAB Menu en Competición, Selector en Panel y Retiro de Vista Partidos)

**Feature Branch**: `025-competition-isolated-fixture`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "de Notion HU 15.2 en curso: [Épica 15] HU 15.2: Generación de Fixture Independiente por Competición (FAB Menu en Competición, Selector en Panel y Retiro de Vista Partidos)"

## Clarifications

### Session 2026-11-09

- Q: ¿Se debe retirar por completo `OrganizerPendingMatchesBanner` de `MatchdayTabView` para dejar la pestaña Partidos 100% dedicada a la consulta por fecha, o conservar el aviso de partidos pendientes de programar? → A: Retirar por completo `OrganizerPendingMatchesBanner` de `MatchdayTabView`, dejando la pestaña principal "Partidos" 100% limpia y dedicada exclusivamente a la consulta por fecha (Ayer, Hoy, Mañana y Calendario).
- Q: ¿Cómo debe comportarse visualmente el FAB Menu en `CompetitionDetailScreen`? → A: FAB expandible tipo *Speed Dial* visible en `CompetitionDetailScreen` que al pulsarse despliega la píldora/acción flotante "Generar Fixture" sobre el lienzo.
- Q: ¿Qué competiciones debe listar el selector de competición en `/panel` al pulsar "Generar Fixture"? → A: Todas las competiciones activas/editables (`openRegistration` e `inProgress`), mostrando su estado y cantidad de equipos elegibles (permitiendo generar o regenerar si no hay partidos iniciados/finalizados).
- Q: Cuando el Organizador genera el fixture desde el FAB Menu en `CompetitionDetailScreen` estando ubicado en la pestaña *Clasificación* o *Información*, ¿cómo debe comportarse la navegación de pestañas tras completarse la generación? → A: Colapsar el FAB *Speed Dial* y mostrar el `SnackBar`, permaneciendo en la pestaña actual sin cambiar automáticamente a *Partidos*.
- Q: Cuando el Organizador selecciona una competición y confirma la generación de su fixture desde el Panel Administrativo (`/panel`), ¿qué debe ocurrir en pantalla inmediatamente después de completarse la generación? → A: Navegar automáticamente a la pantalla de detalle de la competición seleccionada (`/competitions/:id`) tras mostrar el `SnackBar`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retiro de Controles de Generación de Fixture de la Vista Principal de Partidos (Priority: P1) 🎯 MVP

Como Organizador de ViFutbol,  
quiero que la pestaña principal de "Partidos" (`MatchdayTabView`) no muestre banners ni botones de generación de fixture,  
para mantener el feed diario de partidos dedicado exclusivamente a la consulta cronológica por fecha (Ayer, Hoy, Mañana y Calendario) sin contaminarlo con acciones administrativas globales.

**Why this priority**: Es el primer paso indispensable para desacoplar la administración de sorteos del feed público diario de partidos y evitar la generación accidental de fixtures sobre torneos arbitrarios desde la vista de consulta diaria.

**Independent Test**:
1. Iniciar sesión con un usuario de rol `Organizador` habiendo torneos activos sin fixture generado.
2. Navegar a la pestaña principal "Partidos" (`MatchdayTabView`).
3. Verificar que no se renderiza ningún botón (`organizer_generate_fixture_button`) ni banner de generación de fixture en la vista diaria de partidos.

**Acceptance Scenarios**:

1. **Given** que el usuario con rol `Organizador` ingresa a la pestaña principal "Partidos" (`MatchdayTabView`), **When** visualiza el feed diario de partidos (incluso existiendo torneos activos sin fixture generado), **Then** no se muestra ningún botón ni banner para generar fixture en esta vista.
2. **Given** un usuario con cualquier otro rol (`Aficionado`, `Jugador`, `Entrenador`, `Árbitro`) en la pestaña "Partidos", **When** consulta las pestañas Ayer, Hoy, Mañana o el selector de calendario, **Then** visualiza únicamente las agrupaciones de partidos programados por fecha.

---

### User Story 2 - Generación de Fixture Aislada desde el FAB Menu en el Detalle de Competición (Priority: P1)

Como Organizador de ViFutbol,  
quiero contar con un botón flotante de acciones (FAB Menu) dentro de la pantalla de detalle de una competición (`/competitions/:id`) que me permita ejecutar "Generar Fixture" exclusivamente para ese torneo,  
para crear las jornadas y enfrentamientos de esa competición de forma controlada y verlos reflejados de inmediato en su pestaña de partidos.

**Why this priority**: Proporciona el punto de entrada contextual directo dentro de cada campeonato para que el organizador gestione el sorteo únicamente con los equipos inscritos y elegibles de esa competición específica.

**Independent Test**:
1. Iniciar sesión como `Organizador` y abrir el detalle de una competición editable (`openRegistration` o `inProgress`) en `/competitions/:id` que tenga al menos 2 equipos elegibles.
2. Verificar que el FAB Menu (`competition_detail_fab_menu`) es visible, pulsarlo y seleccionar la opción "Generar Fixture" (`competition_detail_fab_generate_fixture`).
3. Confirmar en el diálogo de confirmación y verificar que se generan únicamente los partidos de esa competición, mostrándose en la pestaña de jornadas y notificando mediante un `SnackBar` con el conteo de partidos creados.
4. Cambiar a un rol no autorizado (`Aficionado`, `Jugador`, `Entrenador` o `Árbitro`) y verificar que el FAB Menu no se renderiza.

**Acceptance Scenarios**:

1. **Given** que el `Organizador` selecciona una competición editable (`openRegistration` o `inProgress`) y entra a su página de detalle (`/competitions/:id`), **When** pulsa el botón flotante de acciones (FAB Menu) y selecciona "Generar Fixture", **Then** se solicita confirmación para generar las jornadas únicamente de esa competición y, al confirmar, se crean todos los partidos del campeonato filtrando estrictamente los equipos elegibles de ese `tournamentId` y se muestran en la pestaña de jornadas.
2. **Given** que un usuario con rol `Aficionado`, `Jugador`, `Entrenador` o `Árbitro` entra al detalle de una competición (`/competitions/:id`), **When** visualiza la pantalla de la competición, **Then** el FAB Menu administrativo no se muestra en pantalla.
3. **Given** que un `Organizador` entra al detalle de una competición en estado `finished` (Finalizado), **When** visualiza la pantalla de la competición, **Then** el FAB Menu administrativo no se muestra en pantalla.

---

### User Story 3 - Selección Previa de Competición al Generar Fixture desde el Panel Administrativo (Priority: P2)

Como Organizador de ViFutbol,  
quiero que al pulsar "Generar Fixture" dentro del Panel Administrativo (`/panel`) se despliegue primero un selector con las competiciones activas disponibles antes de confirmar y generar el calendario,  
para elegir explícitamente a qué campeonato deseo generarle el fixture sin afectar otros torneos.

**Why this priority**: Completa la experiencia administrativa desde el centro de mando (`/panel`), sustituyendo la selección automática implícita del primer torneo sin fixture por una decisión explícita del organizador.

**Independent Test**:
1. Iniciar sesión como `Organizador` y navegar al Panel Administrativo (`/panel`).
2. Pulsar el botón de acción rápida "Generar Fixture" (`organizer_action_generate_fixture`).
3. Verificar que se despliega un selector modal con las competiciones activas disponibles.
4. Seleccionar una competición específica, confirmar la generación y comprobar que los partidos se crean exclusivamente para el campeonato elegido.

**Acceptance Scenarios**:

1. **Given** que el `Organizador` se encuentra en el Panel Administrativo (`/panel`), **When** pulsa el botón "Generar Fixture", **Then** se despliega primero un selector con las competiciones activas disponibles.
2. **Given** el selector de competiciones abierto en `/panel`, **When** el organizador elige una competición específica y confirma la operación, **Then** el sistema genera el fixture exclusivamente para la competición seleccionada usando únicamente sus equipos elegibles, muestra un `SnackBar` con el conteo de partidos generados y navega automáticamente al detalle de esa competición (`/competitions/:id`).

---

### Edge Cases

- **Aislamiento estricto de equipos por competición (`tournamentId`)**: Cuando existen múltiples torneos con equipos registrados en el catálogo general, la generación del fixture para un torneo $T_1$ debe filtrar exclusivamente aquellos `TournamentTeam` cuyo `tournamentId == T_1.id` y `isEligible == true`, evitando mezclar equipos de otros campeonatos.
- **Competición con menos de 2 equipos elegibles**: Si el organizador intenta generar el fixture de una competición que tiene menos de 2 equipos habilitados (`isEligible`), el sistema debe rechazar la operación y mostrar un mensaje claro indicando que se requieren al menos 2 equipos elegibles en ese torneo.
- **Competición con partidos ya en juego o finalizados**: Si la competición seleccionada ya cuenta con partidos en estado `inProgress` o `completed`, el sistema debe bloquear la regeneración del fixture e informar al organizador mediante retroalimentación visual.
- **Sin competiciones disponibles en el Panel**: Si el organizador pulsa "Generar Fixture" en `/panel` cuando no existen competiciones elegibles/activas para generar fixture, el sistema debe informar claramente mediante un estado vacío o aviso sin producir errores no controlados.
- **Vista compacta ($320 \times 640\text{ px}$ @ $130\%$ text scale)**: El FAB Menu en `CompetitionDetailScreen` y el selector modal de competiciones en `/panel` deben renderizarse sin desbordamientos `RenderFlex` y respetando áreas táctiles mínimas de $48 \times 48\text{ dp}$.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE retirar por completo `OrganizerPendingMatchesBanner` y cualquier acción o control de generación de fixture de `MatchdayTabView`, dejando la pestaña principal "Partidos" dedicada exclusivamente a la consulta de partidos por fecha (Ayer, Hoy, Mañana y Calendario) para todos los roles.
- **FR-002**: El caso de uso `FixtureSchedulingUseCase.generateRoundRobinFixture` (y `MatchesCatalogController.generateFixture`) DEBE filtrar explícitamente la lista de equipos recibida para incluir únicamente aquellos `TournamentTeam` con `team.tournamentId == tournament.id` además de `team.isEligible == true`.
- **FR-003**: En `CompetitionDetailScreen` (`/competitions/:id`), el sistema DEBE mostrar un botón flotante de acciones (FAB Menu, `Key('competition_detail_fab_menu')`) única y exclusivamente cuando el usuario activo tenga la capacidad `RoleCapability.manageTournaments` (`UserRole.organizer`) y el torneo se encuentre en estado editable (`TournamentStatus.openRegistration` o `TournamentStatus.inProgress`).
- **FR-004**: El FAB Menu en `CompetitionDetailScreen` DEBE funcionar como un menú flotante expandible (*Speed Dial*) que, al pulsarse, despliega la acción/píldora flotante "Generar Fixture" (`Key('competition_detail_fab_generate_fixture')`).
- **FR-005**: Al seleccionar "Generar Fixture" desde el FAB Menu en `CompetitionDetailScreen`, el sistema DEBE colapsar el FAB *Speed Dial*, solicitar confirmación (`GenerateFixtureConfirmationDialog`) indicando la competición objetivo y, tras confirmar, generar las jornadas exclusivamente para esa competición, actualizar reactivamente el estado de partidos y mostrar el `SnackBar` permaneciendo en la pestaña activa actual.
- **FR-006**: En `OrganizerPanelContent` (`/panel`), al pulsar la acción rápida "Generar Fixture" (`Key('organizer_action_generate_fixture')`), el sistema DEBE abrir primero una hoja modal o diálogo de selección de competición (`Key('select_tournament_for_fixture_sheet')`) que liste todas las competiciones editables (`TournamentStatus.openRegistration` y `TournamentStatus.inProgress`) indicando su estado y cantidad de equipos elegibles; tras elegir y confirmar la generación aislada para el torneo seleccionado, el sistema DEBE mostrar el `SnackBar` de confirmación y navegar automáticamente a la pantalla de detalle de dicha competición (`/competitions/:id`).
- **FR-007**: Tras generar exitosamente el fixture de una competición (ya sea desde `CompetitionDetailScreen` o desde `/panel`), el sistema DEBE mostrar un `SnackBar` de confirmación con el conteo de partidos generados para dicha competición.
- **FR-008**: Si la generación del fixture falla por validaciones de dominio (p. ej., menos de 2 equipos elegibles en ese torneo o partidos ya iniciados/finalizados), el sistema DEBE mostrar un `SnackBar` o alerta con el mensaje localizado del error correspondiente sin alterar los partidos existentes.
- **FR-009**: Todos los textos visibles al usuario (etiquetas del FAB Menu, título y subtítulo del selector de competición, mensajes de confirmación y errores) DEBEN estar en español y centralizados en `lib/l10n/app_es.arb`.
- **FR-010**: Todos los identificadores de código, nombres de clases, métodos, claves de prueba y descripciones de tests DEBEN estar escritos en inglés conforme a la Constitución de ViFutbol.

### Key Entities *(include if feature involves data)*

- **ChampionshipTournament**: Representa la competición objetivo sobre la cual se genera el fixture (`id`, `name`, `category`, `format`, `status`, `rules`).
- **TournamentTeam**: Representa un equipo inscrito en un torneo específico (`id`, `tournamentId`, `name`, `eligibilityStatus`), cuyo `tournamentId` vincula de forma exclusiva al equipo con su competición.
- **ChampionshipMatch**: Representa cada partido generado dentro de una jornada (`id`, `tournamentId`, `roundNumber`, `roundName`, `homeTeamId`, `awayTeamId`, `status`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las generaciones de fixture ejecutadas desde `CompetitionDetailScreen` o `/panel` crean partidos únicamente con equipos cuyo `tournamentId` coincide con la competición seleccionada, con cero filtraciones de equipos de otros campeonatos.
- **SC-002**: La pestaña principal "Partidos" (`MatchdayTabView`) presenta 0 controles de generación de fixture para todos los roles de usuario.
- **SC-003**: Un organizador puede generar el fixture de una competición desde su pantalla de detalle (`/competitions/:id`) o desde el Panel (`/panel`) en menos de 15 segundos y máximo 3 toques.
- **SC-004**: El 100% de los escenarios de prueba (unitarios y de widgets) pasan sin errores de análisis estático y con cero desbordamientos `RenderFlex` en pantallas compactas de $320 \times 640\text{ px}$ al $130\%$ de escala de texto.

---

## Assumptions

- Se reutiliza el algoritmo determinista `RoundRobinGenerator` existente en el dominio para formatos de liga (`league`) y eliminación directa (`knockoutCup`).
- Se reutiliza el diálogo de confirmación `GenerateFixtureConfirmationDialog` (adaptándolo opcionalmente para mostrar el nombre de la competición seleccionada).
- Los partidos recién generados nacen en estado `MatchStatus.pendingSchedule` (`scheduledStartTime == null`), listos para ser programados individualmente en sus jornadas.
