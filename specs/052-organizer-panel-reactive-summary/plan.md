# Implementation Plan: Reactive Organizer Panel Summary with Cloud-Synchronized Data

**Branch**: `052-organizer-panel-reactive-summary` | **Date**: 2026-11-19 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/052-organizer-panel-reactive-summary/spec.md)  
**Input**: Feature specification from `/specs/052-organizer-panel-reactive-summary/spec.md` (Notion HU 22.4)

---

## Summary

Make the Organizer Panel's General Summary ("Torneos Activos", "Partidos por Programar", "Torneos sin Fixture") and "Mis Competiciones" cards 100% reactive to in-memory mutations and automatically hydrated from Supabase DEV (`vifutboldev`) on cold start, account switch, background `CloudSyncService` completion, and pull-to-refresh—strictly isolated to `organizerId == currentUserId` with zero new SQL migrations.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter (null-safe, Riverpod 2.x)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `flutter_localizations` (`app_es.arb`)  
**Storage**: Existing dual-layer offline-first cache + Supabase PostgREST (`vifutboldev.tournaments`, `vifutboldev.tournament_teams`, `vifutboldev.matches`)  
**Testing**: `flutter_test` (unit + widget tests) + `flutter analyze`  
**Target Platform**: Android & iOS (mobile-first)  
**Project Type**: Mobile app (Clean Architecture: `domain` / `application` / `infrastructure` / `presentation`)  
**Performance Goals**: < 1s reactive counter recalculation on local mutations (SC-001); < 5s cold-start cloud hydration (SC-004)  
**Constraints**: Strict organizer isolation (`organizerId == currentUserId`, HU 19.3), instant back-navigation reactivity without redundant network fetches (Clarification Q2), non-destructive offline cache retention, Spanish UI via `l10n`, English technical identifiers  
**Scale/Scope**: 2 application provider files (`tournaments_providers.dart`, `sync_bootstrap_provider.dart`) + 2 presentation widget files (`organizer_panel_content.dart`, `organizer_competitions_section.dart`) + 4 test files

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Pre-Design | Post-Design | Verification Notes |
|---|---|---|---|
| **I. Spec-Driven & Incremental Delivery** | PASS | PASS | Driven by `spec.md` + 2 resolved clarifications (`openRegistration`+`inProgress` active scope; in-memory reactive + init/sync/pull-to-refresh hydration). |
| **II. Data Integrity & Persistence Reliability** | PASS | PASS | Pure deterministic metric calculation (`computeOrganizerPanelMetrics`) scoped strictly to active owned competitions; post-sync callbacks refresh controllers from cloud truth. |
| **III. Automated Tests & Quality Gate** | PASS | PASS | Unit tests for all metric transitions + widget tests for live updates, cold-start hydration, pull-to-refresh, and account isolation; `flutter analyze` must report 0 issues. |
| **IV. Clean Architecture & Modularity** | PASS | PASS | Pure calculation & post-sync wiring stay in `application/providers/`; UI hydration & rendering stay in `presentation/panel/widgets/`. |
| **V. Role-Based Security & KickPulse Design System** | PASS | PASS | Organizer-only access preserved in `PanelScreen` and strict `organizerId == currentUserId` filtering in `organizerTournamentsProvider`; KickPulse cards/badges used consistently. |
| **VI. English Codebase & Spanish UI Localization** | PASS | PASS | All identifiers/tests in English; reuses existing Spanish `l10n` keys (`competitionTeamsHeaderCount`, `organizerSummaryTitle`, etc.). |
| **VII. Mobile Engineering & Usability Resilience** | PASS | PASS | `_isHydrating` concurrency guard, `RefreshIndicator` with `AlwaysScrollableScrollPhysics`, non-destructive offline cache retention, compact screen overflow safety. |

---

## Project Structure

### Documentation (this feature)

```text
specs/052-organizer-panel-reactive-summary/
├── spec.md                                                  # Feature specification + clarifications
├── checklists/requirements.md                               # Spec quality checklist (16/16 PASS)
├── plan.md                                                  # This file (/speckit-plan output)
├── research.md                                              # Phase 0 codebase audit
├── data-model.md                                            # Derived aggregates & reactive triggers
├── quickstart.md                                            # Automated tests & manual E2E scenarios
├── contracts/
│   └── organizer_panel_reactive_summary_contract.md         # Provider, sync & UI contracts
└── tasks.md                                                 # Phase 2 output (/speckit-tasks — not created yet)
```

### Source Code (repository root)

```text
lib/
├── application/
│   └── providers/
│       ├── tournaments_providers.dart                       # Refine computeOrganizerPanelMetrics (exclude finished/completed from pendingScheduleMatchesCount)
│       └── sync_bootstrap_provider.dart                     # Register CloudSyncService afterSyncCallback to refresh tournaments/teams/matches controllers
└── presentation/
    └── panel/
        └── widgets/
            ├── organizer_panel_content.dart                 # Convert to ConsumerStatefulWidget: initState() parallel hydration, auth user change listener, RefreshIndicator
            └── organizer_competitions_section.dart          # Watch teamsControllerProvider and render live enrolled team count badge per competition card

test/
├── unit/
│   └── application/
│       └── organizer_panel_metrics_test.dart                # Extend tests: create tournament, generate/regenerate fixture, schedule match, finish/delete tournament, multi-organizer isolation
└── presentation/
    └── panel/
        ├── organizer_panel_widget_test.dart                 # Extend tests: live reactive updates without restart, cold-start hydration, pull-to-refresh, team count badge parity
        ├── organizer_competitions_addition_verification_test.dart # Verify existing suite passes with live hydration & team badge
        └── panel_screen_test.dart                           # Verify PanelScreen integration with stateful OrganizerPanelContent
```

**Structure Decision**: Existing Flutter Clean Architecture layout (`lib/` + `test/`). Zero new dependencies or SQL migrations required.

---

## Complexity Tracking

> No Constitution violations. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | — | — |
