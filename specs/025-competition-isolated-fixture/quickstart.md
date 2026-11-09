# Quickstart Validation Guide: Generación de Fixture Independiente por Competición (HU 15.2)

**Feature**: `025-competition-isolated-fixture`  
**Date**: 2026-11-09  

---

## Prerequisites

- Flutter SDK `3.29+` / Dart `3.7+`
- Dependencias instaladas (`flutter pub get`)
- Localizaciones generadas (`flutter gen-l10n`)

---

## 1. Ejecutar Pruebas Unitarias de Aislamiento de Fixture por Competición

Verifica que `FixtureSchedulingUseCase.generateRoundRobinFixture` filtre estrictamente los equipos por `team.tournamentId == tournament.id` y `team.isEligible`, sin mezclar equipos de otros campeonatos:

```bash
flutter test test/unit/application/fixture_scheduling_use_case_test.dart
```

---

## 2. Ejecutar Pruebas de Widgets (Partidos, Detalle de Competición y Panel)

Verifica los 3 flujos de la HU 15.2:
1. Ausencia de controles/banners de generación de fixture en `MatchdayTabView`.
2. Visibilidad por rol y generación de fixture desde el FAB Menu (*Speed Dial*) en `CompetitionDetailScreen`.
3. Selección previa de competición, generación aislada y redirección a `/competitions/:id` desde `OrganizerPanelContent` (`/panel`).

```bash
flutter test test/presentation/shell/tabs/matchday_tab_view_test.dart
flutter test test/presentation/tournaments/competition_detail_screen_test.dart
flutter test test/presentation/panel/organizer_panel_widget_test.dart
```

---

## 3. Verificación de Análisis Estático y Formato

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```
