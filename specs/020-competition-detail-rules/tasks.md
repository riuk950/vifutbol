# Tasks: Pestaña de Información y Reglas Oficiales de la Competición (HU 13.3)

**Input**: Design documents from `specs/020-competition-detail-rules/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-competition-rules-contracts.md`, `quickstart.md`  

**Organization**: Tasks are structured by user story to guarantee independent testability, clear priority ordering, and incremental delivery.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies).
- **[Story]**: Associated user story (e.g. `[US1]`, `[US2]`, `[US3]`, `[US4]`).
- Includes exact file paths for each task.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Spanish localization keys, code generation, and component scaffolding.

- [X] T001 Define Spanish localization keys for competition info tab (`competitionMainVenueTitle`, `competitionMainVenueAddress`, `competitionMainVenuePitches`, `competitionInfoNotFoundTitle`, `competitionInfoNotFoundDescription`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Role-based audit trail guard and component refactoring.

**⚠️ CRITICAL**: Must be completed before user story implementation.

- [X] T003 Update `TournamentRulesSummaryCard` in `lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart` to guard audit trail visibility strictly with `isOrganizer && tournament.auditTrail.isNotEmpty`
- [X] T004 Refactor `CompetitionInfoTabView` in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart` into a `ConsumerWidget` watching `tournamentsControllerProvider`, `activeUserRoleProvider`, `matchesControllerProvider`, and `venuesControllerProvider`

**Checkpoint**: Foundation ready — Audit trail role guard in place and `CompetitionInfoTabView` transformed to a reactive consumer widget.

---

## Phase 3: User Story 1 - Visualización del Sistema de Puntuación y Normativa Deportiva (Priority: P1) 🎯 MVP

**Goal**: Deliver official scoring system (pts for win, draw, loss), match parameters (half duration), squad limits (min/max players), and disciplinary policy in strictly read-only mode.

**Independent Test**: Navigate to `/competitions/:id`, select the "Información" tab, and verify that `TournamentRulesSummaryCard` renders scoring boxes, match parameters, and squad/discipline rows with no editing/action buttons.

### Implementation for User Story 1

- [X] T005 [US1] Integrate `TournamentRulesSummaryCard` inside `CompetitionInfoTabView` in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart` passing `onEditPressed: null`, `onTransitionStatusPressed: null`, `onBackupPressed: null`, and `onCloseSeasonPressed: null` (read-only mode)
- [X] T006 [P] [US1] Implement widget tests in `test/presentation/tournaments/competition_info_tab_view_test.dart` verifying scoring system metrics, match duration, squad limits, and disciplinary cards threshold

**Checkpoint**: User Story 1 complete — Official tournament rules and scoring system visible in read-only mode as independent MVP.

---

## Phase 4: User Story 2 - Criterios de Desempate Ordenados y Fechas Oficiales (Priority: P2)

**Goal**: Present the ordered hierarchical list of tiebreaker criteria and tournament validity dates (`DD/MM/AAAA`).

**Independent Test**: In the "Información" tab, verify that tiebreaker criteria are listed in strict hierarchical order (1. Diferencia de gol, 2. Goles a favor, etc.) and validity dates are displayed formatted in the header card.

### Implementation for User Story 2

- [X] T007 [US2] Verify and ensure tiebreaker criteria ordered list and formatted validity dates are rendered within `TournamentRulesSummaryCard` in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart`
- [X] T008 [P] [US2] Implement widget tests in `test/presentation/tournaments/competition_info_tab_view_test.dart` verifying tiebreaker ordering and date range formatting

**Checkpoint**: User Story 2 complete — Tiebreaker criteria and official dates operational.

---

## Phase 5: User Story 3 - Auditoría de Reglas Críticas para Organizadores (Priority: P3)

**Goal**: Expose the audit trail section exclusively for users with `UserRole.organizer` when entries exist, and hide it for all other roles or when empty.

**Independent Test**: Access the "Información" tab as `UserRole.organizer` and verify the audit trail appears if `auditTrail.isNotEmpty`. Switch active role to `UserRole.fan` or `UserRole.player` and verify the audit trail section is completely absent.

### Implementation for User Story 3

- [X] T009 [US3] Connect `activeUserRoleProvider` in `CompetitionInfoTabView` in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart` and pass `isOrganizer: activeRole == UserRole.organizer` to `TournamentRulesSummaryCard`
- [X] T010 [P] [US3] Implement widget tests in `test/presentation/tournaments/competition_info_tab_view_test.dart` verifying audit trail visibility for `organizer` role and invisibility for non-organizer roles (`fan`, `player`, `coach`, `referee`) or empty audit trail

**Checkpoint**: User Story 3 complete — Role-based security and audit governance operational.

---

## Phase 6: User Story 4 - Resiliencia, Estados de Carga y Sede Principal (Priority: P4)

**Goal**: Deliver friendly loading and not found states with `KickPulseStateView`, plus a dedicated primary venue summary card with name, address, and pitches count.

**Independent Test**: Load a tournament with an invalid ID and verify `KickPulseStateView` is displayed. For a valid tournament, verify that the primary venue card is rendered below the rules summary with name, address, and pitches badge.

### Implementation for User Story 4

- [X] T011 [US4] Implement loading state (`CircularProgressIndicator` with `Key('competition_detail_info_loading')`) and not found state (`KickPulseStateView` with `Key('competition_detail_info_not_found')`) in `CompetitionInfoTabView` in `lib/presentation/tournaments/widgets/competition_info_tab_view.dart`
- [X] T012 [US4] Implement primary sports venue resolution and summary card (`Key('competition_main_venue_card')`) in `CompetitionInfoTabView` displaying venue name, address, and active pitches count badge, or omitting gracefully if no venue is resolved
- [X] T013 [P] [US4] Implement widget tests in `test/presentation/tournaments/competition_info_tab_view_test.dart` verifying loading, not found, primary venue rendering, and omission when venue is absent

**Checkpoint**: User Story 4 complete — Resilient state handling and primary venue card fully functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Screen integration, responsive verification, and code quality.

- [X] T014 Run full integration test in `test/presentation/tournaments/competition_detail_screen_test.dart` verifying smooth switching between "Partidos", "Clasificación" and "Información" tabs
- [X] T015 [P] Run responsive layout tests in `test/presentation/directories_responsive_widget_test.dart` asserting zero `RenderFlex` overflows at $320 \times 640\text{ px}$ with $130\%$ text scaling
- [X] T016 [P] Execute static analysis (`flutter analyze`) and code formatting (`dart format --output=none --set-exit-if-changed .`)
- [X] T017 Verify all visual scenarios from `specs/020-competition-detail-rules/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 completion — blocks all user stories.
- **User Stories (Phase 3+)**:
  - `US1` (MVP - Rules & Scoring): Depends on Phase 2.
  - `US2` (Tiebreakers & Dates): Depends on Phase 2; complements `US1`.
  - `US3` (Audit Trail Guard): Depends on Phase 2; complements `US1`.
  - `US4` (Loading, Empty & Venue Card): Depends on Phase 2; complements `US1`.
- **Polish (Phase 7)**: Depends on completion of all user story phases.

### Parallel Opportunities

- T001 and T003 can be prepared in parallel.
- All widget tests (`T006`, `T008`, `T010`, `T013`) can be implemented in the test suite file `test/presentation/tournaments/competition_info_tab_view_test.dart`.
- T015 and T016 can execute in parallel during Polish.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1 (Localization keys & `flutter gen-l10n`).
2. Complete Phase 2 (Foundational refactor & audit guard).
3. Complete Phase 3 (US1 - Scoring & parameters in read-only mode).
4. Run independent widget test to validate MVP.

### Incremental Delivery
1. Add US2: Tiebreaker order & dates.
2. Add US3: Role-segregated audit trail.
3. Add US4: Primary venue card & empty/loading states.
4. Execute full suite & responsive validation.
