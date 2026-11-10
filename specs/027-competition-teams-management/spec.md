# Feature Specification: Gestión de Equipos Inscritos en Competición (Opción en FAB Menu, Pestaña de Equipos, Retiro y Traslado de Grupo) (HU 15.4)

**Feature Branch**: `027-competition-teams-management`  
**Created**: 2026-11-10  
**Status**: Approved  
**Input**: User description: "Notion [Épica 15] HU 15.4: Gestión de Equipos Inscritos en Competición (Opción en FAB Menu, Pestaña de Equipos, Retiro y Traslado de Grupo) (Page ID: 4148442e-3f49-813d-acae-c2a598583b13)"

## Clarifications

### Session 2026-11-10

- Q: ¿Cómo debe asignarse y persistirse el grupo de un equipo en competiciones con formato `mixedGroupsAndKnockout`? → A: Se agrega el campo opcional `groupName` (ej. `"Grupo A"`, `"Grupo B"`) en `TournamentTeam` con retrocompatibilidad JSON y asignación determinista por defecto en `StandingsCalculatorService` si un equipo aún no tiene `groupName` explícito.
- Q: ¿Qué ocurre cuando el Organizador retira/quita un equipo de una competición desde la pestaña de Equipos? → A: Se solicita confirmación mediante diálogo de seguridad y, al confirmar, se elimina la inscripción del equipo en ese campeonato (`deleteTeam` en `TeamsRepository` / `TeamsController`), refrescando reactivamente el listado de equipos y las tablas de posiciones de la competición.
- Q: ¿Cómo se inscribe un equipo desde la opción "Agregar Equipo" del FAB Menu en `CompetitionDetailScreen`? → A: Abre un diálogo (`CompetitionEnrollTeamDialog`) pre-vinculado al `tournamentId` actual que permite registrar un nuevo equipo en el campeonato (nombre, código corto de 2-4 letras, forma de escudo, color principal y selector de grupo inicial si el torneo es `mixedGroupsAndKnockout`) o vincular/clonar un club existente de otros torneos que aún no esté inscrito en esta competición.
- Q: ¿Qué debe ocurrir cuando el Organizador intenta quitar un equipo del campeonato si ya existen partidos generados para ese equipo? → A: Permitir quitar el equipo si no tiene partidos iniciados ni finalizados (eliminando sus partidos pendientes si los hubiera), y bloquear el retiro con alerta si ya tiene partidos `inProgress` o `completed`.
- Q: ¿Cómo deben organizarse visualmente los equipos en la pestaña "Equipos" cuando la competición tiene formato de Fase de Grupos (`mixedGroupsAndKnockout`)? → A: Mostrar secciones con encabezados por grupo (*Grupo A*, *Grupo B*, ...) además de la insignia en cada tarjeta para torneos con grupos, y lista alfabética simple para Liga o Copa.
- Q: ¿Qué grupo debe preseleccionarse por defecto al abrir el diálogo "Agregar Equipo" en una competición con Fase de Grupos (`mixedGroupsAndKnockout`)? → A: Preseleccionar automáticamente el grupo con menos equipos inscritos en ese momento (balanceo automático), permitiendo cambiarlo manualmente en el selector.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inscripción de Equipos al Campeonato desde el FAB Menu de la Competición (Priority: P1) 🎯 MVP

Como **Organizador**, quiero desplegar el botón flotante de acciones (`FAB Menu`) dentro del detalle de una competición (`/competitions/:id`) y contar con la opción **"Agregar Equipo"** para inscribir clubes directamente en ese campeonato (asignándoles opcionalmente su grupo cuando el formato incluye fase de grupos).

**Why this priority**: Permite al organizador poblar de equipos el campeonato directamente desde la pantalla de la competición antes de generar el fixture.

**Independent Test**: Se puede probar iniciando sesión como `Organizador`, abriendo `/competitions/:id` de un torneo editable, pulsando el `FAB Menu`, tocando **"Agregar Equipo"**, completando el formulario (o eligiendo un club existente) y comprobando que el equipo queda inscrito en ese `tournamentId` y aparece en la pestaña **"Equipos"**.

**Acceptance Scenarios**:

