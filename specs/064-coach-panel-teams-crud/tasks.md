# Tasks: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

**Input**: Design documents from `/specs/064-coach-panel-teams-crud/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/064-coach-panel-teams-crud/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/064-coach-panel-teams-crud/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/064-coach-panel-teams-crud/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/064-coach-panel-teams-crud/data-model.md), [coach-panel-teams-crud-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/064-coach-panel-teams-crud/contracts/coach-panel-teams-crud-contracts.md)

**Tests**: Included per Project Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad — NON-NEGOTIABLE*).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`)
- All file paths are relative to repository root.

---

## Phase 1: Setup & Localization

**Purpose**: Prepare Spanish localization strings for team listing, edit mode, and safe deletion dialogs/errors.

- [X] T001 Add Spanish l10n keys for Coach Panel team cards, edit mode (`editTeamScreenTitle`, `editTeamSubmitButton`, `editTeamSuccessMessage`, `editTeamTournamentLockedHelper`), and delete confirmation/error messages (`coachPanelEditTeamAction`, `coachPanelDeleteTeamAction`, `coachPanelAddAnotherTeamAction`, `coachPanelDeleteTeamTitle`, `coachPanelDeleteTeamMessage`, `coachPanelDeleteTeamConfirm`, `coachPanelDeleteTeamSuccess`, `coachPanelDeleteTeamBlockedTournament`, `coachPanelDeleteTeamBlockedMatches`) in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain error code and strict coach-ownership filtering before UI & CRUD flows.

- [X] T002 [P] Add `teamInActiveOrFinishedTournament` to `TeamEligibilityErrorCode` in `lib/domain/failures/app_failure.dart` for blocking deletion of teams enrolled in `inProgress` or `finished` tournaments
- [X] T003 Update `coachTeamsProvider` in `lib/application/providers/teams_providers.dart` to filter strictly by `team.coachId == currentCoachId` whenever `authState.session?.user.id` is non-empty (only falling back to `'coach-seed-1'` when there is no active session)

**Checkpoint**: Ownership filtering and domain failure codes ready — user stories can now proceed.

---

## Phase 3: User Story 1 - Listado Exclusivo y Selección de Equipos Creados en el Panel Técnico (Priority: P1) 🎯 MVP

**Goal**: Show all teams created by the authenticated coach in `CoachPanelContent` with circular crest, club metadata, reactive selection switching, and persistent button to register an additional team.

**Independent Test**: Authenticate as a coach with 2+ teams (plus teams from other coaches), open `/panel`, verify only the coach's teams appear, tap a second team to confirm metrics/next match/roster update reactively, and verify the button to create another team remains visible.

### Tests for User Story 1

- [X] T004 [P] [US1] Update `test/application/providers/coach_teams_provider_test.dart` to verify that an authenticated coach only sees teams matching their `user.id` and never sees `'coach-seed-1'` or other coaches' teams

### Implementation for User Story 1

- [X] T005 [US1] Update `CoachPanelContent` in `lib/presentation/panel/widgets/coach_panel_content.dart` to render the list of all `coachTeams` with circular `KickPulseTeamCrest`, name, `shortCode`, delegate, distinctive color indicators, squad count, active selection highlight (`teamsState.selectedTeamId` falling back to `coachTeams.first`), tap-to-select via `TeamsController.selectTeam`, and a visible "Registrar equipo" button when 1+ teams exist
- [X] T006 [P] [US1] Add widget tests for `CoachPanelContent` multi-team listing, exclusive coach filtering, empty state CTA, additional team creation button, and reactive team switching in `test/widget/coach_panel_teams_crud_test.dart`

**Checkpoint**: User Story 1 is independently functional and testable (MVP).

---

## Phase 4: User Story 2 - Edición de Equipos Creados desde el Panel Técnico (Priority: P2)

**Goal**: Allow the owner coach to edit any of their teams from `CoachPanelContent` using `CreateTeamScreen` in edit mode with prefilled fields, circular crest, read-only tournament lock when `inProgress`/`finished`, `single-flight` save, and offline-first sync.

**Independent Test**: Tap "Editar" on a team card in `CoachPanelContent`, verify all fields and crest are prefilled (and tournament is locked if `inProgress`/`finished`), modify valid fields, tap "Guardar cambios", and verify local/remote persistence and updated card in `/panel`.

### Implementation for User Story 2

