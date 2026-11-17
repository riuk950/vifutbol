# Implementation Plan: Carga y Selección de Equipos del Catálogo Global en el FAB Menu de Competición (HU 18.5)

**Branch**: `043-competition-fab-catalog-enrollment` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/043-competition-fab-catalog-enrollment/spec.md)  
**Input**: Feature specification from `/specs/043-competition-fab-catalog-enrollment/spec.md`

## Summary

Garantizar que al accionar `"Agregar Equipos"` desde el menú flotante (`CompetitionDetailFabMenu`) en `CompetitionDetailScreen`, el modal `AddTeamsToCompetitionModal` refresque y cargue el catálogo global completo de clubes registrados en la plataforma (incluyendo clubes autónomos en `vifutboldev.teams` aún no inscritos en ningún torneo y clubes de otros torneos), mostrando escudo, nombre oficial, categoría (`"Categoría libre"` por defecto), cantidad de jugadores y nombre del entrenador responsable (ocultándolo si no está resuelto), permitiendo buscar en tiempo real e inscribir clubes preexistentes en estado `"Pendiente de verificación"` sin exponer ningún botón ni formulario de creación de equipos al organizador.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter SDK  
**Primary Dependencies**: `flutter_riverpod ^2.6.1`, `supabase_flutter ^2.18.3`, `hive ^2.2.3`, `flutter_localizations` + `intl`  
**Storage**: Supabase PostgreSQL (`vifutboldev.teams`, `vifutboldev.tournament_teams`, `vifutboldev.players`, `vifutboldev.user_accounts`) + Hive caché local (`LocalTeamsRepository`)  
**Testing**: `flutter_test` + `mocktail ^1.0.4`  
**Target Platform**: Android & iOS mobile app (Flutter)  
**Project Type**: Mobile application  
**Performance Goals**: Filtrado de búsqueda en memoria <16ms por pulsación; actualización reactiva instantánea de `AddTeamsToCompetitionModal` y `CompetitionTeamsTabView`  
**Constraints**: Offline-first mediante `HybridTeamsRepository`; textos de interfaz 100% en español vía `AppLocalizations` (`lib/l10n/app_es.arb`); prohibición estricta de creación de clubes por el rol `organizer`  
**Scale/Scope**: Extensión de `TournamentTeam`, ajuste de consulta global en `PostgrestTeamsRemoteDataSource.fetchAll()`, enriquecimiento visual y recarga en `AddTeamsToCompetitionModal`, alineación de `organizer_panel_content.dart` y pruebas unitarias/widgets.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

1. **I. Spec-Driven Development**: PASS — `spec.md` creado y clarificado (3 preguntas resueltas, 16/16 ítems del checklist aprobados).
2. **II. Data Integrity & Offline-First**: PASS — `HybridTeamsRepository.loadTeams()` sincroniza el catálogo completo desde Supabase (`teams` + `tournament_teams`) con respaldo automático en `LocalTeamsRepository` cuando no hay red; la inscripción preserva la plantilla e inicia en `pendingVerification`.
3. **III. Automated Testing Discipline**: PASS — Pruebas unitarias planeadas para la fusión del catálogo global (`PostgrestTeamsRemoteDataSource` / `buildGlobalCatalogEntries` / `enrollExistingTeamFromCatalog`) y pruebas de widgets para `AddTeamsToCompetitionModal`.
4. **IV. Clean Architecture & Modularity**: PASS — Dominio (`TournamentTeam`), Aplicación (`TeamsController`, `ManageTeamsEligibilityUseCase`), Infraestructura (`PostgrestTeamsRemoteDataSource`), Presentación (`AddTeamsToCompetitionModal`, `OrganizerPanelContent`).
5. **V. Role-Based Security & Design System**: PASS — Respeta estrictamente la matriz RBAC (HU 16.2): el organizador solo inscribe clubes preexistentes sin botones de creación; usa `KickPulseColors`, `KickPulseBadge`, `KickPulseSearchBar`, `KickPulseTeamCrest`.
6. **VI. Multilingual Discipline**: PASS — Código en inglés; textos visibles localizados en `lib/l10n/app_es.arb`.
7. **VII. Mobile Resilience**: PASS — Manejo de estado de carga inicial, estado vacío orientativo, estado de búsqueda sin resultados, protección contra doble toque (`_enrollingKeys`) y preservación del modal abierto para inscripción múltiple.

*Post-Phase 1 Re-Check*: PASS — Todos los artefactos (`research.md`, `data-model.md`, `contracts/catalog_enrollment_contract.md`, `quickstart.md`) cumplen los 7 principios constitucionales.

## Project Structure

### Documentation (this feature)

```text
specs/043-competition-fab-catalog-enrollment/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── catalog_enrollment_contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   └── entities/
│       └── tournament_team.dart                             # + coachName, categoryLabel
├── infrastructure/
│   └── repositories/
│       └── hybrid_teams_repository.dart                     # fetchAll() merges standalone `teams` + `tournament_teams` + coach/category metadata
├── l10n/
│   └── app_es.arb                                           # Empty catalog copy + category/coach metadata labels
└── presentation/
    ├── panel/
    │   └── widgets/
    │       └── organizer_panel_content.dart                 # Route team enrollment shortcut to AddTeamsToCompetitionModal
    └── tournaments/
        └── widgets/
            └── add_teams_to_competition_modal.dart          # Trigger loadTeams() on open, render category & optional coachName, enforce zero creation actions

test/
├── unit/
│   └── infrastructure/
│       └── sync/
│           └── hybrid_teams_repository_teams_test.dart      # Global catalog fetch merging standalone teams + tournament_teams
└── presentation/
    └── tournaments/
        └── add_teams_to_competition_modal_test.dart         # Global catalog rendering, coach/category metadata, empty message, zero create actions, enrollment
```

**Structure Decision**: Se mantiene la arquitectura limpia existente del proyecto Flutter (`domain` / `application` / `infrastructure` / `presentation`).

## Complexity Tracking

Sin violaciones a la constitución ni excepciones de arquitectura.
