# Implementation Plan: Persistencia de Roles, Perfiles Extensibles en Nube y Validación de Datos Incompletos

**Branch**: `042-role-profile-persistence-validation` | **Date**: 2026-11-13 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/042-role-profile-persistence-validation/spec.md)  
**Input**: Feature specification from `/specs/042-role-profile-persistence-validation/spec.md`

## Summary

Guarantee atomic cloud persistence of user roles (`organizer`, `coach`, `referee`, `player`, `fan`) and extensible role-specific profiles in Supabase DEV (`vifutboldev`), reuse and link existing `players` and `match_referees` records by `document_id` without duplication, create dedicated RLS-protected satellite tables (`coach_profiles`, `organizer_profiles`, `fan_profiles`), and surface an `"Datos incompletos"` amber badge/banner in `ProfileTabView` paired with an adaptive `CompleteProfileDialog` modal.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter SDK, PostgreSQL 15+ (Supabase `vifutboldev` schema)  
**Primary Dependencies**: `flutter_riverpod ^2.6.1`, `supabase_flutter ^2.18.3`, `hive ^2.2.3`, `connectivity_plus ^6.1.4`, `flutter_localizations` + `intl`  
**Storage**: Supabase PostgreSQL (`vifutboldev` schema via PostgREST + RPC) + Hive local session cache (`LocalStorageRepository`)  
**Testing**: `flutter_test` + `mocktail ^1.0.4`  
**Target Platform**: Android & iOS mobile app (Flutter) + Supabase Cloud Backend  
**Project Type**: Mobile application + Supabase SQL migrations/RPC  
**Performance Goals**: Instantaneous profile completeness evaluation from cached `UserAccount` (<16ms UI frame); atomic RPC roundtrip <500ms on standard mobile network  
**Constraints**: Online connectivity required for `CompleteProfileDialog` submission (`document_id` conflict verification); Spanish UI via `AppLocalizations` (`lib/l10n/app_es.arb`); English technical identifiers/comments  
**Scale/Scope**: 5 user roles, 1 new SQL migration (`202611130001_role_profiles_and_player_referee_linking.sql`), domain/application/infrastructure auth updates, 2 presentation components (`ProfileTabView`, `CompleteProfileDialog`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

1. **I. Spec-Driven Development**: PASS — `spec.md` created and clarified (3 high-impact ambiguities resolved, 16/16 quality checklist items passing).
2. **II. Data Integrity & Offline-First**: PASS — Atomic PostgreSQL RPC prevents orphaned accounts or duplicate `players`/`match_referees`; `CompleteProfileDialog` enforces online check and preserves inputs on offline/error without false positives.
3. **III. Automated Testing Discipline**: PASS — Unit tests planned for `UserAccount` completeness, `SupabaseAuthRepository` RPC/error mapping, and widget tests for `ProfileTabView` and `CompleteProfileDialog`.
4. **IV. Clean Architecture & Modularity**: PASS — Domain (`UserAccount`, `RoleProfileData`, `AuthRepository`, `AppFailure`), Application (`AuthController`), Infrastructure (`SupabaseAuthRepository`, `LocalAuthRepository`), Presentation (`ProfileTabView`, `CompleteProfileDialog`).
5. **V. Role-Based Security & Design System**: PASS — RLS policies strictly scope `coach_profiles`, `organizer_profiles`, `fan_profiles` to `(select auth.uid()) = user_account_id`; atomic `SECURITY DEFINER` RPC verifies `auth.uid()` and prevents overwriting claimed documents; UI uses `KickPulseColors`, `KickPulseBadge`, `KickPulseButton`, `KickPulseCard`.
6. **VI. Multilingual Discipline**: PASS — Technical code/comments in English; all UI strings localized in `lib/l10n/app_es.arb` (`AppLocalizations`).
7. **VII. Mobile Resilience**: PASS — Loading, error, offline, and empty/incomplete states explicitly handled; form preserves user input on network/conflict errors.

*Post-Phase 1 Re-Check*: PASS — `data-model.md`, `contracts/profile_persistence_contract.md`, and `quickstart.md` adhere to all 7 principles without exceptions.

## Project Structure

### Documentation (this feature)

```text
specs/042-role-profile-persistence-validation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── profile_persistence_contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611130001_role_profiles_and_player_referee_linking.sql

lib/
├── domain/
│   ├── entities/
│   │   ├── role_profile_data.dart          # New value object for role-specific attributes
│   │   └── user_account.dart               # Extended with phone, documentId, roleProfile & completeness
│   ├── failures/
│   │   └── app_failure.dart                # DocumentAlreadyLinkedFailure
│   └── repositories/
│       └── auth_repository.dart            # updateRoleProfile method
├── application/
│   └── controllers/
│       └── auth_controller.dart            # updateRoleProfile state mutation
├── infrastructure/
│   └── auth/
│       ├── local_auth_repository.dart      # Local implementation for updateRoleProfile
│       └── supabase_auth_repository.dart   # Atomic RPC integration & profile hydration
├── l10n/
│   └── app_es.arb                          # Localized Spanish labels/errors for incomplete profile & modal
└── presentation/
    └── shell/
        └── tabs/
            ├── profile_tab_view.dart       # Incomplete/Complete badge + banner CTA
            └── complete_profile_dialog.dart # Adaptive modal form per activeRole

test/
├── domain/entities/user_account_test.dart
├── infrastructure/auth/supabase_auth_repository_test.dart
└── presentation/shell/
    ├── profile_tab_view_test.dart
    └── complete_profile_dialog_test.dart
```

**Structure Decision**: Existing Clean Architecture Flutter layout (`domain` / `application` / `infrastructure` / `presentation`) + `supabase/migrations/` for `vifutboldev` DDL, RLS, and RPC.

## Complexity Tracking

No constitution violations or architectural exceptions required.
