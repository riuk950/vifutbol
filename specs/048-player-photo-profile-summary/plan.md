# Implementation Plan: Player Photo Capture, Profile Avatar, and Personal Data Summary Page

**Branch**: `048-player-photo-profile-summary` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/048-player-photo-profile-summary/spec.md)

**Input**: Feature specification from `/specs/048-player-photo-profile-summary/spec.md`

## Summary

Implement player profile photograph capture (camera/gallery with circular ID-card preview) inside `PlayerPersonalDataScreen`, extend offline-first storage and Supabase backend (`player-avatars` bucket, `photo_url` columns, and 27-parameter `complete_role_profile` RPC), render the player's real avatar reactively in `ProfileTabView` with updated completeness badge/button transitions, and deliver the dedicated `PlayerPersonalDataSummaryScreen` showing identity header with calculated age, demographics, tactical position chips, interactive dual-side ID card previews with zoom viewer, and an "Editar Datos" action.

## Technical Context

**Language/Version**: Dart 3.x / Flutter SDK (mobile app) + PostgreSQL / PL/pgSQL (Supabase backend)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `image_picker`, `path_provider`, `hive` / local persistence, `flutter_localizations` (`l10n`)  
**Storage**: Local device filesystem + Hive cache for offline-first state; Supabase Postgres (`vifutboldev` schema) + Supabase Storage (`player-avatars` public-read/owner-write bucket & `player-documents` private bucket)  
**Testing**: `flutter_test`, `mocktail`  
**Target Platform**: Android & iOS mobile devices  
**Project Type**: Mobile application (Flutter Clean Architecture + Supabase backend)  
**Performance Goals**: Circular preview renders immediately after picker returns; avatar renders smoothly at 60fps from local file or cached network image; images resized/compressed (`maxWidth: 1024`, `imageQuality: 85`) to stay well under 5 MB.  
**Constraints**: Offline-first resilience (local save works disconnected and syncs automatically when online); strict `player` role scoping; Spanish UI via `l10n` ARB files and English technical identifiers; adherence to `DESIGN.md` (`KickPulse*` tokens).  
**Scale/Scope**: Single player profile dossier, 1 new screen (`PlayerPersonalDataSummaryScreen`), 1 SQL migration (`202611170004_player_profile_avatar.sql`), updates to `PlayerPersonalDataScreen`, `ProfileTabView`, `UserAccount`, `RoleProfileData`, `DocumentStorageRepository`, and auth repositories.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda**: Spec `048-player-photo-profile-summary/spec.md` created, clarified (3 questions resolved), and validated against `MOBILE_GUIDELINES.md`. -> **PASS**
- **II. Integridad de Datos y Fuente de Verdad Transparente**: `photo_url` persisted atomically in `vifutboldev.players` and `vifutboldev.user_accounts` via `complete_role_profile` RPC, synced offline-first without duplicates. -> **PASS**
- **III. Pruebas Automatizadas como Puerta de Calidad**: Unit & widget tests planned for `UserAccount`/`RoleProfileData`, `ProfileTabView`, `PlayerPersonalDataScreen`, and `PlayerPersonalDataSummaryScreen`. -> **PASS**
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: Domain entities (`RoleProfileData`, `UserAccount`) and repository interfaces (`DocumentStorageRepository`, `AuthRepository`) remain independent of Flutter UI and Supabase SDK; infrastructure implements adapters. -> **PASS**
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: Feature scoped to `UserRole.player` and uses `KickPulseColors`, `KickPulseTypography`, `KickPulseCard`, `KickPulseBadge`, `KickPulseButton`. -> **PASS**
- **VI. Convenciones de Idioma y Nomenclatura**: All identifiers, files, tests, and comments in English; all UI strings centralized in `app_es.arb` / `app_en.arb` (`l10n`). -> **PASS**
- **VII. Resiliencia y Experiencia Móvil**: Covers camera/gallery permissions, offline local storage & deferred upload, fallback icons for missing/broken images, background lifecycle preservation, double-tap prevention, safe areas, and accessibility semantics. -> **PASS**

*Post-Design Re-Check*: All Phase 1 artifacts (`research.md`, `data-model.md`, `contracts/storage_and_rpc_contract.md`, `quickstart.md`) uphold all seven principles with zero violations.

## Project Structure

### Documentation (this feature)

```text
specs/048-player-photo-profile-summary/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── contracts/
    └── storage_and_rpc_contract.md
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611170004_player_profile_avatar.sql

lib/
├── domain/
│   ├── entities/
│   │   ├── role_profile_data.dart          # Add photoUrl field
│   │   └── user_account.dart               # Require photoUrl for player completeness
│   └── repositories/
│       └── document_storage_repository.dart # Add uploadPlayerAvatar & getSignedDocumentUrl
├── infrastructure/
│   ├── auth/
│   │   ├── local_auth_repository.dart      # Persist photoUrl offline
│   │   └── supabase_auth_repository.dart   # Pass p_photo_url (27th param) & sync
│   └── storage/
│       └── supabase_document_storage_repository.dart # Implement player-avatars upload & signed URLs
├── application/
│   └── controllers/
│       └── auth_controller.dart            # Ensure photoUrl preserved on profile updates
├── l10n/
│   ├── app_es.arb                          # Spanish strings for photo capture & summary screen
│   └── app_en.arb                          # English fallback strings
└── presentation/
    ├── navigation/
    │   └── app_router.dart                 # Register /profile/personal-data/summary route
    └── shell/tabs/
        ├── player_personal_data_screen.dart         # Add circular portrait capture & preview
        ├── player_personal_data_summary_screen.dart # New dedicated summary page + zoom viewer
        └── profile_tab_view.dart                    # Reactive avatar & contextual Datos Personales nav

test/
├── domain/entities/
│   └── user_account_test.dart
└── presentation/shell/tabs/
    ├── profile_tab_view_test.dart
    ├── player_personal_data_screen_test.dart
    └── player_personal_data_summary_screen_test.dart
```

**Structure Decision**: Clean Architecture layering inside `lib/` (`domain` -> `infrastructure` -> `application` -> `presentation`) paired with incremental SQL migration in `supabase/migrations/`, preserving existing `/profile/personal-data` form route and adding `/profile/personal-data/summary` for the dedicated summary screen.

## Complexity Tracking

> No Constitution Check violations. No complexity exceptions required.