- [X] T007 [P] [US2] Update `ManageTeamsEligibilityUseCase.registerOrUpdateTeam` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` to enforce owner check (`actorRole == UserRole.organizer || team.coachId == actorUserId`) when updating an existing team, exclude `team.id` from `normalizedName` uniqueness checks, and permit updating club details when already enrolled in an `inProgress`/`finished` tournament without changing `tournamentId`
- [X] T008 [P] [US2] Add `updateTeam(...)` in `lib/application/controllers/teams_controller.dart` with `single-flight` (`state.isSaving`) protection, preserving `crestUrl`, `coachId`, and `selectedTeamId` on the updated team
- [X] T009 [US2] Extend `CreateTeamScreen` in `lib/presentation/teams/create_team_screen.dart` to accept `TournamentTeam? initialTeam`, prefill `name`, `shortCode`, `delegateName`, `foundedDate`, `primaryColorHex`, `secondaryColorHex`, `selectedTournamentId`, and existing circular crest (`_existingRemoteCrestUrl` / `_localCrestPath`), lock the tournament dropdown as read-only when `initialTeam` belongs to an `inProgress` or `finished` tournament (`FR-006`), show edit title/button ("Guardar cambios"), and submit via `TeamsController.updateTeam`
- [X] T010 [US2] Register `/teams/edit` (passing `TournamentTeam` argument) in `lib/presentation/navigation/app_router.dart` and wire the **Editar** action (≥ 48×48 dp touch target) on each team card in `lib/presentation/panel/widgets/coach_panel_content.dart`

### Tests for User Story 2

- [X] T011 [P] [US2] Add unit and widget tests for edit ownership validation, normalized name exclusion, `single-flight` `updateTeam`, prefilled edit form, and read-only tournament lock on `inProgress`/`finished` tournaments in `test/unit/application/manage_teams_eligibility_use_case_test.dart`, `test/unit/application/teams_controller_test.dart`, and `test/widget/create_team_screen_test.dart`

**Checkpoint**: User Story 2 is independently functional and testable.

---

## Phase 5: User Story 3 - Eliminación Segura de Equipos Creados con Confirmación (Priority: P3)

**Goal**: Allow the owner coach to delete an autonomous or `openRegistration` (match-free) team after explicit Spanish confirmation, blocking deletion when enrolled in `inProgress`/`finished` tournaments or having matches, with offline-first persistence.

**Independent Test**: Tap "Eliminar" on a team card, verify Cancel keeps the team, verify Confirm deletes an autonomous/match-free team from local & remote storage and adjusts `selectedTeamId` (or shows empty state), and verify blocked deletion shows a clear Spanish message when the team has matches or an active/finished tournament.

### Implementation for User Story 3

- [X] T012 [P] [US3] Update `PostgrestTeamsRemoteDataSource.deleteById` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` to delete the `tournament_teams` enrollment (if present) and remove the parent `teams` record when matching/unreferenced so both autonomous and enrolled teams are deleted in Supabase
- [X] T013 [P] [US3] Add `deleteCoachTeam(...)` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` enforcing owner permission (`actorRole == UserRole.organizer || team.coachId == actorUserId`), blocking deletion if `tournament != null && tournament.status != TournamentStatus.openRegistration` or if any match in `_matchesRepository` involves `team.id` (`FR-010`), and calling `_repository.deleteTeam(team.id)`
- [X] T014 [US3] Add `deleteCoachTeam(...)` in `lib/application/controllers/teams_controller.dart` with `single-flight` (`state.isSaving`) guard, reloading teams and adjusting `selectedTeamId` to the next remaining team (or `null`)
- [X] T015 [US3] Wire the **Eliminar** action (≥ 48×48 dp touch target) and Spanish `AlertDialog` confirmation (team name + irreversible warning + Cancelar / Eliminar) with Spanish success/error SnackBar feedback in `lib/presentation/panel/widgets/coach_panel_content.dart`

### Tests for User Story 3

- [X] T016 [P] [US3] Add unit and widget tests for owner validation, blocked deletion on `inProgress`/`finished` tournaments or matches, cancel confirmation, confirmed deletion, `selectedTeamId` re-selection, and empty-state transition in `test/unit/application/manage_teams_eligibility_use_case_test.dart`, `test/unit/application/teams_controller_test.dart`, and `test/widget/coach_panel_teams_crud_test.dart`

**Checkpoint**: All user stories (US1, US2, US3) are independently functional and verified.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Final static analysis and full test suite verification across the repository.

- [X] T017 Run `flutter analyze` and `flutter test` across the full suite to verify zero analyzer warnings/errors and 100% passing tests

---

## Dependencies & Execution Order

- **Phase 1 (`T001`)** -> must complete before UI tasks (`T005`, `T009`, `T015`) use the new `AppLocalizations` getters.
- **Phase 2 (`T002`, `T003`)** -> blocks `T004`, `T005`, `T013`.
- **Phase 3 (US1: `T004`–`T006`)** -> MVP; can be tested independently right after Phase 2.
- **Phase 4 (US2: `T007`–`T011`)** -> `T007` and `T008` can run in parallel, then `T009` and `T010`, then `T011`.
- **Phase 5 (US3: `T012`–`T016`)** -> `T012` and `T013` can run in parallel, then `T014`, then `T015`, then `T016`.
- **Phase 6 (`T017`)** -> runs after all implementation and test tasks complete.

## Parallel Execution Examples

- `T007`, `T008`, `T012`, `T013` modify distinct files (`manage_teams_eligibility_use_case.dart`, `teams_controller.dart`, `hybrid_teams_repository.dart`) and can be batched cleanly.
- `T004`, `T006`, `T011`, `T016` target separate test files and can run in parallel per phase.
