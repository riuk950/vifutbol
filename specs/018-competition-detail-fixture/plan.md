# Implementation Plan: Pantalla de Detalle de Competición con Pestañas y Partidos por Jornadas (Fixture Completo)

**Branch**: `018-competition-detail-fixture` | **Date**: 2026-11-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/018-competition-detail-fixture/spec.md`

---

## Summary

Implementar la pantalla dedicada de Detalle de Competición en la ruta `/competitions/:id` (`CompetitionDetailScreen`) accesible desde el directorio de torneos. La pantalla cuenta con una barra de 3 pestañas fijas inmediatamente bajo el AppBar ("Partidos", "Clasificación" e "Información"). La pestaña "Partidos" despliega el fixture completo del campeonato agrupado cronológicamente por jornadas mediante un desplazamiento vertical continuo con encabezados destacados por fecha, tarjetas de partido interactivas (`MatchCenterCard` con modal inferior de detalles) y estado vacío informativo (`KickPulseStateView`) para torneos sin partidos generados.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Riverpod (`flutter_riverpod`), Fluro Router (`fluro`), Intl (`intl`)  
**Storage**: Almacenamiento local persistido a través de repositorios desacoplados (`LocalTournamentsRepository`, `LocalTournamentMatchesRepository`, `LocalStorageRepository`)  
**Testing**: `flutter test` (Widget tests, component tests, responsive tests con `tester.view`)  
**Target Platform**: Mobile (Android / iOS) con diseño responsive adaptativo  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: Desplazamiento a 60 fps en listas largas de jornadas con más de 100 partidos; tiempo de carga de pantalla < 1 segundo  
**Constraints**: 100% offline-first, sin llamadas de red obligatorias, 0 desbordamientos de `RenderFlex` en $320 \times 640\text{ px}$ con escalado de texto al $130\%$  
**Scale/Scope**: 1 nueva pantalla de detalle (`CompetitionDetailScreen`), subwidgets para fixture, integración en `AppRouter`, actualización de `CompetitionsDirectoryScreen` y suites de pruebas asociadas  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: ✅ Cumple. La especificación en `spec.md` delimita rigurosamente los alcances de la HU 13.1 y resuelve las 3 ambigüedades mediante clarificaciones explícitas.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: ✅ Cumple. Se reutilizan las relaciones referenciales del modelo de dominio (`tournamentId`, `roundNumber`, `roundName`, `homeTeamId`, `awayTeamId`).
- **III. Pruebas Automatizadas como Puerta de Calidad**: ✅ Cumple. Se establecen pruebas unitarias y de widget dedicadas para cada pestaña, estado vacío y comportamiento táctil.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: ✅ Cumple. Desacoplamiento entre capa de presentación (`CompetitionDetailScreen`), capa de aplicación (Riverpod controllers) y dominio (`ChampionshipMatch`, `ChampionshipTournament`).
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: ✅ Cumple. Los aficionados, jugadores, entrenadores y organizadores pueden acceder a consultar el fixture; se aplican tokens estrictos de `KickPulseColors`, `KickPulseTypography` y `KickPulseRadiiSpacing`.
- **VI. Convenciones de Idioma y Nomenclatura**: ✅ Cumple. Código, clases, métodos y pruebas en **inglés**; interfaz de usuario y cadenas visibles centralizadas en **español** en `app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: ✅ Cumple. Contempla persistencia offline, ciclo de vida al pasar a segundo plano, estados vacíos/error amigables y viewport compacto de 320x640 @ 130% texto.

---

## Project Structure

### Documentation (this feature)

```text
specs/018-competition-detail-fixture/
├── plan.md              # Plan de implementación (/speckit-plan)
├── research.md          # Investigación técnica y decisiones de diseño (Fase 0)
├── data-model.md        # Modelos de presentación y agregados (Fase 1)
├── quickstart.md        # Guía de validación manual y automatizada (Fase 1)
├── contracts/           # Contratos de UI, claves de widgets y l10n (Fase 1)
│   └── ui-competition-detail-contracts.md
└── checklists/
    └── requirements.md  # Checklist de calidad de requerimientos
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                  # Claves de internacionalización en español
│   ├── app_localizations.dart
│   └── app_localizations_es.dart
├── presentation/
│   ├── directories/
│   │   └── competitions_directory_screen.dart       # Actualización: navegación a /competitions/:id
│   ├── navigation/
│   │   └── app_router.dart                         # Definición de ruta /competitions/:id
│   └── tournaments/
│       ├── competition_detail_screen.dart          # Pantalla principal con AppBar y TabBar
│       ├── models/
│       │   └── matchday_fixture_group.dart         # Agrupado determinista de jornadas y partidos
│       └── widgets/
│           ├── competition_fixture_tab_view.dart   # Pestaña "Partidos" con scroll de jornadas
│           ├── competition_standings_tab_view.dart # Pestaña "Clasificación" (reutiliza Standings)
│           ├── competition_info_tab_view.dart      # Pestaña "Información" (estado de preparación)
│           └── match_detail_bottom_sheet.dart      # Hoja modal inferior de detalle de partido

test/
├── presentation/
│   ├── directories_responsive_widget_test.dart     # Validación responsiva a 320x640 @ 130% texto
│   └── tournaments/
│       ├── competition_detail_screen_test.dart     # Pruebas integrales de navegación y pestañas
│       └── competition_fixture_widget_test.dart    # Pruebas de jornadas y partidos
```

---

## Complexity Tracking

*No se detectan violaciones a la constitución ni complejidades injustificadas.*
