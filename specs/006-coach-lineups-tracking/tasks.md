# Tasks: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Input**: Design documents from `/specs/006-coach-lineups-tracking/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/data-model.md), [lineups-and-tracking-contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/contracts/lineups-and-tracking-contract.md)

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description.

---

## Phase 1: Setup (Shared Localization & Seed Squad Expansion)

**Purpose**: Prepare Spanish localization entries (`FR-008`) and expand the `dev` seed squad of `'team-seed-atletico-norte'` so it has `10` players (`7` starters + `2` substitutes + `1` suspended player) for immediate end-to-end validation (`FR-007`).

- [x] T001 Add Spanish localization strings for match convocation, tactical roles (`"Titular"`, `"Suplente"`, `"No convocado"`, `"Capitán"`), disciplinary badges (`"Suspendido ({count} fecha)"`, `"Suspendido ({count} fechas)"`, `"En capilla ({count} TA)"`), internal tracking metrics, referee synced roster view, and validation messages in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations*.dart`
- [x] T002 [P] Expand `'team-seed-atletico-norte'` seed roster to 10 registered players (`shirtNumber` `1, 3, 4, 5, 6, 8, 9, 10, 11, 14`) in `lib/infrastructure/repositories/local_teams_repository.dart` and update `test/unit/infrastructure/local_teams_repository_test.dart`

---

## Phase 2: Foundational (Core Domain Entities, Failures & Repository Contract)

**Purpose**: Core domain models, error codes, and repository abstractions that MUST be complete before user story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 [P] Create domain enumerations `PlayerConvocationRole` (`notConvoked`, `starter`, `substitute`), `PlayerDisciplinaryState` (`eligible`, `warningAccumulation`, `suspended`), and `ConvocationStatus` (`draft`, `confirmed`) in `lib/domain/entities/lineup_enums.dart`
- [x] T004 [P] Create `PlayerInternalTracking` entity (`playerId`, `teamId`, `tournamentId` non-empty; `matchesPlayed >= 0`, `goals >= 0`, `assists >= 0`, `yellowCards >= 0`, `redCards >= 0`, `pendingSuspensionMatches >= 0`) with deterministic `effectiveSuspensionMatches(int yellowCardSuspensionLimit)`, `isSuspended`, `isAtYellowCardWarning`, `disciplinaryState`, and JSON serialization in `lib/domain/entities/player_internal_tracking.dart`
- [x] T005 [P] Create `MatchLineupConvocation` entity (`id`, `tournamentId`, `teamId`, `matchLabel` non-empty; disjoint `starterPlayerIds` and `substitutePlayerIds`; `captainPlayerId` in `starterPlayerIds`; `status` `draft | confirmed`; confirmed snapshots `confirmedStarterPlayerIds`, `confirmedSubstitutePlayerIds`, `confirmedCaptainPlayerId`, `confirmedAt`, `updatedAt`) with JSON serialization in `lib/domain/entities/match_lineup_convocation.dart`
- [x] T006 [P] Create immutable `TeamLineupsTrackingState` container (`convocationsByTeamId`, `trackingByPlayerId`, `isLoading`, `isSaving`, `errorMessage`) in `lib/domain/entities/team_lineups_tracking_state.dart`
- [x] T007 [P] Extend `lib/domain/failures/app_failure.dart` with `LineupConvocationErrorCode` (`unauthorizedRole`, `teamNotFound`, `teamNotEligible`, `suspendedPlayerSelected`, `invalidStartersCount`, `missingCaptain`, `invalidTrackingMetrics`) and `LineupConvocationValidationFailure`
- [x] T008 [P] Define abstract `LineupsTrackingRepository` interface (`loadTrackingForTeam`, `savePlayerTracking`, `loadConvocationForTeam`, `saveConvocation`) in `lib/domain/repositories/lineups_tracking_repository.dart`
- [x] T009 Implement `LocalLineupsTrackingRepository` with JSON persistence (`'vifutbol.lineups.tracking.v1'` and `'vifutbol.lineups.convocations.v1'`) and `dev` seed tracking data (including `p-seed-atn-8` `Wilmar Barrios` with `pendingSuspensionMatches: 1` and `p-seed-atn-2` `Yerry Mina` with `yellowCards: 2`) in `lib/infrastructure/repositories/local_lineups_tracking_repository.dart`
- [x] T010 [P] Write unit tests for `PlayerInternalTracking`, `MatchLineupConvocation`, and `LocalLineupsTrackingRepository` in `test/unit/domain/lineup_and_tracking_entities_test.dart` and `test/unit/infrastructure/local_lineups_tracking_repository_test.dart`

**Checkpoint**: Domain & infrastructure foundation ready.

---

## Phase 3: User Story 1 - Convocatoria y Publicación de Alineación Oficial para un Partido (Priority: P1) 🎯 MVP

**Goal**: Allow the `Entrenador` (and `Organizador`) to select starters (`requiredStarters = min(minPlayersPerTeam, 11)`), designate a mandatory starter captain, select eligible substitutes, confirm/re-confirm the official match convocation, and synchronize the roster with the `Árbitro`'s digital report view (`FR-001`, `FR-002`, `FR-005`).

**Independent Test**: Open `CoachLineupTrackingScreen` as `Entrenador` for `'Atlético Norte FC'`, select `7` starters, assign a captain, select `1..2` substitutes, confirm the convocation, and verify that switching to the `Árbitro` view shows the synchronized official starters (with captain badge) and substitutes.

### Implementation & Tests for User Story 1

- [x] T011 [US1] Implement `ManageLineupsTrackingUseCase` with `requiredStartersForTournament`, `updateDraftSelection`, `confirmOfficialConvocation`, and role capability guards (`RoleCapability.manageLineups` / `RoleCapability.manageTournaments`) in `lib/application/use_cases/manage_lineups_tracking_use_case.dart`
- [x] T012 [US1] Implement `LineupsTrackingController` (`StateNotifier<TeamLineupsTrackingState>`) and Riverpod providers (`lineupsTrackingRepositoryProvider`, `manageLineupsTrackingUseCaseProvider`, `lineupsTrackingControllerProvider`) in `lib/application/controllers/lineups_tracking_controller.dart` and `lib/application/providers/lineups_tracking_providers.dart`
- [x] T013 [US1] Create `CoachLineupTrackingScreen` with the `"Convocatoria"` builder tab (starter/substitute/captain selection, starter counter `selected/requiredStarters`, confirmation button) and `"Acta Arbitral"` synchronized roster tab for the `Árbitro` in `lib/presentation/teams/coach_lineup_tracking_screen.dart`
- [x] T014 [US1] Register `/tournaments/teams/lineup` (`AppRouter.teamLineupTrackingPath`) in `lib/presentation/navigation/app_router.dart` and add the navigation action button (`Key('open_team_lineup_tracking_button')`) in `lib/presentation/teams/team_roster_detail_screen.dart`

**Checkpoint**: User Story 1 (Convocation publication and referee roster synchronization) is functional and testable.

---

## Phase 4: User Story 2 - Bloqueo Automático de Sancionados y Seguimiento Interno del Plantel (Priority: P2)

**Goal**: Automatically lock players with active disciplinary suspensions (`"Suspendido (1 fecha)"`, `#EF4444` badge + disabled controls), highlight players at yellow card warning threshold (`"En capilla"`, `#F59E0B`), and provide the internal tracking panel (`matchesPlayed`, `goals`, `assists`, `yellowCards`, `redCards`, `pendingSuspensionMatches`) (`FR-003`, `FR-004`).

