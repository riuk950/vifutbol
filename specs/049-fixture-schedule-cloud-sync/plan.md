# Implementation Plan: Fixture Generation, Match Scheduling Cloud Synchronization, and Daily Matches Visibility

**Branch**: `049-fixture-schedule-cloud-sync` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/049-fixture-schedule-cloud-sync/spec.md` (HU 22.1)

## Summary

Guarantee reliable, idempotent, offline-first cloud persistence and synchronization for generated competition fixtures and individual match schedules in `vifutboldev.matches` (Supabase DEV), and ensure all scheduled matches automatically surface in the main **Partidos** screen (`MatchdayTabView`) across all five user roles.

Key technical changes identified during Phase 0 research ([research.md](research.md)):
1. **Remote Pruning + Idempotent Batch Upsert**: Add `replaceForTournament(tournamentId, matches)` to `TournamentMatchesRemoteDataSource` (`PostgrestTournamentMatchesRemoteDataSource`) and wire it into `HybridTournamentMatchesRepository.replaceMatchesForTournament` and `replayOutboxItem` (`replaceBatch`), pruning stale remote rows before upserting so fixture regeneration (FR-002a) leaves zero orphaned or duplicate rows.
2. **Canonical Deterministic UUIDs**: Normalize generated fixture match IDs to deterministic UUIDv5 (`HybridRepositorySupport.ensureUuid(id, 'match')`) prior to local Hive persistence so local IDs and `vifutboldev.matches.id` match 1:1 immediately without drift.
3. **Reactive Cloud-Hydrated Daily Matches Feed**: Add `loadAllMatches({bool silent})` to `MatchesCatalogController`, merge (rather than wipe) tournament-scoped updates in `loadTournamentMatches`, and upgrade `DailyMatchesFeedController` + `MatchdayTabView` to listen reactively to `matchesCatalogControllerProvider` and `tournamentsControllerProvider` while executing cache-first + cloud refresh on tab entry/return, date selection, and pull-to-refresh (FR-010).
4. **Optional Scheduling Logistics & UX Guards**: Make `venue`, `pitch`, and `referee` optional in `FixtureSchedulingUseCase.scheduleMatch`, `MatchesCatalogController.scheduleMatch`, and `ScheduleMatchDialog` (only date + start time mandatory per FR-004/FR-008), update collision detection to handle null pitch/referee safely, add Spanish `"Por definir"` fallbacks in match cards via `l10n`, guard against duplicate taps, and prompt confirmation before regenerating an existing unstarted fixture.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (null-safe)

**Primary Dependencies**: `flutter_riverpod` (state management), `supabase_flutter` (PostgREST & GoTrue client), `hive_ce` / `LocalStorageRepository` (local persistence), `clock` (testable time), `flutter_localizations` / `AppLocalizations` (`app_es.arb`)

**Storage**: Local Hive (`LocalTournamentMatchesRepository` + `SyncOutboxQueue`) synced offline-first to PostgreSQL (`vifutboldev.matches`, `vifutboldev.match_referees`, `vifutboldev.tournament_teams`, `vifutboldev.tournaments`, `vifutboldev.sports_venues`, `vifutboldev.venue_pitches`) on self-hosted Supabase DEV.

**Testing**: `flutter test` (unit tests for repositories, use cases, controllers; widget tests for `ScheduleMatchDialog`, `CompetitionDetailScreen`, `MatchdayTabView`), plus live verification against Supabase DEV.

**Target Platform**: iOS & Android mobile app (Flutter).

**Project Type**: Mobile application (Clean Architecture: `domain` / `application` / `infrastructure` / `presentation`).

**Performance Goals**: Immediate render from local Hive cache (< 100 ms); cloud refresh and visibility of scheduled matches in `MatchdayTabView` within 5 seconds (SC-002); batch upsert of full league fixture (e.g., 20 teams = 190–380 matches) in a single PostgREST call without blocking the UI thread.

**Constraints**: Offline-first with FIFO outbox (`SupabaseCloudSyncService`), strict RBAC (organizer-only mutations, public/authenticated read), zero hardcoded Spanish UI strings (all via `lib/l10n/app_es.arb`), zero `flutter analyze` warnings/errors.

**Scale/Scope**: Competitions up to 20+ teams (up to ~380 matches per league fixture) across multiple concurrent tournaments; 5 user roles (`organizer`, `coach`, `referee`, `player`, `fan`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: PASS — `spec.md` created, validated (16/16), and clarified (3 high-impact clarifications integrated) prior to planning. Incorporates `docs/MOBILE_GUIDELINES.md`.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS — Deterministic UUIDv5 IDs align local Hive and `vifutboldev.matches`; `replaceForTournament` prunes stale rows on regeneration; foreign keys (`tournament_id`, `home_tournament_team_id`, `away_tournament_team_id`, `venue_id`, `pitch_id`, `referee_id`) preserved.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS — Plan includes unit tests for `HybridTournamentMatchesRepository` (batch replace, prune + upsert, outbox replay), `FixtureSchedulingUseCase` (optional logistics, collision checks, regeneration guard), `DailyMatchesFeedController` (reactive cloud hydration), and widget tests for `ScheduleMatchDialog` and `MatchdayTabView`.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS — Domain (`FixtureSchedulingUseCase`, `RoundRobinGenerator`, `TournamentMatchesRepository`) remains decoupled from Supabase/Hive; infrastructure (`HybridTournamentMatchesRepository`, `PostgrestTournamentMatchesRemoteDataSource`) encapsulates PostgREST & outbox replay; presentation (`MatchdayTabView`, `ScheduleMatchDialog`) interacts only with Riverpod controllers.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS — Organizer-only mutations enforced both in `FixtureSchedulingUseCase` (`RoleCapability.manageTournaments`) and PostgreSQL RLS (`matches_insert_organizer`, `matches_update_organizer_or_referee`, `matches_delete_organizer`). UI uses `KickPulseColors`, `KickPulseRadiiSpacing`, `KickPulseStateView`.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS — All code, identifiers, and tests in English; all user-facing strings (confirmation dialogs, `"Por definir"` placeholders, error/success messages) in Spanish via `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: PASS — Offline queueing, automatic reconnect flush, cache-first instant render + background refresh, duplicate-tap guards (`isSaving`), explicit loading/empty/error/success states, and UTC↔local timezone handling explicitly addressed.

