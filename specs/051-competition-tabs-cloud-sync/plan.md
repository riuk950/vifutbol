# Implementation Plan: Cloud Persistence and Synchronization for Competition Standings, Teams, and Information Tabs

**Branch**: `051-competition-tabs-cloud-sync` | **Date**: 2026-11-19 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/051-competition-tabs-cloud-sync/spec.md)  
**Input**: Feature specification from `/specs/051-competition-tabs-cloud-sync/spec.md` (Notion HU 22.3)

---

## Summary

Guarantee end-to-end cloud persistence, lossless rule/audit synchronization, remote pruning of withdrawn team enrollments, deterministic standings computation, parallel cold-start hydration across all four competition detail tabs ("Fixture", "Clasificación", "Equipos", "Información"), pull-to-refresh support, and strict dependency-ordered offline outbox replay (`venue → tournament → team → match → matchReport → seasonHonorRoll`) against the existing `vifutboldev` Supabase schema with zero new SQL migrations.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter (null-safe, Riverpod 2.x)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `shared_preferences`, `uuid`, `flutter_localizations` (`app_es.arb`)  
**Storage**: Dual-layer offline-first — Local `SharedPreferences` JSON cache + `SyncOutboxItem` queue ↔ Remote PostgreSQL via Supabase PostgREST (`vifutboldev` schema: `tournaments`, `rule_audit_entries`, `teams`, `tournament_teams`, `season_honor_rolls`, `tournament_matches`, `match_reports`, `venues`)  
**Testing**: `flutter_test` (unit, repository, sync-engine, and widget tests) + `flutter analyze`  
**Target Platform**: Android & iOS (mobile-first) + macOS/Web testability  
**Project Type**: Mobile app (Clean Architecture: `domain` / `application` / `infrastructure` / `presentation`)  
**Performance Goals**: Cold-start parallel cloud hydration of all 4 competition detail tabs in < 5 seconds on normal mobile connectivity (SC-005); instant local cache render on frame 1  
**Constraints**: Offline-first resilience (cached data remains viewable offline, no destructive cache wipes on transient network errors), strict FK dependency ordering during outbox flush (zero `23503` errors), RBAC organizer-only writes, Spanish UI strings via `lib/l10n/app_es.arb`, English technical identifiers  
**Scale/Scope**: Single competition detail flow (4 tabs) + 3 infrastructure files (`HybridTournamentsRepository`, `HybridTeamsRepository`, `SupabaseCloudSyncService`) + 1 application controller (`StandingsAndRankingsController`) + 5 presentation files (`CompetitionDetailScreen` + 4 tab views)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Pre-Design | Post-Design | Verification Notes |
|---|---|---|---|
| **I. Spec-Driven & Incremental Delivery** | PASS | PASS | Driven by `spec.md` with 2 resolved clarifications, scoped strictly to HU 22.3 (dashboard metrics deferred to HU 22.4). |
| **II. Data Integrity & Persistence Reliability** | PASS | PASS | Deterministic UUIDv5 normalization before local & remote writes; remote pruning of withdrawn `tournament_teams`; lossless JSONB `rules_config` with backward-compatible defaults; dependency-ordered outbox replay prevents `23503` FK errors. |
| **III. Automated Tests & Quality Gate** | PASS | PASS | Dedicated unit/repository/sync/widget tests planned in `test/infrastructure/` and `test/presentation/tournaments/`; `flutter analyze` must report 0 issues. |
| **IV. Clean Architecture & Modularity** | PASS | PASS | Changes stay strictly within their layers: repository normalization/pruning & outbox ordering in `infrastructure/`, standings refresh in `application/`, hydration & pull-to-refresh in `presentation/`. Zero domain logic leaked into UI. |
| **V. Role-Based Security & KickPulse Design System** | PASS | PASS | Organizer-only mutation guards preserved in UI (`RolePermissionMatrix`) and enforced by PostgreSQL RLS; KickPulse tokens & `KickPulseStateView` used for loading/empty/error states. |
| **VI. English Codebase & Spanish UI Localization** | PASS | PASS | All identifiers, files, tests, and comments in English; any new user-facing feedback or error strings added to `lib/l10n/app_es.arb` and generated via `flutter gen-l10n`. |
| **VII. Mobile Engineering & Usability Resilience** | PASS | PASS | Duplicate-tap guards (`isSaving` / `_isHydrating`) on team & competition actions; `RefreshIndicator` with `AlwaysScrollableScrollPhysics`; offline cached content preserved without crashes. |

---

## Project Structure

### Documentation (this feature)

```text
specs/051-competition-tabs-cloud-sync/
├── spec.md                                              # Feature specification + clarifications
├── checklists/requirements.md                           # Spec quality checklist (16/16 PASS)
├── plan.md                                              # This file (/speckit-plan output)
├── research.md                                          # Phase 0 codebase & DB audit
├── data-model.md                                        # Entity mappings & outbox dependency graph
├── quickstart.md                                        # Automated tests & manual E2E scenarios
├── contracts/
│   └── competition_tabs_cloud_sync_contract.md          # Repository, sync & hydration contracts
└── tasks.md                                             # Phase 2 output (/speckit-tasks — not created yet)
```

### Source Code (repository root)

```text
lib/
├── infrastructure/
│   ├── repositories/
│   │   ├── hybrid_tournaments_repository.dart           # UUIDv5 normalization before local & remote writes + lossless rules/audit sync
│   │   └── hybrid_teams_repository.dart                 # UUIDv5 normalization + remote pruning of withdrawn enrollments in replaceForTournament
│   └── sync/
│       └── supabase_cloud_sync_service.dart             # Dependency-ordered outbox flush (venue → tournament → team → match → matchReport → honorRoll)
├── application/
│   └── controllers/
│       └── standings_and_rankings_controller.dart       # Non-destructive refresh retaining cached snapshot on transient offline errors
├── presentation/
│   └── tournaments/
│       ├── competition_detail_screen.dart               # initState() parallel cloud hydration + shared _hydrateCompetitionData() callback
│       └── widgets/
│           ├── competition_info_tab_view.dart           # RefreshIndicator + tournament.venueIds-first venue resolution
│           ├── competition_teams_tab_view.dart          # RefreshIndicator + duplicate-tap guards on group move / withdrawal / eligibility toggle
│           ├── competition_standings_tab_view.dart      # RefreshIndicator wired to full competition hydration + standings recomputation
│           └── competition_fixture_tab_view.dart        # Optional onRefresh callback hook to unify pull-to-refresh across all 4 tabs
└── l10n/
    └── app_es.arb                                       # Spanish localization strings if any new error/offline feedback keys are needed

test/
├── infrastructure/
│   ├── repositories/
│   │   ├── hybrid_tournaments_repository_test.dart      # Lossless rules_config round-trip, backward-compatible defaults, UUID normalization, rule audit dedup
│   │   └── hybrid_teams_repository_test.dart            # Enrollment/group/eligibility sync, remote pruning on withdrawal, UUID normalization
│   └── sync/
│       └── supabase_cloud_sync_service_test.dart        # Dependency-ordered outbox flush tests (mixed out-of-order offline queue → strict FK replay)
└── presentation/
    └── tournaments/
        └── competition_detail_screen_test.dart          # Cold-start parallel hydration, pull-to-refresh, venueIds resolution, duplicate-tap guard, RBAC read-only
```

**Structure Decision**: Existing Flutter Clean Architecture single-project layout (`lib/` + `test/`). No new packages, no new SQL migrations, and no new architectural layers are required.

---

## Complexity Tracking

> No Constitution violations. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | — | — |
