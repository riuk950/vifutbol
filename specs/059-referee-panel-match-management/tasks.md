# Tasks: Panel del Árbitro — Lista de Partidos Asignados y Gestión Completa hasta el Cierre

**Input**: Design documents from `/specs/059-referee-panel-match-management/`

**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/referee_panel_match_contract.md`, `quickstart.md`

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and HU 26.1 checklist.

**Organization**: Tasks are grouped by user story (`US1`–`US4`) so each increment can be implemented and tested independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (`US1`, `US2`, `US3`, `US4`)
- Exact repository-relative file paths included in every task description

---

## Phase 1: Setup (Localization & Database Migration)

**Purpose**: Add Spanish localization strings and idempotent SQL migration for match report referee observations.

- [X] T001 Add the 20 Spanish localization keys defined in `contracts/referee_panel_match_contract.md` (`refereeFilterAll`, `refereeFilterInProgress`, `refereeFilterScheduled`, `refereeFilterCompleted`, `refereeEmptyFilterMessage`, `refereeMatchStatusScheduled`, `refereeMatchStatusInProgress`, `refereeMatchStatusCompleted`, `refereeMatchStatusPending`, `refereeMatchStatusCancelled`, `refereeMatchDateUnscheduled`, `refereeMatchActionManage`, `refereeMatchActionViewClosed`, `refereeMatchUnauthorizedBanner`, `refereeMatchUnconfirmedConvocationBanner`, `refereeObservationsTitle`, `refereeObservationsHint`, `refereeObservationsSaveAction`, `refereeObservationsSavedMessage`, `refereeObservationsEmpty`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate Flutter localization delegates via `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)
- [X] T003 [P] Create idempotent SQL migration `supabase/migrations/202611250004_match_report_referee_observations.sql` adding `referee_observations text` to `vifutboldev.match_reports` and executing `NOTIFY pgrst, 'reload schema'`

---

## Phase 2: Foundational (Domain Entities, Service & Repository Mapping)

**Purpose**: Core domain matching/sorting service, match report entity extensions, and PostgREST persistence mapping.

- [X] T004 [P] Create `RefereeAssignedMatchesService` and `RefereeMatchFilter` (`all`, `inProgress`, `scheduled`, `completed`) implementing `isAssignedToReferee` (`linkedRefereeId` + `userId` fallback) and operational sorting (`inProgress` first → `scheduled`/`pending` asc → `completed`/`cancelled` desc) in `lib/domain/services/referee_assigned_matches_service.dart`
- [X] T005 [P] Add optional `refereeObservations` field (`copyWith`, `toJson`, `fromJson` reading `refereeObservations` / `referee_observations`) to `DigitalMatchReport` in `lib/domain/entities/digital_match_report.dart` and add `homeConvocationConfirmed`, `awayConvocationConfirmed`, and `hasUnconfirmedConvocation` to `DigitalMatchReportState` in `lib/domain/entities/digital_match_report_state.dart`
- [X] T006 Map `referee_observations` in PostgREST serialization/deserialization in `lib/infrastructure/repositories/hybrid_match_reports_repository.dart` (depends on T005)
- [X] T007 [P] Create unit test suite in `test/domain/services/referee_assigned_matches_service_test.dart` covering `linkedRefereeId` matching, `userId` fallback, exclusion of unassigned matches, operational sorting across statuses, and status filters (depends on T004)

**Checkpoint**: Foundation ready — user story implementation can proceed in parallel.

---

## Phase 3: User Story 1 - Lista actualizada de partidos asignados en el Panel del Árbitro (Priority: P1) 🎯 MVP

**Goal**: Display all matches assigned to the authenticated referee across tournaments in `RefereePanelContent` with real team/tournament/venue names, Colombia date/time, localized status badges, operational sorting, status filter chips, pull-to-refresh, and refresh on return from the report.

**Independent Test**: Render `RefereePanelContent` for a referee with `linkedRefereeId` and multi-tournament matches; verify real team/tournament/venue/Colombia time rendering, operational ordering, filter chips, empty state, pull-to-refresh, and opening `DigitalMatchReportScreen`.

### Implementation for User Story 1

- [X] T008 [US1] Refactor `RefereePanelContent` into a `ConsumerStatefulWidget` in `lib/presentation/panel/widgets/referee_panel_content.dart` with initial multi-tournament loading (`loadAllMatches()`, tournaments, teams), `RefreshIndicator` preserving local cache on error, status filter bar (`referee_matches_filter_bar`), operational sorting via `RefereeAssignedMatchesService`, rich cards showing real team names, tournament name, round, Colombia date/time, venue/pitch, score, localized status badge, Spanish `Semantics` labels, tap-to-open `DigitalMatchReportScreen`, and automatic refresh upon returning

### Tests for User Story 1

- [X] T009 [P] [US1] Create/update widget tests in `test/presentation/panel/referee_panel_content_test.dart` verifying multi-tournament assigned matches matched via `linkedRefereeId` and `userId`, real team/tournament/venue/Colombia time display (no raw IDs), operational sorting, filter chips, empty state, pull-to-refresh, and navigation to `DigitalMatchReportScreen` (depends on T008)

**Checkpoint**: User Story 1 is independently functional and tested.

---

## Phase 4: User Story 2 & 3 - Inicio, desarrollo completo del partido y cierre oficial del acta (Priority: P1)

**Goal**: Enable the assigned referee to start a scheduled match (even with unconfirmed coach convocation using enrolled roster fallback), record all events plus general referee observations, and close the official report immutably with single-flight protection.

