# Implementation Plan: Generación de Fixture Independiente por Competición (HU 15.2)

**Branch**: `025-competition-isolated-fixture` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/025-competition-isolated-fixture/spec.md`

---

## Summary

Implementar la generación de fixture aislada por competición y retirar los controles globales de generación de la vista diaria de partidos (HU 15.2):
1. **Aislamiento de Dominio/Aplicación por Competición**: Actualizar `FixtureSchedulingUseCase.generateRoundRobinFixture` para filtrar estrictamente `teams.where((t) => t.tournamentId == tournament.id && t.isEligible)` y persistir mediante `replaceMatchesForTournament`, asegurando que `MatchesCatalogController.generateFixture` actualice los partidos del torneo objetivo sin sobrescribir en memoria los partidos de otros campeonatos.
2. **Limpieza Total de la Pestaña Principal de Partidos (`MatchdayTabView`)**: Retirar `OrganizerPendingMatchesBanner` y los métodos de generación/programación directa de `MatchdayTabView`, dejando la pestaña **Partidos** dedicada exclusivamente a la consulta cronológica por fecha (*Ayer*, *Hoy*, *Mañana* y *Calendario*).
3. **FAB Menu Expandible (*Speed Dial*) en `CompetitionDetailScreen` (`/competitions/:id`)**: Incorporar un botón flotante expandible visible únicamente para el rol `Organizador` cuando el torneo es editable (`openRegistration` o `inProgress`), que despliega la acción **"Generar Fixture"** (`Key('competition_detail_fab_generate_fixture')`), solicita confirmación, genera las jornadas exclusivamente para ese torneo y muestra un `SnackBar` con el conteo de partidos creados permaneciendo en la pestaña actual.
4. **Selector Previo de Competición en `/panel` (`OrganizerPanelContent`)**: Al pulsar **"Generar Fixture"** (`Key('organizer_action_generate_fixture')`), abrir una hoja modal (`SelectTournamentForFixtureSheet`, `Key('select_tournament_for_fixture_sheet')`) con las competiciones editables mostrando su estado y número de equipos elegibles; tras seleccionar y confirmar, generar el fixture exclusivamente para ese torneo, mostrar el `SnackBar` y navegar automáticamente a `/competitions/:id`.

---

## Technical Context

**Language/Version**: Dart 3.7+ / Flutter 3.29+  
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl`  
**Storage**: Offline-first con `LocalStorageRepository` (`LocalTournamentMatchesRepository`, `LocalTournamentsRepository`, `LocalTeamsRepository`)  
**Testing**: `flutter_test` (unit and widget testing)  
**Target Platform**: Mobile-first (iOS / Android)  
**Project Type**: Mobile Application (`vifutbol`)  
**Performance Goals**: Generación determinista de fixture y actualización reactiva de UI en $<100\text{ ms}$.  
**Constraints**: Zero `RenderFlex` overflow en $320 \times 640\text{ px}$ con $130\%$ de escalado de texto; áreas táctiles $\ge 48 \times 48\text{ dp}$; textos de interfaz en español vía `lib/l10n/app_es.arb`; código e identificadores en inglés.  
**Scale/Scope**: 1 caso de uso (`FixtureSchedulingUseCase`), 1 controlador (`MatchesCatalogController`), 3 pantallas/vistas (`MatchdayTabView`, `CompetitionDetailScreen`, `OrganizerPanelContent`), 1 nuevo widget modal (`SelectTournamentForFixtureSheet`), localización (`app_es.arb`) y suites de pruebas unitarias y de widgets.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. La Spec Manda** | Basado estrictamente en `spec.md` clarificado sin desvíos de alcance | **PASS** | 5 decisiones de clarificación formalizadas en `spec.md`. |
| **II. Integridad de Datos** | Integridad referencial estricta entre `ChampionshipTournament`, `TournamentTeam` y `ChampionshipMatch` | **PASS** | `generateRoundRobinFixture` filtra por `team.tournamentId == tournament.id && team.isEligible`. |
| **III. Pruebas Automatizadas** | Pruebas unitarias y de widgets aisladas para cada historia de usuario | **PASS** | Cubierto en `fixture_scheduling_use_case_test.dart`, `matchday_tab_view_test.dart`, `competition_detail_screen_test.dart` y `organizer_panel_widget_test.dart`. |
| **IV. Arquitectura Limpia** | Separación entre presentación, aplicación y dominio | **PASS** | Validación y generación en `FixtureSchedulingUseCase`; estado en `MatchesCatalogController`; UI reactiva en `presentation/`. |
| **V. Segregación de Roles & UI** | Permisos exclusivos para `UserRole.organizer` y tokens `DESIGN.md` | **PASS** | FAB Menu y Panel restringidos por `RoleCapability.manageTournaments` / `UserRole.organizer`. |
| **VI. Idioma y Nomenclatura** | Código en inglés; textos visibles en español en `app_es.arb` | **PASS** | Todas las etiquetas nuevas se centralizan en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia Móvil** | Sin desbordamientos en $320 \times 640\text{ px}$ @ $130\%$ text scale y protección contra doble toque | **PASS** | Guardas `isSaving` / `_isGeneratingFixture` y layouts adaptativos con `Flexible`/`Expanded`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/025-competition-isolated-fixture/
├── plan.md                                       # This file
├── research.md                                   # Phase 0 output
├── data-model.md                                 # Phase 1 output
├── quickstart.md                                 # Phase 1 output
├── contracts/                                    # Phase 1 output
│   └── ui-isolated-fixture-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md                                      # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── application/
│   ├── controllers/
│   │   └── matches_catalog_controller.dart       # Preserves other tournaments' matches on generateFixture
│   └── use_cases/
│       └── fixture_scheduling_use_case.dart      # Enforces team.tournamentId == tournament.id filter
├── l10n/
│   ├── app_es.arb                                # Spanish localization strings
│   └── app_localizations.dart                    # Generated localizations
└── presentation/
    ├── panel/
    │   └── widgets/
    │       ├── organizer_panel_content.dart      # Opens tournament selector before generating fixture
    │       └── select_tournament_for_fixture_sheet.dart # Modal bottom sheet for selecting editable competition
    ├── shell/
    │   └── tabs/
    │       └── matchday_tab_view.dart            # Removes OrganizerPendingMatchesBanner & fixture generation
    └── tournaments/
        └── competition_detail_screen.dart        # Adds Organizer-only Speed Dial FAB Menu ("Generar Fixture")

test/
├── unit/
│   └── application/
│       └── fixture_scheduling_use_case_test.dart # Tests tournamentId team isolation
├── presentation/
│   ├── panel/
│   │   └── organizer_panel_widget_test.dart      # Tests competition selector & navigation to /competitions/:id
│   ├── shell/
│   │   └── tabs/
│   │       └── matchday_tab_view_test.dart       # Tests absence of fixture banner/buttons for Organizer
│   └── tournaments/
│       └── competition_detail_screen_test.dart   # Tests Speed Dial FAB Menu visibility & fixture generation
└── widget/
    └── matchday_fixture_widget_test.dart         # Updated widget tests aligned with MatchdayTabView cleanup
```

**Structure Decision**: Single Flutter mobile project adhering to clean layered architecture (`domain` → `application` → `infrastructure` → `presentation`).

---

## Complexity Tracking

> No constitution violations detected. All changes follow the established Riverpod + Clean Architecture patterns.
