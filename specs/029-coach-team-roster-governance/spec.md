# Feature Specification: Coach Team & Roster Governance

**Feature Branch**: `029-coach-team-roster-governance`

**Created**: 2026-11-10

**Status**: Draft

**Input**: User description: "Notion HU 16.2: Gobernanza de Equipos: Creación y Gestión de Plantilla Exclusiva para Entrenadores"

## Clarifications

### Session 2026-11-10

- Q: ¿Cómo debe estructurarse la creación de un equipo por parte del entrenador respecto a las competiciones disponibles? → A: Creación autónoma de club: El entrenador puede registrar y gestionar un club/equipo independiente sin requerir torneo asociado inmediato, y posteriormente inscribirlo a competiciones.
- Q: ¿Qué debe mostrar el Panel del Entrenador (`CoachPanelContent`) cuando el usuario con rol de entrenador aún no tiene ningún equipo registrado? → A: Tarjeta de estado vacío con acción directa: Mostrar un componente de estado vacío explicativo (`coach_no_team_card`) con el botón de acción principal "Registrar mi Equipo" que abre directamente el diálogo de creación.
- Q: ¿Cómo debe vincularse formalmente la identidad del usuario entrenador con el equipo que crea y administra? → A: Atributo `coachId` explícito: Añadir un campo `coachId` de tipo `String?` en `TournamentTeam` persistido y serializado en JSON, asociando el ID del entrenador en sesión con fallback retrocompatible (`coach-seed-1`) para equipos y pruebas preexistentes.
- Q: ¿Cómo debe quedar configurado el menú flotante Speed Dial del Organizador en la pantalla de Detalle de Competición (`CompetitionDetailScreen`) al remover la opción de inscribir equipos? → A: FAB dinámico simplificado: Al removerse la opción de inscribir equipos del organizador, la pantalla presenta directamente un FloatingActionButton para "Generar Fixture" cuando la competición sea editable y no tenga fixture generado, eliminando el submenú Speed Dial redundante de un solo ítem.
- Q: ¿Qué campos y validaciones obligatorias debe solicitar el diálogo/formulario de creación de equipo cuando el entrenador lo invoca? → A: Nombre, sigla y torneo opcional: El formulario modal de creación de equipo para entrenadores solicita nombre ($\ge 3$ caracteres), sigla (2 a 4 caracteres alfanuméricos en mayúsculas) y selector opcional de torneo activo (con opción "Sin torneo asignado" por defecto para clubs autónomos).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Coach Team Creation & Roster Management (Priority: P1)

As an authenticated club coach (`UserRole.coach`), I want to register my team and manage its official player roster from the Coach Panel and Teams Directory, so that I can autonomously maintain my squad's lineup and enrollment without dependency on tournament administrators.

**Why this priority**: Club and squad management is the core functional identity of the Coach role in vifutbol. Giving coaches exclusive ownership over team and roster registration establishes the foundational sports governance model.

**Independent Test**: Can be tested by signing in as a coach, navigating to the Teams Directory or Coach Panel, creating a new team, and adding players to its roster, verifying that the team and squad persist accurately.

**Acceptance Scenarios**:

1. **Given** an authenticated user with role `coach`, **When** the coach navigates to the Teams Directory or Coach Panel, **Then** the action "Crear Equipo" is visible and interactive.
2. **Given** an authenticated coach in their team management screen, **When** the coach accesses the roster tab or section, **Then** the action "Agregar Jugador" is visible and allows registering a player with name, document number, and shirt number.
3. **Given** an authenticated coach creating a team, **When** filling the registration modal with name ($\ge 3$ characters), uppercase short code (2–4 characters), and optional tournament selection, **Then** the team is created as an autonomous club or enrolled in the selected tournament, assigned to the coach's `coachId`, and listed in their managed teams.

4. **Given** an authenticated coach with no registered teams, **When** accessing the Coach Panel, **Then** an empty state card (`coach_no_team_card`) is rendered inviting them to create their team, with an actionable button "Registrar mi Equipo" that opens the team registration modal.

---

### User Story 2 - Strict Access Restriction for Non-Coach Roles in UI (Priority: P2)

As a tournament organizer, referee, player, or fan, I want the team creation and player registration actions to be completely hidden in the user interface, so that I cannot inadvertently attempt unauthorized operations or encounter dead-end submission errors.

**Why this priority**: Eliminates visual clutter, prevents confusion across system roles, and ensures adherence to the principle of least privilege in the user experience.

**Independent Test**: Can be tested by logging in as organizer, referee, player, or fan, navigating to the Teams Directory, Players Directory, and Competition Detail screens, and verifying that team creation buttons, speed-dial actions for team registration, and player addition buttons are not rendered.

**Acceptance Scenarios**:

1. **Given** an authenticated user with role `organizer`, `referee`, `player`, or `fan`, **When** navigating to the Teams Directory screen, **Then** the action button "Inscribir equipo" / "Crear Equipo" is not displayed in the app bar or content area.
2. **Given** an authenticated organizer viewing a competition in `CompetitionDetailScreen`, **When** the competition is editable and lacks a fixture, **Then** a direct FloatingActionButton "Generar Fixture" is presented instead of an open/close Speed Dial, and the "Inscribir equipo" action is completely removed.
3. **Given** an authenticated user with role `organizer`, `referee`, `player`, or `fan`, **When** viewing the Players Directory screen, **Then** the action button "Registrar jugador" is not rendered.

