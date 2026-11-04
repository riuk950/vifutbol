# Tasks: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)

**Input**: Design documents from `/specs/008-referee-digital-match-report/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/data-model.md), [digital-match-report-contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/contracts/digital-match-report-contract.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description.

---

## Phase 1: Setup (Shared Localization & Seed Data)

**Purpose**: Prepare Spanish localization strings for the referee digital match report, live scoreboard, event forms, double-yellow expulsion notice, offline banner (`"Modo sin conexión: cambios guardados en el dispositivo"`), and official sign-off (`FR-010`), and ensure seed rosters in `AppEnvironment.development` support immediate testing (`FR-009`).

- [x] T001 Add Spanish localization strings for digital match report screen, match periods (`"Por Iniciar"`, `"Primer Tiempo"`, `"Descanso"`, `"Segundo Tiempo"`, `"Tiempo Cumplido"`, `"Acta Cerrada"`), quick actions (`"Registrar Gol"`, `"Tarjeta Amarilla"`, `"Tarjeta Roja"`, `"Sustitución"`, `"Cerrar Acta Oficial"`), offline banner (`"Modo sin conexión: cambios guardados en el dispositivo"`), and validation messages in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations*.dart`
- [x] T002 [P] Ensure seed teams and players for `match-seed-clausura-1` (`team-seed-atletico-norte` with dorsal `5` `Dávinson Sánchez` and `team-seed-real-sabana`) have eligible players ready for live match report testing in `lib/infrastructure/repositories/local_teams_repository.dart`

---

## Phase 2: Foundational (Core Domain Entities, Failures & Repository Contract)

**Purpose**: Core domain models, timestamp timer calculations, double-yellow expulsion invariants, error codes, and repository abstractions that MUST be complete before user story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 [P] Create domain enumerations `MatchPeriod` (`notStarted`, `firstHalf`, `halfTime`, `secondHalf`, `fullTime`, `closed` with `isRunning`, `isOpenForEvents`, `isClosed`) and `MatchEventType` (`goal`, `yellowCard`, `secondYellowRedCard`, `directRedCard`, `substitution`, `periodTransition`) in `lib/domain/entities/match_report_enums.dart`
- [x] T004 [P] Create `MatchEvent` entity (`id` non-empty, `matchId` non-empty, `type`, `minute` `1..130`, `teamId` non-empty, `primaryPlayerId`, `primaryPlayerName`, `primaryPlayerShirtNumber`, `secondaryPlayerId`, `secondaryPlayerName`, `secondaryPlayerShirtNumber`, `linkedParentEventId`, `description`, `isSynced`, `createdAt`) with JSON serialization in `lib/domain/entities/match_event.dart`
- [x] T005 [P] Create `DigitalMatchReport` aggregate (`matchId`, `tournamentId`, `homeTeamId`, `awayTeamId != homeTeamId`, `homeScore >= 0`, `awayScore >= 0`, `currentPeriod`, `periodStartedAt`, `elapsedSecondsBeforeCurrentPeriod >= 0`, `events`, `closedAt`, `closedByUserId`, `updatedAt`) with timestamp timer methods `totalElapsedSecondsAt(DateTime now)` and `currentMatchMinuteAt(DateTime now)`, `yellowCardCountForPlayer(String playerId)`, `expelledPlayerIds`, `isPlayerExpelled(String playerId)`, `pendingSyncCount`, and JSON serialization in `lib/domain/entities/digital_match_report.dart`
- [x] T006 [P] Extend `ChampionshipMatch` with optional `int? homeScore` and `int? awayScore` fields and JSON serialization in `lib/domain/entities/championship_match.dart`
- [x] T007 [P] Create `DigitalMatchReportState` immutable state (`match`, `report`, `homeTeam`, `awayTeam`, `homeEligiblePlayers`, `awayEligiblePlayers`, `isOfflineMode`, `pendingSyncEventsCount`, `isLoading`, `isSubmitting`, `errorMessage`, `lastActionFeedback`) in `lib/domain/entities/digital_match_report_state.dart`
- [x] T008 [P] Extend `lib/domain/failures/app_failure.dart` with `MatchReportErrorCode` (`unauthorizedRole`, `reportAlreadyClosed`, `matchNotInProgress`, `invalidMinute`, `playerAlreadyExpelled`, `invalidAssistantPlayer`, `invalidSubstitutionPlayers`) and `MatchReportValidationFailure`
- [x] T009 [P] Define `MatchReportsRepository` abstract interface (`loadOrCreateReport`, `saveReport`, `loadPendingSyncQueue`, `synchronizePendingEvents`) in `lib/domain/repositories/match_reports_repository.dart`
- [x] T010 [P] Write unit tests for `DigitalMatchReport` timestamp timer calculation across background intervals, `MatchEvent` serialization, and computed `expelledPlayerIds` / `yellowCardCountForPlayer` in `test/unit/domain/digital_match_report_entities_test.dart`

