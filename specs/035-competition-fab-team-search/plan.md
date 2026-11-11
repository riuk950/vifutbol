# Implementation Plan: Inscripción de Equipos mediante Menú Flotante con Buscador en Detalles de Competición (HU 18.4)

**Branch**: `develop` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)  
**Feature Directory**: `specs/035-competition-fab-team-search`  
**Notion Target Card**: `[Épica 18] HU 18.4` (`4158442e-3f49-8186-9672-fee8a77257ce`)  

---

## Summary

Implementar en [`CompetitionDetailScreen`](../../../lib/presentation/tournaments/competition_detail_screen.dart) un menú flotante expandible (FAB Menu) exclusivo para `UserRole.organizer` en competiciones editables con las acciones `"Generar Fixture"` (solo si aún no existe fixture) y `"Agregar Equipos"` (disponible siempre mientras el torneo sea editable). Al seleccionar `"Agregar Equipos"`, se despliega el modal [`AddTeamsToCompetitionModal`](../../../lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart) con un buscador en tiempo real insensible a mayúsculas y tildes (`normalizeSearchText` / `matchesSearchQuery`), listado alfabético deduplicado del catálogo global de clubes, distintivo `"Inscrito"` con botón deshabilitado para equipos ya presentes en la competición, e inscripción transaccional mediante `ManageTeamsEligibilityUseCase.enrollExistingTeamFromCatalog` en estado `TeamEligibilityStatus.pendingVerification` copiando identidad y jugadores no conflictivos en estado pendiente de validación, auto-asignando el grupo menos poblado en formato mixto y manteniendo el modal abierto para inscripciones consecutivas.

---

## Technical Context

**Language/Version**: Dart ^3.12.0 (Flutter SDK)  
**Primary Dependencies**: Flutter Material, `flutter_riverpod` (^2.6.1), `flutter_localizations`, `uuid` (^4.5.1)  
**Storage**: `LocalTeamsRepository` respaldado por almacenamiento local persistente (`shared_preferences` / fallback en memoria)  
**Testing**: `flutter_test`, `mocktail`, `flutter_localizations`  
**Target Platform**: Android, iOS (Mobile-first)  
**Project Type**: Mobile Application (`vifutbol`)  
**Performance Goals**:
- Expansión/contracción del FAB Menu en `120 ms` (`< 150 ms` requerido por `SC-001`).
- Filtrado de búsqueda en tiempo real síncrono en memoria `< 50 ms` por pulsación (`SC-002`).  
**Constraints**:
- Segregación estricta de rol (`RoleCapability.manageTournaments` para `UserRole.organizer`).
- Todos los textos visibles en español centralizados en `lib/l10n/app_es.arb` y código técnico 100% en inglés.
- Cero inscripciones duplicadas en una competición (validación por `id` y nombre normalizado case/diacritic-insensitive).
- Protección multi-tap durante el guardado (`isSaving` + bloqueo por fila en modal).  
**Scale/Scope**: Pantalla `CompetitionDetailScreen`, capa de aplicación (`ManageTeamsEligibilityUseCase`, `TeamsController`, `search_utils.dart`) y archivos `l10n`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Plan Compliance (Pre-Research & Post-Design) | Status |
|---|---|---|---|
| **I. La Spec Manda** | Basado en `spec.md`, clarificaciones y `docs/MOBILE_GUIDELINES.md`. | Todos los requisitos (`FR-001`..`FR-008`) y las 4 clarificaciones de sesión están trazados en diseño y contratos. | **PASS** |
| **II. Integridad de Datos** | Integridad referencial, unicidad de equipo y jugador por torneo. | Unicidad de equipo por torneo (`id` y nombre normalizado), ID único generado vía `uuid`, jugadores conflictivos por `documentId` omitidos con aviso y estado inicial `pendingVerification`. | **PASS** |
| **III. Pruebas como Puerta** | Pruebas unitarias y de widget antes de cerrar la especificación. | Pruebas unitarias (`search_utils`, `enrollExistingTeamFromCatalog`) y pruebas de widget (`CompetitionDetailFabMenu`, `AddTeamsToCompetitionModal`) planificadas, reemplazando `competition_detail_fab_simplification_test.dart`. | **PASS** |
| **IV. Arquitectura Limpia** | Desacoplamiento Dominio / Casos de Uso / Controladores / UI. | Reglas de negocio (validación de rol, editabilidad, balanceo de grupo, copia de plantilla sin conflictos) viven en `ManageTeamsEligibilityUseCase` y `TeamsController`; la UI solo observa estado y dispara acciones. | **PASS** |
| **V. Segregación de Roles y Diseño** | Permisos por rol y tokens de `DESIGN.md`. | FAB Menu exclusivo para `RoleCapability.manageTournaments`; componentes usan `KickPulseColors`, `KickPulseTypography`, `KickPulseSearchBar`, `KickPulseBadge` y `KickPulseRadiiSpacing`. | **PASS** |
| **VI. Convenciones de Idioma** | Código técnico en inglés, interfaz en español vía `l10n`. | Identificadores, archivos, contratos y tests 100% en inglés; textos visibles definidos como claves en `lib/l10n/app_es.arb`. | **PASS** |
| **VII. Resiliencia y Experiencia Móvil** | Estados vacío/búsqueda/carga/error, safe area, multi-tap guard. | `showModalBottomSheet` con `useSafeArea: true` e `isScrollControlled: true`, estados vacíos diferenciados, conservación de filtro tras agregar y bloqueo contra pulsaciones repetidas. | **PASS** |

