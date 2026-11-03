---

description: "Task list for Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)"
---

# Tasks: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Input**: Design documents from `/specs/005-teams-players-eligibility/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/teams-players-ui-and-storage-contract.md, quickstart.md

**Tests**: Automated unit and widget tests are included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and `SC-005` (`>= 80%` coverage).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Add all Spanish localization strings (`app_es.arb`) including the exact Gherkin error messages and domain failure codes required across HU 5.1.

- [X] T001 Add Spanish localization strings for team eligibility statuses (`Pendiente de Cupo`, `Listo para Habilitar`, `Habilitado`), player positions (`Portero`, `Defensa`, `Mediocampista`, `Delantero` and short labels `POR`, `DEF`, `MED`, `DEL`), crest shapes (`Escudo Clásico`, `Circular`, `Rombo`, `Hexágono`), team and player form labels, quota progress labels, and exact Gherkin validation messages (`"El número de camiseta {number} ya está en uso en este equipo."` and `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`) in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations*.dart`
- [X] T002 [P] Extend `lib/domain/failures/app_failure.dart` with `TeamEligibilityErrorCode` (`tournamentRegistrationsClosed`, `invalidTeamName`, `invalidShortCode`, `duplicateTeamNameInTournament`, `invalidPlayerName`, `invalidDocumentId`, `invalidShirtNumber`, `duplicateShirtNumberInTeam`, `playerAlreadyRegisteredInTournament`, `maxPlayersQuotaReached`, `insufficientPlayersForApproval`, `teamNotFound`) and `TeamEligibilityValidationFailure`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain enumerations, entities (`RegisteredPlayer`, `TournamentTeam`), catalog state (`TeamsCatalogState`), and repository interface (`TeamsRepository`) that MUST be complete before user story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Create domain enumerations `TeamEligibilityStatus` (`pendingQuota`, `readyForApproval`, `eligible`), `PlayerPosition` (`goalkeeper`, `defender`, `midfielder`, `forward`), and `TeamCrestShape` (`shield`, `circle`, `diamond`, `hexagon`) in `lib/domain/entities/team_enums.dart`
- [X] T004 [P] Create `RegisteredPlayer` entity (`id` unique immutable String, `fullName` non-empty `>= 3` chars, `documentId` normalized String `>= 5` chars unique within tournament, `shirtNumber` integer in range `1..99` unique within team, `position` `PlayerPosition`, `isEligible` bool `true` when team is `TeamEligibilityStatus.eligible`, `normalizedDocumentId` getter returning `documentId.trim().toUpperCase()`, `copyWith`, `toJson`, and `fromJson`) in `lib/domain/entities/registered_player.dart`
- [X] T005 Create `TournamentTeam` aggregate root (`id` unique immutable String, `tournamentId` mandatory reference to `ChampionshipTournament.id`, `name` non-empty `>= 3` chars unique per `tournamentId`, `shortCode` uppercase `2..4` chars, `crestShape` default `TeamCrestShape.shield`, `primaryColorHex` int ARGB e.g. `0xFF00E676`, `secondaryColorHex` int ARGB e.g. `0xFF0A0E17`, `eligibilityStatus` `TeamEligibilityStatus`, `players` `List<RegisteredPlayer>` sorted by `shirtNumber` ascending, `updatedAt` `DateTime`, plus helper getters `normalizedName => name.trim().toLowerCase()`, `meetsMinimumQuota(int minPlayers) => players.length >= minPlayers`, `hasAvailableSlot(int maxPlayers) => players.length < maxPlayers`, `copyWith`, `toJson`, and `fromJson`) in `lib/domain/entities/tournament_team.dart`
- [X] T006 [P] Create `TeamsCatalogState` container (`teams` `List<TournamentTeam>`, `selectedTeamId` `String?`, `isSaving` bool single-flight flag, `lastFailure` `AppFailure?`, `selectedTeam` getter, and `teamsForTournament(String tournamentId)` helper method) in `lib/domain/entities/teams_catalog_state.dart`
- [X] T007 [P] Define `TeamsRepository` abstract interface (`loadTeams()`, `loadTeamsForTournament(String tournamentId)`, `saveTeam(TournamentTeam team)`) in `lib/domain/repositories/teams_repository.dart`
- [X] T008 Write unit tests for `TeamEligibilityStatus`, `PlayerPosition`, `TeamCrestShape`, `RegisteredPlayer` (`normalizedDocumentId`, JSON round-trip), `TournamentTeam` (`normalizedName`, `meetsMinimumQuota`, `hasAvailableSlot`, player sorting by `shirtNumber`, JSON round-trip), and `TeamsCatalogState` (`teamsForTournament`, `selectedTeam`) in `test/unit/domain/tournament_team_and_player_test.dart`

**Checkpoint**: Foundation ready — user story implementation can now proceed.

---

## Phase 3: User Story 1 - Registro de Equipos e Inscripción de Plantilla Oficial en un Campeonato (Priority: P1) 🎯 MVP

**Goal**: Allow `Organizador` (`RoleCapability.manageTournaments` / `RoleCapability.approveRegistrations`) and `Entrenador` (`RoleCapability.manageTeamRoster`) to register teams with native vector crest (`shortCode` `2..4` chars, `TeamCrestShape`, primary/secondary colors) and enroll/edit/remove players (`fullName`, `documentId`, `position`, `shirtNumber` `1..99` with `TextInputType.number`) exclusively when the championship is in `"Inscripciones Abiertas"` (`TournamentStatus.openRegistration`).

**Independent Test**: Authenticate as `Organizador` or `Entrenador`, select an open-registration championship in `StandingsTabView`, register a new team with vector crest and colors, navigate to `/tournaments/teams/detail`, enroll players using numeric keyboard for `documentId` and `shirtNumber`, and verify persistence in `LocalTeamsRepository` and blocking when the championship is `"En Curso"` or `"Finalizado"`.

### Tests for User Story 1

- [X] T009 [P] [US1] Write unit tests for `LocalTeamsRepository` covering `dev` seed loading (`"Atlético Norte FC"` with `shortCode: 'ATN'`, `TeamEligibilityStatus.eligible`, `7` players with shirt numbers `1, 4, 5, 8, 9, 10, 11` and documents `'10100001'`..`'10100007'`; `"Real Sabana Club"` with `shortCode: 'RSC'`, `TeamEligibilityStatus.pendingQuota`, `5` players with shirt numbers `1, 2, 6, 7, 10` and documents `'20200001'`..`'20200005'` for `'tournament-seed-liga-clausura'`), empty `prod` storage, `loadTeamsForTournament`, and `saveTeam` persistence under `'vifutbol.teams.catalog.v1'` in `test/unit/infrastructure/local_teams_repository_test.dart`
- [X] T010 [P] [US1] Write unit tests for `ManageTeamsEligibilityUseCase` covering role authorization (`Organizador` and `Entrenador` allowed; `Aficionado`, `Jugador`, `Árbitro` rejected with `UnauthorizedRoleFailure`), tournament status guard (`TournamentStatus.openRegistration` required; `inProgress` and `finished` rejected with `TeamEligibilityErrorCode.tournamentRegistrationsClosed`), team field validation (`name.trim().length >= 3`, `shortCode.trim().length` in `2..4`), and player field validation (`fullName.trim().length >= 3`, `documentId.trim().length >= 5`, `shirtNumber` in `1..99`) in `test/unit/application/manage_teams_eligibility_use_case_test.dart`

### Implementation for User Story 1

- [X] T011 [US1] Implement `LocalTeamsRepository` backed by `LocalStorageRepository` (storage key `'vifutbol.teams.catalog.v1'` and 2 development seed teams `"Atlético Norte FC"` and `"Real Sabana Club"` linked to `'tournament-seed-liga-clausura'`) in `lib/infrastructure/repositories/local_teams_repository.dart`
- [X] T012 [US1] Implement `ManageTeamsEligibilityUseCase` (`registerOrUpdateTeam`, `enrollOrUpdatePlayer`, `removePlayer`, `approveTeamEligibility`) enforcing role permissions (`RoleCapability.manageTeamRoster || RoleCapability.manageTournaments || RoleCapability.approveRegistrations` for roster mutations) and `tournament.status == TournamentStatus.openRegistration` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart`
- [X] T013 [US1] Implement `TeamsController` (`StateNotifier<UiViewState<TeamsCatalogState>>`) and Riverpod providers (`teamsRepositoryProvider`, `manageTeamsEligibilityUseCaseProvider`, `teamsControllerProvider`) in `lib/application/controllers/teams_controller.dart` and `lib/application/providers/teams_providers.dart`
- [X] T014 [P] [US1] Create `KickPulseTeamCrest` native vector crest widget rendering `TeamCrestShape` (`shield`, `circle`, `diamond`, `hexagon`), primary/secondary ARGB colors, and uppercase `shortCode` (`2..4` chars) at 60 fps in `lib/presentation/teams/widgets/kick_pulse_team_crest.dart`
- [X] T015 [US1] Create `TournamentTeamsSection` widget displaying registered teams for the active championship, quota progress (`X / min..max jugadores`), eligibility badge, and `"Inscribir Equipo"` dialog (with team name, `2..4` char `shortCode`, `TeamCrestShape` selector, and curated primary/secondary color pickers) when `tournament.status == TournamentStatus.openRegistration` in `lib/presentation/teams/widgets/tournament_teams_section.dart`
- [X] T016 [US1] Create `TeamRosterDetailScreen` displaying the team header (`KickPulseTeamCrest`, quota progress bar, eligibility status badge), ordered player roster list (`shirtNumber`, `fullName`, `documentId`, `position`), and player enrollment/edit sheet with `keyboardType: TextInputType.number` on `player_document_input` and `player_shirt_number_input` and single-flight submit protection in `lib/presentation/teams/team_roster_detail_screen.dart`
- [X] T017 [US1] Register `/tournaments/teams/detail` route in `lib/presentation/navigation/app_router.dart` and integrate `TournamentTeamsSection` inside `StandingsTabView` (`lib/presentation/shell/tabs/standings_tab_view.dart`) below `TournamentRulesSummaryCard`