1. **Given** que el usuario con rol `Organizador` visualiza el detalle de una competición editable (`openRegistration` o `inProgress`), **When** pulsa el botón flotante `competition_detail_fab_menu`, **Then** se despliega la opción **"Agregar Equipo"** (`competition_detail_fab_add_team`) además de **"Generar Fixture"**.
2. **Given** que el `Organizador` toca **"Agregar Equipo"** en el FAB Menu, **When** ingresa un nombre válido (3-60 caracteres), código corto (2-4 caracteres), escudo y (si el torneo es `mixedGroupsAndKnockout`) selecciona el grupo inicial (*Grupo A*, *Grupo B*, etc.) y confirma, **Then** el equipo se guarda asociado al `tournamentId` de la competición y se muestra un `SnackBar` de confirmación en español.
3. **Given** que el `Organizador` intenta inscribir un equipo cuyo nombre normalizado ya existe dentro de la misma competición, **When** envía el formulario, **Then** el sistema muestra un error de validación impidiendo duplicados dentro del mismo campeonato.

---

### User Story 2 - Pestaña de Equipos Inscritos en el Detalle de la Competición (Priority: P1)

Como **usuario de ViFutbol** (cualquier rol), quiero ver una pestaña **"Equipos"** dentro del detalle de la competición (`/competitions/:id`) para consultar todos los clubes inscritos en ese campeonato, su estado de elegibilidad, cantidad de jugadores y su distribución por grupos (cuando aplique).

**Why this priority**: Brinda visibilidad transparente del padrón oficial de equipos participantes en el torneo para organizadores, entrenadores, jugadores, árbitros y aficionados.

**Independent Test**: Se puede probar abriendo `/competitions/:id` con cualquier rol, tocando la pestaña **"Equipos"** (`competition_detail_tab_teams`) y verificando que se listan únicamente los equipos de ese campeonato con su escudo, código, conteo de jugadores, insignia de elegibilidad y grupo asignado, o el estado vacío si no hay inscritos.

**Acceptance Scenarios**:

1. **Given** que cualquier usuario ingresa al detalle de una competición (`/competitions/:id`), **When** toca la pestaña **"Equipos"** en la barra superior (`TabBar`), **Then** visualiza la lista de equipos inscritos exclusivamente en ese campeonato (`CompetitionTeamsTabView`), mostrando su escudo, nombre, código corto, número de jugadores registrados y estado de elegibilidad.
2. **Given** que la competición tiene formato `mixedGroupsAndKnockout` (*Grupos y Eliminatoria*), **When** se visualiza la pestaña **"Equipos"**, **Then** cada equipo muestra su insignia de grupo asignado (*Grupo A*, *Grupo B*, etc.) ordenada por grupo y nombre.
3. **Given** que el usuario toca la tarjeta de un equipo inscrito en la pestaña **"Equipos"**, **When** se procesa la acción, **Then** navega a la pantalla de detalle de ese equipo (`/teams/:id`).
4. **Given** que una competición aún no tiene equipos inscritos, **When** el usuario abre la pestaña **"Equipos"**, **Then** se muestra un estado vacío informativo en español (`competition_teams_empty_state`).

---

### User Story 3 - Retiro de Equipos del Campeonato y Traslado entre Grupos por el Organizador (Priority: P2)

Como **Organizador**, quiero poder **quitar un equipo inscrito** de la competición o **trasladarlo de un grupo a otro** desde la pestaña **"Equipos"** para ajustar la conformación del campeonato y sus grupos de clasificación.

**Why this priority**: Otorga al organizador control administrativo completo para corregir inscripciones, dar de baja equipos retirados o reequilibrar los grupos del torneo.

**Independent Test**: Se puede probar como `Organizador` en la pestaña **"Equipos"** de un torneo `mixedGroupsAndKnockout`: (1) cambiando un equipo del *Grupo A* al *Grupo B* y verificando que tanto la pestaña **"Equipos"** como las tablas por grupo en **"Clasificación"** reflejan el cambio; y (2) pulsando **"Quitar equipo"**, confirmando en el diálogo y comprobando que el equipo desaparece del campeonato.

**Acceptance Scenarios**:

