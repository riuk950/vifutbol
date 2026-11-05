# Quickstart & Validation Guide: Reestructuración del Navigation Bar Inferior (HU 10.1)

**Feature**: `013-restructure-bottom-navigation` (HU 10.1)  
**Date**: 2026-11-05

## Prerequisites

- Flutter SDK `^3.11.0` / Dart `^3.11.0`
- Repository root: `/Volumes/DATA/Development/FlutterProjects/vifutbol`
- Reference documents:
  - [spec.md](spec.md)
  - [data-model.md](data-model.md)
  - [ui-navigation-contracts.md](contracts/ui-navigation-contracts.md)

## Setup & Code Generation

```bash
flutter pub get
flutter gen-l10n
```

## Runnable Validation Scenarios

### Scenario 1: 4-Destination Bottom Navigation Bar Across All 5 Roles (US1)

1. Run the App Shell navigation widget tests:
   ```bash
   flutter test test/presentation/app_shell_widget_test.dart test/application/app_shell_controller_test.dart
   ```
2. **Expected Outcome**:
   - The bottom `NavigationBar` renders exactly 4 destinations in order: **`Partidos`**, **`Explorar`**, **`Noticias`**, **`Perfil`**.
   - **`Sedes`** is absent from the bottom `NavigationBar` for all 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`).
   - Active destination highlights with `KickPulseColors.accentPrimary` (`#00E676`).
   - Tab state and scroll positions are preserved in memory via `IndexedStack`.

### Scenario 2: "Partidos" Calendar Date Filtering & Organizer-Only "Por programar (N)" (US2)

1. Run the matches controller unit tests and matchday widget tests:
   ```bash
   flutter test test/unit/application/matches_catalog_controller_test.dart test/widget/matchday_fixture_widget_test.dart test/widget/live_matches_feed_widget_test.dart
   ```
2. **Expected Outcome**:
   - `Key('matchday_segmented_button')` is completely removed from `MatchdayTabView`.
   - Live matches (`MatchStatus.inProgress`) appear highlighted at the top in `Key('live_matches_section')` with the `"EN VIVO"` badge.
   - `Key('matchday_date_chips_list')` renders calendar date chips (`Hoy`, `Mañana`, and scheduled match dates) and filters the main match list exclusively by the selected calendar date (`scheduledStartTime`).
   - Unscheduled matches (`scheduledStartTime == null`) do not appear in the calendar day list for non-organizer roles.
   - `UserRole.organizer` sees `Key('unscheduled_matches_section')` (`"Por programar (N)"`) when unscheduled matches exist, and scheduling a match moves it automatically to its calendar date.

### Scenario 3: Standalone "Noticias" Tab, "Explorar" Rename & Global Tournament Sync (US3)

1. Run the news feed and standings widget tests:
   ```bash
   flutter test test/widget/tournament_news_feed_widget_test.dart test/widget/standings_tab_view_test.dart
   ```
2. **Expected Outcome**:
   - Tapping **"Explorar"** (2nd tab) opens `StandingsTabView` with championship standings, knockout brackets, honor roll, teams, and rankings.
   - Tapping **"Noticias"** (3rd tab) opens `NewsTabView` directly with category filter chips (`Todos`, `General`, `Reprogramación`, `Disciplinario`), `Organizador` publish/delete controls, and historical read-only protection when the active tournament is `Finalizado`.
   - Changing the active tournament in **"Partidos"**, **"Explorar"**, or **"Noticias"** synchronizes globally across all three tabs.

### Scenario 4: Compact Screen (320x640 @ 130% Text Scale) & Full Quality Gate

1. Run static analysis, formatting check, and the complete test suite:
   ```bash
   flutter analyze
   dart format --output=none --set-exit-if-changed .
   flutter test
   ```
2. **Expected Outcome**:
   - `0` analyzer issues, `0` formatting issues, and `100%` of unit and widget tests passing (including `320x640` viewport at `130%` text scaling with zero `RenderFlex` overflows).
