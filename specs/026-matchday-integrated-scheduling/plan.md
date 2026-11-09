# Implementation Plan: Programación Integral de Partido al Seleccionarlo en la Jornada (Árbitro, Fecha, Sede y Cancha) (HU 15.3)

**Branch**: `026-matchday-integrated-scheduling` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/026-matchday-integrated-scheduling/spec.md`

## Summary

Habilitar al rol **Organizador** para programar o reprogramar integralmente cualquier partido en estado `pendingSchedule` o `scheduled` seleccionándolo directamente dentro de la pestaña de **Partidos por Jornadas** (`CompetitionFixtureTabView`) en el detalle de la competición (`/competitions/:id`). El flujo despliega `ScheduleMatchDialog` con selectores de Fecha (acotado con margen seguro a `[tournament.startDate, tournament.endDate]`), Hora, Sede Deportiva, Cancha dinámica y Árbitro Oficial; valida globalmente que no existan colisiones de horario en la misma cancha o con el mismo árbitro en todo el catálogo (`loadAllMatches()`); refleja la fecha, sede, cancha y árbitro directamente en el pie logístico de cada tarjeta de la jornada; y sincroniza reactivamente tanto el catálogo de partidos (preservando partidos de otros torneos en memoria) como el feed diario de `DailyMatchesFeedController`.

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter `^3.11.0`  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `intl: ^0.20.2`, `shared_preferences: ^2.5.4`, `google_fonts: ^6.2.1`  
**Storage**: Almacenamiento local offline-first (`LocalStorageRepository` / `LocalTournamentMatchesRepository` / `LocalVenuesRepository`)  
**Testing**: `flutter_test` (Unit & Widget tests)  
**Target Platform**: iOS & Android (Mobile-First, adaptable desde $320 \times 640\text{ px}$ con escalado de texto del $130\%$)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Renderizado a 60 fps sin bloqueos de UI; validación de colisiones y actualización reactiva de jornadas y feed diario en $<50\text{ ms}$  
**Constraints**: Offline-first, 0 errores/advertencias en `flutter analyze`, UI 100% en español vía `l10n`, código técnico en inglés  
**Scale/Scope**: Múltiples competiciones activas simultáneas compartiendo sedes deportivas, canchas y cuerpo arbitral

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — La especificación (`spec.md`) ha sido creada y clarificada a partir de la HU 15.3 de Notion antes de escribir código.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Se refuerza la detección global de colisiones de cancha y árbitro (`loadAllMatches()`) y se preserva el estado multi-torneo en `MatchesCatalogController.scheduleMatch`.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Se incluyen pruebas unitarias para colisiones globales y formato de sede/cancha, y pruebas de widgets para apertura por rol en `CompetitionFixtureTabView`, pie logístico, programación completa y viewport compacto ($320 \times 640\text{ px}$ @ $130\%$).
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — La validación de colisiones permanece en la capa de aplicación/dominio (`FixtureSchedulingUseCase`), la persistencia en `TournamentMatchesRepository` y los componentes visuales en `presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — Solo `UserRole.organizer` (`RoleCapability.manageTournaments`) abre `ScheduleMatchDialog` en torneos editables; el resto de roles mantiene la vista de solo lectura.
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Identificadores técnicos en inglés y textos visibles al usuario 100% en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Bloqueo *single-flight* durante el guardado (`catalogState.isSaving`), acotación segura de `DatePicker` y layout adaptable sin `RenderFlex overflow`.

## Project Structure

### Documentation (this feature)

```text
specs/026-matchday-integrated-scheduling/
├── plan.md                                        # Plan técnico de implementación
├── research.md                                    # Decisiones de diseño y arquitectura (Phase 0)
├── data-model.md                                  # Modelo de datos y reglas de colisión (Phase 1)
├── quickstart.md                                  # Guía de validación funcional y comandos (Phase 1)
├── contracts/
│   └── ui-matchday-scheduling-contracts.md        # Contratos de Widget Keys, casos de uso y l10n
└── tasks.md                                       # Lista de tareas ordenadas (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                 # Claves de localización para pie logístico y confirmación
│   ├── app_localizations.dart                     # Generado por flutter gen-l10n
│   └── app_localizations_es.dart                  # Generado por flutter gen-l10n
├── domain/
│   └── repositories/
│       └── tournament_matches_repository.dart     # Exposición de loadAllMatches()
├── infrastructure/
│   └── repositories/
│       └── local_tournament_matches_repository.dart # Implementación de loadAllMatches()
├── application/
│   ├── use_cases/
│   │   └── fixture_scheduling_use_case.dart       # Validación global de colisiones y formato Sede - Cancha
│   └── controllers/
│       └── matches_catalog_controller.dart        # Preservación multi-torneo en scheduleMatch
└── presentation/
    ├── matches/
    │   └── widgets/
    │       └── schedule_match_dialog.dart         # Rango seguro de DatePicker y refresco de DailyMatchesFeedController
    └── tournaments/
        └── widgets/
            └── competition_fixture_tab_view.dart  # Apertura directa de ScheduleMatchDialog para Organizador y pie logístico

test/
├── unit/
│   └── application/
│       └── fixture_scheduling_use_case_test.dart  # Tests unitarios de colisión global entre torneos y sede-cancha
├── presentation/
│   └── tournaments/
│       └── competition_fixture_widget_test.dart   # Tests de widgets para programación desde la jornada, RBAC, pie logístico y 320x640 @ 130%
└── widget/
    └── matchday_fixture_widget_test.dart          # Tests integrados de programación y colisión
```

**Structure Decision**: Se mantiene la arquitectura limpia del proyecto Flutter (`domain`, `application`, `infrastructure`, `presentation`), extendiendo los componentes existentes sin duplicar diálogos ni repositorios.

## Complexity Tracking

> No existen violaciones a la Constitución; no se requiere justificación de complejidad adicional.