**Checkpoint**: User Story 1 is complete and independently testable.

---

## Phase 4: User Story 2 - Validaciones de Integridad Deportiva y Unicidad de Equipo, Dorsal y Jugador por Torneo (Priority: P2)

**Goal**: Enforce deterministic uniqueness of team names per championship (`normalizedName`), shirt numbers (`1..99`) within the same team with exact Spanish message `"El número de camiseta {number} ya está en uso en este equipo."`, and player exclusivity (`normalizedDocumentId`) across all teams in the same championship with exact Spanish message `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`, while allowing the same player document in a different championship.

**Independent Test**: Attempt to enroll a player with document `"10100001"` (already in `"Atlético Norte FC"`) into `"Real Sabana Club"` in the same tournament and verify rejection with `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`; attempt to enroll a player with shirt number `10` (already taken) in the same team and verify rejection with `"El número de camiseta 10 ya está en uso en este equipo."`; attempt to create another team named `"atletico norte fc"` or `"Atlético Norte FC"` in the same tournament and verify duplicate name rejection.

### Tests for User Story 2

- [X] T018 [P] [US2] Extend `test/unit/application/manage_teams_eligibility_use_case_test.dart` and create `test/unit/application/teams_controller_test.dart` to verify: (1) duplicate team name rejection (`duplicateTeamNameInTournament`, case-insensitive & trimmed) within the same `tournamentId` while allowing the same name in another `tournamentId`; (2) duplicate shirt number rejection (`duplicateShirtNumberInTeam`) with exact message `"El número de camiseta 10 ya está en uso en este equipo."`; (3) cross-team duplicate player document rejection (`playerAlreadyRegisteredInTournament`) within the same `tournamentId` with exact message `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."` while allowing the same `documentId` in another `tournamentId`