**Independent Test**: Run full match lifecycle (`Programado` → `Primer Tiempo` → goals/assists/cards/double-yellow/subs/periods/observations → `Finalizado`) verifying real-time score/timeline updates, single-flight guard, and read-only lock after close.

### Implementation for User Story 2 & 3

- [X] T010 [US2] Add `updateRefereeObservations` and optional actor ownership validation (`actorUserId`, `actorRefereeId`) to `ManageDigitalMatchReportUseCase` in `lib/application/use_cases/manage_digital_match_report_use_case.dart` (depends on T005)
- [X] T011 [US2] Update `DigitalMatchReportController` in `lib/application/controllers/digital_match_report_controller.dart` to enforce `if (state.isSubmitting) return false;` single-flight guard across all mutations, set `homeConvocationConfirmed`/`awayConvocationConfirmed` when loading report rosters, add `updateObservations(...)`, and forward `actorUserId`/`actorRefereeId` to `ManageDigitalMatchReportUseCase` (depends on T010)
- [X] T012 [US3] Update `DigitalMatchReportScreen` in `lib/presentation/matches/digital_match_report_screen.dart` to forward authenticated referee credentials (`user.id`, `user.roleProfile?.linkedRefereeId`), display non-blocking unconfirmed convocation banner (`digital_match_report_unconfirmed_convocation_banner`), add editable/read-only referee observations card (`digital_match_report_observations_card`, `digital_match_report_observations_field`, `digital_match_report_save_observations_button`), and keep closed reports strictly read-only (depends on T011)

### Tests for User Story 2 & 3

- [X] T013 [P] [US3] Add unit tests in `test/application/use_cases/manage_digital_match_report_use_case_test.dart` covering `updateRefereeObservations`, full match lifecycle (`scheduled` → `firstHalf` → events + observations → `closed`/`completed`), and rejection of edits/observations after closure (depends on T010)

**Checkpoint**: User Stories 1, 2, and 3 cover the complete referee match workflow end-to-end.

---

## Phase 5: User Story 4 - Operación offline-first, propiedad de acceso y resiliencia móvil (Priority: P2)

**Goal**: Enforce assigned-referee/organizer ownership in UI and use case, preserve offline event/observation/closure writes with idempotent sync, and verify mobile resilience.

**Independent Test**: Open a match as an unassigned referee and verify read-only banner + blocked mutations; run start/events/observations/close offline and verify local persistence and sync queue.

### Implementation for User Story 4

- [X] T014 [US4] Render Spanish read-only unauthorized banner (`digital_match_report_unauthorized_banner`) and disable editing controls when an unassigned referee opens a match in `lib/presentation/matches/digital_match_report_screen.dart` (depends on T012)

### Tests for User Story 4

- [X] T015 [P] [US4] Add unit tests in `test/application/use_cases/manage_digital_match_report_use_case_test.dart` verifying assigned referee authorization, unauthorized referee rejection (`MatchReportErrorCode.unauthorizedRole`), and organizer override (depends on T010)
- [X] T016 [P] [US4] Add widget tests in `test/presentation/matches/digital_match_report_screen_test.dart` covering unconfirmed convocation fallback banner, referee observations save & read-only mode after closure, unauthorized referee banner, single-flight guard, and offline persistence (depends on T014)

**Checkpoint**: All 4 user stories are complete, secured, and offline-resilient.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Final static analysis and full regression test verification per `quickstart.md`.

- [X] T017 Run `flutter analyze` across all modified and new files listed in `quickstart.md` and resolve any warnings or errors
- [X] T018 Run `flutter test test/domain/services/referee_assigned_matches_service_test.dart test/application/use_cases/manage_digital_match_report_use_case_test.dart test/presentation/panel/referee_panel_content_test.dart test/presentation/matches/digital_match_report_screen_test.dart` and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately (`T001` → `T002`; `T003` in parallel).
- **Phase 2 (Foundational)**: `T004` and `T005` run in parallel; `T006` depends on `T005`; `T007` depends on `T004`.
- **Phase 3 (US1)** and **Phase 4 (US2/US3)**: Depend on Phase 1–2 and touch disjoint files (`referee_panel_content.dart` vs `manage_digital_match_report_use_case.dart` / `digital_match_report_controller.dart` / `digital_match_report_screen.dart`), so they can proceed in parallel.
- **Phase 5 (US4)**: Builds on `T010` and `T012`.
- **Phase 6 (Polish)**: Runs after `T001`–`T016` complete.

### Parallel Opportunities

- `T001` (`app_es.arb`), `T003` (SQL migration), `T004` (`RefereeAssignedMatchesService`), and `T005` (`DigitalMatchReport` / `DigitalMatchReportState`) can execute in parallel.
- `T008` (`RefereePanelContent`) and `T010`/`T011`/`T012` (match report flow) touch separate files and can execute in parallel.
- `T007`, `T009`, `T013`/`T015`, and `T016` test suites can run in parallel once their target modules are implemented.

---

## Implementation Strategy

### MVP First (US1)

1. Complete Phase 1 (`T001`–`T003`) and Phase 2 (`T004`–`T007`).
2. Complete Phase 3 (`US1`: multi-tournament assigned matches panel with real names, Colombia time, ordering, and filters).

### Incremental Delivery

1. Add Phase 4 (`US2` + `US3`: observations, unconfirmed convocation fallback banner, single-flight, full lifecycle to read-only close).
2. Add Phase 5 (`US4`: assigned-referee ownership enforcement and offline resilience tests).
3. Run Phase 6 (`T017`–`T018`: `flutter analyze` and `flutter test`).
