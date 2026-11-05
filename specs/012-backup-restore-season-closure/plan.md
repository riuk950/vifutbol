# Implementation Plan: Exportación e Importación de Respaldos (Backup/Restore) y Cierre Histórico de Temporada (HU 9.2)

**Branch**: `012-backup-restore-season-closure` | **Date**: 2026-11-05 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/012-backup-restore-season-closure/spec.md)

**Input**: Feature specification from `/specs/012-backup-restore-season-closure/spec.md`

## Summary

Implementar la capacidad para que el `Organizador` exporte e importe copias de respaldo estructuradas (`schemaVersion: 1`) de cualquier campeonato con validación estricta previa de esquema e integridad referencial cruzada, aplicando una restauración aislada (`upsert`) por torneo sin corromper ni borrar otros campeonatos locales. Asimismo, implementar el cierre oficial de temporada una vez finalizados todos los partidos obligatorios o la gran final, proclamando el **Cuadro de Honor** oficial (**Campeón**, **Subcampeón**, **Máximo Goleador** y **Valla Menos Vencida**), exigiendo confirmación explícita de seguridad de dos pasos para ambas operaciones críticas y protegiendo los torneos cerrados en modo de consulta histórica permanente.

## Technical Context

**Language/Version**: Dart `>=3.11.0`, Flutter `>=3.41.0`

