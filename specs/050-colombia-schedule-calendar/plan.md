# Implementation Plan: Unrestricted Future Match Calendar and Colombia Time Zone (12-Hour AM/PM) Standardization

**Branch**: `050-colombia-schedule-calendar` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/050-colombia-schedule-calendar/spec.md` (HU 22.2)

## Summary

Standardize all match scheduling, calendar navigation, day grouping, and time rendering across `vifutbol` onto official **Colombia time (`America/Bogota`, fixed UTC-5)** with zero-padded **12-hour uppercase AM/PM** formatting (`08:00 AM`, `04:00 PM`, `09:00 PM`, `12:00 PM`, `12:00 AM`), and remove restrictive upper/lower tournament date caps in favor of an unrestricted future horizon up to `2100-12-31`.

Key technical components ([research.md](research.md)):
1. **Centralized `ColombiaTimeUtils` (`lib/domain/services/colombia_time_utils.dart`)**: Pure-Dart utility providing bidirectional `UTC ↔ Colombia (UTC-5)` conversion, Colombia calendar-day extraction (`colombiaDateOnly`), Colombia-anchored `todayColombia`/`presentMinuteUtc`, and deterministic zero-padded 12h AM/PM formatting (`formatTime12h`, `formatTimeOfDay12h`, `formatDate`, `formatDateTime12h`, `formatDateTimeRange12h`).
2. **Unrestricted Future Date Pickers & Forced 12h AM/PM Time Picker**:
   - `ScheduleMatchDialog`: `firstDate = ColombiaTimeUtils.todayColombia()`, `lastDate = DateTime(2100, 12, 31)` (no tournament start/end clamping); `showTimePicker` wrapped with `MediaQuery(alwaysUse24HourFormat: false)`; submit converts Colombia wall-clock input to UTC via `ColombiaTimeUtils.fromColombiaWallClock(...)`.
   - `AppShellScreen` (`_onPickCalendarDate`): `firstDate = DateTime(2000, 1, 1)`, `lastDate = DateTime(2100, 12, 31)`.
3. **Colombia Calendar-Day Grouping & UTC Persistence**:
   - `DailyMatchesFeedController`, `MatchesCatalogState`, `MatchesCatalogController`, and `FixtureSchedulingUseCase` use `ColombiaTimeUtils` so evening matches (`7:00 PM – 11:59 PM` Colombia = `00:00 – 04:59 UTC` next day) never jump to the wrong day, and `PostgrestTournamentMatchesRemoteDataSource._fromRow` preserves UTC instants cleanly.
4. **Uniform AM/PM Display Across All Match Views**:
   - Update `MatchCenterCard`, `MatchCard`, `CompetitionFixtureTabView`, `TeamMatchesTabView`, and `TeamInfoTabView` to format times exclusively via `ColombiaTimeUtils`, verifying compact-screen / text-scale fit.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (null-safe)

**Primary Dependencies**: `clock` (testable time), `flutter_riverpod`, `supabase_flutter`, `intl` (existing), `AppLocalizations` (`app_es.arb`)

**Storage**: Local Hive (`ChampionshipMatch` ISO-8601 UTC) & Supabase DEV PostgreSQL (`vifutboldev.matches.scheduled_at` / `scheduled_end_at` as `timestamptz` UTC). No DB migration required.

**Testing**: `flutter test` — unit tests (`colombia_time_utils_test.dart`, `fixture_scheduling_use_case_test.dart`, `daily_matches_feed_controller_test.dart`) and widget tests (`schedule_match_dialog_test.dart`, `match_center_card_test.dart`, `matchday_tab_view_test.dart`, `competition_fixture_widget_test.dart`, `team_matches_schedule_test.dart`).

**Target Platform**: iOS & Android mobile app (Flutter).

**Project Type**: Mobile application (Clean Architecture: `domain` / `application` / `infrastructure` / `presentation`).

**Performance Goals**: Zero-overhead pure arithmetic conversions (< 1 ms per batch of 380 matches); zero startup timezone database loading.

**Constraints**: Permanent UTC-5 offset (no DST in Colombia), zero device-timezone leakage, zero 24-hour displays in match views, zero overflow on 320px/1.3x text-scale mobile screens, zero `flutter analyze` issues.

**Scale/Scope**: All match scheduling and viewing surfaces across 5 user roles.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda**: PASS — `spec.md` created, validated (16/16), and clarified (2 clarifications integrated) before planning.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS — All persisted timestamps remain canonical UTC instants (`timestamptz`), projected deterministically to Colombia (UTC-5) on read/group/display.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS — Comprehensive unit tests for midnight UTC boundaries (`9:00 PM` Colombia = `02:00 AM` UTC next day), `12:00 AM`/`12:00 PM`, and widget tests for future dates and AM/PM rendering.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS — `ColombiaTimeUtils` resides in `lib/domain/services/` with zero Flutter/Supabase dependencies.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS — Uses existing `KickPulseColors`, `KickPulseTypography`, and `KickPulseRadiiSpacing`; organizer-only scheduling preserved.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS — All code/identifiers/tests in English; Spanish UI strings via `l10n`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: PASS — Explicit regional format & timezone handling, compact-screen/text-scaling safety, offline/online consistency.

*Post-Design Re-Check*: All 7 principles remain PASS with zero violations.

## Project Structure

### Documentation (this feature)

```text
specs/050-colombia-schedule-calendar/
├── plan.md                                  # This file
├── research.md                              # Phase 0 audit & decisions
├── data-model.md                            # Phase 1 temporal rules & calendar bounds
├── quickstart.md                            # Phase 1 validation guide
├── contracts/
│   └── colombia_time_contract.md            # Phase 1 ColombiaTimeUtils & picker contracts
├── checklists/
│   └── requirements.md                      # Spec quality checklist (16/16 passing)
└── tasks.md                                 # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── services/
│   │   └── colombia_time_utils.dart                        # NEW: Centralized UTC <-> Colombia (UTC-5) & 12h AM/PM formatter
│   └── entities/
│       └── matches_catalog_state.dart                      # Use ColombiaTimeUtils.colombiaDateOnly in normalizeDate
├── application/
│   ├── use_cases/
│   │   └── fixture_scheduling_use_case.dart                # Validate past time via ColombiaTimeUtils.presentMinuteUtc()
│   └── controllers/
│       ├── matches_catalog_controller.dart                 # Use ColombiaTimeUtils.todayColombia() / colombiaDateOnly()
│       └── daily_matches_feed_controller.dart              # Anchor Ayer/Hoy/Mañana & day grouping to Colombia UTC-5
├── infrastructure/
│   └── repositories/
│       └── hybrid_tournament_matches_repository.dart       # Parse scheduled_at / scheduled_end_at as UTC instants
└── presentation/
    ├── matches/
    │   └── widgets/
    │       ├── schedule_match_dialog.dart                  # firstDate=todayColombia, lastDate=2100-12-31, forced 12h TimePicker, UTC-5 conversion
    │       ├── match_center_card.dart                      # Display ColombiaTimeUtils.formatTime12h() with compact fit
    │       └── match_card.dart                             # Display ColombiaTimeUtils.formatDateTimeRange12h()
    ├── shell/
    │   └── app_shell_screen.dart                           # Matchday calendar picker: 2000-01-01 to 2100-12-31
    ├── tournaments/
    │   └── widgets/
    │       └── competition_fixture_tab_view.dart           # Display ColombiaTimeUtils.formatDateTime12h()
    └── teams/
        └── widgets/
            ├── team_matches_tab_view.dart                  # Display ColombiaTimeUtils.formatDateTime12h() / formatDate()
            └── team_info_tab_view.dart                     # Display ColombiaTimeUtils.formatDateTime12h()

