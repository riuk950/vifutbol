# Implementation Plan: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Branch**: `005-teams-players-eligibility` | **Date**: 2026-04-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/005-teams-players-eligibility/spec.md)
**Input**: Feature specification from `/specs/005-teams-players-eligibility/spec.md`

## Summary

Implementar el módulo de **Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)** siguiendo la Arquitectura Limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) y el sistema de diseño **Kick Pulse** (`DESIGN.md`). El módulo permite a los roles `Organizador` y `Entrenador` inscribir equipos con nombre, sigla/escudo vectorial nativo y colores distintivos dentro de campeonatos con estado `"Inscripciones Abiertas"`, así como gestionar su plantilla de jugadores (nombre completo, documento de identidad único por campeonato, posición y dorsal único `1..99` por equipo con teclado numérico automático). Hace cumplir las reglas de integridad deportiva (unicidad de nombre de equipo por torneo, unicidad de dorsal por equipo y exclusividad de jugador por torneo con los mensajes exactos de Gherkin en español) y permite al `Organizador` (`RoleCapability.approveRegistrations`) habilitar oficialmente al equipo una vez alcanzado el cupo mínimo de jugadores definido en `TournamentRulesConfig`.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `3.41.2` (stable)  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `shared_preferences: ^2.5.4`, `flutter_localizations` (`intl: ^0.20.2`)  
**Storage**: Offline-first en `LocalStorageRepository` mediante `LocalTeamsRepository` (clave `'vifutbol.teams.catalog.v1'`), precargando 2 equipos semilla en `AppEnvironment.development` vinculados a `'tournament-seed-liga-clausura'`  
**Testing**: `flutter_test` (pruebas unitarias de dominio, repositorio local, caso de uso de elegibilidad/unicidad, controlador Riverpod y widget tests de interfaz y formularios)  
**Target Platform**: Android & iOS (Mobile-first, portrait orientation, dark mode `#0A0E17`)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Renderizado fluido a 60 fps del escudo vectorial y validaciones de unicidad instantáneas (`< 5ms`)  
**Constraints**: Offline-capable, teclado numérico automático para documento y dorsal, 100% de textos visibles en español en `lib/l10n/app_es.arb`, 100% de identificadores técnicos en inglés, segregación por `RoleCapability`  
**Scale/Scope**: 5 archivos nuevos/actualizados en `domain`, 3 en `application`, 1 en `infrastructure`, 5 en `presentation`, más localización y pruebas automatizadas

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — Especificación y diseño derivados directamente de la tarjeta Notion HU 5.1 (`4078442e-3f49-81c4-8588-c3b324c765e3`) y clarificados antes de planificar.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Se garantiza integridad referencial entre `ChampionshipTournament`, `TournamentTeam` y `RegisteredPlayer`, con validación determinista de unicidad de equipo, dorsal y documento por campeonato.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Se incluyen pruebas unitarias de entidades, repositorio, caso de uso (`ManageTeamsEligibilityUseCase`), controlador y widget tests con meta de cobertura `>= 80%`.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — Entidades y contratos en `lib/domain/` en Dart puro; reglas de negocio y elegibilidad en `lib/application/`; persistencia JSON en `lib/infrastructure/`; vistas y widgets en `lib/presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — `Organizador` y `Entrenador` registran equipos y jugadores; solo `Organizador` (`RoleCapability.approveRegistrations`) habilita oficialmente equipos; `Aficionado`, `Jugador` y `Árbitro` tienen acceso de solo lectura.
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Código, clases, métodos, archivos y tests 100% en inglés; textos de interfaz y mensajes Gherkin 100% en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Teclado numérico automático (`TextInputType.number`) para documento y dorsal, validación en línea, estados de vista explícitos y protección contra envíos duplicados (`isSaving`).

## Project Structure

### Documentation (this feature)

```text
specs/005-teams-players-eligibility/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── teams-players-ui-and-storage-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── team_enums.dart                     # TeamEligibilityStatus, PlayerPosition, TeamCrestShape
│   │   ├── registered_player.dart              # RegisteredPlayer entity
│   │   ├── tournament_team.dart                # TournamentTeam aggregate root
│   │   └── teams_catalog_state.dart            # TeamsCatalogState container
│   ├── failures/
│   │   └── app_failure.dart                    # Extend with TeamEligibilityErrorCode & TeamEligibilityValidationFailure
│   └── repositories/
│       └── teams_repository.dart               # Abstract TeamsRepository contract
├── application/
│   ├── use_cases/
│   │   └── manage_teams_eligibility_use_case.dart # Uniqueness, quota, role guards, and eligibility approval
│   ├── controllers/
│   │   └── teams_controller.dart               # StateNotifier<TeamsCatalogState>
│   └── providers/
│       └── teams_providers.dart                # Riverpod providers for repository, use case, and controller
├── infrastructure/
│   └── repositories/
│       └── local_teams_repository.dart         # JSON persistence + dev seed teams & rosters
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                     # Register '/tournaments/teams/detail' route
│   ├── shell/
│   │   └── tabs/
│   │       └── standings_tab_view.dart         # Integrate TournamentTeamsSection below rules summary card
│   └── teams/
│       ├── team_roster_detail_screen.dart      # Dedicated screen for team roster, player enrollment & eligibility approval
│       └── widgets/
│           ├── kick_pulse_team_crest.dart      # Native vector crest widget (shape, monogram, primary/secondary colors)
│           └── tournament_teams_section.dart   # Teams list & Create Team modal/dialog for active championship
└── l10n/
    └── app_es.arb                              # Spanish strings & exact Gherkin validation messages for HU 5.1

test/
├── unit/
│   ├── domain/
│   │   └── tournament_team_and_player_test.dart
│   ├── application/
│   │   ├── manage_teams_eligibility_use_case_test.dart
│   │   └── teams_controller_test.dart
│   └── infrastructure/
│       └── local_teams_repository_test.dart
└── widget/
    └── teams_roster_eligibility_widget_test.dart
```

**Structure Decision**: Mantiene la arquitectura limpia de 4 capas del proyecto y extiende `StandingsTabView` con `TournamentTeamsSection` y la vista de detalle `TeamRosterDetailScreen` (`/tournaments/teams/detail`).

## Complexity Tracking

Sin violaciones a la Constitución; no se requiere justificación adicional.