**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl` (sin añadir paquetes externos de terceros fuera del stack actual)

**Storage**: `LocalStorageRepository` (`SharedPreferences` con namespace aislado por entorno y clave dedicada `vifutbol.season_honor_rolls.v1` + métodos de reemplazo por torneo en repositorios existentes)

**Testing**: `flutter_test`, `mockito` (unit tests de entidades, validación de respaldos, cierre de temporada y widget tests de modales de respaldo, cuadro de honor y responsividad 320px/130%)

**Target Platform**: iOS y Android (Mobile App Offline-First)

**Project Type**: Mobile Application (Clean Architecture por capas)

**Performance Goals**: Exportación, validación e importación de paquete de respaldo en `<100 ms` en memoria (`<3 s` incluyendo interacción UI), renderizado a 60 fps sin bloqueos del hilo principal

**Constraints**: Offline-first, máximo 4 pestañas en barra de navegación inferior (`MOBILE_GUIDELINES.md`), confirmación de seguridad de dos pasos antes de sobrescribir datos o cerrar campeonato, 0 overflows a 320 px de ancho y 130% de escala tipográfica

**Scale/Scope**: Paquetes de respaldo por campeonato (hasta 32 equipos, ~600 jugadores, ~120 partidos con actas y comunicados), 3 entidades de dominio nuevas, 1 repositorio nuevo, extensiones atómicas en 4 repositorios existentes, 4 casos de uso y 3 componentes de presentación

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Estado Pre-Research | Estado Post-Design | Justificación |
| :--- | :--- | :--- | :--- |
| **I. La Spec Manda** | ✅ PASS | ✅ PASS | Especificación completa con 5 clarificaciones resueltas e integradas en `spec.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | ✅ PASS | ✅ PASS | `ValidateTournamentBackupUseCase` verifica integridad referencial cruzada completa antes de cualquier escritura; el Cuadro de Honor se calcula deterministamente desde las actas y tablas oficiales. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | ✅ PASS | ✅ PASS | Se definen pruebas unitarias para entidades, validación/restauración de respaldos y cierre de temporada, más pruebas de widgets y accesibilidad (320px/130%). |
| **IV. Arquitectura Limpia y Separación de Capas** | ✅ PASS | ✅ PASS | Entidades y contratos en `lib/domain/`, casos de uso y controladores en `lib/application/`, persistencia en `lib/infrastructure/` y widgets en `lib/presentation/`. |
| **V. Segregación de Roles y Sistema de Diseño** | ✅ PASS | ✅ PASS | Exportar/Importar respaldos y Finalizar Campeonato restringidos a `UserRole.organizer`; Cuadro de Honor visible para los 5 roles con tokens `KickPulseColors` y `KickPulseTypography`. |
| **VI. Convenciones de Idioma y Nomenclatura** | ✅ PASS | ✅ PASS | Código técnico en inglés; textos visibles y mensajes de validación 100% en español vía `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | ✅ PASS | ✅ PASS | Confirmación de 2 pasos con casilla obligatoria, prevención de doble toque, diseño adaptable a 320 px y 130% de texto. |

## Project Structure

### Documentation (this feature)

```text
specs/012-backup-restore-season-closure/
├── plan.md              # Este archivo
├── research.md          # Decisiones arquitectónicas (Fase 0)
├── data-model.md        # Entidades, invariantes y esquema JSON (Fase 1)
├── quickstart.md        # Escenarios y comandos de validación (Fase 1)
├── contracts/           # Contratos de repositorios y casos de uso (Fase 1)
│   ├── backup_restore_contract.md
│   └── season_closure_contract.md
└── tasks.md             # Lista de tareas ordenadas por dependencias (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   └── app_es.arb                                               # Nuevas cadenas en español para respaldos, validación, cierre y cuadro de honor
├── domain/
│   ├── entities/
│   │   ├── season_honor_roll.dart                               # Entidad SeasonHonorRoll con serialización JSON
│   │   ├── tournament_backup_package.dart                       # Entidad TournamentBackupPackage (schemaVersion: 1)
│   │   └── backup_validation_result.dart                        # Entidad BackupValidationResult
│   └── repositories/
│       ├── season_honor_roll_repository.dart                    # Contrato SeasonHonorRollRepository
│       ├── teams_repository.dart                                # Extensión replaceTeamsForTournament
│       ├── tournament_matches_repository.dart                   # Extensión replaceMatchesForTournament
│       ├── match_reports_repository.dart                        # Extensión replaceReportsForTournament
│       └── tournament_news_repository.dart                      # Extensión replaceNewsForTournament
├── infrastructure/
│   └── repositories/
│       ├── local_season_honor_roll_repository.dart              # Implementación persistente en vifutbol.season_honor_rolls.v1
│       ├── local_teams_repository.dart                          # Implementación replaceTeamsForTournament
│       ├── local_tournament_matches_repository.dart             # Implementación replaceMatchesForTournament
│       ├── local_match_reports_repository.dart                  # Implementación replaceReportsForTournament
│       └── local_tournament_news_repository.dart                # Implementación replaceNewsForTournament
├── application/
│   ├── use_cases/
│   │   ├── tournament_backup_use_cases.dart                     # ExportTournamentBackupUseCase, ValidateTournamentBackupUseCase, ImportTournamentBackupUseCase
│   │   ├── close_tournament_season_use_case.dart                # CloseTournamentSeasonUseCase (previewHonorRoll y closeSeason)
│   │   ├── manage_teams_eligibility_use_case.dart               # Guardia de solo lectura si el campeonato está finalizado
│   │   ├── fixture_scheduling_use_case.dart                     # Guardia de solo lectura si el campeonato está finalizado
│   │   └── manage_tournament_news_use_cases.dart                # Guardia de solo lectura si el campeonato está finalizado
│   ├── controllers/
│   │   └── backup_and_season_closure_controller.dart            # Estado y controlador Riverpod para respaldos, cierre y cuadro de honor
│   └── providers/
│       └── backup_and_season_closure_providers.dart             # Providers de repositorio, casos de uso y controlador
└── presentation/
    ├── tournaments/
    │   └── widgets/
    │       ├── tournament_rules_summary_card.dart               # Botones de "Respaldo del torneo" y "Finalizar Campeonato" (Organizador) + aviso de solo lectura histórica
    │       ├── tournament_backup_sheet.dart                     # Hoja modal para exportar/copiar e importar/validar respaldos con confirmación de 2 pasos
    │       └── season_closure_confirmation_dialog.dart          # Diálogo de confirmación de 2 pasos con vista previa del Cuadro de Honor
    ├── standings/
    │   └── widgets/
    │       └── season_honor_roll_card.dart                      # Panel destacado del Cuadro de Honor oficial para todos los roles
    └── shell/
        └── tabs/
            └── standings_tab_view.dart                          # Integración de SeasonHonorRollCard, flujo de cierre de temporada y modal de respaldos

test/
├── unit/
│   ├── domain/
│   │   └── backup_and_honor_roll_entities_test.dart             # Pruebas unitarias de entidades y serialización JSON
│   └── application/
│       ├── tournament_backup_use_cases_test.dart                # Pruebas de exportación, rechazo de archivos corruptos/huérfanos y restauración aislada
│       └── close_tournament_season_use_case_test.dart           # Pruebas de cierre de temporada, cálculo determinista del Cuadro de Honor e inmutabilidad histórica
└── widget/
    ├── tournament_backup_restore_widget_test.dart               # Pruebas de widgets para exportación, rechazo con mensaje exacto y restauración en 2 pasos
    └── season_closure_honor_roll_widget_test.dart               # Pruebas de widgets para cierre de temporada, Cuadro de Honor y responsividad 320px/130%
```

**Structure Decision**: Se mantiene la estructura Clean Architecture de proyecto único Flutter (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`) integrando los nuevos componentes en los módulos de torneos y clasificación sin añadir pestañas nuevas a la navegación principal.

## Complexity Tracking

> Sin violaciones a la Constitución. No se requieren excepciones de complejidad.
