# Tasks: Carga y Selección de Equipos del Catálogo Global en Competición (HU 18.5)

**Input**: Design documents from `/specs/043-competition-fab-catalog-enrollment/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/catalog_enrollment_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III and HU 18.5 Definition of Done (unit tests for global catalog loading/enrollment + widget tests for `AddTeamsToCompetitionModal`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Localization keys and generated localization artifacts required across all user stories

- [X] T001 Update `addTeamsEmptyCatalogMessage` to `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."` and add `addTeamsDefaultCategoryLabel` (`"Categoría libre"`) and `addTeamsCoachMeta` (`"DT: {coachName}"`) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain entity extension and remote data source global catalog merge that block user story UI and tests

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Extend `TournamentTeam` with optional `coachName` (`String?`) and `categoryLabel` (`String?`) fields, updating constructor, `copyWith`, `toJson`, and `fromJson` in `lib/domain/entities/tournament_team.dart`
- [X] T004 Update `PostgrestTeamsRemoteDataSource.fetchAll()` and `_fromEnrollmentRow()` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` to query both `vifutboldev.tournament_teams` (with `teams(*, user_accounts(full_name))` and `tournaments(name, category)`) and `vifutboldev.teams` (with `user_accounts(full_name)`), merging standalone clubs without prior tournament enrollments (`tournamentId: ''`, `players: const []`) and resolving `categoryLabel` and `coachName`

**Checkpoint**: Foundation ready — user story implementation and testing can now proceed

---

## Phase 3: User Story 1 - Carga del Catálogo Global e Inscripción de Equipos Preexistentes (Priority: P1) 🎯 MVP

**Goal**: Load the complete global catalog (`loadTeams()`) on opening `AddTeamsToCompetitionModal`, display crest, official name, category (`"Categoría libre"` fallback), player count, and optional coach name (`"DT: <Nombre>"` only when resolved), and enroll clubs in `"Pendiente de verificación"` while keeping the modal open and reactively updating `CompetitionTeamsTabView`.

**Independent Test**: Verify unit and widget tests for global catalog merging (including standalone clubs without prior tournaments), metadata rendering, and reactive enrollment into `pendingVerification`.

### Tests for User Story 1

- [X] T005 [P] [US1] Add unit tests in `test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart` verifying `fetchAll()` / `loadTeams()` merges standalone clubs from `teams` with enrolled rows from `tournament_teams` and populates `categoryLabel` and `coachName`
- [X] T006 [P] [US1] Add unit and widget tests in `test/presentation/tournaments/add_teams_to_competition_modal_test.dart` verifying `AddTeamsToCompetitionModal` triggers `loadTeams()` on open, lists standalone + cross-tournament clubs, renders category (`"Categoría libre"` when unassigned) and resolved coach name (omitting coach line when `coachName` is null/empty), and keeps the modal open while transitioning enrolled clubs to `"Inscrito"` (`pendingVerification`)

### Implementation for User Story 1

- [X] T007 [US1] Update `buildGlobalCatalogEntries` in `lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart` to preserve `categoryLabel` and `coachName` across candidate instances of the same club
- [X] T008 [US1] Update `AddTeamsToCompetitionModal` in `lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart` to trigger `ref.read(teamsControllerProvider.notifier).loadTeams()` in `initState()`, display category (`team.categoryLabel ?? l10n.addTeamsDefaultCategoryLabel`) and optional coach line (`l10n.addTeamsCoachMeta(team.coachName!)` only when `coachName` is non-empty), and keep the modal open after enrollment

**Checkpoint**: User Story 1 is independently testable via `flutter test test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart test/presentation/tournaments/add_teams_to_competition_modal_test.dart`

---

## Phase 4: User Story 2 - Restricción Estricta de Creación de Clubes para el Organizador (Priority: P1)

**Goal**: Ensure the Organizer flow strictly selects/enrolls existing clubs without exposing any create-team buttons or forms, displaying the exact orientation empty message when the platform catalog has zero clubs.

**Independent Test**: Render `AddTeamsToCompetitionModal` in populated, empty-search, and empty-catalog states and verify zero create-team buttons/forms exist and the exact empty message is shown.

### Tests for User Story 2

- [X] T009 [P] [US2] Add widget tests in `test/presentation/tournaments/add_teams_to_competition_modal_test.dart` asserting the absence of any create/register team actions across all modal states and verifying the exact empty catalog message `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."`

### Implementation for User Story 2

- [X] T010 [US2] Replace the legacy `CompetitionEnrollTeamDialog.show` call in `lib/presentation/panel/widgets/organizer_panel_content.dart` with `AddTeamsToCompetitionModal.show` so all Organizer competition team-addition entry points use the catalog selector without team creation forms

**Checkpoint**: User Stories 1 and 2 pass all unit and widget tests

---

## Phase 5: User Story 3 - Búsqueda Reactiva Normalizada en el Catálogo Global (Priority: P2)

**Goal**: Filter the global catalog in real time by official club name or short code (case- and accent-insensitive), preserving a clean empty-search state with filter reset and no creation buttons.

**Independent Test**: Enter accented/uppercase queries and short codes in `AddTeamsToCompetitionModal` search bar and verify real-time filtering and empty-search reset.

### Tests for User Story 3

- [X] T011 [P] [US3] Add/verify widget tests in `test/presentation/tournaments/add_teams_to_competition_modal_test.dart` for case- and diacritic-insensitive search by name and `shortCode` across standalone and enrolled catalog clubs, plus empty-search filter reset

### Implementation for User Story 3

- [X] T012 [US3] Verify and refine search filtering in `lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart` so `matchesTeamQuery` filters seamlessly across standalone (`tournamentId: ''`) and enrolled clubs while preserving category and coach metadata

**Checkpoint**: All three user stories are complete and independently verified

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis and full test verification

- [X] T013 Run `flutter analyze` and resolve any lint or analyzer warnings across modified files
- [X] T014 Run `flutter test test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart test/presentation/tournaments/add_teams_to_competition_modal_test.dart test/presentation/tournaments/competition_detail_fab_menu_test.dart` and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: `T001` -> `T002`.
- **Foundational (Phase 2)**: `T003` -> `T004` (blocks Phases 3–5).
- **User Story 1 (Phase 3 — P1 MVP)**: Depends on Phase 2 (`T005`/`T006` in parallel -> `T007` -> `T008`).
- **User Story 2 (Phase 4 — P1)**: Depends on Phase 1 & Phase 2 (`T009` -> `T010`).
- **User Story 3 (Phase 5 — P2)**: Depends on Phase 3 (`T011` -> `T012`).
- **Polish (Phase 6)**: Depends on Phases 1–5 (`T013` -> `T014`).

### Parallel Opportunities

- `T005` and `T006` can run in parallel.
- `T009` and `T010` can run in parallel with `T007`/`T008`.

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1 (Localization) + Phase 2 (`TournamentTeam` + `PostgrestTeamsRemoteDataSource.fetchAll()`).
2. Complete Phase 3 (US1: Global catalog load on modal open + category/coach metadata + enrollment).
3. Complete Phase 4 (US2: Strict no-creation governance & empty state) + Phase 5 (US3: Normalized search) + Phase 6 (Verification).
