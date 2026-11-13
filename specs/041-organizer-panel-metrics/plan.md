# Implementation Plan: Panel de Organización — Métricas Exclusivas por Organizador Autenticado (HU 19.3)

**Branch**: `041-organizer-panel-metrics` | **Date**: 2026-11-13 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/041-organizer-panel-metrics/spec.md)

**Input**: Feature specification from `/specs/041-organizer-panel-metrics/spec.md`

## Summary

Aislar estrictamente las métricas superiores del Panel Administrativo ("Torneos Activos", "Partidos por Programar", "Torneos sin Fixture") y el listado "Mis Competiciones" para que operen únicamente sobre las competiciones creadas por el organizador autenticado en sesión (`t.organizerId == currentUserId`). Se corrige el filtro de `organizerTournamentsProvider` eliminando el escape hacia `'org-seed-1'` cuando existe sesión activa, se introduce un helper determinista `computeOrganizerPanelMetrics` junto al proveedor reactivo `organizerPanelMetricsProvider`, y se actualiza `OrganizerPanelContent` para consumir dicho proveedor.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter SDK 3.x  
**Primary Dependencies**: `flutter_riverpod`  
**Storage**: Estado reactivo en memoria sincronizado con Hive / Supabase (`tournamentsControllerProvider`, `matchesCatalogControllerProvider`, `authControllerProvider`)  
**Testing**: `flutter_test` (pruebas unitarias del cálculo de métricas y proveedor, pruebas de widget de `OrganizerPanelContent`)  
**Target Platform**: Android / iOS (Flutter mobile)  
**Project Type**: Mobile application (Clean Architecture)  
**Performance Goals**: Recálculo reactivo en < 16 ms (respuesta UI < 200 ms)  
**Constraints**: Cero dependencias nuevas; compatibilidad con pruebas aisladas sin sesión (`'org-seed-1'` fallback solo sin sesión); cero advertencias en `flutter analyze`  
**Scale/Scope**: 1 proveedor actualizado (`organizerTournamentsProvider`), 1 proveedor nuevo (`organizerPanelMetricsProvider`), 1 widget actualizado (`OrganizerPanelContent`), suites unitarias y de widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Design Status | Post-Design Status | Verification |
|-----------|-------------------|--------------------|--------------|
| I. La Spec Manda | PASS | PASS | Alcance fiel a `spec.md` y clarificación Q1. |
| II. Integridad de Datos y Fuente de Verdad | PASS | PASS | Cálculo determinista y consistencia 1 a 1 entre métricas y "Mis Competiciones". |
| III. Pruebas Automatizadas como Puerta de Calidad | PASS | PASS | Tests unitarios en `organizer_panel_metrics_test.dart` y de widget en `organizer_panel_widget_test.dart`. |
| IV. Arquitectura Limpia | PASS | PASS | Lógica de cálculo aislada en aplicación/providers y consumida de forma declarativa en presentación. |
| V. Segregación de Roles y Sistema de Diseño | PASS | PASS | Exclusivo para `UserRole.organizer`; mantiene tokens y claves existentes en `OrganizerPanelContent`. |
| VI. Convenciones de Idioma | PASS | PASS | Símbolos y pruebas en inglés; etiquetas visibles ya localizadas en español vía `app_es.arb`. |
| VII. Resiliencia y Experiencia Móvil | PASS | PASS | Funciona tanto conectado como offline sobre datos locales y maneja cambios/ausencia de sesión sin errores. |

## Project Structure

### Documentation (this feature)

```text
specs/041-organizer-panel-metrics/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── organizer-panel-metrics-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── application/
│   └── providers/
│       └── tournaments_providers.dart                  # Filtro estricto organizerTournamentsProvider + organizerPanelMetricsProvider
└── presentation/
    └── panel/
        └── widgets/
            └── organizer_panel_content.dart            # Consumir organizerPanelMetricsProvider

test/
├── unit/
│   └── application/
│       └── organizer_panel_metrics_test.dart           # Pruebas unitarias de aislamiento por organizador
└── presentation/
    └── panel/
        └── organizer_panel_widget_test.dart            # Pruebas de widget para métricas aisladas
```

## Complexity Tracking

No existen violaciones a la Constitución que requieran justificación.
