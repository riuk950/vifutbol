# Implementation Plan: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)

**Branch**: `008-referee-digital-match-report` | **Date**: 2026-11-04 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/spec.md)  
**Input**: Feature specification from `/specs/008-referee-digital-match-report/spec.md`

## Summary

Implementar el módulo de **Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)** para la Épica 7 siguiendo la Arquitectura Limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) y el sistema de diseño **Kick Pulse** (`DESIGN.md`). El módulo permite al `Árbitro` designado (y al `Organizador` en contingencia) abrir desde cada tarjeta de partido en `"Jornada"` una vista dedicada (`/matches/report`) para iniciar el encuentro (`"En Juego"`), controlar los periodos con un cronómetro exacto basado en marcas de tiempo persistidas, registrar en tiempo real goles (con anotador y asistente), tarjetas disciplinarias aplicando automáticamente la **Regla de Doble Amarilla** (segunda amarilla genera expulsión por roja automática e inhabilita al jugador en el resto del partido) y sustituciones, operar sin conexión mostrando el indicador `"Modo sin conexión: cambios guardados en el dispositivo"` con sincronización idempotente automática al recuperar red, anular incidencias erróneas mientras el acta siga abierta, y firmar el cierre definitivo e inmutable del acta oficial (`"Finalizado"`).

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter SDK `3.41.2` (stable)  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `shared_preferences: ^2.5.4`, `flutter_localizations` (`intl: ^0.20.2`)  
**Storage**: Offline-first en `LocalStorageRepository` mediante `LocalMatchReportsRepository` (claves `'vifutbol.match_reports.v1'` y `'vifutbol.match_events_sync_queue.v1'`), sincronizado con `LocalTournamentMatchesRepository` (estado y marcador del partido) y `LocalLineupsTrackingRepository` (estadísticas y suspensiones al cerrar el acta)  
**Testing**: `flutter_test` (pruebas unitarias de dominio para `DigitalMatchReport`, cronómetro por marcas de tiempo, regla de doble amarilla y expulsión; pruebas de repositorio offline e idempotencia de cola; pruebas de caso de uso y controlador Riverpod; y widget tests de los 4 escenarios Gherkin y escalado de texto)  
**Target Platform**: Android & iOS (Mobile-first, portrait orientation, dark mode `#0A0E17`, áreas táctiles `>= 44x44px`)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Guardado local de incidencias en `< 20ms`, precisión de cronómetro con `0s` de deriva al pasar a segundo plano, sincronización idempotente de cola sin duplicados en `< 50ms`  
**Constraints**: Marcador en vivo con `FontFeature.tabularFigures()`, señal semántica `"Accent Live"` (`#EF4444`), inmutabilidad absoluta tras `"Cerrar Acta Oficial"`, 100% de textos visibles en `lib/l10n/app_es.arb` y 100% de identificadores técnicos en inglés  
**Scale/Scope**: 4 archivos de entidades/enums en `domain/entities`, extensión de `championship_match.dart` y `app_failure.dart`, 1 contrato de repositorio en `domain/repositories`, 1 repositorio local offline en `infrastructure/repositories`, 1 caso de uso + 1 controlador + 1 archivo de providers en `application`, pantalla `DigitalMatchReportScreen` + diálogos de registro en `presentation/matches/`, integración en `MatchCard` y `AppRouter`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — Especificación generada a partir de la tarjeta de Notion HU 7.1 (`4078442e-3f49-8153-92b9-cf76fe79fa33`) y refinada con 3 clarificaciones cerradas (`/matches/report`, anulación previa al cierre e indicador/cola offline reactiva).
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Cada `MatchEvent` posee un `id` único inmutable; el marcador (`homeScore`, `awayScore`) y las expulsiones (`expelledPlayerIds`) se calculan de forma determinista a partir de los eventos oficiales y al cerrar el acta se propagan al partido y al seguimiento disciplinario del campeonato.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Planificación de pruebas unitarias para entidades, repositorio con cola offline idempotente, caso de uso (doble amarilla, bloqueo de expulsados, cierre inmutable), controlador y widget tests de los 4 escenarios Gherkin.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — Entidades e invariantes en `lib/domain/`; reglas de arbitraje, doble amarilla y cierre en `lib/application/`; persistencia y cola de sincronización en `lib/infrastructure/`; interfaz en tiempo real en `lib/presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — Solo `Árbitro` (`RoleCapability.recordMatchEvents`, `RoleCapability.closeMatchReport`) y `Organizador` (`RoleCapability.manageTournaments`) pueden controlar el partido y registrar/cerrar el acta; los demás roles visualizan el acta en modo lectura. Uso estricto de tokens Kick Pulse (`KickPulseColors.accentLive` `#EF4444`, números tabulares).
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Código, clases, métodos y tests 100% en inglés; textos de interfaz y mensajes Gherkin (`"Modo sin conexión: cambios guardados en el dispositivo"`) 100% en español en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Cronómetro calculado por diferencia de *timestamps* inmune al bloqueo de pantalla/segundo plano, operación offline-first con cola idempotente, botones de acción rápida `>= 44x44px` y bloqueo *single-flight*.

