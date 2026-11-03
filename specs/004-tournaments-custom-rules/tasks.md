---

description: "Task list for Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (HU 4.1)"
---

# Tasks: Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (HU 4.1)

**Input**: Design documents from `/specs/004-tournaments-custom-rules/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/tournaments-ui-and-storage-contract.md, quickstart.md

**Tests**: Automated unit and widget tests are included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and `SC-005` (`>= 80%` coverage).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Add all Spanish localization strings (`app_es.arb`) and domain failure codes required across HU 4.1.

- [X] T001 Add Spanish localization strings for tournament formats (`Liga`, `Copa Eliminatoria`, `Mixto`), statuses (`Inscripciones Abiertas`, `En Curso`, `Finalizado`), tiebreaker criteria (`Diferencia de Gol`, `Goles a Favor`, `Duelo Directo`, `Juego Limpio (Fair Play)`), knockout rounds (`Octavos de Final`, `Cuartos de Final`, `Semifinal`, `Final`), form labels, validation errors, draft banner, exit confirmation dialog (`"¿Deseas descartar los cambios o guardar como borrador?"`), and critical-rule audit dialog in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations*.dart`
- [X] T002 [P] Extend `lib/domain/entities/app_failure.dart` with `TournamentValidationErrorCode` (`invalidName`, `invalidCategory`, `invalidDateRange`, `invalidPointsDistribution`, `invalidTiebreakerOrder`, `invalidYellowCardLimit`, `invalidSquadSizeRange`, `invalidHalfDuration`, `invalidLeagueRounds`, `invalidGroupStageConfig`, `criticalRulesImmutableWithoutAudit`, `tournamentAlreadyFinished`) and `TournamentValidationFailure`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain enumerations, value objects, aggregate root, catalog state, and repository contract that MUST be complete before user story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Create domain enumerations `TournamentFormat` (`league`, `knockoutCup`, `mixedGroupsAndKnockout`), `TournamentStatus` (`openRegistration`, `inProgress`, `finished`), `TiebreakerCriterion` (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`), and `KnockoutRound` (`roundOf16`, `quarterFinals`, `semiFinals`, `finalMatch`) in `lib/domain/entities/tournament_enums.dart`
- [X] T004 [P] Create `RuleAuditEntry` value object (`recordedAt`, `summary`, `reason` non-empty, `recalculationConfirmed`) with JSON serialization (`toJson` / `fromJson`) in `lib/domain/entities/rule_audit_entry.dart`
- [X] T005 Create `KnockoutStageConfig` (`startingRound` default `KnockoutRound.quarterFinals`, `twoLeggedTies` default `false`, `directPenaltyShootoutOnDraw` default `true`, and `activeRoundsSequence` getter), `GroupStageConfig` (`groupCount` in range `2..8` default `4`, `advancingPerGroup` in range `1..4` default `2`, independent of knockout bracket size), and `TournamentRulesConfig` (`pointsForWin` default `3`, `pointsForDraw` default `1`, `pointsForLoss` default `0` with invariant `pointsForWin > pointsForDraw >= pointsForLoss >= 0`, `tiebreakerOrder` non-empty without duplicates default `[goalDifference, goalsFor, headToHead, fairPlay]`, `yellowCardSuspensionLimit` in `2..10` default `3`, `minPlayersPerTeam` default `7` and `maxPlayersPerTeam` default `18` with `5 <= minPlayersPerTeam <= maxPlayersPerTeam <= 35`, `halfDurationMinutes` in `10..60` default `45`, `leagueRounds` `1` or `2` default `1`, `knockoutConfig`, `groupStageConfig`) in `lib/domain/entities/tournament_rules_config.dart`
- [X] T006 Create `ChampionshipTournament` aggregate root (`id`, `name` `>= 3` chars, `category` non-empty, `startDate`, `endDate` with `!endDate.isBefore(startDate)`, `format`, `status` default `openRegistration`, `rules`, `auditTrail`, `updatedAt`) with `copyWith`, `toJson`, and `fromJson` in `lib/domain/entities/championship_tournament.dart`
- [X] T007 [P] Create `TournamentDraft` value object (`name`, `category`, `startDate`, `endDate`, `format`, `rules`, `savedAt`) with `toJson` / `fromJson` in `lib/domain/entities/tournament_draft.dart`
- [X] T008 [P] Create `TournamentsCatalogState` (`tournaments`, `selectedTournamentId`, `selectedFormatFilter`, `hasSavedDraft`, `filteredTournaments`, `selectedTournament`) in `lib/domain/entities/tournaments_catalog_state.dart`
- [X] T009 Define `TournamentsRepository` abstract interface (`loadTournaments`, `saveTournament`, `loadDraft`, `saveDraft`, `clearDraft`) in `lib/domain/repositories/tournaments_repository.dart`
- [X] T010 Write unit tests for `TournamentEnums`, `KnockoutStageConfig`, `GroupStageConfig`, `TournamentRulesConfig`, `RuleAuditEntry`, `ChampionshipTournament`, `TournamentDraft`, and `TournamentsCatalogState` in `test/unit/domain/tournament_rules_and_entities_test.dart`

**Checkpoint**: Foundation ready — user story implementation can now proceed.

---

## Phase 3: User Story 1 - Creación de Campeonatos con Formatos de Liga, Copa Eliminatoria o Mixto y Reglas Personalizadas (Priority: P1) 🎯 MVP

**Goal**: Allow `Organizador` (`RoleCapability.manageTournaments`) to create championships in `Liga`, `Copa Eliminatoria`, or `Mixto` formats with full custom rules validation and persist them with initial status `"Inscripciones Abiertas"`.

**Independent Test**: Authenticate as `Organizador`, open `/tournaments/form`, configure a `Liga` and a `Copa Eliminatoria` with penalty shootouts, save both, and verify they persist in `LocalTournamentsRepository` with status `openRegistration` and all custom rules intact.

### Tests for User Story 1

- [X] T011 [P] [US1] Write unit tests for `LocalTournamentsRepository` covering `dev` seed loading (`Liga Clausura ViFutbol 2026`, `Copa Relámpago Nocturna`, `Torneo Metropolitano Mixto`), empty `prod` storage, and saving/updating tournaments in `test/unit/infrastructure/local_tournaments_repository_test.dart`
- [X] T012 [P] [US1] Write unit tests for `ManageTournamentsUseCase` covering role authorization (`RoleCapability.manageTournaments`), creation with initial `openRegistration` status, and all validation constraints (`invalidName`, `invalidCategory`, `invalidDateRange`, `invalidPointsDistribution`, `invalidTiebreakerOrder`, `invalidYellowCardLimit`, `invalidSquadSizeRange`, `invalidHalfDuration`, `invalidLeagueRounds`, `invalidGroupStageConfig`) in `test/unit/application/manage_tournaments_use_case_test.dart`

### Implementation for User Story 1

- [X] T013 [US1] Implement `LocalTournamentsRepository` backed by `LocalStorageRepository` (catalog key `'vifutbol.tournaments.catalog.v1'`, draft key `'vifutbol.tournaments.creation_draft.v1'`, and 3 representative `dev` seed tournaments) in `lib/infrastructure/repositories/local_tournaments_repository.dart`
- [X] T014 [US1] Implement `ManageTournamentsUseCase` (`validateAndPrepareTournament`, `transitionStatus`) enforcing `RoleCapability.manageTournaments`, custom rule invariants, initial status `TournamentStatus.openRegistration`, and independent `Mixto` group stage bounds (`groupCount` in `2..8`, `advancingPerGroup` in `1..4`) in `lib/application/use_cases/manage_tournaments_use_case.dart`
- [X] T015 [US1] Implement `TournamentsController` (`StateNotifier<UiViewState<TournamentsCatalogState>>`) and Riverpod providers (`tournamentsRepositoryProvider`, `manageTournamentsUseCaseProvider`, `tournamentsControllerProvider`) in `lib/application/controllers/tournaments_controller.dart` and `lib/application/providers/tournaments_providers.dart`
- [X] T016 [US1] Create `TournamentFormScreen` supporting `Liga` (1 or 2 rounds), `Copa Eliminatoria` (starting round `Octavos`/`Cuartos`/`Semifinal`/`Final`, single or two-legged ties, direct penalty shootout toggle), and `Mixto` (groups `2..8` and qualifiers `1..4` + knockout stage), custom points (`3/1/0`), interactive tiebreaker order reordering, yellow card suspension limit (`2..10`), squad min/max (`5..35`), and half duration (`10..60` min) in `lib/presentation/tournaments/tournament_form_screen.dart`
- [X] T017 [US1] Register `/tournaments/form` route in `lib/presentation/navigation/app_router.dart`

**Checkpoint**: User Story 1 is complete and independently testable.

---

## Phase 4: User Story 2 - Consulta de Normativa Oficial e Inmutabilidad Auditada de Reglas Críticas (Priority: P2)

**Goal**: Provide a complete Championship & Official Rules Center in `StandingsTabView` for all roles, enforce role-based UI visibility (`RoleCapability.manageTournaments`), manage status transitions (`openRegistration` → `inProgress` → `finished`), and enforce audited immutability (`RuleAuditEntry` with mandatory reason) when modifying format or scoring points while `inProgress`.

**Independent Test**: View championships as non-organizer roles (`Aficionado`, `Jugador`, `Delegado de Equipo`, `Árbitro`) and verify mutation buttons are hidden while full official rules are visible; switch to `Organizador`, transition a tournament to `En Curso`, attempt to modify `pointsForWin` or `format`, and verify the mandatory audit reason dialog and `RuleAuditEntry` creation.

### Tests for User Story 2

- [X] T018 [P] [US2] Extend `test/unit/application/manage_tournaments_use_case_test.dart` and create `test/unit/application/tournaments_controller_test.dart` to verify status transitions (`openRegistration` → `inProgress` → `finished`), blocking critical rule edits (`format`, `pointsForWin`, `pointsForDraw`, `pointsForLoss`) when `inProgress` without `confirmCriticalRuleOverride` and non-empty `auditReason`, recording `RuleAuditEntry`, and blocking all edits when `finished`
- [X] T019 [P] [US2] Write widget tests for `StandingsTabView` covering role segregation (`Organizador` vs `Aficionado`/`Jugador`/`Delegado`/`Árbitro`), format filtering, official rules summary card, knockout bracket visualization, status transition actions, and audited edit flow in `test/widget/standings_tab_view_test.dart`

### Implementation for User Story 2

- [X] T020 [P] [US2] Create `TournamentRulesSummaryCard` displaying format badge, status badge, scoring table (`V / E / D`), numbered tiebreaker priority list, disciplinary & squad rules (`yellowCardSuspensionLimit`, `minPlayersPerTeam..maxPlayersPerTeam`, `halfDurationMinutes`), knockout bracket progression (`Octavos` → `Cuartos` → `Semifinal` → `Final` + penalty shootout indicator), group stage summary, and `RuleAuditEntry` history in `lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart`
- [X] T021 [US2] Update `StandingsTabView` to integrate `TournamentsController`, `KickPulseStateView`, format filter chips, tournament selector cards, `TournamentRulesSummaryCard`, and organizer-only controls (`"Crear Campeonato"`, `"Editar Reglas"`, `"Iniciar Campeonato"`, `"Finalizar Campeonato"`) in `lib/presentation/shell/tabs/standings_tab_view.dart`
- [X] T022 [US2] Add critical-rule immutability lock banner and administrative audit confirmation dialog (requiring non-empty `auditReason` and explicit confirmation before saving changes to `format` or `pointsForWin`/`pointsForDraw`/`pointsForLoss` when `status == TournamentStatus.inProgress`) in `lib/presentation/tournaments/tournament_form_screen.dart`

**Checkpoint**: User Stories 1 and 2 are complete and independently testable.

---

## Phase 5: User Story 3 - Autoguardado de Borrador Móvil y Protección al Salir con Cambios sin Guardar (Priority: P3)

**Goal**: Automatically persist a local creation draft when the app transitions to background or when the `Organizador` selects `"Guardar borrador"` in the exit confirmation dialog (`"¿Deseas descartar los cambios o guardar como borrador?"`), restore the draft when reopening the creation wizard, and protect both creation and edit forms against accidental exit with unsaved changes.

**Independent Test**: Enter partial championship data in `TournamentFormScreen`, trigger back navigation, verify the dialog `"¿Deseas descartar los cambios o guardar como borrador?"`, select `"Guardar borrador"`, reopen `TournamentFormScreen`, and verify all partial fields are restored and cleared upon final publish.

### Tests for User Story 3

- [X] T023 [P] [US3] Add unit tests for draft persistence (`saveDraft`, `loadDraft`, `clearDraft`, and auto-clearing draft on new tournament creation) in `test/unit/infrastructure/local_tournaments_repository_test.dart` and `test/unit/application/tournaments_controller_test.dart`
- [X] T024 [P] [US3] Write widget tests for `TournamentFormScreen` covering creation of `Liga` and `Copa Eliminatoria`, validation errors, critical-rule audit dialog in `inProgress` mode, exit confirmation dialog (`"¿Deseas descartar los cambios o guardar como borrador?"`), and draft restoration banner in `test/widget/tournament_form_screen_test.dart`

### Implementation for User Story 3

- [X] T025 [US3] Implement `AppLifecycleListener` background draft autosave, initial draft restoration with `"Se recuperó un borrador guardado"` banner, and `PopScope` exit confirmation dialog (`"¿Deseas descartar los cambios o guardar como borrador?"` with `"Guardar borrador"`, `"Descartar cambios"`, and `"Seguir editando"`) in `lib/presentation/tournaments/tournament_form_screen.dart`

**Checkpoint**: All user stories (`US1`, `US2`, `US3`) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final static analysis, code formatting, test suite execution, and coverage verification (`SC-005`).

- [X] T026 Run `flutter analyze` and resolve any static analysis warnings or errors across `lib/` and `test/`
- [X] T027 Run `dart format --output=none --set-exit-if-changed lib test` and `flutter test --coverage` to verify 100% passing tests and `>= 80%` coverage on HU 4.1 domain and application logic

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T001`, `T002`) — **BLOCKS** all user stories.
- **Phase 3 (User Story 1 - P1)**: Depends on Phase 2 (`T003`..`T010`).
- **Phase 4 (User Story 2 - P2)**: Depends on Phase 3 (`T013`..`T017`).
- **Phase 5 (User Story 3 - P3)**: Depends on Phase 3 & Phase 4 (`T015`, `T016`, `T022`).
- **Phase 6 (Polish)**: Depends on all user stories (`T001`..`T025`).

