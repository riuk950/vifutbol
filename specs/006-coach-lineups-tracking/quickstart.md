# Quickstart Validation Guide: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Feature**: `006-coach-lineups-tracking`  
**Date**: 2026-11-04

## Prerequisites

- Flutter SDK `3.41.2` (Dart `^3.11.0`)
- Repositorio en la rama `develop` / feature `006-coach-lineups-tracking`

## 1. Ejecutar Análisis Estático y Formato

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

**Resultado esperado**: `0` problemas de análisis y `0` archivos con formato pendiente.

## 2. Ejecutar Pruebas Automatizadas (Unitarias y de Widgets)

```bash
flutter test --coverage
```

**Resultado esperado**:
- `test/unit/domain/lineup_and_tracking_entities_test.dart`: Valida cálculo de estado disciplinario (`eligible`, `warningAccumulation`, `suspended`), reglas de `MatchLineupConvocation` e invariantes de titulares/suplentes/capitán.
- `test/unit/infrastructure/local_lineups_tracking_repository_test.dart`: Valida persistencia JSON y precarga de datos semilla en `dev` (incluyendo jugador suspendido por `1 fecha`).
- `test/unit/application/manage_lineups_tracking_use_case_test.dart`: Valida bloqueo de jugadores suspendidos, validación de cantidad exacta de titulares según modalidad del torneo (`requiredStarters`), capitán obligatorio, conservación de borrador y sincronización con el acta arbitral.
- `test/unit/application/lineups_tracking_controller_test.dart`: Valida el ciclo de vida del controlador Riverpod.
- `test/widget/coach_lineup_tracking_widget_test.dart`: Verifica los 3 escenarios Gherkin de la HU 5.2:
  1. Publicación exitosa de convocatoria con titulares, capitán y suplentes habilitados y visualización inmediata en la vista del `Árbitro`.
  2. Visualización de la insignia `"Suspendido (1 fecha)"` y control de selección deshabilitado para jugadores sancionados.
  3. Conservación intacta de la selección parcial al pasar la app a segundo plano (`AppLifecycleState.paused` → `resumed`) o reabrir la pantalla.