1. **Given** que el `Organizador` visualiza la pestaña **"Equipos"** de una competición editable con formato `mixedGroupsAndKnockout`, **When** selecciona la acción **"Trasladar de Grupo"** en un equipo inscrito y elige otro grupo válido del torneo (ej. *"Grupo B"*), **Then** el equipo actualiza su `groupName` a *"Grupo B"*, muestra confirmación visual y actualiza inmediatamente su ubicación en la pestaña **"Equipos"** y en las tablas por grupo de la pestaña **"Clasificación"**.
2. **Given** que el `Organizador` visualiza la pestaña **"Equipos"** de una competición editable, **When** selecciona la acción **"Quitar del campeonato"** sobre un equipo y confirma en el diálogo de seguridad, **Then** el equipo es eliminado del campeonato y desaparece de la lista de equipos inscritos.
3. **Given** que un usuario con rol distinto a `Organizador` (`Aficionado`, `Jugador`, `Entrenador`, `Árbitro`) o en un torneo `finished` visualiza la pestaña **"Equipos"**, **When** inspecciona las tarjetas de los equipos, **Then** no se muestran los botones administrativos de quitar equipo ni trasladar de grupo.

---

### Edge Cases

- **Campeonato finalizado (`TournamentStatus.finished`)**: El FAB Menu y las acciones de quitar equipo o trasladar de grupo permanecen ocultos, garantizando la inmutabilidad histórica del campeonato cerrado.
- **Intento de retiro de equipo con partidos iniciados o finalizados (`inProgress` / `completed`)**: Si el equipo que se intenta quitar ya tiene encuentros en estado `inProgress` o `completed` en el campeonato, el sistema bloquea la eliminación mostrando un mensaje de alerta en español; si solo tiene partidos pendientes (`pendingSchedule` o `scheduled`), permite retirar al equipo y limpia dichos partidos pendientes del fixture.
- **Equipos sin `groupName` explícito en torneos `mixedGroupsAndKnockout`**: Si existen equipos creados previamente sin `groupName`, el sistema les asigna o resuelve un grupo determinista (`Grupo A`, `Grupo B`, ...) según `groupCount`, permitiendo al organizador trasladarlos a cualquier grupo válido en cualquier momento.
- **Protección contra operaciones duplicadas (*Single-Flight*)**: Mientras una inscripción, traslado de grupo o retiro de equipo está guardándose (`isSaving`), los controles deshabilitan envíos concurrentes.
- **Pantallas compactas ($320 \times 640\text{ px}$) con escalado de texto al $130\%$**: El `TabBar` de 4 pestañas (*Partidos*, *Clasificación*, *Equipos*, *Información*), las tarjetas de equipos con sus controles administrativos y los diálogos modales deben renderizarse sin `RenderFlex overflow`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `CompetitionDetailScreen` (`/competitions/:id`) DEBE contar con 4 pestañas en su `TabBar`: **Partidos** (`competition_detail_tab_matches`), **Clasificación** (`competition_detail_tab_standings`), **Equipos** (`competition_detail_tab_teams`) e **Información** (`competition_detail_tab_info`).
- **FR-002**: El menú flotante (`competition_detail_fab_menu`) en `CompetitionDetailScreen` DEBE incluir el botón de acción **"Agregar Equipo"** (`Key('competition_detail_fab_add_team')`) cuando el usuario tiene `RoleCapability.manageTournaments` (`UserRole.organizer`) y `tournament.status.isEditable == true`.
- **FR-003**: Al pulsar `competition_detail_fab_add_team`, DEBE abrirse `CompetitionEnrollTeamDialog` (`Key('competition_enroll_team_dialog')`), permitiendo inscribir un equipo en el campeonato actual (creando un equipo nuevo o copiando/inscribiendo un club existente del catálogo que aún no participe en este torneo), validando nombre (3-60 caracteres, único en el torneo) y código corto (2-4 caracteres), y permitiendo elegir el grupo inicial (`Grupo A` .. `Grupo N`) si `tournament.format == TournamentFormat.mixedGroupsAndKnockout`, preseleccionando por defecto el grupo con menor cantidad de equipos inscritos en ese momento (balanceo automático).
- **FR-004**: La entidad `TournamentTeam` DEBE incluir el campo opcional `final String? groupName`, serializado en JSON (`'groupName'`) con retrocompatibilidad total cuando sea `null`.
- **FR-005**: La vista `CompetitionTeamsTabView` (`Key('competition_teams_tab_view')`) DEBE listar todos los `TournamentTeam` cuyo `tournamentId` coincida con la competición actual, mostrando escudo, nombre, `shortCode`, cantidad de jugadores e insignia de elegibilidad; cuando `tournament.format == TournamentFormat.mixedGroupsAndKnockout`, DEBE organizar los equipos en secciones con encabezado por grupo (*Grupo A*, *Grupo B*, ...) además de su insignia de grupo, y en lista alfabética simple para formatos de Liga o Copa.
- **FR-006**: Cuando el rol activo sea `Organizador` y la competición sea editable (`tournament.status.isEditable`), cada tarjeta de equipo en `CompetitionTeamsTabView` DEBE mostrar:
  - Acción para **Trasladar de Grupo** (`Key('competition_team_move_group_${team.id}')`) si `tournament.format == TournamentFormat.mixedGroupsAndKnockout`, abriendo un selector modal con los grupos válidos (`Grupo A` hasta `Grupo <groupCount>`) para actualizar `team.groupName`.
  - Acción para **Quitar del campeonato** (`Key('competition_team_remove_${team.id}')`), abriendo un diálogo de confirmación (`Key('competition_remove_team_confirm_dialog')`) antes de eliminar el equipo de la competición.