*Post-Design Re-Check*: All 7 principles remain PASS with zero violations.

## Project Structure

### Documentation (this feature)

```text
specs/049-fixture-schedule-cloud-sync/
├── plan.md                                  # This file (/speckit-plan output)
├── research.md                              # Phase 0 audit & technical decisions
├── data-model.md                            # Phase 1 entity mapping & state transitions
├── quickstart.md                            # Phase 1 runnable validation & E2E guide
├── contracts/
│   └── matches_cloud_sync_contract.md       # Phase 1 repository, use case & controller contracts
├── checklists/
│   └── requirements.md                      # Spec quality checklist (16/16 passing)
└── tasks.md                                 # Phase 2 output (/speckit-tasks - NOT created here)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── services/
│   │   └── round_robin_generator.dart                      # Deterministic UUIDv5 match IDs
│   └── repositories/
│       └── tournament_matches_repository.dart              # Repository interface (verified)
├── application/
│   ├── use_cases/
│   │   └── fixture_scheduling_use_case.dart                # Optional venue/pitch/referee + nullable collision checks + regeneration guard
│   ├── controllers/
│   │   ├── matches_catalog_controller.dart                 # Add loadAllMatches(), merge per-tournament updates, guard isSaving
│   │   └── daily_matches_feed_controller.dart              # Reactive ref.listen + cache-first refreshFromCloud()
│   └── providers/
│       └── matches_catalog_providers.dart                  # Ensure repository & feed providers wire cleanly
├── infrastructure/
│   └── repositories/
│       └── hybrid_tournament_matches_repository.dart       # Add replaceForTournament() pruning + upsert, canonical UUIDs, outbox replay
├── presentation/
│   ├── shell/
│   │   └── tabs/
│   │       └── matchday_tab_view.dart                      # Trigger refreshFromCloud() on init/return/date-change/pull-to-refresh
│   ├── matches/
│   │   └── widgets/
│   │       ├── schedule_match_dialog.dart                  # Optional venue/pitch/referee + double-tap guard
│   │       └── match_card.dart                             # Spanish "Por definir" fallbacks for optional logistics
│   └── tournaments/
│       └── competition_detail_screen.dart                  # Confirmation dialog on fixture regeneration + refresh daily feed
└── l10n/
    └── app_es.arb                                          # New Spanish l10n keys (regeneration confirmation, "Por definir")

test/
├── infrastructure/
│   └── repositories/
│       └── hybrid_tournament_matches_repository_test.dart  # Batch replace, stale pruning, outbox replay, idempotency
├── unit/
│   └── application/
│       ├── fixture_scheduling_use_case_test.dart           # Optional logistics, collision checks, regeneration guard
│       └── daily_matches_feed_controller_test.dart         # Cloud hydration, date filtering, unscheduled exclusion
└── presentation/
    ├── tournaments/
    │   └── competition_fixture_widget_test.dart            # Regeneration confirmation, optional scheduling form, double-tap guard
    └── matches/
        └── matchday_tab_view_test.dart                     # Cache-first render, cloud refresh on tab/date/pull-to-refresh
```

**Structure Decision**: Follows the existing single-project Flutter Clean Architecture layout (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`, `lib/l10n`, `test/`). No new backend SQL migration is required because `vifutboldev.matches` already contains all required columns, indexes, and RLS policies.

## Complexity Tracking

> No Constitution Check violations; table intentionally left empty.
