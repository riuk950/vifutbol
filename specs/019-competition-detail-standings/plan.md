# Implementation Plan: Pestaña de Clasificación y Resultados de Equipos en el Detalle de Competición (HU 13.2)

**Branch**: `019-competition-detail-standings` | **Date**: 2026-11-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/019-competition-detail-standings/spec.md`

---

## Summary

Implementar la experiencia completa de la pestaña "Clasificación" dentro de `CompetitionDetailScreen` (`/competitions/:id`), adaptándola dinámicamente según el formato de la competición:
1. **Torneos de Liga (`league`)**: Tabla de posiciones oficial (`StandingsTableCard`) con tipografía tabular (`FontFeature.tabularFigures()`) y rankings de goleadores, tarjetas y vallas invictas (`TournamentRankingsCard`).
2. **Torneos de Copa (`knockoutCup`)**: Cuadro visual interactivo de llaves eliminatorias (`KnockoutBracketCard`) y rankings.
3. **Torneos Mixtos (`mixedGroupsAndKnockout`)**: Selector de subvistas por chips ("Posiciones", "Llaves", "Estadísticas") con tablas de grupos separadas y bracket.
4. **Resiliencia & Estados Vacíos**: Estados de carga y vacíos informativos (`KickPulseStateView`) contextualizados por subvista.

---

## Technical Context

**Language/Version**: Dart 3.7+ / Flutter 3.29+  
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl`  
**Storage**: Offline-first con `LocalStorageRepository` (memoria/persistencia desacoplada)  
**Testing**: `flutter_test` (unit and widget testing)  
**Target Platform**: Mobile-first (iOS / Android)  
**Project Type**: Mobile Application (`vifutbol`)  
**Performance Goals**: Renderizado de snapshot competitivo en $<1\text{ s}$; cero recálculos al cambiar de pestaña.  
**Constraints**: Zero `RenderFlex` overflow en $320 \times 640\text{ px}$ con $130\%$ de escalado de texto; tipografía tabular para todas las columnas numéricas; textos exclusivamente en español mediante `app_es.arb`.  
**Scale/Scope**: 1 componente de pestaña principal (`CompetitionStandingsTabView`), 1 archivo de localización, 2 suites de pruebas de widget.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. La Spec Manda** | Basado estrictamente en especificación aprobada sin cambios no documentados | **PASS** | `spec.md` detallado y clarificado (3 decisiones formalizadas). |
| **II. Integridad de Datos** | Tabla y rankings calculados determinísticamente a partir de actas cerradas | **PASS** | Se reutiliza `CalculateTournamentStandingsAndRankingsUseCase`. |
| **III. Pruebas Automatizadas** | Suite de tests aislados de widgets para cada formato y subvista | **PASS** | Planificada suite dedicada `competition_standings_tab_view_test.dart` y validaciones en pantalla completa. |
| **IV. Arquitectura Limpia** | Separación estricta entre presentación, aplicación y dominio | **PASS** | `CompetitionStandingsTabView` delega estado al controller y no realiza lógica de negocio directa. |
| **V. Segregación de Roles & UI** | Fidelidad a tokens KickPulse (`DESIGN.md`) y permisos | **PASS** | `KickPulseTheme`, `KickPulseColors`, `ChoiceChip`s y `KickPulseStateView`. |
| **VI. Idioma y Nomenclatura** | Código en inglés, interfaz de usuario en español vía `l10n` | **PASS** | Nuevas claves agregadas a `app_es.arb`. |
| **VII. Resiliencia Móvil** | Cero desbordamientos a $320 \times 640\text{ px}$ @ $130\%$ font scale | **PASS** | Desplazamiento horizontal controlado en tablas y soporte de accesibilidad. |

---

## Project Structure

### Documentation (this feature)

```text
specs/019-competition-detail-standings/
├── plan.md                                          # This file
├── research.md                                      # Phase 0 output
├── data-model.md                                    # Phase 1 output
├── quickstart.md                                    # Phase 1 output
├── contracts/                                       # Phase 1 output
│   └── ui-competition-standings-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md                                         # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                   # Spanish localization keys
│   └── app_localizations.dart                       # Generated localizations
├── presentation/
│   ├── standings/
│   │   └── widgets/
│   │       ├── standings_table_card.dart            # Existing table component
│   │       ├── knockout_bracket_card.dart           # Existing bracket component
│   │       └── tournament_rankings_card.dart        # Existing rankings component
│   └── tournaments/
│       ├── competition_detail_screen.dart           # Host screen with 3 tabs
│       └── widgets/
│           └── competition_standings_tab_view.dart  # Target implementation widget

test/
└── presentation/
    ├── directories_responsive_widget_test.dart      # Viewport and text scaling test
    └── tournaments/
        ├── competition_detail_screen_test.dart      # Full screen integration test
        └── competition_standings_tab_view_test.dart # Dedicated standings tab widget tests
```

**Structure Decision**: Single Flutter mobile application architecture. The feature extends `lib/presentation/tournaments/widgets/competition_standings_tab_view.dart` to integrate the competitive subviews and connects with `StandingsAndRankingsController`.

---

## Complexity Tracking

> No constitution violations detected. Standard layered architecture preserved without introducing new external packages or bypasses.