test/
├── unit/
│   ├── domain/
│   │   └── colombia_time_utils_test.dart                   # NEW: Midnight UTC boundaries, 12:00 AM/PM, UTC round-trip
│   └── application/
│       └── fixture_scheduling_use_case_test.dart           # Verify Colombia past-time check & UTC instants
├── application/
│   └── controllers/
│       └── daily_matches_feed_controller_test.dart         # Verify 9:00 PM Colombia (02:00 UTC next day) stays on Colombia date
└── presentation/
    ├── matches/
    │   ├── schedule_match_dialog_test.dart                 # Verify future date (2030/2100), forced 12h AM/PM picker, UTC-5 submit
    │   └── widgets/
    │       └── match_center_card_test.dart                 # Verify 04:00 PM / 09:00 PM AM/PM display
    ├── tournaments/
    │   └── competition_fixture_widget_test.dart            # Verify AM/PM display in fixture cards
    └── teams/
        └── team_matches_schedule_test.dart                 # Verify AM/PM display in team schedule
```

**Structure Decision**: Extends the existing Flutter Clean Architecture layout by adding a pure-Dart `ColombiaTimeUtils` service in `lib/domain/services/` consumed uniformly across application and presentation layers.

## Complexity Tracking

> No Constitution Check violations; table intentionally left empty.
