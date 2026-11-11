# Implementation Plan: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Branch**: `032-competition-inline-venues` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/032-competition-inline-venues/spec.md`

---

## Summary

Esta característica habilita al Organizador (`UserRole.organizer`) a seleccionar sedes existentes y crear nuevas sedes deportivas directamente desde el formulario de creación de torneos (`TournamentFormScreen`) mediante un Modal Bottom Sheet interactivo deslizable (`CreateVenueBottomSheet`). La creación de la sede es no destructiva (preserva intactos los datos del torneo), valida unicidad del nombre contra el catálogo, genera canchas internas de forma secuencial ("Cancha 1", ..., "Cancha N"), persiste la sede en `VenuesRepository` y la asocia automáticamente a la lista `venueIds` del nuevo campeonato.

---

## Technical Context

**Language/Version**: Dart 3.12.0 / Flutter 3.44.0  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `hive: ^2.2.3`, `uuid: ^4.5.1`, `intl: any`  
**Storage**: `HiveLocalStorageRepository` (persistencia local offline de sedes y torneos)  
**Testing**: `flutter_test`, `mocktail: ^1.0.4`  
**Target Platform**: Android, iOS, Web (mobile smartphones en orientación vertical estricta)  
**Project Type**: Mobile Application (Clean Architecture + Riverpod)  
**Performance Goals**: Despliegue del bottom sheet < 100ms, guardado de sede < 300ms, flujo total de creación de sede < 45s  
**Constraints**: Operación offline tolerante, sin pérdida de datos del torneo al crear o cancelar sedes, teclado deslizable sin *RenderFlex overflow*  
**Scale/Scope**: Formulario de torneo, componente de bottom sheet, extensión de 2 entidades de dominio, 1 caso de uso, actualización de controladores y tests  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check Item | Status | Justification / Implementation Evidence |
|---|---|---|---|
| **I. Spec-Driven Development** | Funcionalidad derivada estrictamente de la spec | **PASS** | Todo el diseño se apega a `spec.md` (HU 18.1 de Notion) y las clarificaciones acordadas en la sesión 2026-11-11. |
| **II. Data Integrity** | Integridad referencial y validación de entidades | **PASS** | `ChampionshipTournament.venueIds` referencia `SportsVenue.id`; validación de unicidad de nombre de sede en `ManageVenuesUseCase`; canchas válidas $N \ge 1$. |
| **III. Automated Testing** | Pruebas unitarias, de caso de uso y widgets | **PASS** | Suites de pruebas planificadas para serialización de dominio, validación de duplicados, controladores y widgets de Bottom Sheet y formulario. |
| **IV. Clean Architecture** | Separación estricta de capas | **PASS** | Entidades de dominio puras (`SportsVenue`, `ChampionshipTournament`); orquestación en `ManageVenuesUseCase`; estado en Riverpod (`VenuesController`, `TournamentsController`); presentación aislada. |
| **V. Role Segregation & Design** | Control de acceso y fidelidad a KickPulse | **PASS** | Restringido a `UserRole.organizer`; uso de tokens de `KickPulseColors`, `KickPulseRadiiSpacing` y `KickPulseTypography`. |
| **VI. Language Conventions** | Código en inglés y UI en español localizada | **PASS** | Código técnico (nombres de clases, métodos, variables y tests) 100% en inglés; textos de UI centralizados en `lib/l10n/app_es.arb` y `app_en.arb`. |
| **VII. Mobile Resilience** | Pautas de `docs/MOBILE_GUIDELINES.md` | **PASS** | `isScrollControlled: true` para adaptación de teclado; flujo no destructivo; doble tap guard; preservación en `TournamentDraft`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/032-competition-inline-venues/
├── spec.md              # Especificación funcional con clarificaciones resueltas
├── plan.md              # Este archivo de arquitectura y diseño técnico
├── research.md          # Investigación técnica y decisiones arquitectónicas
├── data-model.md        # Modelado de datos de entidades y diagramas ER
├── quickstart.md        # Guía de verificación y ejecución de pruebas
├── contracts/
│   └── inline-venue-contracts.md # Contratos de widgets, controladores y localización
└── checklists/
    └── requirements.md  # Checklist de calidad de la especificación (16/16)
```

### Source Code Layout

```text
lib/
├── domain/
│   └── entities/
│       ├── championship_tournament.dart # Añadido atributo `venueIds: List<String>`
│       └── tournament_draft.dart        # Añadido atributo `venueIds: List<String>`
├── application/
│   ├── use_cases/
│   │   └── manage_venues_use_case.dart  # Incorporada validación de unicidad de nombre
│   └── controllers/
│       └── tournaments_controller.dart  # Parámetro `venueIds` en guardado de torneo
├── presentation/
│   ├── venues/
│   │   └── widgets/
│   │       └── create_venue_bottom_sheet.dart # Modal deslizable para alta rápida de sede
│   └── tournaments/
│       └── tournament_form_screen.dart        # Sección de Sedes Oficiales y selector
└── l10n/
    ├── app_en.arb                       # Claves de localización en inglés
    └── app_es.arb                       # Textos de usuario en español

test/
├── domain/
│   └── championship_tournament_venues_test.dart
├── application/
│   └── use_cases/
│       └── manage_venues_duplicate_validation_test.dart
└── presentation/
    ├── venues/
    │   └── create_venue_bottom_sheet_test.dart
    └── tournaments/
        └── tournament_form_screen_venues_test.dart
```

---

## Complexity Tracking

> **No violations**: El diseño no introduce complejidad injustificada ni viola los principios de la Constitución.
