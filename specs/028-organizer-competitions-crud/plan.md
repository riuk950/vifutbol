# Implementation Plan: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador (HU 16.1)

**Branch**: `028-organizer-competitions-crud` | **Date**: 2026-11-10 | **Spec**: [specs/028-organizer-competitions-crud/spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/028-organizer-competitions-crud/spec.md)

**Input**: Feature specification from `/specs/028-organizer-competitions-crud/spec.md`

## Summary

Implement the complete CRUD and lifecycle management capabilities for tournaments in the Organizer Panel (`OrganizerPanelContent`). Organizers will have a dedicated section (`OrganizerCompetitionsSection`) listing exclusively their competitions, with responsive cards showing name, category, teams count, and status badges. The feature includes:
1. Fast filtering via `organizerTournamentsProvider` using `organizerId`.
2. Metadata editing dialog for name, category, format, rules, and scoring system without breaking existing matches or teams.
3. Unidirectional lifecycle state machine (`openRegistration` → `inProgress` → `finished`) with strict validations (minimum 2 teams and fixture generated to start).
4. Restricted deletion mechanism requiring destructive confirmation and blocking deletion if a tournament is active or has played matches.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`
**Storage**: `LocalStorageRepository` (`LocalTournamentsRepository` via JSON serialization)
**Testing**: `flutter_test`, `package:test`
**Target Platform**: Mobile (Android / iOS)
**Project Type**: Mobile Application (Clean Architecture + Riverpod)
**Performance Goals**: Instant reactivity (<100ms UI update upon CRUD action); zero jank during list rendering
**Constraints**: Fully offline-capable local persistence; 320x640 with 130% text scaling without RenderFlex overflow; 100% Spanish UI via `l10n`; 100% English technical codebase
**Scale/Scope**: 1 domain entity update (`ChampionshipTournament.organizerId`), 1 repository update, 1 provider extension, 1 new section widget, 3 new dialog widgets, 4 unit/widget test suites

## Constitution Check

*GATE: Evaluated before Phase 0 and re-checked after Phase 1 design.*

| Principle | Evaluation | Compliance Details |
|---|---|---|
| **I. La Spec Manda (Spec-Driven Development)** | PASS | All user stories, edge cases, and mobile guidelines have been documented in `spec.md` based on Notion HU 16.1. |
| **II. Integridad de Datos y Fuente de Verdad Transparente** | PASS | Unidirectional lifecycle prevents incoherent states; deletion safeguards prevent orphan match records or corrupted tournament history. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | Detailed unit tests for repository, use cases, and controller, along with widget tests for the competitions section and all dialogs. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | PASS | Clear separation: Domain entities & repository interfaces, application use cases/providers, presentation UI components. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | PASS | Filtered strictly to `UserRole.organizer`; UI adheres 100% to KickPulse tokens (`KickPulseColors`, `KickPulseTypography`, `KickPulseCard`, `KickPulseButton`, `KickPulseBadge`). |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | Technical codebase, methods, files, commits, and tests in English. User-facing strings 100% in Spanish in `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)** | PASS | Loading and empty states covered; defensive checks for back navigation and state transitions; responsive layout verified at 320x640 with 130% font scale. |

## Project Structure

### Documentation (this feature)

```text
specs/028-organizer-competitions-crud/
├── plan.md              # Implementation plan (this file)
├── spec.md              # Feature specification
├── research.md          # Technical decisions & entity analysis
├── data-model.md        # Domain entities, use cases & state machine
├── quickstart.md        # Verification and test instructions
└── contracts/
    └── ui-organizer-competitions-contracts.md # Widget keys, localization keys & signatures
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   └── championship_tournament.dart        # Add organizerId and copyWith/json mapping
│   └── repositories/
│       └── tournaments_repository.dart         # Add deleteTournament(String id)
├── infrastructure/
│   └── repositories/
│       └── local_tournaments_repository.dart   # Implement deleteTournament, update seeds
├── application/
│   ├── controllers/
│   │   └── tournaments_controller.dart         # Add updateTournament, transitionStatus, deleteTournament
│   └── providers/
│       └── tournaments_providers.dart          # Add organizerTournamentsProvider
├── presentation/
│   └── panel/
│       └── widgets/
│           ├── organizer_panel_content.dart        # Embed OrganizerCompetitionsSection
│           ├── organizer_competitions_section.dart # Dedicated competitions list & actions
│           ├── competition_edit_dialog.dart        # Modal dialog for metadata editing
│           ├── competition_lifecycle_dialog.dart   # Modal dialog for controlled status transitions
│           └── competition_delete_dialog.dart      # Destructive confirmation & blocking dialog
└── l10n/
    ├── app_en.arb
    └── app_es.arb                              # Add Spanish translations for all new UI strings

test/
├── domain/
│   └── championship_tournament_organizer_test.dart
├── infrastructure/
│   └── repositories/
│       └── local_tournaments_repository_crud_test.dart
├── application/
│   └── controllers/
│       └── tournaments_controller_crud_test.dart
└── presentation/
    └── panel/
        ├── organizer_competitions_section_test.dart
        ├── competition_edit_dialog_test.dart
        ├── competition_lifecycle_dialog_test.dart
        └── competition_delete_dialog_test.dart
```

**Structure Decision**: Standard Clean Architecture layout used throughout `vifutbol`. Domain entities remain pure, repository interfaces dictate storage contracts, application providers isolate state, and presentation widgets compose KickPulse components.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | N/A | Fully complies with Constitution v2.0.0 and existing design guidelines |
