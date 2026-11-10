# Tasks: Coach Team & Roster Governance

**Input**: Design documents from `/specs/029-coach-team-roster-governance/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to ([US1], [US2], [US3])
- Include exact file paths in descriptions

---

## Phase 1: Setup (Localization & Shared Assets)

**Purpose**: Register all Spanish UI strings and localization tokens required across the feature.

- [X] T001 [P] Add Spanish localization keys for coach team governance (`coachNoTeamTitle`, `coachNoTeamDescription`, `coachActionRegisterTeamEmpty`, `createTeamDialogTitle`, `createTeamNameLabel`, `createTeamShortCodeLabel`, `createTeamTournamentLabel`, `createTeamNoTournamentOption`, `createTeamSubmitAction`, `createTeamSuccessMessage`, `unauthorizedTeamCreationMessage`) in `lib/l10n/app_es.arb`
- [X] T002 Generate localized Dart files by executing `flutter gen-l10n` to update `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Entities & Domain Access Matrix)

**Purpose**: Update core entities and pure domain access matrix that block all user stories.

**⚠️ CRITICAL**: Must complete before user story implementation begins.

- [X] T003 [P] Update `TournamentTeam` in `lib/domain/entities/tournament_team.dart` to add optional `coachId: String?` (defaulting to `'coach-seed-1'`), allow optional `tournamentId` (defaulting to `''`), update `copyWith`, `toJson`, and `fromJson` with retrocompatible fallbacks
- [X] T004 [P] Update `RolePermissionMatrix` in `lib/domain/entities/role_permission_matrix.dart` ensuring `RoleCapability.manageTeamRoster` is strictly exclusive to `UserRole.coach` and verify capabilities for all 5 roles
- [X] T005 [P] Create unit tests in `test/domain/tournament_team_coach_test.dart` validating `TournamentTeam` constructor, `coachId` persistence, JSON serialization roundtrip, and equality
- [X] T006 [P] Update domain unit tests in `test/domain/role_permission_matrix_test.dart` validating that only `UserRole.coach` has `RoleCapability.manageTeamRoster` and all other roles are excluded

**Checkpoint**: Foundation ready - domain models and matrix verified.

---

## Phase 3: User Story 1 - Coach Team Creation & Roster Management (Priority: P1) 🎯 MVP

**Goal**: Authenticated coaches can create autonomous or tournament-enrolled teams via a dedicated modal (`CreateTeamDialog`) and manage their squad roster from the Coach Panel.

**Independent Test**: Sign in as a coach, open Coach Panel or Teams Directory, tap create team, fill the dialog, and verify the team is created, linked to `coachId`, and displayed in the Coach Panel.

### Tests for User Story 1

- [X] T007 [P] [US1] Create widget test in `test/presentation/teams/create_team_dialog_test.dart` validating `CreateTeamDialog` form inputs, validation rules (name $\ge 3$, shortCode 2–4 uppercase), optional tournament dropdown, and submission
- [X] T008 [P] [US1] Create unit test in `test/application/providers/coach_teams_provider_test.dart` validating that `coachTeamsProvider` filters teams matching `team.coachId == currentCoachId || team.coachId == 'coach-seed-1'`
- [X] T009 [P] [US1] Create widget test in `test/presentation/panel/coach_panel_empty_state_test.dart` verifying that `CoachPanelContent` renders `coach_no_team_card` with `coach_action_register_team_empty` when no teams exist, and renders squad metrics when a team is created

### Implementation for User Story 1

- [X] T010 [P] [US1] Create modal dialog widget `CreateTeamDialog` in `lib/presentation/teams/dialogs/create_team_dialog.dart` with name field, short code field, tournament selector dropdown, and `KickPulseButton` submission
- [X] T011 [US1] Implement `createTeam` method in `TeamsController` in `lib/application/controllers/teams_controller.dart` assigning `coachId` from session and updating catalog state
- [X] T012 [P] [US1] Add reactive `coachTeamsProvider` in `lib/application/providers/teams_providers.dart` filtering teams by active coach session ID with safe test fallback
- [X] T013 [US1] Update `CoachPanelContent` in `lib/presentation/panel/widgets/coach_panel_content.dart` to watch `coachTeamsProvider`, display `coach_no_team_card` with `coach_action_register_team_empty` when empty, and wire button to open `CreateTeamDialog`
- [X] T014 [US1] Update `TeamsDirectoryScreen` in `lib/presentation/directories/teams_directory_screen.dart` to open `CreateTeamDialog` when `create_team_from_directory_button` is pressed by a coach

**Checkpoint**: User Story 1 functional and independently testable as an MVP.

---

## Phase 4: User Story 2 - Strict Access Restriction for Non-Coach Roles in UI (Priority: P2)

**Goal**: Hide all team creation and player registration actions in UI for non-coach roles (`organizer`, `referee`, `player`, `fan`) and simplify the Organizer's FAB in `CompetitionDetailScreen`.

**Independent Test**: Sign in as organizer, referee, player, or fan, navigate to Teams Directory, Players Directory, and Competition Detail, verifying that all team/player creation buttons are absent.

### Tests for User Story 2

