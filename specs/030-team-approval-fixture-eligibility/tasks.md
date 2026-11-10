# Tasks: Aprobación de Equipos y Habilitación para Fixture con Mínimo 11 Jugadores (HU 16.3)

**Input**: Design documents from `/specs/030-team-approval-fixture-eligibility/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/team-approval-api.md`, `quickstart.md`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared state dependencies)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`)
- Includes exact file paths in every task description

---

## Phase 1: Setup (Shared Infrastructure & Localizations)

**Purpose**: Localization keys, test helpers, and baseline configuration.

- [X] T001 Add localized strings in Spanish to `lib/l10n/app_es.arb` (`teamEligibilityPendingVerification`, `teamEligibilityQuotaInsufficientTitle`, `teamEligibilityQuotaInsufficientMessage`, `teamEligibilityActionApprove`, `teamEligibilityActionRevoke`, `teamEligibilityActionUnderstood`, `competitionTeamPlayersIncomplete`, `competitionTeamPlayersComplete`, `competitionFixtureMinEligibleTeamsError`, `teamEligibilityRevokedSuccess`) and execute `flutter gen-l10n`
- [X] T002 [P] Create test fixtures and mock helpers for team approval in `test/test_helpers/teams_eligibility_test_helper.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain entity unification and backward-compatible model serialization.

**⚠️ CRITICAL**: Must be completed before User Stories 1, 2, and 3.

- [X] T003 [P] Unify `TeamEligibilityStatus` in `lib/domain/entities/team_enums.dart` into `pendingVerification` and `eligible`, with retrocompatible `fromJson` resolver mapping legacy `pendingQuota` and `readyForApproval` to `pendingVerification`
- [X] T004 [P] Update `TournamentTeam` in `lib/domain/entities/tournament_team.dart` with `isEligible` getter and ensure `fromJson`/`toJson`/`copyWith` support the unified `TeamEligibilityStatus`
- [X] T005 [P] Create unit tests in `test/domain/team_eligibility_status_test.dart` validating state transitions, `isEligible` helper, and JSON retrocompatibility
- [X] T006 Update existing codebase references across `lib/` and `test/` where `TeamEligibilityStatus.pendingQuota` or `readyForApproval` were directly referenced, updating them to `pendingVerification`

**Checkpoint**: Foundation ready - Domain layer unified and all existing tests passing.

---

## Phase 3: User Story 1 - Verificación de Cuota y Aprobación de Equipos (Priority: P1) 🎯 MVP

**Goal**: Enable tournament organizer to approve team eligibility strictly when squad has $\ge 11$ players, blocking insufficient squads with canonical warning dialog.

**Independent Test**: Can be tested independently by creating a team with 9 players (approval blocked with exact error message) and a team with 11 players (approved and transitioned to `eligible`).

### Tests for User Story 1

- [X] T007 [P] [US1] Create unit tests in `test/application/use_cases/manage_teams_eligibility_approval_test.dart` verifying `approveTeamEligibility` succeeds for $\ge 11$ players and throws `TeamEligibilityValidationFailure` with exact message "El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})" for $< 11$ players
- [X] T008 [P] [US1] Create widget tests in `test/presentation/tournaments/competition_teams_tab_view_approval_test.dart` verifying tapping "Habilitar Equipo" on incomplete squad opens `AlertDialog` with exact regulatory message and "Entendido" button, and succeeds on complete squad

### Implementation for User Story 1

- [X] T009 [US1] Refactor `approveTeamEligibility` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` to strictly validate `team.players.length >= 11`, require `RoleCapability.approveRegistrations`, and throw canonical Spanish failure message when quota is not met
- [X] T010 [US1] Add `approveTeamEligibility({required String teamId, required ChampionshipTournament tournament, required UserRole actorRole})` to `TeamsController` in `lib/application/controllers/teams_controller.dart`
- [X] T011 [US1] Implement "Habilitar Equipo" button and insufficient quota `AlertDialog` in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart` calling `approveTeamEligibility` on complete squads

**Checkpoint**: User Story 1 complete (MVP ready and verified).

---

## Phase 4: User Story 2 - Indicadores Visuales de Nómina y Control de Roles (Priority: P2)

**Goal**: Render transparent roster status counters (`X/11 jugadores - Incompleto` vs `X jugadores - Nómina válida`) and enforce role-based action visibility (hidden for non-organizers).

**Independent Test**: Can be tested independently by logging in as organizer, coach, referee, player, and fan, verifying roster count displays on all roles while action buttons remain visible only to organizer.

### Tests for User Story 2

