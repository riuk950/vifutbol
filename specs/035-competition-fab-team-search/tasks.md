---

description: "Task list for HU 18.4: Inscripción de Equipos mediante FAB Menu con Buscador en Detalles de Competición"
---

# Tasks: Inscripción de Equipos mediante FAB Menu con Buscador en Detalles de Competición (HU 18.4)

**Input**: Design documents from `/specs/035-competition-fab-team-search/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/competition-fab-team-search-contracts.md`, `quickstart.md`

**Tests**: Required by Constitution Principle III (automated unit & widget tests written first in TDD order).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`)
- Every task includes exact repository file paths

---

## Phase 1: Setup (Localization & Shared Foundation)

**Purpose**: Prepare Spanish UI localization keys and confirm clean generator state before application/UI work.

- [X] T001 Add Spanish l10n keys (`competitionFabAddTeamsLabel`, `addTeamsModalTitle`, `addTeamsModalSubtitle`, `addTeamsSearchHint`, `addTeamsActionAdd`, `addTeamsStatusEnrolledBadge`, `addTeamsEmptyCatalogTitle`, `addTeamsEmptyCatalogMessage`, `addTeamsEmptySearchMessage`, `addTeamsClearSearchAction`, `addTeamsEnrollSuccess`, `addTeamsEnrollSuccessSkippedPlayers`, `addTeamsDuplicateError`, `addTeamsPlayersCountMeta`) to lib/l10n/app_es.arb
- [X] T002 Regenerate `AppLocalizations` Dart classes by running `flutter gen-l10n` affecting lib/l10n/app_localizations.dart and lib/l10n/app_localizations_es.dart (depends on T001)

---

## Phase 2: Foundational (Search Normalization, Group Balancing & Catalog Enrollment Use Case)

**Purpose**: Core application and domain logic required by US2 and US3 before building UI flows.

**⚠️ CRITICAL**: No US2 or US3 integration work can complete until this phase is ready.

- [X] T003 [P] Add diacritic-insensitive team search test cases (including grave/circumflex/tilde vowels `'àèìòùâêîôûãõç'`, `"Atlético del Sur"`, `"Águilas FC"`, and case-insensitive short-code matching) in test/unit/application/search_utils_test.dart
- [X] T004 Extend `normalizeSearchText` diacritic mapping (`'àèìòùâêîôûãõç'`) and add `matchesTeamQuery(name, shortCode, query)` helper in lib/application/utils/search_utils.dart (depends on T003)
- [X] T005 [P] Write unit tests for `ManageTeamsEligibilityUseCase.enrollExistingTeamFromCatalog` verifying `RoleCapability.manageTournaments` guard, `tournament.status.isEditable` guard, duplicate team name rejection (`normalizedName` and `normalizeSearchText`), least-populated group auto-assignment for `TournamentFormat.mixedGroupsAndKnockout`, copying identity + non-conflicting players forced to `isEligible: false` with `TeamEligibilityStatus.pendingVerification`, and skipping/counting conflicting `normalizedDocumentId` players or `maxPlayersPerTeam` overflow in test/application/use_cases/enroll_existing_team_from_catalog_test.dart
- [X] T006 Add `resolveLeastPopulatedGroupName` static helper in lib/domain/services/standings_calculator_service.dart and refactor group counting in lib/presentation/tournaments/widgets/competition_enroll_team_dialog.dart to reuse it without duplicating logic
- [X] T007 Implement `EnrollExistingTeamResult` (`enrolledTeam`, `copiedPlayersCount`, `skippedConflictingPlayersCount`, `assignedGroupName`) and `enrollExistingTeamFromCatalog` (validating `name.trim().length >= 3`, `shortCode.trim().length` in `2..4`, diacritic/case-insensitive uniqueness, mixed-format least-populated group via `StandingsCalculatorService.resolveLeastPopulatedGroupName`, conflict-filtered players marked `isEligible: false`, and `TeamEligibilityStatus.pendingVerification`) in lib/application/use_cases/manage_teams_eligibility_use_case.dart (depends on T004, T005, T006)
- [X] T008 Implement `TeamsController.enrollExistingTeamFromCatalog` with single-flight `state.isSaving` guard, repository reload, and `AppFailure` state capture in lib/application/controllers/teams_controller.dart (depends on T007)

**Checkpoint**: Foundation ready — search normalization, group balancing, and transactional catalog enrollment are tested and decoupled.

---

## Phase 3: User Story 1 - Menú Flotante Expandible de Acciones de Competición (Priority: P1) 🎯 MVP

**Goal**: Provide an organizer-only expandable FAB Menu on editable competitions offering `"Generar Fixture"` (when `!hasFixture`) and `"Agregar Equipos"` (always while editable).

**Independent Test**: Open `CompetitionDetailScreen` as `UserRole.organizer` on an editable tournament without fixture, tap `competition_detail_fab_menu`, verify both `"Generar Fixture"` and `"Agregar Equipos"` appear within `<= 120ms`, verify `"Generar Fixture"` disappears when `hasFixture == true` while `"Agregar Equipos"` remains visible, and confirm FAB is hidden for `finished` status or non-organizer roles.

### Tests for User Story 1

- [X] T009 [P] [US1] Create widget tests covering `CompetitionDetailFabMenu` visibility, role segregation (`organizer` vs `coach`/`referee`/`player`/`fan`), `finished` hiding, expandable options (`competition_detail_fab_generate_fixture`, `competition_detail_fab_add_team`), collapsing after selection, and keeping `"Agregar Equipos"` visible when `hasFixture == true` in test/presentation/tournaments/competition_detail_fab_menu_test.dart and remove obsolete test/presentation/tournaments/competition_detail_fab_simplification_test.dart

### Implementation for User Story 1

- [X] T010 [US1] Implement `CompetitionDetailFabMenu` widget (`Key('competition_detail_fab_menu')`, `120ms` animation `< 150ms`, `Key('competition_detail_fab_generate_fixture')` gated by `showGenerateFixture`, `Key('competition_detail_fab_add_team')`, KickPulse tokens, and collapse-on-action behavior) in lib/presentation/tournaments/widgets/competition_detail_fab_menu.dart (depends on T002, T009)
- [X] T011 [US1] Replace single FAB in `CompetitionDetailScreen._buildFloatingActionButton` with `CompetitionDetailFabMenu` checking `RoleCapability.manageTournaments`, `tournament.status.isEditable`, and `showGenerateFixture: !hasFixture` in lib/presentation/tournaments/competition_detail_screen.dart (depends on T010)

**Checkpoint**: User Story 1 works independently — Organizer can expand/collapse the FAB Menu and trigger fixture generation with strict role and state boundaries.

---

## Phase 4: User Story 2 - Modal de Selección de Equipos con Buscador en Tiempo Real (Priority: P1) 🎯 MVP

**Goal**: Open a bottom-sheet modal from `"Agregar Equipos"` displaying a top search bar (`KickPulseSearchBar`) and the alphabetically sorted deduplicated catalog of platform teams filtered in real time ignoring case and diacritics.

**Independent Test**: Tap `"Agregar Equipos"` from the FAB menu, verify `add_teams_modal` opens with `add_teams_search_field` at the top and deduplicated teams sorted alphabetically, type `"atletico"` or `"AGUILAS"` and verify instant matching against `"Atlético del Sur"` / `"Águilas FC"`, and verify empty catalog + empty search with clear-filter action (`add_teams_clear_filter_button`).

### Tests for User Story 2

- [X] T012 [P] [US2] Write widget tests for modal opening from FAB, alphabetical deduplication across tournaments (preferring richest roster then latest `updatedAt`), real-time case/diacritic-insensitive search by name and shortCode, empty catalog state (`add_teams_empty_catalog_state`), empty search state with `add_teams_clear_filter_button`, and modal close discarding temporary query in test/presentation/tournaments/add_teams_to_competition_modal_test.dart

### Implementation for User Story 2

- [X] T013 [US2] Implement `CatalogTeamEntry` deduplication helper and `AddTeamsToCompetitionModal` layout (`Key('add_teams_modal')`, `Key('add_teams_modal_close_button')`, `KickPulseSearchBar` with `Key('add_teams_search_field')`, `Key('add_teams_catalog_list')`, `Key('add_teams_catalog_item_<id>')`, empty catalog state `Key('add_teams_empty_catalog_state')`, empty search state `Key('add_teams_empty_search_state')` + `Key('add_teams_clear_filter_button')`, `useSafeArea: true`, `isScrollControlled: true`) in lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart (depends on T002, T004, T012)
- [X] T014 [US2] Connect `onAddTeams` callback in `CompetitionDetailScreen` to `AddTeamsToCompetitionModal.show(context, tournament: tournament)` in lib/presentation/tournaments/competition_detail_screen.dart (depends on T011, T013)

**Checkpoint**: User Stories 1 and 2 work end-to-end — Organizer opens the searchable modal catalog from the FAB Menu and searches seamlessly without accents or case sensitivity.

---

## Phase 5: User Story 3 - Inscripción de Equipos sin Duplicidad y con Estado Inicial Pendiente (Priority: P2)

**Goal**: Allow tapping `"Agregar"` on any available catalog team to enroll it immediately in `TeamEligibilityStatus.pendingVerification` (with conflict-filtered pending players and least-populated group assignment), keep the modal open preserving the search query, update the row to `"Inscrito"` disabled, and reflect reactively in `CompetitionTeamsTabView`.

**Independent Test**: Open modal for an editable tournament containing one enrolled team and two catalog teams; confirm enrolled team displays `"Inscrito"` badge (`add_teams_enrolled_badge_*`) and disabled button; tap `"Agregar"` on an available team; confirm `pendingVerification` enrollment, modal stays open with search text preserved, card switches to `"Inscrito"` disabled, conflicting-player warning appears when applicable, double-tap produces only one record, and `CompetitionTeamsTabView` displays the newly enrolled team immediately.

### Tests for User Story 3

- [X] T015 [P] [US3] Extend widget & reactive integration tests in test/presentation/tournaments/add_teams_to_competition_modal_test.dart verifying `"Inscrito"` badge + disabled button for already enrolled teams (matching by `id` or diacritic/case-insensitive name), enrollment via `"Agregar"` keeping modal open and preserving `_searchQuery`, card transition to `"Inscrito"`, double-tap prevention, conflicting-player omitted count feedback, and reactive update in `CompetitionTeamsTabView`

### Implementation for User Story 3

- [X] T016 [US3] Wire reactive enrollment state (`isEnrolledInCurrentTournament`), `"Inscrito"` `KickPulseBadge` (`Key('add_teams_enrolled_badge_<id>')`), disabled/loading action button (`Key('add_teams_action_button_<id>')`), `_enrollingTeamKeys` + `teamsState.isSaving` double-tap guard, `teamsControllerProvider.notifier.enrollExistingTeamFromCatalog` invocation, and `SnackBar` confirmation/omitted-players feedback preserving `_searchQuery` in lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart (depends on T008, T013, T015)

**Checkpoint**: All user stories (`US1`, `US2`, `US3`) are complete, verified, and reactively synchronized across modal and `Equipos` tab.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final static quality gates, formatting, and full verification suite execution.

- [X] T017 [P] Run `dart format --output=none --set-exit-if-changed lib/ test/` and `flutter analyze` across the workspace ensuring zero formatting diffs, warnings, or errors
- [X] T018 Execute targeted unit tests (`test/unit/application/search_utils_test.dart`, `test/application/use_cases/enroll_existing_team_from_catalog_test.dart`) and presentation tests (`test/presentation/tournaments/competition_detail_fab_menu_test.dart`, `test/presentation/tournaments/add_teams_to_competition_modal_test.dart`, `test/presentation/tournaments/`) per specs/035-competition-fab-team-search/quickstart.md (depends on T017)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately (`T001` -> `T002`).
- **Phase 2 (Foundational)**: Starts after `T001`/`T002` (`T003`, `T005` can run in parallel; `T007` and `T008` depend on `T004`/`T005`/`T006`).
- **Phase 3 (US1 - P1 MVP)**: Can start as soon as `T002` completes (`T009` -> `T010` -> `T011`), independent of Phase 2 logic!
- **Phase 4 (US2 - P1 MVP)**: Depends on `T002`, `T004`, and `T011` (`T012` -> `T013` -> `T014`).
- **Phase 5 (US3 - P2)**: Depends on Phase 2 (`T008`) and Phase 4 (`T013`) (`T015` -> `T016`).
- **Phase 6 (Polish)**: Depends on completion of `US1`, `US2`, and `US3` (`T017` -> `T018`).

### Parallel Opportunities

- **Within Phase 2**: `T003` (search tests), `T005` (use case tests), and `T006` (domain group balancing helper) operate on separate files and can run in parallel.
- **Cross-Story Parallelism**: Once `T002` finishes, `US1` (`T009`..`T011`) can proceed in parallel with Phase 2 (`T003`..`T008`).
- **Within US2 & US3**: Test creation tasks (`T012`, `T015`) isolate cleanly before widget updates (`T013`, `T016`).

---

## Parallel Example: Foundational + User Story 1

```bash
# After T002 (l10n generation):
Task T003: "Add diacritic-insensitive team search test cases in test/unit/application/search_utils_test.dart"
Task T005: "Write unit tests for enrollExistingTeamFromCatalog in test/application/use_cases/enroll_existing_team_from_catalog_test.dart"
Task T006: "Extract resolveLeastPopulatedGroupName helper in lib/domain/services/standings_calculator_service.dart"
Task T009: "Create FAB Menu widget tests in test/presentation/tournaments/competition_detail_fab_menu_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1 (`T001`–`T002`) + Phase 2 (`T003`–`T008`).
2. Complete Phase 3 (`US1`: FAB Menu) -> validate `competition_detail_fab_menu_test.dart`.
3. Complete Phase 4 (`US2`: Searchable Modal Catalog) -> validate search/filtering scenarios in `add_teams_to_competition_modal_test.dart`.
4. Complete Phase 5 (`US3`: Transactional Enrollment & Reactive Tab Update) + Phase 6 (`T017`–`T018`).

---

## Notes

- Every task references exact repository file paths and maintains strict English technical naming / Spanish `l10n` UI separation (Constitution Principle VI).
- Verify newly written TDD tests fail before implementing production logic and pass completely after Phase 6.
