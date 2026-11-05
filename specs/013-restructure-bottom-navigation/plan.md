# Implementation Plan: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)

**Branch**: `[013-restructure-bottom-navigation]` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/013-restructure-bottom-navigation/spec.md`

## Summary

Restructure the primary bottom `NavigationBar` in `AppShellScreen` across all 5 user roles (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`) into 4 unified destinations in fixed order: **Partidos** (`0`), **Explorar** (`1`), **Noticias** (`2`), and **Perfil** (`3`), removing **Sedes** from the bottom bar while preserving `VenuesTabView` and venue repositories for match scheduling and future secondary navigation (HU 10.2 Drawer). Refactor the first tab (**Partidos**) to remove the internal news `SegmentedButton`, highlight live matches (`"EN VIVO"`), filter matches exclusively via a horizontal calendar day selector (`Hoy`, `Mañana`, and specific scheduled dates), and provide an `Organizador`-only `"Por programar (N)"` section for unscheduled matches. Promote **Noticias** to a standalone 3rd tab (`NewsTabView`) and synchronize the active championship globally across **Partidos**, **Explorar**, and **Noticias** via `tournamentsControllerProvider`.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `^3.11.0`

**Primary Dependencies**: `flutter`, `flutter_localizations`, `intl` (`^0.20.2`), `flutter_riverpod` (`^2.6.1`), `fluro` (`^2.0.5`), `hive` (`^2.2.3`), `hive_flutter` (`^1.1.0`)

**Storage**: Local offline-first persistence via `LocalStorageRepository` (Hive / JSON namespaces for tournaments, matches, teams, venues, and news); in-memory `AppShellController` and `IndexedStack` for shell navigation state

**Testing**: `flutter_test` (Unit tests for `AppShellController` and `MatchesCatalogController` calendar-date filtering; Widget tests for `AppShellScreen`, `MatchdayTabView`, `NewsTabView`, role visibility, global tournament sync, and `320x640` @ `130%` text scaling)

**Target Platform**: Android & iOS mobile applications (Portrait orientation, dark mode "Kick Pulse" design system)

**Project Type**: Mobile application (`mobile-app`) following Clean Architecture (`domain`, `application`, `infrastructure`, `presentation`)

**Performance Goals**: `< 100ms` tab transition latency via `IndexedStack` with zero redundant storage reloads; 60fps scrolling on calendar date strips and match/news lists

**Constraints**: Offline-first operation; zero `RenderFlex` overflows on `320x640` logical pixel screens at `130%` text scale; minimum `48x48dp` (`>= 44x44px`) touch targets; 100% Spanish UI via `l10n` (`lib/l10n/app_es.arb`) and 100% English technical identifiers

