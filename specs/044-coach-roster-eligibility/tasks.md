# Tasks: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico (HU 20.1)

**Input**: Design documents from `/specs/044-coach-roster-eligibility/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/roster_join_requests_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III (`Pruebas Automatizadas como Puerta de Calidad`) and HU 20.1 Definition of Done.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Database Migration & Localization)

**Purpose**: Database schema for team join requests and localization keys required across all user stories

- [X] T001 Create idempotent SQL migration defining `vifutboldev.team_join_requests` (`status` in `'pending'`, `'accepted'`, `'rejected'`, `'cancelled'`, `shirt_number` 1..99, `position` check, partial unique indexes `ux_team_join_requests_pending_player` and `ux_team_join_requests_pending_shirt`), RLS policies for `coach` and `player`, and RPCs `vifutboldev.search_registered_players` and `vifutboldev.respond_team_join_request` in `supabase/migrations/202611170001_team_join_requests.sql`
- [X] T002 Apply `supabase/migrations/202611170001_team_join_requests.sql` to Oracle Cloud Supabase DEV (`vifutboldev`) via SSH and reload PostgREST schema cache (`NOTIFY pgrst, 'reload schema'`)
- [X] T003 Add Spanish UI localization keys for join requests, player search modal, profile requests inbox, minimum 11-player eligibility indicator (`"No elegible / Faltan jugadores"`), and `"Habilitar para Competiciones"` action in `lib/l10n/app_es.arb`
- [X] T004 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Domain, Repositories & State Management)

**Purpose**: Core domain entities, repository interfaces, offline-first adapters, and Riverpod controller blocking user stories 2 and 3

**⚠️ CRITICAL**: User Stories 2 and 3 depend on this phase

- [X] T005 [P] Create `TeamJoinRequest` and `TeamJoinRequestStatus` (`pending`, `accepted`, `rejected`, `cancelled`) with JSON serialization and `copyWith` in `lib/domain/entities/team_join_request.dart`
- [X] T006 [P] Create `AvailablePlayerCandidate` entity (`userAccountId`, `fullName`, `documentId`, `normalizedDocumentId`) in `lib/domain/entities/available_player_candidate.dart`
- [X] T007 Create `TeamJoinRequestsRepository` interface (`searchRegisteredPlayers`, `loadRequestsForTeam`, `loadRequestsForCurrentPlayer`, `sendJoinRequest`, `respondToJoinRequest`, `cancelJoinRequest`) in `lib/domain/repositories/team_join_requests_repository.dart`
- [X] T008 [P] Implement `LocalTeamJoinRequestsRepository` backed by `LocalStorageRepository` in `lib/infrastructure/repositories/local_team_join_requests_repository.dart`
- [X] T009 Implement `PostgrestTeamJoinRequestsRemoteDataSource` and `HybridTeamJoinRequestsRepository` (calling `search_registered_players`, `respond_team_join_request`, and `team_join_requests` table with offline fallback) in `lib/infrastructure/repositories/hybrid_team_join_requests_repository.dart`
- [X] T010 Create `ManageTeamJoinRequestsUseCase`, `TeamJoinRequestsController`, and `teamJoinRequestsProviders` (with duplicate shirt/player validation and single-flight guards) in `lib/application/use_cases/manage_team_join_requests_use_case.dart`, `lib/application/controllers/team_join_requests_controller.dart`, and `lib/application/providers/team_join_requests_providers.dart`

**Checkpoint**: Foundation ready — user story implementation and testing can now proceed

---

## Phase 3: User Story 1 - Navegación Funcional a Gestión de Planilla desde el Panel Técnico (Priority: P1) 🎯 MVP

**Goal**: Make the "Gestionar Planilla" button in `CoachPanelContent` select the active team and navigate directly to `TeamRosterDetailScreen` (`/tournaments/teams/detail`).

**Independent Test**: Render `CoachPanelContent` as `UserRole.coach` with an assigned team, tap `coach_manage_roster_button`, and verify navigation to `/tournaments/teams/detail` with the selected team loaded in `teamsControllerProvider`.

### Tests for User Story 1

- [X] T011 [P] [US1] Add widget tests in `test/presentation/panel/coach_panel_content_test.dart` verifying tapping "Gestionar Planilla" selects the active team in `teamsControllerProvider` and navigates to `TeamRosterDetailScreen` (`/tournaments/teams/detail`)

### Implementation for User Story 1

- [X] T012 [US1] Update `_onManageRosterAction` in `lib/presentation/panel/widgets/coach_panel_content.dart` to call `ref.read(teamsControllerProvider.notifier).selectTeam(team.id)` and `Navigator.of(context).pushNamed('/tournaments/teams/detail')` instead of showing a SnackBar

**Checkpoint**: User Story 1 is independently testable via `flutter test test/presentation/panel/coach_panel_content_test.dart`

---

## Phase 4: User Story 2 - Solicitud de Incorporación y Respuesta de Jugadores Registrados (Priority: P1)

**Goal**: Replace manual player creation in `TeamRosterDetailScreen` with a `player` user search & join request modal (`InvitePlayerToTeamModal`), show pending sent requests to the `coach`, and add a dedicated "Solicitudes de Equipos" view in `ProfileTabView` (`PlayerTeamRequestsScreen`) so `player` users can accept or reject invitations before entering the roster.

**Independent Test**: Coach searches for a registered `player`, sends a join request (`pending`) without increasing the 11-player quota; `player` opens Perfil -> Solicitudes de Equipos, taps "Aceptar", and the player is added to the team roster updating the counter.

### Tests for User Story 2

- [X] T013 [P] [US2] Add unit tests in `test/unit/application/coach_roster_eligibility_test.dart` covering sending join requests, duplicate shirt/player rejection, cancellation, player acceptance (adding to roster & incrementing count), and rejection (freeing shirt number)
- [X] T014 [P] [US2] Add widget tests in `test/presentation/shell/profile_team_requests_test.dart` verifying `ProfileTabView` shows the "Solicitudes de Equipos" entry for `UserRole.player` and `PlayerTeamRequestsScreen` handles Accept and Reject actions without overflow

### Implementation for User Story 2

- [X] T015 [P] [US2] Create `InvitePlayerToTeamModal` (searching registered `player` accounts via `search_registered_players`, selecting shirt number 1..99 and `PlayerPosition`, zero manual registration form) in `lib/presentation/teams/widgets/invite_player_to_team_modal.dart`
- [X] T016 [US2] Update `TeamRosterDetailScreen` in `lib/presentation/teams/team_roster_detail_screen.dart` so "Agregar Jugador" (`enroll_player_button`) is visible only to `UserRole.coach`, opens `InvitePlayerToTeamModal`, and displays pending sent join requests with a cancel option
- [X] T017 [P] [US2] Create `PlayerTeamRequestsScreen` showing pending team invitations with team crest, coach name, proposed shirt number, position, and Accept/Reject buttons in `lib/presentation/shell/tabs/player_team_requests_screen.dart`
- [X] T018 [US2] Register `/profile/team-requests` route in `lib/presentation/navigation/app_router.dart` and add the "Solicitudes de Equipos" (`profile_team_requests_tile`) entry with pending badge in `lib/presentation/shell/tabs/profile_tab_view.dart` for users with `UserRole.player`

**Checkpoint**: User Story 2 passes unit and widget tests

---

## Phase 5: User Story 3 - Validación de Cuota Mínima y Habilitación del Equipo para Competiciones (Priority: P1)

**Goal**: Enforce the strict minimum 11-player quota (`players.length >= 11`), show "No elegible / Faltan jugadores" (`X/11 jugadores mínimos`) when under 11, and allow `UserRole.coach` (and `organizer`) to enable the team to `TeamEligibilityStatus.eligible` when `>= 11`, persisting both standalone and tournament-enrolled clubs to Hive and Supabase DEV.

**Independent Test**: Verify unit and widget tests for `< 11` blocking (`8/11 jugadores mínimos`) and `>= 11` transition to `eligible` by `UserRole.coach` on both standalone and tournament teams.

### Tests for User Story 3

- [X] T019 [P] [US3] Add unit tests in `test/unit/application/coach_roster_eligibility_test.dart` verifying `< 11` players throws `insufficientPlayersForApproval` and `>= 11` players allows `UserRole.coach` to transition the team to `TeamEligibilityStatus.eligible` (including standalone clubs with `tournamentId == ''`)
- [X] T020 [P] [US3] Add widget tests in `test/presentation/teams/team_roster_detail_screen_test.dart` verifying `"No elegible / Faltan jugadores"` indicator & disabled confirmation when `< 11`, enabled `"Habilitar para Competiciones"` button when `>= 11`, and transition to `eligible` on tap

### Implementation for User Story 3

- [X] T021 [US3] Update `ManageTeamsEligibilityUseCase.approveTeamEligibility` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` to authorize `UserRole.coach` (`RoleCapability.manageTeamRoster`), enforce strict minimum of `max(11, tournament.rules.minPlayersPerTeam)`, and support standalone clubs (`tournamentId == ''`) via `loadTeams()`
- [X] T022 [US3] Update `PostgrestTeamsRemoteDataSource.upsert()` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` to persist `eligibility_status` updates on `tournament_teams` when `tournamentId.isNotEmpty` and sync standalone `teams` metadata cleanly
- [X] T023 [US3] Update `TeamRosterDetailScreen` in `lib/presentation/teams/team_roster_detail_screen.dart` to allow `UserRole.coach` to view the `"No elegible / Faltan jugadores"` indicator when `< 11` and press `"Habilitar para Competiciones"` (`approve_team_eligibility_button`) when `>= 11`

**Checkpoint**: All three user stories pass independently

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, regression checks, and documentation/Notion synchronization

- [X] T024 Run `flutter analyze` and resolve any warnings or errors across all modified and new files
- [X] T025 Run `flutter test test/unit/application/coach_roster_eligibility_test.dart test/presentation/panel/coach_panel_content_test.dart test/presentation/teams/team_roster_detail_screen_test.dart test/presentation/shell/profile_team_requests_test.dart` and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: `T001` -> `T002`; `T003` -> `T004`.
- **Foundational (Phase 2)**: Depends on Phase 1 (`T005`/`T006` in parallel -> `T007` -> `T008`/`T009` -> `T010`).
- **User Story 1 (Phase 3 — P1 MVP)**: Can run in parallel with Phase 2 (`T011` -> `T012`).
- **User Story 2 (Phase 4 — P1)**: Depends on Phase 2 (`T013`/`T014` in parallel -> `T015` -> `T016`; `T017` -> `T018`).
- **User Story 3 (Phase 5 — P1)**: Depends on Phase 2 (`T019`/`T020` -> `T021` -> `T022` -> `T023`).
- **Polish (Phase 6)**: Depends on Phases 1–5 (`T024` -> `T025`).

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 (Migration + Localization) + Phase 3 (US1: Direct navigation from `CoachPanelContent` to `TeamRosterDetailScreen`).
2. Complete Phase 2 (Join Request Domain & Repositories) + Phase 4 (US2: Player Search, Join Requests & Profile Inbox).
3. Complete Phase 5 (US3: 11-player quota validation & Coach eligibility approval) + Phase 6 (Verification).