**Checkpoint**: Foundation ready — user story implementation can begin.

---

## Phase 3: User Story 1 - Control del Encuentro y Registro en Vivo de Goles, Asistencias, Tarjetas y Sustituciones (Priority: P1) 🎯 MVP

**Goal**: Allow the `Árbitro` (or `Organizador`) to start the match (`"En Juego"`), control match periods with a timestamp-based timer, record live goals (with scorer and optional assistant), yellow/red cards (automatically triggering a `secondYellowRedCard` expulsion on the 2nd yellow card and blocking expelled players from further goals/assists/substitutions), substitutions, and undo accidental events while the report is open (`FR-001` to `FR-006`, `FR-008`).

**Independent Test**: Open `DigitalMatchReportScreen` for a scheduled match as `Árbitro`, start the match (`"En Juego"`), record a goal with assistant at minute 34, and record two yellow cards for player `#5` (`Dávinson Sánchez`, second at minute 68). Verify tabular score updates to `1 - 0`, timeline displays `"Accent Live"` (`#EF4444`), and the second yellow card automatically generates a red card expulsion and blocks player `#5` from scoring or assisting.

### Implementation & Tests for User Story 1

- [x] T011 [US1] Implement `LocalMatchReportsRepository` with JSON persistence under key `'vifutbol.match_reports.v1'` in `lib/infrastructure/repositories/local_match_reports_repository.dart`
- [x] T012 [US1] Implement `ManageDigitalMatchReportUseCase` methods `transitionMatchPeriod`, `recordGoalEvent`, `recordDisciplinaryCard` (enforcing the automatic double-yellow → `secondYellowRedCard` expulsion rule and blocking expelled players), `recordSubstitution`, and `removeMatchEvent` (undo while open, cascading removal of linked `secondYellowRedCard`) in `lib/application/use_cases/manage_digital_match_report_use_case.dart`
- [x] T013 [US1] Implement `DigitalMatchReportController` (`StateNotifier<DigitalMatchReportState>`) and Riverpod providers loading match, teams, convocation/eligible rosters, period transitions, and event recording in `lib/application/controllers/digital_match_report_controller.dart` and `lib/application/providers/digital_match_report_providers.dart`
- [x] T014 [P] [US1] Create `MatchEventTimelineTile` widget (with `#EF4444` `KickPulseColors.accentLive` signal, player shirt badge, assistant detail, and undo button while report is open) in `lib/presentation/matches/widgets/match_event_timeline_tile.dart`
- [x] T015 [P] [US1] Create event recording dialogs `RecordGoalDialog`, `RecordCardDialog`, and `RecordSubstitutionDialog` (filtering out expelled players and enforcing `assistant != scorer` and `>= 44x44px` touch targets) in `lib/presentation/matches/dialogs/record_goal_dialog.dart`, `lib/presentation/matches/dialogs/record_card_dialog.dart`, and `lib/presentation/matches/dialogs/record_substitution_dialog.dart`
- [x] T016 [US1] Create `DigitalMatchReportScreen` with tabular live scoreboard (`FontFeature.tabularFigures()`), timestamp-based live clock, period control bar, quick-action buttons (`>= 44x44px`, single-flight lock) for `Árbitro`/`Organizador`, and read-only view for other roles in `lib/presentation/matches/digital_match_report_screen.dart`
- [x] T017 [US1] Register `/matches/report` route in `lib/presentation/navigation/app_router.dart` and update `MatchCard` in `lib/presentation/matches/widgets/match_card.dart` to display live/final scores and navigate to `/matches/report`

**Checkpoint**: User Story 1 (Live match control, goal/assist recording, automatic double-yellow expulsion, and live timeline) is functional and testable.

---

## Phase 4: User Story 2 - Operación Offline-First en Cancha y Sincronización Idempotente sin Duplicados (Priority: P2)

**Goal**: Support seamless offline operation on the pitch where every recorded event is persisted immediately with `isSynced: false`, displaying `"Modo sin conexión: cambios guardados en el dispositivo"`, and automatically synchronizing the pending queue idempotently by `event.id` without duplicates when connectivity returns (`FR-007`).

**Independent Test**: Toggle offline mode in `DigitalMatchReportScreen`, verify the Spanish banner `"Modo sin conexión: cambios guardados en el dispositivo"` appears, record a goal, a yellow card, and half-time transition, then restore connectivity and verify all queued events synchronize idempotently (`pendingSyncEventsCount == 0`) with zero duplicated goals or cards.

### Implementation & Tests for User Story 2