### Implementation for User Story 2

- [X] T019 [US2] Ensure `ManageTeamsEligibilityUseCase` (`lib/application/use_cases/manage_teams_eligibility_use_case.dart`) and inline error mapping in `TournamentTeamsSection` (`lib/presentation/teams/widgets/tournament_teams_section.dart`) and `TeamRosterDetailScreen` (`lib/presentation/teams/team_roster_detail_screen.dart`) surface the exact localized Gherkin messages `"El número de camiseta {number} ya está en uso en este equipo."` and `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."` and duplicate team name error in real time

**Checkpoint**: User Stories 1 and 2 are complete and independently testable.

---

## Phase 5: User Story 3 - Validación de Cupos Reglamentarios y Habilitación Oficial del Equipo por el Organizador (Priority: P3)

**Goal**: Enforce `ChampionshipTournament.rules.minPlayersPerTeam` and `maxPlayersPerTeam` quota constraints, block player additions when `maxPlayersPerTeam` is reached, automatically transition team status between `pendingQuota` and `readyForApproval` as players are added/removed, revert `eligible` teams to `pendingQuota` if player removal drops the roster below `minPlayersPerTeam`, allow exclusively `Organizador` (`RoleCapability.approveRegistrations`) to execute `"Habilitar Equipo"` when `[minPlayersPerTeam, maxPlayersPerTeam]` is satisfied, and provide read-only inspection for `Aficionado`, `Jugador`, and `Árbitro`.