**Gate Result (Pre-Research & Post-Design)**: **7 / 7 PASSED**. Sin violaciones arquitectónicas.

---

## Project Structure

### Documentation (this feature)

```text
specs/035-competition-fab-team-search/
├── spec.md                                           # Especificación funcional + clarificaciones
├── plan.md                                           # Este plan de implementación
├── research.md                                       # Decisiones de arquitectura e investigación (Phase 0)
├── data-model.md                                     # Modelos y reglas de transición (Phase 1)
├── quickstart.md                                     # Escenarios y comandos de validación (Phase 1)
├── contracts/                                        # Contratos de UI y Use Case (Phase 1)
│   └── competition-fab-team-search-contracts.md
├── checklists/
│   └── requirements.md                               # Checklist 16/16 aprobado
└── tasks.md                                          # Tareas ordenadas (generado por /speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── application/
│   ├── controllers/
│   │   └── teams_controller.dart                     # Método enrollExistingTeamFromCatalog con single-flight guard
│   ├── use_cases/
│   │   └── manage_teams_eligibility_use_case.dart    # EnrollExistingTeamResult, enrollExistingTeamFromCatalog, helper de grupo
│   └── utils/
│       └── search_utils.dart                         # Ampliación de normalización diacritic-insensitive
├── l10n/
│   ├── app_es.arb                                    # Claves l10n para FAB Menu y modal buscador
│   ├── app_localizations.dart                        # Regenerado vía flutter gen-l10n
│   └── app_localizations_es.dart                     # Regenerado vía flutter gen-l10n
└── presentation/
    └── tournaments/
        ├── competition_detail_screen.dart            # Reemplazo de FAB único por CompetitionDetailFabMenu
        └── widgets/
            ├── competition_detail_fab_menu.dart      # [NUEVO] FAB Menu expandible (Generar Fixture / Agregar Equipos)
            ├── add_teams_to_competition_modal.dart   # [NUEVO] Bottom sheet modal con KickPulseSearchBar y catálogo
            └── competition_enroll_team_dialog.dart   # Reutilización opcional de helper de grupo menos poblado

test/
├── unit/
│   └── application/
│       └── search_utils_test.dart                    # [AMPLIADO] Casos de búsqueda sin tildes y mayúsculas
├── application/
│   └── use_cases/
│       └── enroll_existing_team_from_catalog_test.dart # [NUEVO] Pruebas unitarias de copia, conflicto y grupo
└── presentation/
    └── tournaments/
        ├── competition_detail_fab_simplification_test.dart # [ACTUALIZAR/REEMPLAZAR] -> competition_detail_fab_menu_test.dart
        └── add_teams_to_competition_modal_test.dart  # [NUEVO] Pruebas de widget e integración reactiva
```

**Structure Decision**: Se mantiene la arquitectura limpia existente por capas (`domain/`, `application/`, `presentation/`) reutilizando `KickPulseSearchBar`, `KickPulseBadge`, `KickPulseTeamCrest`, `StandingsCalculatorService` y `search_utils.dart` sin introducir dependencias externas ni alterar esquemas de persistencia.

---

## Complexity Tracking

> No existen violaciones constitucionales que requieran justificación.