- **FR-007**: `TeamsRepository`, `LocalTeamsRepository`, `ManageTeamsEligibilityUseCase` y `TeamsController` DEBEN soportar la eliminación de un equipo inscrito (`removeTeamFromCompetition`) y la actualización de su grupo (`moveTeamToGroup`), verificando permisos de `RoleCapability.manageTournaments`, que el campeonato no esté `finished`, y bloqueando el retiro si el equipo ya tiene partidos en estado `inProgress` o `completed` (eliminando los partidos pendientes del equipo cuando el retiro sea válido).
- **FR-008**: `StandingsCalculatorService.calculateGroupStageTables` DEBE respetar el `groupName` explícito de cada `TournamentTeam` cuando coincida con uno de los grupos válidos del torneo (`Grupo A` .. `Grupo N`), utilizando la distribución modular determinista únicamente como respaldo para equipos con `groupName == null` o fuera de rango.
- **FR-009**: Todos los textos visibles al usuario DEBEN servirse en español desde `lib/l10n/app_es.arb`, manteniendo el código técnico en inglés.

### Key Entities *(include if feature involves data)*

- **`TournamentTeam`**: Club inscrito en un campeonato (`id`, `tournamentId`, `name`, `shortCode`, `crestShape`, `primaryColorHex`, `secondaryColorHex`, `eligibilityStatus`, `players`, `groupName`, `updatedAt`).
- **`ChampionshipTournament`**: Competición a la que pertenecen los equipos inscritos, definiendo su formato (`league`, `knockoutCup`, `mixedGroupsAndKnockout`), estado (`openRegistration`, `inProgress`, `finished`) y configuración de grupos (`rules.groupStageConfig.groupCount`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El `Organizador` puede inscribir un equipo nuevo o existente en un campeonato editable desde el FAB Menu de `/competitions/:id` en menos de 3 pasos y verlo reflejado inmediatamente en la pestaña **"Equipos"**.
- **SC-002**: El 100% de los traslados de grupo realizados por el `Organizador` en torneos `mixedGroupsAndKnockout` se persisten localmente y actualizan de inmediato tanto la pestaña **"Equipos"** como las tablas por grupo de la pestaña **"Clasificación"**.
- **SC-003**: El 100% de los retiros de equipos confirmados por el `Organizador` eliminan al club del listado de la competición sin afectar equipos homónimos inscritos en otros campeonatos.
- **SC-004**: Cero errores de análisis estático (`flutter analyze`) y cero desbordamientos visuales (`RenderFlex overflow`) en resoluciones compactas de $320 \times 640\text{ px}$ con escalado de texto al $130\%$.