**Independent Test**: Open `"Real Sabana Club"` (`5/7` players) as `Organizador` and verify `"Habilitar Equipo"` is blocked (`insufficientPlayersForApproval`); enroll `2` valid players to reach `7/7` (`readyForApproval`), tap `"Habilitar Equipo"`, and verify the team transitions to `"Habilitado"` (`TeamEligibilityStatus.eligible`) with all players marked `isEligible = true`; remove `1` player (`6/7`) and verify automatic reversion to `"Pendiente de Cupo"`; switch to `Aficionado`, `Jugador`, or `Árbitro` and verify read-only access without mutation or approval controls.

### Tests for User Story 3

- [X] T020 [P] [US3] Extend `test/unit/application/manage_teams_eligibility_use_case_test.dart` and create `test/unit/application/teams_controller_test.dart` to verify: blocking player enrollment at `maxPlayersPerTeam` (`maxPlayersQuotaReached`), automatic `pendingQuota` ↔ `readyForApproval` transitions, blocking `approveTeamEligibility` for `Entrenador` (`UnauthorizedRoleFailure`) and when `players.length < minPlayersPerTeam` (`insufficientPlayersForApproval`), setting `TeamEligibilityStatus.eligible` and `player.isEligible = true` upon organizer approval, and automatic reversion from `eligible` to `pendingQuota` (`isEligible = false`) when `removePlayer` drops the squad below `minPlayersPerTeam`
- [X] T021 [P] [US3] Write widget tests in `test/widget/teams_roster_eligibility_widget_test.dart` covering: team registration dialog in `StandingsTabView`, navigating to `TeamRosterDetailScreen`, numeric keyboard (`TextInputType.number`) on `player_document_input` and `player_shirt_number_input`, Gherkin error display for duplicate shirt number and duplicate player document across teams, quota enforcement and organizer-only `"Habilitar Equipo"` approval, and read-only view for `Aficionado`/`Jugador`/`Árbitro` and closed-registration tournaments

### Implementation for User Story 3

- [X] T022 [US3] Implement organizer-only `"Habilitar Equipo"` action (`RoleCapability.approveRegistrations`), quota status banner (`minPlayersPerTeam..maxPlayersPerTeam`), and strict read-only role guards for `Aficionado`, `Jugador`, and `Árbitro` (and for `Entrenador` on the eligibility approval button) in `lib/presentation/teams/team_roster_detail_screen.dart` and `lib/presentation/teams/widgets/tournament_teams_section.dart`

