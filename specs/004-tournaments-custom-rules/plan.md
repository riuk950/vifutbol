# Implementation Plan: Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (HU 4.1)

**Branch**: `004-tournaments-custom-rules` | **Date**: 2026-04-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/004-tournaments-custom-rules/spec.md)
**Input**: Feature specification from `/specs/004-tournaments-custom-rules/spec.md`

## Summary

Implementar el módulo de **Creación de Campeonatos (Ligas, Copas Eliminatorias y Mixtos) y Reglas Personalizadas (HU 4.1)** siguiendo la Arquitectura Limpia en 4 capas del proyecto (`domain`, `application`, `infrastructure`, `presentation`) y el sistema de diseño **Kick Pulse** (`DESIGN.md`). El módulo permite al rol `Organizador` (`RoleCapability.manageTournaments`) crear y editar campeonatos definiendo formato (`Liga`, `Copa Eliminatoria`, `Mixto`), puntos por victoria/empate/derrota (`3/1/0` por defecto), orden de criterios de desempate (`Diferencia de Gol`, `Goles a Favor`, `Duelo Directo`, `Fair Play`), límite de acumulación de tarjetas amarillas para suspensión automática, cupo mínimo/máximo de jugadores por equipo, duración por tiempo y configuración de llaves eliminatorias (incluyendo desempate directo por penales). Incluye máquina de estados (`Inscripciones Abiertas` → `En Curso` → `Finalizado`), protección de inmutabilidad con confirmación administrativa explícita y registro de auditoría (`RuleAuditEntry`) al modificar formato o puntuación en estado `En Curso`, y autoguardado local de borrador móvil con diálogo de salida ante cambios sin guardar.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `3.41.2` (stable)  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `shared_preferences: ^2.5.4`, `flutter_localizations` (`intl: ^0.20.2`)  
**Storage**: Offline-first en `LocalStorageRepository` (`SharedPreferences`) mediante `LocalTournamentsRepository` (catálogo JSON bajo `'vifutbol.tournaments.catalog.v1'` y borrador de creación bajo `'vifutbol.tournaments.creation_draft.v1'`), con 3 campeonatos semilla en `AppEnvironment.dev`  
**Testing**: `flutter_test` (pruebas unitarias de dominio, casos de uso, repositorio local, controlador Riverpod y widget tests de vistas, formularios y diálogos)  
**Target Platform**: Android & iOS (Mobile-first, portrait orientation, dark mode nativo `#0A0E17`)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Renderizado a 60 fps sin bloqueos de hilo principal; creación completa de campeonato en `< 90s` (`SC-001`)  
**Constraints**: Offline-capable, 100% de textos visibles en español en `lib/l10n/app_es.arb`, 100% de identificadores técnicos en inglés, segregación estricta por `RoleCapability.manageTournaments`  
**Scale/Scope**: 6 archivos nuevos/actualizados en `domain`, 3 en `application`, 1 en `infrastructure`, 4 en `presentation`, más localización y pruebas automatizadas

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — Trazabilidad completa desde la tarjeta Notion HU 4.1 (`4078442e-3f49-8108-9e3e-d6d4fd477b75`) hacia `spec.md`, `research.md`, `data-model.md`, `contracts/` y `quickstart.md`.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — `ChampionshipTournament` y `TournamentRulesConfig` validan de forma determinista el sistema de puntuación, el orden sin duplicados de criterios de desempate, los cupos de plantilla, la estructura de llaves eliminatorias y el historial `auditTrail` (`RuleAuditEntry`).
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Se contemplan pruebas unitarias exhaustivas de dominio/aplicación/infraestructura y widget tests de presentación con meta de cobertura `>= 80%`.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — El dominio (`lib/domain/`) es Dart puro sin dependencias de Flutter ni de `shared_preferences`; los casos de uso (`lib/application/`) orquestan permisos, validaciones y auditoría; la infraestructura (`lib/infrastructure/`) implementa la serialización local.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — Solo `UserRole.organizer` posee `RoleCapability.manageTournaments`; todos los demás roles acceden en modo lectura a la normativa oficial. La interfaz aplica los tokens de `DESIGN.md` (`KickPulseColors`, `KickPulseTypography`, `KickPulseCard`, `KickPulseButton`, `KickPulseStateView`).
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Todos los nombres de archivos, clases, métodos, variables y tests están en inglés; todos los textos de UI están en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Cubre estados `loading`, `empty`, `content`, `error`, autoguardado de borrador al pasar a segundo plano (`AppLifecycleListener`), intercepción de salida con cambios sin guardar (`PopScope`) y protección contra envíos duplicados (`isSaving`).

## Project Structure

### Documentation (this feature)

```text
specs/004-tournaments-custom-rules/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── tournaments-ui-and-storage-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── app_failure.dart                    # Extend with TournamentValidationErrorCode & TournamentValidationFailure
│   │   ├── tournament_enums.dart               # TournamentFormat, TournamentStatus, TiebreakerCriterion, KnockoutRound
│   │   ├── tournament_rules_config.dart        # KnockoutStageConfig, GroupStageConfig, TournamentRulesConfig
│   │   ├── rule_audit_entry.dart               # RuleAuditEntry value object
│   │   ├── championship_tournament.dart        # ChampionshipTournament aggregate root
│   │   ├── tournament_draft.dart               # TournamentDraft value object
│   │   └── tournaments_catalog_state.dart      # TournamentsCatalogState
│   └── repositories/
│       └── tournaments_repository.dart         # Abstract TournamentsRepository contract
├── application/
│   ├── use_cases/
│   │   └── manage_tournaments_use_case.dart    # Validation, role guard, state transitions, and audited critical-rule overrides
│   ├── controllers/
│   │   └── tournaments_controller.dart         # StateNotifier<UiViewState<TournamentsCatalogState>>
│   └── providers/
│       └── tournaments_providers.dart          # Riverpod providers for repository, use case, and controller
├── infrastructure/
│   └── repositories/
│       └── local_tournaments_repository.dart   # JSON persistence + dev seed championships + local draft storage
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                     # Register '/tournaments/form' route
│   ├── shell/
│   │   └── tabs/
│   │       └── standings_tab_view.dart         # Championships & Official Rules Center in Standings tab
│   └── tournaments/
│       ├── tournament_form_screen.dart         # Create/Edit wizard with draft autosave, PopScope dialog & audit confirmation dialog
│       └── widgets/
│           └── tournament_rules_summary_card.dart # Visual summary of scoring, tiebreakers, knockout bracket & audit trail
└── l10n/
    └── app_es.arb                              # Spanish strings for HU 4.1

test/
├── unit/
│   ├── domain/
│   │   └── tournament_rules_and_entities_test.dart
│   ├── application/
│   │   ├── manage_tournaments_use_case_test.dart
│   │   └── tournaments_controller_test.dart
│   └── infrastructure/
│       └── local_tournaments_repository_test.dart
└── widget/
    ├── standings_tab_view_test.dart
    └── tournament_form_screen_test.dart
```

**Structure Decision**: Se mantiene la arquitectura limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) exactamente igual que en las HU 1.1, HU 2.1 y HU 3.1, integrando el centro de campeonatos y normativa oficial en `StandingsTabView` y exponiendo `/tournaments/form` en `AppRouter`.

## Complexity Tracking

No existen violaciones a la Constitución; no se requiere justificación de complejidad adicional.
