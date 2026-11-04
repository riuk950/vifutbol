# Quickstart Validation Guide: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Feature**: `010-player-team-stats`  
**Date**: 2026-11-04

## Prerequisites
- Flutter SDK `3.41.4` / Dart `3.11.1`
- Project dependencies installed (`flutter pub get`)
- Localization generated (`flutter gen-l10n`)

## 1. Run Unit Tests for Player & Team Stats Calculation
```bash
flutter test test/unit/domain/player_team_stats_calculator_service_test.dart
flutter test test/unit/application/calculate_tournament_standings_and_rankings_use_case_test.dart
```
**Expected Outcome**:
- Verifies deterministic calculation of `PJ`, `Titularidades`, `Goles`, `Asistencias`, `Promedio de Gol` (`0.00` when `PJ == 0`), `Tarjetas Amarillas`, `Tarjetas Rojas`, and `Habilitado` / `Suspendido` status.
- Verifies `TeamDetailedStats` recent 5-match form (`V`, `E`, `D`), completed match history, upcoming matches, and full squad stats.
- Verifies offline caching of the player performance profile via `LocalStorageRepository`.

## 2. Run Widget Tests for Player Profile, Team Detailed Stats & 130% Text Scaling
```bash
flutter test test/widget/player_team_stats_widget_test.dart
```
**Expected Outcome**:
- Renders `PlayerPerformanceProfileCard` with `tabular-nums` metrics and match-by-match breakdown.
- Renders `PlayerPerformanceProfileCard` for a newly enrolled player (`PJ == 0`) showing all counters in `0` / `0.00` and the exact message `"Aún no registras participaciones en partidos oficiales de este torneo."`
- Renders `TeamDetailedStatsCard` showing position, recent form (`V`, `E`, `D`), completed results, upcoming matches, and squad list; tapping a squad player navigates to their `PlayerPerformanceProfile`.
- Zero `RenderFlex` overflows at `320px` width and `130%` text scaling (`SC-004`).

## 3. Static Analysis & Full Test Suite
```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test --coverage
```
**Expected Outcome**: `0` analyzer issues, `0` formatting diffs, and 100% of unit and widget tests passing.
