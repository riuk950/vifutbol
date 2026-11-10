# Implementation Plan: Team Approval & Fixture Eligibility (HU 16.3)

**Branch**: `030-team-approval-fixture-eligibility` | **Date**: 2026-11-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/030-team-approval-fixture-eligibility/spec.md` (Notion HU 16.3)

## Summary

Implement official team approval and eligibility governance exclusively for tournament organizers (`UserRole.organizer`) with a strict minimum quota of 11 players. The system enables organizers to approve and revoke team eligibility from the "Equipos" tab of `CompetitionDetailScreen`, displays transparent roster progress counts (`X/11 jugadores - Incompleto` vs `X jugadores - Nómina válida`), automatically reverts status if a roster drops below 11 players, and strictly restricts fixture generation to tournaments with at least 2 officially eligible teams.

---

## Technical Context

**Language/Version**: Dart 3.5+ / Flutter 3.24+  
**Primary Dependencies**: Flutter, Flutter Riverpod (2.5+), Flutter Localizations  
**Storage**: In-memory domain repositories with reactive controller state, JSON serialization support  
**Testing**: `flutter_test`, component widget tests, mockito/fakes  
**Target Platform**: Android, iOS, Web, macOS ($320 \times 640\text{ px}$ responsive minimum)  
**Project Type**: Mobile Application (Clean Architecture + Riverpod)  
**Performance Goals**: State transitions and dialog interactions under 16ms (60 fps), instant reactive badge updates  
**Constraints**: Zero RenderFlex overflows at $320\text{ px}$ with 130% text scaling; Spanish UI (`app_es.arb`), English technical code  
**Scale/Scope**: 1 tournament screen (`CompetitionTeamsTabView`), 1 use case refactor (`ManageTeamsEligibilityUseCase`), 1 fixture generation update (`FixtureSchedulingUseCase`), 1 enum simplification (`TeamEligibilityStatus`)

---

## Constitution Check

*GATE: Evaluated against vifutbol Constitution v2.0.0*

- **I. La Spec Manda**: PASS. Complete specification in `spec.md`, clarified through `/speckit-clarify` across 5 sessions.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS. Referential integrity strictly verified: minimum 11 players required before transitioning to `eligible`; fixture requires $\ge 2$ eligible teams.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS. Comprehensive test plan covering domain invariants, application controllers, widget role gating, and responsive layout without overflows.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS. Core rules reside in `ManageTeamsEligibilityUseCase` and `FixtureSchedulingUseCase`; presentation layer observes Riverpod controllers.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS. Actions gated strictly on `RoleCapability.approveRegistrations` (`UserRole.organizer`); UI tokens strictly adhere to KickPulse design system.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS. Technical code in English; Spanish UI localized via `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil**: PASS. Edge cases covered (disputed match boundaries, unsaved state, scaled text layout, reactive demotion).

---

## Project Structure

### Documentation (this feature)

```text
specs/030-team-approval-fixture-eligibility/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Architecture decisions and clarifications
├── data-model.md        # Domain entities, lifecycle, and invariants
├── contracts/           # API and UI interface contracts
│   └── team-approval-api.md
├── quickstart.md        # Test suite and verification instructions
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
lib/
├── domain/
│   └── entities/
│       ├── team_enums.dart                              # TeamEligibilityStatus unification (pendingVerification, eligible)
│       └── tournament_team.dart                         # isEligible getter and retrocompatible fromJson
├── application/
│   ├── use_cases/
│   │   ├── manage_teams_eligibility_use_case.dart       # approveTeamEligibility (>=11 players), revokeTeamEligibility, auto-demotion
│   │   └── fixture_scheduling_use_case.dart             # eligible teams filter (>= 2 check)
│   └── controllers/
│       ├── teams_controller.dart                        # approveTeamEligibility, revokeTeamEligibility methods
│       └── matches_catalog_controller.dart              # propagates fixture generation with eligible teams
├── presentation/
│   └── tournaments/
│       └── widgets/
│           └── competition_teams_tab_view.dart          # Roster indicator (incomplete/valid) + Organizer action buttons (Approve/Revoke) + warning dialog
└── l10n/
    └── app_es.arb                                       # Spanish localized strings

test/
├── domain/
│   └── team_eligibility_status_test.dart
├── application/
│   └── use_cases/
│       ├── manage_teams_eligibility_approval_test.dart
│       └── fixture_scheduling_eligibility_filter_test.dart
└── presentation/
    └── tournaments/
        ├── competition_teams_tab_view_approval_test.dart
        ├── competition_teams_tab_view_role_visibility_test.dart
        └── competition_teams_tab_view_responsive_test.dart
```

---

## Complexity Tracking

> **Constitution Check: No violations. Standard architecture patterns followed.**