- [X] T015 [P] [US2] Create widget tests in `test/presentation/directories/teams_directory_role_visibility_test.dart` asserting that `create_team_from_directory_button` is visible ONLY for `UserRole.coach` and hidden for all other 4 roles
- [X] T016 [P] [US2] Create widget tests in `test/presentation/directories/players_directory_role_visibility_test.dart` asserting that `register_player_from_directory_button` is visible ONLY for `UserRole.coach` and hidden for all other 4 roles
- [X] T017 [P] [US2] Create widget test in `test/presentation/tournaments/competition_detail_fab_simplification_test.dart` asserting that `CompetitionDetailScreen` displays direct `competition_detail_fab_generate_fixture` for editable tournaments without fixtures and completely removes `competition_detail_fab_add_team` and speed dial menu

### Implementation for User Story 2

- [X] T018 [US2] Update `TeamsDirectoryScreen` in `lib/presentation/directories/teams_directory_screen.dart` so `canRegisterTeams` strictly checks `activeUserRole == UserRole.coach` (or `capabilities.contains(RoleCapability.manageTeamRoster)`)
- [X] T019 [US2] Update `PlayersDirectoryScreen` in `lib/presentation/directories/players_directory_screen.dart` so `canRegisterPlayers` strictly checks `activeUserRole == UserRole.coach`
- [X] T020 [US2] Update `TournamentTeamsSection` in `lib/presentation/teams/widgets/tournament_teams_section.dart` so `canRegisterTeams` strictly checks `actorRole == UserRole.coach`
- [X] T021 [US2] Refactor `_buildFloatingActionButton` in `lib/presentation/tournaments/competition_detail_screen.dart` to remove speed dial and render direct `FloatingActionButton` with key `competition_detail_fab_generate_fixture` when editable and fixture is missing

**Checkpoint**: User Stories 1 and 2 functional and independently testable.

---

## Phase 5: User Story 3 - Domain-Level Authorization Enforcement & Error Messaging (Priority: P3)

**Goal**: Reject any unauthorized team creation or player addition use case invocation at the domain layer with the exact message "Solo los entrenadores pueden registrar equipos o futbolistas".

**Independent Test**: Invoke `ManageTeamsEligibilityUseCase.registerOrUpdateTeam` and `enrollPlayerInRoster` with non-coach roles, verifying an `UnauthorizedRoleFailure` is thrown.

### Tests for User Story 3

- [X] T022 [P] [US3] Create unit tests in `test/application/use_cases/manage_teams_eligibility_use_case_governance_test.dart` testing role enforcement for `registerOrUpdateTeam` and `enrollPlayerInRoster`, verifying `UnauthorizedRoleFailure` with message "Solo los entrenadores pueden registrar equipos o futbolistas" for organizer, referee, player, and fan

### Implementation for User Story 3

- [X] T023 [US3] Refactor `_ensureRosterManagementPermission` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` to strictly check `RolePermissionMatrix.hasCapability(role, RoleCapability.manageTeamRoster)` and throw `UnauthorizedRoleFailure('Solo los entrenadores pueden registrar equipos o futbolistas')`
- [X] T024 [US3] Update existing unit test assertions across `test/widget/` and `test/presentation/` where organizer previously registered teams to use `UserRole.coach` or appropriate role separation

**Checkpoint**: All 3 user stories complete with defense-in-depth security.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end integration, anti-overflow verification, static analysis, and documentation.

- [X] T025 [P] Create responsive widget test in `test/presentation/panel/coach_panel_responsive_test.dart` verifying `CoachPanelContent` and `CreateTeamDialog` at $320 \times 640\text{ px}$ with 130% text scaling with 0 RenderFlex overflows
- [X] T026 Execute `flutter analyze` and resolve any warnings or lint errors to maintain 0 issues
- [X] T027 Execute all feature test suites in `quickstart.md` (`flutter test test/domain/ test/application/ test/presentation/`) to verify 100% green pass rate

---

## Dependencies & Execution Order

```text
Phase 1: Setup (T001, T002)
   ↓
Phase 2: Foundational (T003, T004, T005, T006)
   ↓
Phase 3: User Story 1 (T007 - T014) [MVP]
   ↓
Phase 4: User Story 2 (T015 - T021)
   ↓
Phase 5: User Story 3 (T022 - T024)
   ↓
Phase 6: Polish (T025, T026, T027)
```

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (Foundational). Has no dependencies on other user stories. Delivers MVP.
- **User Story 2 (P2)**: Depends on Phase 2. Can be worked in parallel with US1, integrates with US1 UI entry points.
- **User Story 3 (P3)**: Depends on Phase 2. Secures use cases implemented in US1 and restricted in US2.
- **Polish (Phase 6)**: Depends on completion of US1, US2, and US3.

---

## Parallel Opportunities

- **Phase 1**: T001 and T002 run sequentially for build step.
- **Phase 2**: T003, T004, T005, T006 can run in parallel.
- **Phase 3**: Tests T007, T008, T009 can run in parallel before implementation.
- **Phase 4**: Tests T015, T016, T017 can run in parallel.
- **Phase 5**: T022 test runs in parallel before use case refactor.