---

### User Story 3 - Domain-Level Authorization Enforcement & Error Messaging (Priority: P3)

As a system security and sports integrity safeguard, I want any direct attempt to invoke team creation or player addition use cases without the coach role to be rejected at the domain layer, so that unauthorized mutations cannot occur even if UI restrictions are bypassed.

**Why this priority**: Guarantees architectural integrity, defense-in-depth, and strict compliance with the Constitution's role separation principles regardless of presentation layer state.

**Independent Test**: Can be tested through automated domain and use case tests that attempt to call team creation and player enrollment methods passing actor roles other than `coach`, verifying that an unauthorized failure with a descriptive Spanish message is thrown.

**Acceptance Scenarios**:

1. **Given** an attempt to invoke team registration with an actor role other than `coach`, **When** the domain validation evaluates the request, **Then** the operation is rejected and returns an unauthorized failure with the message "Solo los entrenadores pueden registrar equipos o futbolistas".
2. **Given** an attempt to enroll a player to a team roster with an actor role other than `coach`, **When** the domain validation evaluates the request, **Then** the operation is rejected with an unauthorized failure and no player data is persisted.

---

### Edge Cases

- **Session Role Switching**: If an active session transitions from `coach` to another role while on the Teams Directory screen, the interface must immediately react and remove creation controls without requiring a full app reload.
- **Tournament Status Safeguard**: Even for authorized coaches, team and player registration into a specific tournament must be blocked if the tournament's registration period is closed or the tournament is finished.
- **Duplicate Document/Shirt Number**: A coach attempting to add a player whose document already exists in the same tournament or whose shirt number is already taken in the squad must receive precise field-level feedback and be prevented from saving.
- **Roster Modification During Ongoing Match**: Player roster modifications while a match of that team is in progress must preserve the integrity of active digital match reports.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST restrict the capability to create teams exclusively to users with the active role `UserRole.coach`, presenting a creation modal (`CreateTeamDialog`) requesting team name ($\ge 3$ characters), uppercase short code (2–4 characters), and optional tournament selection (defaulting to "Sin torneo asignado").
- **FR-002**: The system MUST restrict the capability to register and enroll players in a squad roster exclusively to users with the active role `UserRole.coach`.
- **FR-003**: The system MUST update the role permission matrix so that `RoleCapability.manageTeamRoster` is only granted to `UserRole.coach`, and tournament management or registration approval capabilities do NOT grant team creation or roster addition permissions.
- **FR-004**: The system MUST hide the team creation action button from the Teams Directory screen for all roles other than `UserRole.coach`.
- **FR-005**: The system MUST hide the player creation action button from the Players Directory screen for all roles other than `UserRole.coach`.
- **FR-006**: The system MUST replace the organizer's Speed Dial FAB in `CompetitionDetailScreen` with a direct "Generar Fixture" FAB (displayed only when the tournament is editable and lacks fixtures), completely removing the team enrollment action for organizers.
- **FR-007**: The system MUST validate actor authorization in team registration and player addition use cases, rejecting non-coach roles with an unauthorized failure explaining "Solo los entrenadores pueden registrar equipos o futbolistas".
- **FR-008**: The Coach Panel MUST render an empty state card (`coach_no_team_card`) with a "Registrar mi Equipo" action when the coach has no team registered, and provide quick actions to manage squad roster and lineups once a team is present.
- **FR-009**: The system MUST persist `coachId` in `TournamentTeam` with fallback to `coach-seed-1` for backward compatibility, and the Coach Panel MUST filter and display only the teams corresponding to the logged-in coach's `coachId`.
- **FR-010**: The system MUST maintain full backward compatibility with existing registered teams and players without data corruption.

### Key Entities *(include if feature involves data)*

- **RoleCapability**: Enumeration of operative capabilities (`manageTeamRoster`, `manageTournaments`, `approveRegistrations`, etc.) governing functional access.
- **RolePermissionMatrix**: Domain matrix mapping each `UserRole` to its authorized set of `RoleCapability` items.
- **TournamentTeam**: Entity representing an enrolled or club team, containing squad rosters, status, and associated metadata (with nullable/optional tournament reference for autonomous clubs and `coachId` identifying the owning coach).
- **RegisteredPlayer**: Entity representing an athlete enrolled in a team squad with unique document identification, shirt number, and eligibility status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of unauthorized roles (`organizer`, `referee`, `player`, `fan`) have team creation and player registration buttons hidden in all directory and competition views.
- **SC-002**: 100% of direct use case invocations for team creation and roster modification by non-coach roles fail with an unauthorized failure at the domain layer.
- **SC-003**: Authorized coaches can initiate team creation in under 2 taps from either the Teams Directory or Coach Panel.
- **SC-004**: Zero UI layout regressions or RenderFlex overflows across supported mobile viewports ($320 \times 640\text{ px}$ to large devices) with text scaling up to 130%.
- **SC-005**: 100% pass rate in automated unit, domain, and widget test suites covering role-based visibility and domain security gates.

## Assumptions

- Tournament organizers retain the authority to admit, approve, or reject teams for their competitions, as well as generate fixtures and assign groups, but do not author the team itself or its internal player roster.
- A coach user can manage one or more club teams depending on their account profile.
- Existing teams created under previous test suites or development seeds remain readable across all roles in directory views.
- Localization strings for error messages and UI tooltips are centralized in the application's Spanish localization catalogs.
