# Quickstart Validation Guide: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Feature**: `007-fixture-generation-assignment`  
**Date**: 2026-11-04

## Prerequisites

- Flutter SDK `3.41.2` (Dart `^3.11.0`)
- Repositorio en la rama `develop` / feature `007-fixture-generation-assignment`

## 1. Ejecutar Análisis Estático y Formato

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

**Resultado esperado**: `0` problemas de análisis estático y `0` archivos con formato pendiente.

## 2. Ejecutar Pruebas Automatizadas (Unitarias y de Widgets)

```bash
flutter test --coverage
```

**Resultado esperado**:
- `test/unit/domain/championship_match_entities_test.dart`: Valida estados de partido (`MatchStatus`), cálculo de intervalos de partido, solapamientos temporales (`overlapsWith`) y entidades de árbitros.
- `test/unit/domain/round_robin_generator_test.dart`: Valida generación determinista de Round-Robin con número par de equipos, número impar de equipos (incorporación de fecha libre / bye) y distribución de localías.
- `test/unit/infrastructure/local_tournament_matches_repository_test.dart`: Valida persistencia local en JSON, guardado individual y en lote (`saveMatchesBatch`), y precarga de árbitros oficiales semilla en `dev`.
- `test/unit/application/fixture_scheduling_use_case_test.dart`: Valida reglas de autorización (`manageTournaments`), validación de equipos habilitados mínimos, cálculo de duración de partido ($2 \times \text{mitad} + 15\text{ min}$) y detección estricta de colisiones de cancha, árbitro y equipo.
- `test/unit/application/matches_catalog_controller_test.dart`: Valida el ciclo de vida del controlador Riverpod, carga de partidos por torneo, selección de jornada activa y filtros.
- `test/widget/matchday_fixture_widget_test.dart`: Verifica los 3 escenarios Gherkin de la HU 6.1:
  1. Generación determinista del fixture de fase de grupos/liga y visualización organizada por jornadas en `MatchdayTabView`.
  2. Asignación exitosa de fecha, cancha y árbitro oficial a un partido pendiente actualizándolo a `"Programado"`.
  3. Detección y bloqueo de colisión horaria ante intento de programar en la misma cancha o con el mismo árbitro en un horario superpuesto.