- [X] T012 [P] [US2] Create widget tests in `test/presentation/tournaments/competition_teams_tab_view_role_visibility_test.dart` verifying roster count text formatting (`9/11 jugadores - Incompleto` vs `12 jugadores - Nómina válida`) and verifying approval/revocation buttons are hidden for `UserRole.coach`, `referee`, `player`, and `fan`

### Implementation for User Story 2

- [X] T013 [US2] Update team card in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart` to render dynamic roster count label using `l10n.competitionTeamPlayersIncomplete(count)` when $< 11$ and `l10n.competitionTeamPlayersComplete(count)` when $\ge 11$
- [X] T014 [US2] Gate action buttons in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart` strictly to `canManage` (`RoleCapability.approveRegistrations` / `UserRole.organizer`)
- [X] T015 [US2] Wrap team action buttons in a responsive `Wrap` container with `KickPulseRadiiSpacing.spaceXs` in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart`

**Checkpoint**: User Story 2 complete and integrated with US1.

---

## Phase 5: User Story 3 - Inhabilitación y Fixture Condicionado (Priority: P3)

**Goal**: Allow organizers to revoke team approval, auto-demote squads dropping below 11 players, and block fixture generation unless at least 2 teams are officially eligible.

**Independent Test**: Can be tested independently by revoking an eligible team (returns to `pendingVerification`), unenrolling a player from an 11-player eligible team (auto-demotes to `pendingVerification`), and attempting fixture generation with $< 2$ eligible teams (fails with exact message).

### Tests for User Story 3

- [X] T016 [P] [US3] Create unit tests in `test/application/use_cases/manage_teams_eligibility_revocation_test.dart` verifying `revokeTeamEligibility` transitions team to `pendingVerification` and player removal below 11 triggers automatic demotion
- [X] T017 [P] [US3] Create unit tests in `test/application/use_cases/fixture_scheduling_eligibility_filter_test.dart` verifying fixture generation compiles only eligible teams and throws `FixtureScheduleValidationFailure` with exact message "Se requieren al menos dos equipos habilitados con nómina completa" when eligible count $< 2$

### Implementation for User Story 3

- [X] T018 [US3] Implement `revokeTeamEligibility` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` and add method to `TeamsController` in `lib/application/controllers/teams_controller.dart`
- [X] T019 [US3] Implement automatic status demotion in `unenrollPlayerFromRoster` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` when an eligible team's squad drops below 11 players
- [X] T020 [US3] Update `FixtureSchedulingUseCase.generateRoundRobinFixture` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to strictly filter `t.tournamentId == tournament.id && t.isEligible` and validate `eligibleTeams.length >= 2` with canonical error message
- [X] T021 [US3] Wire "Inhabilitar" button in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart` with confirmation and feedback SnackBar

**Checkpoint**: All 3 user stories complete with end-to-end regulatory governance.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Responsive layout verification, static analysis, and full test suite regression.

- [X] T022 [P] Create responsive widget test in `test/presentation/tournaments/competition_teams_tab_view_responsive_test.dart` verifying `CompetitionTeamsTabView` at $320 \times 640\text{ px}$ with 130% text scaling with 0 RenderFlex overflows
- [X] T023 Execute `flutter analyze` and resolve any warnings or lint errors to maintain 0 issues
- [X] T024 Execute all feature test suites in `quickstart.md` (`flutter test test/domain/ test/application/ test/presentation/`) to verify 100% green pass rate

---

## Dependencies & Execution Order

```text
Phase 1: Setup (T001, T002)
   ↓
Phase 2: Foundational (T003, T004, T005, T006)
   ↓
Phase 3: User Story 1 (T007 - T011) [MVP]
   ↓
Phase 4: User Story 2 (T012 - T015)
   ↓
Phase 5: User Story 3 (T016 - T021)
   ↓
Phase 6: Polish (T022, T023, T024)
```

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (Foundational). Has no dependencies on other user stories. Delivers MVP.
- **User Story 2 (P2)**: Depends on Phase 2. Integrates with US1 UI entry points.
- **User Story 3 (P3)**: Depends on Phase 2. Closes the eligibility lifecycle and secures fixture scheduling.
- **Polish (Phase 6)**: Depends on completion of US1, US2, and US3.

---

## Parallel Opportunities

- **Phase 1**: T001 and T002 can run in parallel.
- **Phase 2**: T003, T004, T005 can run in parallel before T006.
- **Phase 3**: Tests T007 and T008 can run in parallel before implementation.
- **Phase 4**: Test T012 can run in parallel before implementation.
- **Phase 5**: Tests T016 and T017 can run in parallel before implementation.
- **Phase 6**: T022 can run in parallel before final analysis and regression run.