**Independent Test**: View `'Atlético Norte FC'` in `CoachLineupTrackingScreen`, verify `Wilmar Barrios` displays `"Suspendido (1 fecha)"` with disabled selection controls, verify `Yerry Mina` displays the yellow card accumulation warning badge, and inspect/edit player internal tracking metrics in the `"Seguimiento Interno"` tab.

### Implementation & Tests for User Story 2

- [x] T015 [US2] Enhance `ManageLineupsTrackingUseCase` and `LineupsTrackingController` with `updatePlayerInternalTracking` and automatic removal of newly suspended players from active draft selections in `lib/application/use_cases/manage_lineups_tracking_use_case.dart` and `lib/application/controllers/lineups_tracking_controller.dart`
- [x] T016 [US2] Implement the semantic disciplinary badges (`KickPulseBadgeVariant.live` `#EF4444` `"Suspendido ({count} fecha)"` with disabled selection controls, `KickPulseBadgeVariant.warning` `#F59E0B` `"En capilla ({count} TA)"`) and the `"Seguimiento Interno"` tab with player metric editing modal (`TextInputType.number`) in `lib/presentation/teams/coach_lineup_tracking_screen.dart`
- [x] T017 [P] [US2] Write unit tests for `ManageLineupsTrackingUseCase` and `LineupsTrackingController` covering starter count validation, mandatory captain, suspension blocking, and internal tracking updates in `test/unit/application/manage_lineups_tracking_use_case_test.dart` and `test/unit/application/lineups_tracking_controller_test.dart`