**Scale/Scope**: 4 primary bottom navigation tabs across 5 user roles, affecting shell navigation (`AppShellSection`, `AppShellController`, `AppShellScreen`, `AppRouter`), match catalog calendar-day filtering (`MatchesCatalogState`, `MatchesCatalogController`, `MatchdayTabView`), and top-level news tab (`NewsTabView`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Design Status | Post-Design Status | Verification Notes |
|---|---|---|---|
| **I. La Spec Manda (Spec-Driven Development)** | **PASS** | **PASS** | `spec.md` clarified (3 questions resolved) and validated against `docs/MOBILE_GUIDELINES.md` (`16/16 PASS`). |
| **II. Integridad de Datos y Fuente de Verdad Transparente** | **PASS** | **PASS** | Active tournament (`selectedTournamentId`) is synchronized globally across `Partidos`, `Explorar`, and `Noticias`; venue and match repositories remain intact. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | **PASS** | **PASS** | Unit and widget tests planned for `AppShellController`, `MatchesCatalogState`/`MatchesCatalogController` calendar filtering, `MatchdayTabView` (`"Por programar (N)"` role gating), `NewsTabView`, and `AppShellScreen`. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | **PASS** | **PASS** | `AppShellSection` and `MatchesCatalogState` live in `lib/domain/entities/`; controllers in `lib/application/controllers/`; UI widgets in `lib/presentation/shell/`. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | **PASS** | **PASS** | All 5 roles see the unified 4-tab bar; `"Por programar (N)"`, fixture generation, and news creation/deletion are strictly gated to `UserRole.organizer`; tokens adhere to `DESIGN.md` (`KickPulseColors`, `KickPulseTypography`). |
| **VI. Convenciones de Idioma y Nomenclatura** | **PASS** | **PASS** | All classes, enums, methods, files, and tests in English; all UI strings (`"Partidos"`, `"Explorar"`, `"Noticias"`, `"Perfil"`, `"Hoy"`, `"Mañana"`, `"Por programar ({count})"`) in `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)** | **PASS** | **PASS** | `IndexedStack` preserves scroll and filter states across tab switches and app lifecycle changes; tested at `320x640` with `130%` text scaling. |

## Project Structure

### Documentation (this feature)

```text
specs/013-restructure-bottom-navigation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── ui-navigation-contracts.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   └── entities/
│       ├── app_shell_section.dart           # Updated enum: matches, explore, news, profile (+ aliases)
│       └── matches_catalog_state.dart       # Extended with selectedDate, availableCalendarDates, scheduledMatchesForSelectedDate, unscheduledMatches
├── application/
│   └── controllers/
│       ├── app_shell_controller.dart        # Manages 4-destination AppShellState transitions
│       └── matches_catalog_controller.dart  # Extended with selectDate(DateTime) and auto-selection of scheduled date
├── l10n/
│   ├── app_es.arb                           # Spanish labels for Partidos, Explorar, Noticias, Perfil, Hoy, Mañana, Por programar
│   ├── app_localizations.dart               # Generated l10n interface
│   └── app_localizations_es.dart            # Generated Spanish l10n implementation
└── presentation/
    ├── alerts/
    │   └── widgets/
    │       └── fan_alerts_bell_action.dart  # Navigates to AppShellSection.matches on alert tap
    ├── navigation/
    │   └── app_router.dart                  # Routes /matches, /explore, /news, /profile (+ /venues preserved)
    └── shell/
        ├── app_shell_screen.dart            # 4-destination NavigationBar & IndexedStack (Partidos, Explorar, Noticias, Perfil)
        └── tabs/
            ├── matchday_tab_view.dart       # Refactored "Partidos" tab: calendar date chips, EN VIVO, Organizer "Por programar (N)", no SegmentedButton
            ├── standings_tab_view.dart      # "Explorar" tab (existing content preserved)
            ├── news_tab_view.dart           # New top-level "Noticias" tab with global tournament sync & TournamentNewsFeedView
            ├── profile_tab_view.dart        # "Perfil" tab (4th position unchanged)
            └── venues_tab_view.dart         # Preserved intact for secondary access (HU 10.2 Drawer)

test/
├── application/
│   └── app_shell_controller_test.dart       # Updated for 4 sections: matches, explore, news, profile
├── unit/
│   └── application/
│       └── matches_catalog_controller_test.dart # Extended with calendar date filtering & unscheduled matches tests
├── presentation/
│   └── app_shell_widget_test.dart           # Updated for Partidos, Explorar, Noticias, Perfil across all 5 roles & 130% text scale
└── widget/
    ├── matchday_fixture_widget_test.dart    # Updated for calendar date chips & Organizer-only "Por programar (N)"
    ├── live_matches_feed_widget_test.dart   # Verified with refactored MatchdayTabView
    └── tournament_news_feed_widget_test.dart # Extended with NewsTabView & global tournament sync tests
```

**Structure Decision**: Retain the single-project Flutter Clean Architecture layout (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`, and `test/`), adding `lib/presentation/shell/tabs/news_tab_view.dart` for the standalone **Noticias** tab while keeping `lib/presentation/shell/tabs/venues_tab_view.dart` intact for secondary navigation.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | All 7 Constitution principles pass without exceptions. |