## Project Structure

### Documentation (this feature)

```text
specs/008-referee-digital-match-report/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── digital-match-report-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── match_report_enums.dart                  # MatchPeriod, MatchEventType
│   │   ├── match_event.dart                         # MatchEvent entity with unique id & isSynced
│   │   ├── digital_match_report.dart                # DigitalMatchReport aggregate, timestamp timer & expulsion logic
│   │   ├── digital_match_report_state.dart          # Immutable state for DigitalMatchReportController
│   │   └── championship_match.dart                  # Extend with optional homeScore and awayScore
│   ├── failures/
│   │   └── app_failure.dart                         # Extend with MatchReportErrorCode & MatchReportValidationFailure
│   └── repositories/
│       └── match_reports_repository.dart            # Abstract repository contract for match reports & offline sync queue
├── application/
│   ├── use_cases/
│   │   └── manage_digital_match_report_use_case.dart # Period control, goals, double-yellow expulsion, offline sync & immutable close
│   ├── controllers/
│   │   └── digital_match_report_controller.dart     # StateNotifier<DigitalMatchReportState>
│   └── providers/
│       └── digital_match_report_providers.dart      # Riverpod providers for repository, use case & controller
├── infrastructure/
│   └── repositories/
│       └── local_match_reports_repository.dart      # Local JSON storage + idempotent offline sync queue
├── presentation/
│   ├── matches/
│   │   ├── digital_match_report_screen.dart         # Dedicated live match report screen (/matches/report)
│   │   ├── widgets/
│   │   │   ├── match_card.dart                      # Add live/final score display & button to open DigitalMatchReportScreen
│   │   │   └── match_event_timeline_tile.dart       # Timeline item with Accent Live (#EF4444) & undo action while open
│   │   └── dialogs/
│   │       ├── record_goal_dialog.dart              # Modal to select team, scorer, optional assistant & minute
│   │       ├── record_card_dialog.dart              # Modal to select team, player, yellow/red card & minute
│   │       ├── record_substitution_dialog.dart      # Modal to select team, player out, player in & minute
│   │       └── close_match_report_confirmation_dialog.dart # Summary & immutable sign-off confirmation modal
│   └── navigation/
│       └── app_router.dart                          # Register /matches/report route
└── l10n/
    └── app_es.arb                                   # Spanish localization strings for HU 7.1

test/
├── unit/
│   ├── domain/
│   │   └── digital_match_report_entities_test.dart
│   ├── infrastructure/
│   │   └── local_match_reports_repository_test.dart
│   └── application/
│       ├── manage_digital_match_report_use_case_test.dart
│       └── digital_match_report_controller_test.dart
└── widget/
    └── digital_match_report_widget_test.dart
```

**Structure Decision**: Se preserva la estructura limpia de 4 capas de `vifutbol`. La pantalla del acta digital (`DigitalMatchReportScreen`) y sus modales de registro en cancha se ubican en `lib/presentation/matches/` junto a `MatchCard`, conectándose mediante la ruta `/matches/report` en `AppRouter`.

## Complexity Tracking

*No violations detected. All components adhere to the existing Clean Architecture and Riverpod patterns.*
