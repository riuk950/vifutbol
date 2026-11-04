# Implementation Plan: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Branch**: `007-fixture-generation-assignment` | **Date**: 2026-11-04 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/007-fixture-generation-assignment/spec.md)
**Input**: Feature specification from `/specs/007-fixture-generation-assignment/spec.md`

## Summary

Implementar el módulo de **Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)** para la Épica 6 siguiendo la Arquitectura Limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) y el sistema de diseño **Kick Pulse** (`DESIGN.md`). El módulo dota al `Organizador` de la capacidad de generar de forma determinista el calendario completo de partidos en formato todos contra todos (Round-Robin) o eliminatorias a partir de los equipos habilitados, programar cada partido asignándole fecha, hora de inicio, sede/cancha deportiva y árbitro oficial con cálculo automático de ventana de duración ($2 \times \text{mitad} + 15\text{ min descanso}$), detectar y bloquear colisiones logísticas (misma cancha, mismo árbitro o mismos equipos en horarios superpuestos) y presentar el fixture organizado por jornadas en la pestaña principal de **Jornada** (`MatchdayTabView`), integrando filtros por estado y equipo.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `3.41.2` (stable)  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `shared_preferences: ^2.5.4`, `flutter_localizations` (`intl: ^0.20.2`)  
**Storage**: Offline-first en `LocalStorageRepository` mediante `LocalTournamentMatchesRepository` (claves `'vifutbol.matches.v1'` y `'vifutbol.referees.v1'`), precargando en `AppEnvironment.development` árbitros oficiales semilla (`Nicolás Gallo`, `Wilmar Roldán`, `Andrés Rojas`) y partidos semilla para validar de inmediato la experiencia  
**Testing**: `flutter_test` (pruebas unitarias de dominio para Round-Robin e intervalos, repositorio local, caso de uso de fixture y colisiones, controlador Riverpod y widget tests de los 3 escenarios Gherkin en `MatchdayTabView` y modales de programación)  
**Target Platform**: Android & iOS (Mobile-first, portrait orientation, dark mode `#0A0E17`)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Generación de fixture de hasta 32 equipos en `< 20ms`, comprobación de colisiones de horario en `< 2ms`, renderizado fluido a 60 fps en selector de jornadas  
**Constraints**: Detección estricta de solapamiento de intervalos cerrados $[T_{start}, T_{end}]$, 100% de textos visibles en `lib/l10n/app_es.arb` y 100% de identificadores técnicos en inglés, conservación de estado de jornada seleccionada  
**Scale/Scope**: 4 entidades/enums en `domain/entities`, extensión de `app_failure.dart`, 1 contrato de repositorio en `domain/repositories`, 1 servicio de dominio (`round_robin_generator.dart`), 1 repositorio local en `infrastructure/repositories`, 1 caso de uso + 1 controlador + 1 archivo de providers en `application`, refactorización integral de `MatchdayTabView` y creación de `ScheduleMatchDialog` en `presentation/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — Especificación extraída directamente de la tarjeta de Notion HU 6.1 (`4078442e-3f49-81ff-885c-c101c8751f28`) y clarificada con 3 decisiones cerradas (visualización en `MatchdayTabView`, catálogo de árbitros y estado de torneo no forzado a `inProgress`).
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Integridad referencial entre `ChampionshipTournament`, `TournamentTeam`, `SportsVenue`, `VenuePitch`, `MatchReferee` y `ChampionshipMatch`.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Cobertura completa en pruebas unitarias del algoritmo Round-Robin, repositorio local, colisiones horarias, controlador y widget tests de los 3 escenarios Gherkin.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — Algoritmo de fixture y reglas de solapamiento en `lib/domain/`; validaciones de colisión y permisos en `lib/application/`; almacenamiento local en `lib/infrastructure/`; selector de jornadas y tarjetas de partido en `lib/presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — Solo `Organizador` (`RoleCapability.manageTournaments`) y `Administrador` pueden generar fixture y programar partidos; las tarjetas y badges utilizan el sistema de diseño Kick Pulse (`DESIGN.md`).
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Identificadores técnicos en inglés; textos visibles y mensajes de error Gherkin en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Componentes adaptados para visualización móvil con chips deslizables horizontalmente, diálogos de selección de fecha/hora con validación reactiva y prevención de pulsaciones dobles en generación de fixture.

## Project Structure

### Documentation (this feature)

```text
specs/007-fixture-generation-assignment/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── fixture-scheduling-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── match_enums.dart                         # MatchStatus, ScheduleCollisionType
│   │   ├── championship_match.dart                  # ChampionshipMatch entity & interval calculation
│   │   ├── match_referee.dart                       # MatchReferee entity
│   │   ├── matches_catalog_state.dart               # Immutable UI state for MatchesCatalogController
│   │   └── schedule_collision_result.dart           # ScheduleCollisionResult & collision details
│   ├── services/
│   │   └── round_robin_generator.dart               # Pure domain deterministic Round-Robin fixture generator
│   ├── failures/
│   │   └── app_failure.dart                         # Extend with FixtureScheduleErrorCode & FixtureScheduleValidationFailure
│   └── repositories/
│       └── tournament_matches_repository.dart       # Abstract repository contract
├── application/
│   ├── use_cases/
│   │   └── fixture_scheduling_use_case.dart         # Fixture generation, match scheduling & collision detection
│   ├── controllers/
│   │   └── matches_catalog_controller.dart          # StateNotifier<MatchesCatalogState>
│   └── providers/
│       └── matches_catalog_providers.dart           # Riverpod providers for repository, use case, and controller
├── infrastructure/
│   └── repositories/
│       └── local_tournament_matches_repository.dart # Local storage JSON persistence + seed referees & matches
├── presentation/
│   ├── shell/
│   │   └── matchday_tab_view.dart                   # Refactored matchday tab with round chips, status filters & match cards
│   ├── matches/
│   │   ├── widgets/
│   │   │   ├── match_card.dart                      # 16px match card with team badges, status pill & scheduling details
│   │   │   └── schedule_match_dialog.dart           # Dialog to assign date, time, venue, pitch & referee
│   │   └── dialogs/
│   │       └── generate_fixture_confirmation_dialog.dart # Confirmation modal to trigger fixture generation
│   └── navigation/
│       └── app_router.dart                          # Existing router integration
└── l10n/
    └── app_es.arb                                   # Spanish strings & exact Gherkin messages for HU 6.1

test/
├── unit/
│   ├── domain/
│   │   ├── championship_match_entities_test.dart
│   │   └── round_robin_generator_test.dart
│   ├── application/
│   │   ├── fixture_scheduling_use_case_test.dart
│   │   └── matches_catalog_controller_test.dart
│   └── infrastructure/
│       └── local_tournament_matches_repository_test.dart
└── widget/
    └── matchday_fixture_widget_test.dart
```

**Structure Decision**: La estructura mantiene rigurosamente el patrón de 4 capas del proyecto. `MatchdayTabView` en `presentation/shell/` evoluciona desde el prototipo hacia el catálogo real de partidos de la jornada, complementado con componentes modulares en `presentation/matches/`.

## Complexity Tracking

*No violations detected. All additions follow standard domain entities, repositories, use cases, and Riverpod controllers.*
