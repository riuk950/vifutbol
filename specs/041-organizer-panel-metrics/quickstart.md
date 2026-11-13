# Quickstart Validation Guide: Métricas Exclusivas por Organizador (HU 19.3)

**Feature**: `041-organizer-panel-metrics`  
**Date**: 2026-11-13

## Prerequisites

- Entorno Flutter configurado.
- Referencias: [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/data-model.md) y [organizer-panel-metrics-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/contracts/organizer-panel-metrics-contracts.md).

## 1. Automated Verification

```bash
flutter analyze
flutter test \
  test/unit/application/organizer_panel_metrics_test.dart \
  test/presentation/panel/organizer_panel_widget_test.dart \
  test/presentation/panel/organizer_competitions_addition_verification_test.dart \
  test/presentation/panel_screen_test.dart
```

**Expected Outcome**:
- `flutter analyze` finaliza con `No issues found!`.
- 100% de pruebas unitarias y de widgets aprueban verificando:
  - Aislamiento estricto por `organizerId == currentUserId` (excluyendo `org-seed-1` cuando hay sesión activa).
  - Contadores en `0` cuando el organizador no tiene torneos propios aunque existan otros torneos y partidos en el sistema.
  - Incremento reactivo inmediato de métricas al crear un nuevo torneo propio.
