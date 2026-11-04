# Implementation Plan: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Branch**: `006-coach-lineups-tracking` | **Date**: 2026-11-04 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/006-coach-lineups-tracking/spec.md)
**Input**: Feature specification from `/specs/006-coach-lineups-tracking/spec.md`

## Summary

Implementar el módulo de **Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)** siguiendo la Arquitectura Limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) y el sistema de diseño **Kick Pulse** (`DESIGN.md`). El módulo permite al `Entrenador` (y `Organizador`) acceder desde el detalle de su equipo (`/tournaments/teams/detail`) a la pantalla dedicada `/tournaments/teams/lineup` para armar la convocatoria del próximo partido (seleccionando la cantidad reglamentaria de titulares según la modalidad del campeonato, designando al capitán y marcando suplentes habilitados), consultar y actualizar el seguimiento interno de rendimiento y sanciones de la plantilla, bloquear automáticamente la selección de jugadores con sanción activa mostrándolos con la insignia semántica `"Suspendido (1 fecha)"` (`#EF4444`), conservar el borrador de selección ante interrupciones móviles (paso a segundo plano) y sincronizar inmediatamente la alineación confirmada con la vista de acta digital del `Árbitro`.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `3.41.2` (stable)  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `shared_preferences: ^2.5.4`, `flutter_localizations` (`intl: ^0.20.2`)  
**Storage**: Offline-first en `LocalStorageRepository` mediante `LocalLineupsTrackingRepository` (claves `'vifutbol.lineups.tracking.v1'` y `'vifutbol.lineups.convocations.v1'`), precargando métricas y sanciones semilla en `AppEnvironment.development` sobre `'team-seed-atletico-norte'` (ampliado a 10 jugadores semilla para contar con 7 titulares elegibles, 2 suplentes elegibles y 1 jugador suspendido por 1 fecha)  
**Testing**: `flutter_test` (pruebas unitarias de dominio, repositorio local, caso de uso de convocatorias/seguimiento, controlador Riverpod y widget tests de los 3 escenarios Gherkin incluyendo ciclo de vida móvil)  
**Target Platform**: Android & iOS (Mobile-first, portrait orientation, dark mode `#0A0E17`)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Evaluación disciplinaria y guardado local de borrador instantáneos (`< 5ms`), interfaz a 60 fps  
**Constraints**: Conservación automática de estado ante interrupciones del ciclo de vida móvil (`AppLifecycleState`), señales semánticas accesibles (`#EF4444` y `#F59E0B`) acompañadas de etiquetas de texto explícitas en español, 100% de textos visibles en `lib/l10n/app_es.arb` y 100% de identificadores técnicos en inglés  
**Scale/Scope**: 4 archivos nuevos en `domain/entities`, extensión de `app_failure.dart`, 1 contrato de repositorio en `domain/repositories`, 1 repositorio local en `infrastructure/repositories`, 1 caso de uso + 1 controlador + 1 archivo de providers en `application`, 1 pantalla dedicada en `presentation/teams/` e integración en `TeamRosterDetailScreen` y `AppRouter`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — Especificación sincronizada desde la tarjeta Notion HU 5.2 (`4078442e-3f49-8119-b539-f119f3baaece`) y clarificada antes de planificar.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Integridad referencial estricta entre `ChampionshipTournament`, `TournamentTeam`, `RegisteredPlayer`, `PlayerInternalTracking` y `MatchLineupConvocation`.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Cobertura completa mediante pruebas unitarias de entidades, repositorio, caso de uso, controlador y widget tests de los escenarios Gherkin.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — Entidades y reglas disciplinarias en `lib/domain/` en Dart puro; validaciones de convocatoria en `lib/application/`; persistencia JSON en `lib/infrastructure/`; interfaz en `lib/presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — `Entrenador` (`RoleCapability.manageLineups`) y `Organizador` (`RoleCapability.manageTournaments`) arman y confirman convocatorias; `Árbitro` visualiza la nómina oficial sincronizada para su acta digital; colores semánticos `#EF4444` (`KickPulseColors.accentLive`) y `#F59E0B` (`KickPulseColors.accentWarning`) con etiquetas explícitas.
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Identificadores técnicos en inglés; textos de interfaz y etiquetas Gherkin (`"Suspendido (1 fecha)"`, etc.) en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Conservación automática del borrador de selección ante paso a segundo plano (`WidgetsBindingObserver` + persistencia local inmediata) y protección contra pulsaciones repetidas.

## Project Structure

### Documentation (this feature)

```text
specs/006-coach-lineups-tracking/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── lineups-and-tracking-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── lineup_enums.dart                        # PlayerConvocationRole, PlayerDisciplinaryState, ConvocationStatus
│   │   ├── player_internal_tracking.dart            # PlayerInternalTracking entity & disciplinary state calculation
│   │   ├── match_lineup_convocation.dart            # MatchLineupConvocation entity (draft & confirmed snapshots)
│   │   └── team_lineups_tracking_state.dart         # Immutable state for LineupsTrackingController
│   ├── failures/
│   │   └── app_failure.dart                         # Extend with LineupConvocationErrorCode & LineupConvocationValidationFailure
│   └── repositories/
│       └── lineups_tracking_repository.dart         # Abstract LineupsTrackingRepository contract
├── application/
│   ├── use_cases/
│   │   └── manage_lineups_tracking_use_case.dart    # Starter/substitute/captain validation, suspension lock, referee sync
│   ├── controllers/
│   │   └── lineups_tracking_controller.dart         # StateNotifier<TeamLineupsTrackingState>
│   └── providers/
│       └── lineups_tracking_providers.dart          # Riverpod providers for repository, use case, and controller
├── infrastructure/
│   └── repositories/
│       ├── local_teams_repository.dart              # Expand 'team-seed-atletico-norte' to 10 seed players for full lineup + bench + 1 suspended
│       └── local_lineups_tracking_repository.dart   # JSON persistence + dev seed tracking & disciplinary records
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                          # Register '/tournaments/teams/lineup' route
│   └── teams/
│       ├── team_roster_detail_screen.dart           # Add action card/button to open CoachLineupTrackingScreen
│       └── coach_lineup_tracking_screen.dart        # Convocation builder, internal tracking & referee synced roster view
└── l10n/
    └── app_es.arb                                   # Spanish strings & exact Gherkin disciplinary badges/messages for HU 5.2

test/
├── unit/
│   ├── domain/
│   │   └── lineup_and_tracking_entities_test.dart
│   ├── application/
│   │   ├── manage_lineups_tracking_use_case_test.dart
│   │   └── lineups_tracking_controller_test.dart
│   └── infrastructure/
│       └── local_lineups_tracking_repository_test.dart
└── widget/
    └── coach_lineup_tracking_widget_test.dart
```

**Structure Decision**: Mantiene la arquitectura limpia de 4 capas del proyecto y extiende el flujo de equipos (`TeamRosterDetailScreen`) hacia `CoachLineupTrackingScreen` (`/tournaments/teams/lineup`).

## Complexity Tracking

Sin violaciones a la Constitución; no se requiere justificación adicional.