- [x] T018 [US2] Enhance `LocalMatchReportsRepository` with persistent offline sync queue under key `'vifutbol.match_events_sync_queue.v1'` and idempotent `synchronizePendingEvents` deduplicating by `event.id` in `lib/infrastructure/repositories/local_match_reports_repository.dart`
- [x] T019 [US2] Enhance `DigitalMatchReportController` and `DigitalMatchReportScreen` with reactive connectivity state (`setOfflineMode` / `synchronizePendingEvents`) and the Spanish offline indicator banner `"Modo sin conexión: cambios guardados en el dispositivo"` in `lib/application/controllers/digital_match_report_controller.dart` and `lib/presentation/matches/digital_match_report_screen.dart`
- [x] T020 [P] [US2] Write unit tests for `LocalMatchReportsRepository` verifying offline queue persistence and idempotent synchronization without duplicates in `test/unit/infrastructure/local_match_reports_repository_test.dart`

**Checkpoint**: User Stories 1 and 2 are complete and verified.

---

## Phase 5: User Story 3 - Cierre Oficial e Inmutable del Acta Arbitral (Priority: P3)

**Goal**: Allow the `Árbitro` (or `Organizador`) to review the match summary and confirm `"Cerrar Acta Oficial"`, transitioning the match to `"Finalizado"` (`MatchStatus.completed`), permanently locking the report against any subsequent modifications, and updating player stats and disciplinary suspensions in `LineupsTrackingRepository` (`FR-008`).

**Independent Test**: In an `"En Juego"` match with recorded goals and cards, tap `"Cerrar Acta Oficial"`, confirm in `CloseMatchReportConfirmationDialog`, and verify the match transitions to `"Finalizado"`, action buttons are locked/hidden, any subsequent attempt to add or delete an event is rejected with `reportAlreadyClosed`, and player stats are updated.

### Implementation & Tests for User Story 3

- [x] T021 [US3] Implement `closeOfficialMatchReport` in `ManageDigitalMatchReportUseCase` sealing `DigitalMatchReport` (`MatchPeriod.closed`), updating `ChampionshipMatch` (`MatchStatus.completed`, `homeScore`, `awayScore`) in `TournamentMatchesRepository`, and updating player goals, assists, cards, and suspension dates in `LineupsTrackingRepository` in `lib/application/use_cases/manage_digital_match_report_use_case.dart`
- [x] T022 [US3] Create `CloseMatchReportConfirmationDialog` displaying consolidated summary of goals, assists, yellow/red cards, and final score before sign-off in `lib/presentation/matches/dialogs/close_match_report_confirmation_dialog.dart` and wire it into `DigitalMatchReportScreen`
- [x] T023 [P] [US3] Write unit tests for `ManageDigitalMatchReportUseCase` and `DigitalMatchReportController` covering period transitions, goal/assist validation, double-yellow automatic expulsion, offline queue sync, event removal before close, and immutable report closing in `test/unit/application/manage_digital_match_report_use_case_test.dart` and `test/unit/application/digital_match_report_controller_test.dart`
- [x] T024 [US3] Write comprehensive widget tests verifying all 4 Gherkin scenarios (live goal with assist and tabular score, second yellow card automatic expulsion for shirt `#5`, offline mode banner and idempotent reconnection sync, and official report closure locking) in `test/widget/digital_match_report_widget_test.dart`

**Checkpoint**: All 3 user stories (`US1`, `US2`, `US3`) are fully functional, integrated, and verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute full static analysis, code formatting, and test suite verification to satisfy Constitution quality gates.

- [x] T025 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`, and `flutter test --coverage` across the entire workspace to ensure 0 static analysis issues and 100% passing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. Serves as MVP.
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (offline queueing and reconnection sync extend event recording and report screen).
- **User Story 3 (Phase 5)**: Depends on User Stories 1 and 2 completion (closing seals the recorded events and propagates stats).
- **Polish (Phase 6)**: Depends on all user stories being implemented and tested.

### Parallel Opportunities

- Within Phase 1: `T002` can run in parallel with `T001`.
- Within Phase 2: `T003`, `T004`, `T005`, `T006`, `T007`, `T008`, `T009` define independent domain entities/contracts and can be implemented in parallel, followed by `T010`.
- Within Phase 3: `T014` (`MatchEventTimelineTile`) and `T015` (recording dialogs) can be built in parallel.
- Within Phase 4: `T020` (repository unit tests) can run in parallel with UI banner integration.
- Within Phase 5: `T023` (use case & controller unit tests) can run in parallel with `T022`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1 (Localization & Seeds)
2. Complete Phase 2 (Entities, Failures, Repository Contract & Domain Unit Tests)
3. Complete Phase 3 (Use Case, Controller, `DigitalMatchReportScreen`, Event Dialogs & Route Integration)
4. **VALIDATE**: Start a match, record a goal with assist, and verify automatic double-yellow expulsion for shirt `#5`.

### Incremental Delivery
1. Phase 1 + Phase 2 → Foundational domain ready.
2. User Story 1 → Live match control, scoreboard, timeline, and double-yellow rule functional.
3. User Story 2 → Offline persistence banner and idempotent queue synchronization functional.
4. User Story 3 → Immutable report sign-off, match completion, and player statistics propagation complete.
5. Phase 6 → Full quality gate verification (`flutter analyze`, `dart format`, `flutter test --coverage`).