**Checkpoint**: All user stories (`US1`, `US2`, `US3`) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final static analysis, code formatting, test suite execution, and coverage verification (`SC-005`).

- [X] T023 Run `flutter analyze` and resolve any static analysis warnings or errors across `lib/` and `test/`
- [X] T024 Run `dart format --output=none --set-exit-if-changed lib test` and `flutter test --coverage` to verify 100% passing tests and `>= 80%` coverage on HU 5.1 domain and application logic

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — starts immediately (`T001`, `T002`).
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T001`, `T002`) — **BLOCKS** all user stories (`T003`..`T008`).
- **Phase 3 (User Story 1 - P1)**: Depends on Phase 2 (`T003`..`T008`).
- **Phase 4 (User Story 2 - P2)**: Depends on Phase 3 (`T011`..`T017`).
- **Phase 5 (User Story 3 - P3)**: Depends on Phase 3 & Phase 4 (`T012`, `T013`, `T016`, `T019`).
- **Phase 6 (Polish)**: Depends on all user stories (`T001`..`T022`).

### User Story Dependencies

- **User Story 1 (P1)**: Starts immediately after Phase 2 Foundational. Delivers end-to-end team registration, vector crest rendering, and player roster management in open-registration championships.
- **User Story 2 (P2)**: Builds on US1 use case and forms to verify and surface real-time Gherkin uniqueness validations for team names, shirt numbers, and cross-team player documents.
- **User Story 3 (P3)**: Connects US1/US2 rosters with `ChampionshipTournament.rules` (`minPlayersPerTeam`..`maxPlayersPerTeam`) and `RoleCapability.approveRegistrations` for official team eligibility approval and role segregation.

### Parallel Opportunities

- `T003`, `T004`, `T006`, `T007` operate on independent domain files and can run in parallel.
- `T009` and `T010` test separate layers (`infrastructure` vs `application`) and can run in parallel.
- `T014` (`KickPulseTeamCrest`) can be built in parallel with `T011`..`T013`.
- `T020` and `T021` can run in parallel during Phase 5 verification.

---

## Parallel Example: User Story 1

```bash
# Foundational domain models in parallel:
Task: "T003 [P] Create domain enumerations in lib/domain/entities/team_enums.dart"
Task: "T004 [P] Create RegisteredPlayer entity in lib/domain/entities/registered_player.dart"
Task: "T006 [P] Create TeamsCatalogState container in lib/domain/entities/teams_catalog_state.dart"
Task: "T007 [P] Define TeamsRepository abstract interface in lib/domain/repositories/teams_repository.dart"

# User Story 1 unit tests in parallel:
Task: "T009 [P] [US1] Write unit tests for LocalTeamsRepository in test/unit/infrastructure/local_teams_repository_test.dart"
Task: "T010 [P] [US1] Write unit tests for ManageTeamsEligibilityUseCase in test/unit/application/manage_teams_eligibility_use_case_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Localization & Failure codes) and Phase 2 (Domain Models & Repository Interface).
2. Complete Phase 3 (`US1`: `LocalTeamsRepository`, `ManageTeamsEligibilityUseCase`, `TeamsController`, `KickPulseTeamCrest`, `TournamentTeamsSection`, and `TeamRosterDetailScreen`).
3. Validate `US1` unit tests (`T008`, `T009`, `T010`).

### Incremental Delivery

1. Add `US2` (Deterministic uniqueness for team name per tournament, shirt number per team, and player document per tournament with exact Gherkin error messages).
2. Add `US3` (Quota validation against `minPlayersPerTeam`..`maxPlayersPerTeam`, organizer-only `"Habilitar Equipo"` approval, automatic reversion on player removal, and role-based read-only views).
3. Run Phase 6 quality gates (`flutter analyze`, `dart format`, `flutter test --coverage`).