**Checkpoint**: User Stories 1 and 2 are complete and verified.

---

## Phase 5: User Story 3 - Conservación del Estado de Selección ante Interrupciones Móviles (Priority: P3)

**Goal**: Preserve partial convocation selections (`Titular`, `Suplente`, `Capitán`) across mobile lifecycle interruptions (`AppLifecycleState.paused` / `inactive` → `resumed`) and screen re-entry (`FR-006`).

**Independent Test**: Partially select starters and a captain without confirming, simulate `AppLifecycleState.paused` and `AppLifecycleState.resumed` (or navigate back and re-enter `CoachLineupTrackingScreen`), and verify the partial selection remains intact.

### Implementation & Tests for User Story 3

- [x] T018 [US3] Integrate `WidgetsBindingObserver` (`didChangeAppLifecycleState`) and immediate draft persistence/restoration in `lib/presentation/teams/coach_lineup_tracking_screen.dart`
- [x] T019 [US3] Write comprehensive widget tests covering all 3 Gherkin phases (official convocation confirmation + referee sync, suspended player `"Suspendido (1 fecha)"` disabled control, and mobile background lifecycle state preservation) in `test/widget/coach_lineup_tracking_widget_test.dart`

**Checkpoint**: All 3 user stories (`US1`, `US2`, `US3`) are complete and verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final quality gates (`flutter analyze`, `dart format`, `flutter test --coverage`) and Notion synchronization.

- [x] T020 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`, and `flutter test --coverage` across the entire repository to verify 0 static analysis issues and 100% passing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T001`..`T002`) — blocks all user stories.
- **Phase 3 (US1 - P1 MVP)**: Depends on Phase 2 (`T003`..`T010`).
- **Phase 4 (US2 - P2)**: Depends on Phase 3 (`T011`..`T014`).
- **Phase 5 (US3 - P3)**: Depends on Phase 4 (`T015`..`T017`).
- **Phase 6 (Polish)**: Depends on all user stories (`T001`..`T019`).

### Parallel Opportunities

- `T003`, `T004`, `T005`, `T006`, `T007`, and `T008` operate on separate files in `lib/domain/` and can run in parallel.
- `T010` (`lineup_and_tracking_entities_test.dart` & `local_lineups_tracking_repository_test.dart`) can run in parallel once `T003`..`T009` complete.
- `T017` (`manage_lineups_tracking_use_case_test.dart` & `lineups_tracking_controller_test.dart`) can run in parallel with UI refinements.

---

## Parallel Example: Foundational Domain Models

```bash
Task: "T003 [P] Create domain enumerations in lib/domain/entities/lineup_enums.dart"
Task: "T004 [P] Create PlayerInternalTracking entity in lib/domain/entities/player_internal_tracking.dart"
Task: "T005 [P] Create MatchLineupConvocation entity in lib/domain/entities/match_lineup_convocation.dart"
Task: "T006 [P] Create TeamLineupsTrackingState in lib/domain/entities/team_lineups_tracking_state.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Phase 1 (Localization & Seed Squad Expansion) and Phase 2 (Domain & Local Repository).
2. Complete Phase 3 (`US1`: Convocation selection, confirmation, and Referee roster view).
3. Validate `US1` independently.

### Incremental Delivery
1. Add Phase 4 (`US2`: Automatic suspension lock `"Suspendido (1 fecha)"`, yellow card warning badge, and internal tracking tab).
2. Add Phase 5 (`US3`: Mobile lifecycle draft preservation and Gherkin widget test suite).
3. Execute Phase 6 quality gates (`flutter analyze`, `dart format`, `flutter test --coverage`).