### Parallel Opportunities

- `T003`, `T004`, `T007`, `T008` operate on separate domain entity files and can be executed in parallel.
- `T011` and `T012` test separate layers (`infrastructure` vs `application`) and can run in parallel.
- `T018`, `T019`, and `T020` can be developed in parallel once `T015` is complete.
- `T023` and `T024` can run in parallel during Phase 5 verification.

---

## Parallel Example: User Story 1

```bash
# Foundational domain models in parallel:
Task: "T003 [P] Create domain enumerations in lib/domain/entities/tournament_enums.dart"
Task: "T004 [P] Create RuleAuditEntry value object in lib/domain/entities/rule_audit_entry.dart"

# User Story 1 unit tests in parallel:
Task: "T011 [P] [US1] Write unit tests for LocalTournamentsRepository in test/unit/infrastructure/local_tournaments_repository_test.dart"
Task: "T012 [P] [US1] Write unit tests for ManageTournamentsUseCase in test/unit/application/manage_tournaments_use_case_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Localization & Failure codes) and Phase 2 (Domain Models & Repository Interface).
2. Complete Phase 3 (`US1`: Local repository, use case, controller, and `TournamentFormScreen`).
3. Validate `US1` unit tests (`T010`, `T011`, `T012`).

### Incremental Delivery

1. Add `US2` (`TournamentRulesSummaryCard`, `StandingsTabView`, status transitions, and audited critical-rule protection for `inProgress` tournaments).
2. Add `US3` (`AppLifecycleListener` background draft autosave, draft restoration banner, and `PopScope` exit confirmation dialog).
3. Run Phase 6 quality gates (`flutter analyze`, `dart format`, `flutter test --coverage`).
