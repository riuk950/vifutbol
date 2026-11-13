---

description: "Actionable, dependency-ordered task list for HU 19.3: Organizer Panel Exclusive Summary and Metrics"
---

# Tasks: Panel de Organización: Resumen y Métricas Exclusivas de Competiciones del Organizador Autenticado (HU 19.3)

**Input**: Design documents from `/Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/data-model.md), [organizer-panel-metrics-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/contracts/organizer-panel-metrics-contracts.md), [quickstart.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/quickstart.md)

**Tests**: Included per story in accordance with Project Constitution Principle III (`Pruebas Automatizadas`) and [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/plan.md).

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Parallelizable task (independent files, no unmet prerequisite dependencies).
- **[US1]..[US2]**: User story traceability matching `spec.md`.

---

## Phase 1: Foundational (Strict Organizer Filtering & Pure Metrics Helper)

**Purpose**: Fix strict organizer isolation in `organizerTournamentsProvider` and implement the deterministic pure calculation helper before wiring the presentation layer.

- [X] T001 Enforce strict `t.organizerId == effectiveUserId` filtering in `organizerTournamentsProvider` in `lib/application/providers/tournaments_providers.dart` (falling back to `'org-seed-1'` only when no authenticated session exists)
- [X] T002 Implement `computeOrganizerPanelMetrics({required List<ChampionshipTournament> organizerTournaments, required List<ChampionshipMatch> allMatches})` and `organizerPanelMetricsProvider` in `lib/application/providers/tournaments_providers.dart` (depends on T001)

**Checkpoint**: Provider layer ready — strict organizer isolation and metrics calculation tested and exposed via Riverpod.

---

## Phase 2: User Story 1 - Aislamiento de Métricas Superiores por Organizador Autenticado (Priority: P1) 🎯 MVP

**Goal**: Connect `OrganizerPanelContent` to `organizerPanelMetricsProvider` so "Torneos Activos", "Partidos por Programar", and "Torneos sin Fixture" strictly exclude tournaments and matches of other organizers.

**Independent Test**: Authenticate as a specific organizer with other organizers' tournaments and matches present, render `OrganizerPanelContent`, and verify all 3 metric cards show only the authenticated organizer's counts (or `0` when none exist).

- [X] T003 [US1] Update `OrganizerPanelContent` in `lib/presentation/panel/widgets/organizer_panel_content.dart` to consume `ref.watch(organizerPanelMetricsProvider)` for `activeTournamentsCount`, `pendingScheduleMatchesCount`, and `unseededTournamentsCount` (depends on T002)
- [X] T004 [P] [US1] Write unit tests in `test/unit/application/organizer_panel_metrics_test.dart` verifying strict isolation (`organizerId == currentUserId`, excluding `org-seed-1` when authenticated, fallback when unauthenticated, zero counts when organizer has no tournaments, and match filtering by organizer tournament IDs) (depends on T001, T002)
- [X] T005 [P] [US1] Update widget tests in `test/presentation/panel/organizer_panel_widget_test.dart` verifying `organizer_metric_active_tournaments`, `organizer_metric_pending_matches`, and `organizer_metric_unseeded_tournaments` exclude other organizers' competitions and matches (depends on T003)

**Checkpoint**: User Story 1 (P1 MVP isolated metrics) is independently functional and verified.

---

## Phase 3: User Story 2 - Consistencia entre Resumen de Métricas y Listado "Mis Competiciones" (Priority: P1)

**Goal**: Ensure 1-to-1 numerical consistency and immediate reactive updates between the top metric cards and the "Mis Competiciones" section when tournaments are created, updated, or deleted.

**Independent Test**: Create a new tournament owned by the authenticated organizer and verify that both "Mis Competiciones" and the metric cards increment immediately.

- [X] T006 [US2] Verify and add reactive integration/widget tests in `test/presentation/panel/organizer_competitions_addition_verification_test.dart` and `test/presentation/panel/organizer_panel_widget_test.dart` confirming 1-to-1 parity between `organizerTournamentsProvider` and `organizerPanelMetricsProvider` when adding/updating/deleting competitions (depends on T003)

**Checkpoint**: Both User Stories (US1 & US2) are functional and verified by automated tests.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Validate static analysis, formatting, and test suites.

- [X] T007 Run `flutter analyze` and resolve all warnings and lint errors across `lib/` and `test/`
- [X] T008 [P] Run `dart format lib/ test/` to enforce consistent code formatting
- [X] T009 Run target test suite (`flutter test test/unit/application/organizer_panel_metrics_test.dart test/presentation/panel/organizer_panel_widget_test.dart test/presentation/panel/organizer_competitions_addition_verification_test.dart test/presentation/panel_screen_test.dart test/presentation/panel/organizer_competitions_section_test.dart test/presentation/panel/organizer_competitions_responsive_test.dart`) verifying 100% pass rate

---

## Dependencies & Execution Order

- **Phase 1 (Foundational)**: `T001` → `T002`.
- **Phase 2 (US1)**: Depends on `T002`. `T004` and `T005` can run in parallel once `T003` is ready.
- **Phase 3 (US2)**: Depends on `T003`.
- **Phase 4 (Polish)**: Depends on Phases 1–3.

## Implementation Strategy

- **MVP Scope**: Phases 1 & 2 (`T001`–`T005`) deliver strict multiorganizer metric isolation.
- **Incremental Delivery**: Phase 3 (`T006`) verifies reactive parity with "Mis Competiciones", followed by Phase 4 quality gates (`T007`–`T009`).
