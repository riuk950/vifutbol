# Implementation Plan: Coach Team & Roster Governance

**Branch**: `029-coach-team-roster-governance` | **Date**: 2026-11-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/029-coach-team-roster-governance/spec.md` (Notion HU 16.2: Gobernanza de Equipos: Creación y Gestión de Plantilla Exclusiva para Entrenadores).

## Summary

Restrict the creation of teams and management of player rosters exclusively to users authenticated as club coaches (`UserRole.coach`). Hide all team/player creation actions in UI for non-coach roles (`organizer`, `referee`, `player`, `fan`), enforce domain-level authorization in `ManageTeamsEligibilityUseCase`, add `coachId` to `TournamentTeam` with backward compatibility, and implement an empty state with direct registration in `CoachPanelContent`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Flutter Riverpod, KickPulse Theme (design tokens & widgets)
**Storage**: Local persistent storage (`LocalStorageRepository` / in-memory fallback)
**Testing**: `flutter_test`, mocktail
**Target Platform**: Android / iOS / Responsive Web (tested at $320 \times 640\text{ px}$ with 130% text scale)
**Project Type**: Mobile Application
**Performance Goals**: UI interactions respond in < 16ms (60 fps), no UI jank or unhandled async exceptions
**Constraints**: Zero RenderFlex overflows, strict separation between English code/identifiers and Spanish UI strings (`l10n`), Clean Architecture layers
**Scale/Scope**: 5 system roles, directories for Teams and Players, Coach Panel, Competition Detail Screen

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status | Notes |
|---|---|:---:|---|
| **I. La Spec Manda** | Spec, research, data model, contracts defined before code | ✅ PASS | All design artifacts complete in `specs/029-coach-team-roster-governance/`. |
| **II. Integridad de Datos** | Referential integrity between `TournamentTeam`, `coachId`, and rosters | ✅ PASS | `coachId` explicitly links teams to coaches with fallback. |
| **III. Pruebas Automatizadas** | Comprehensive unit, domain, and widget test gates | ✅ PASS | Full test strategy outlined in `quickstart.md`. |
| **IV. Arquitectura Limpia** | Domain rules decoupled from UI and infrastructure | ✅ PASS | Validation in `ManageTeamsEligibilityUseCase` independent of presentation. |
| **V. Segregación de Roles** | Strict RBAC adhering to five roles and design tokens | ✅ PASS | `RolePermissionMatrix` updated; UI actions hidden for non-coaches. |
| **VI. Convenciones de Idioma** | English technical code, Spanish UI strings via `l10n` | ✅ PASS | All code/tests in English, strings in `app_es.arb`. |
| **VII. Resiliencia Móvil** | Mobile guidelines evaluated (empty states, touch targets, overflow) | ✅ PASS | Handled empty states, touch targets $\ge 44\text{px}$, responsive layout. |

## Project Structure

### Documentation (this feature)

```text
specs/029-coach-team-roster-governance/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── ui-coach-team-governance-contracts.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── tournament_team.dart                 # Add coachId and optional tournamentId
│   │   └── role_permission_matrix.dart          # Restrict manageTeamRoster strictly to coach
│   └── failures/
│       └── app_failure.dart                     # Ensure UnauthorizedRoleFailure
├── application/
│   ├── use_cases/
│   │   └── manage_teams_eligibility_use_case.dart # Restrict team & player registration to coach
│   ├── controllers/
│   │   └── teams_controller.dart                # Add createTeam helper & coachId assignment
│   └── providers/
│       └── teams_providers.dart                 # Add coachTeamsProvider
├── presentation/
│   ├── directories/
│   │   ├── teams_directory_screen.dart          # Condition button on coach role, open CreateTeamDialog
│   │   └── players_directory_screen.dart        # Condition button on coach role
│   ├── tournaments/
│   │   ├── competition_detail_screen.dart       # Simplify FAB to direct Generate Fixture button
│   │   └── widgets/
│   │       └── tournament_teams_section.dart    # Hide register team button if not coach
│   └── panel/
│       └── widgets/
│           ├── coach_panel_content.dart         # Empty state card (coach_no_team_card)
│           └── create_team_dialog.dart          # Modal dialog for coach team creation
└── l10n/
    ├── app_es.arb
    ├── app_localizations.dart
    └── app_localizations_es.dart
```

## Complexity Tracking

> No constitution violations detected. Standard Clean Architecture and Riverpod patterns utilized.
