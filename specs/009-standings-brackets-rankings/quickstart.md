# Quickstart: Cálculo Determinista de Tablas de Posiciones, Llaves Eliminatorias y Rankings Deportivos (HU 8.1)

**Feature Branch**: `009-standings-brackets-rankings`  
**Date**: 2026-11-04

---

## 1. Prerequisites & Localization Generation

Ensure dependencies and Spanish localization files (`app_es.arb`) are generated:

```bash
flutter pub get
flutter gen-l10n
```

---

## 2. Running Automated Verification

### Unit Tests (Standings Calculator, Tiebreakers, Knockout Bracket Advancement, Rankings & Fair Play)
```bash
flutter test test/unit/domain/standings_calculator_service_test.dart
flutter test test/unit/domain/knockout_bracket_service_test.dart
flutter test test/unit/domain/sports_rankings_calculator_service_test.dart
flutter test test/unit/application/calculate_tournament_standings_and_rankings_use_case_test.dart
```

### Widget Tests (Gherkin Acceptance Scenarios for US1, US2, US3 + Regression Suite)
```bash
flutter test test/widget/standings_brackets_rankings_widget_test.dart
flutter test test/widget/standings_tab_view_test.dart
```

### Full Quality Gate (Zero Analyzer Issues, Formatting, Full Coverage)
```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test --coverage
```

---

## 3. Manual Verification Flow in App

1. **Tablas de Posiciones (`US1`)**:
   - Open the **Posiciones** tab in the bottom navigation bar.
   - Select `"Liga Relámpago ViFutbol"` (or any `Liga` / `Grupos + Eliminatoria` tournament).
   - Inspect the **Tabla de Posiciones** card with columns `POS`, `EQUIPO`, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS` rendered in aligned `tabular-nums`.
   - Close a match report from the **Partidos** tab (`Acta Arbitral` → `Cerrar Acta Oficial`) and return to **Posiciones** to observe immediate deterministic recalculation and tiebreaker ordering.

2. **Llaves Eliminatorias (`US2`)**:
   - Select `"Copa Eliminatoria Nocturna"` (or switch to the **Llaves** chip).
   - Switch between rounds (`Cuartos de Final`, `Semifinales`, `Gran Final`) or toggle **Visor 2D** to inspect the panoramic bracket tree.
   - Complete a knockout tie (either by regulation score difference or penalty shootout) and verify that the winning team automatically advances into the next round's pairing slot.

3. **Rankings Deportivos (`US3`)**:
   - Select the **Rankings** view in **Posiciones** and toggle between **Goleadores**, **Asistencias**, and **Fair Play**.
   - Verify that player goals, assists, and team Fair Play penalty points (`-1` per yellow, `-3` per double-yellow/red, `-3` per direct red) match the closed match reports.
