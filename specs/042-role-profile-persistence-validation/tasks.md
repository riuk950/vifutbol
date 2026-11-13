# Tasks: Persistencia de Roles, Perfiles Extensibles en Nube y Validación de Datos Incompletos

**Input**: Design documents from `/specs/042-role-profile-persistence-validation/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/profile_persistence_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III and HU 19.4 Definition of Done (unit tests for domain & repository + widget tests for `ProfileTabView` & `CompleteProfileDialog`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization keys and shared failure/entity scaffolding required across all user stories

- [X] T001 Add Spanish localization keys for incomplete/complete profile badges, banner CTA, adaptive form labels, validation messages, offline guard, and document conflict error in `lib/l10n/app_es.arb`
- [X] T002 [P] Add `DocumentAlreadyLinkedFailure` to `lib/domain/failures/app_failure.dart`
- [X] T003 [P] Create `RoleProfileData` value object (`clubName`, `licenseLevel`, `organizationName`, `baseCity`, `city`, `preferences`, `certificationLevel`, `linkedPlayerId`, `linkedRefereeId`, `toJson`, `fromJson`, `copyWith`) in `lib/domain/entities/role_profile_data.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema migration, atomic RPC, domain model extensions, and repository contract that block all user stories

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete

- [X] T004 Create idempotent SQL migration `supabase/migrations/202611130001_role_profiles_and_player_referee_linking.sql` extending `vifutboldev.user_accounts` (`phone`, `document_id`, `normalized_document_id`), altering `vifutboldev.players` (nullable `tournament_team_id`, `tournament_id`, `shirt_number`, `position`, adding `phone`, partial unique indexes `ux_players_user_account_id` and `ux_players_free_agent_doc`), extending `vifutboldev.match_referees` (`document_id`, `normalized_document_id`, `phone`, partial unique indexes `ux_match_referees_user_account_id` and `ux_match_referees_normalized_doc`), creating `vifutboldev.coach_profiles`, `vifutboldev.organizer_profiles`, and `vifutboldev.fan_profiles` with RLS policies (`(SELECT auth.uid()) = user_account_id`), and defining atomic `SECURITY DEFINER` RPC `vifutboldev.complete_role_profile(...)`
- [X] T005 Extend `UserAccount` with `phone`, `documentId`, `roleProfile`, backward-compatible JSON serialization, and `isProfileCompleteForActiveRole` getter (excluding `isGuestFan`, requiring `phone`+`documentId`+role fields for `player`/`referee`/`coach`/`organizer`, and `phone`+`city` without `documentId` for `fan`) in `lib/domain/entities/user_account.dart`
- [X] T006 Add `updateRoleProfile` method signature to `AuthRepository` in `lib/domain/repositories/auth_repository.dart`
- [X] T007 Add `updateRoleProfile` implementation to `LocalAuthRepository` in `lib/infrastructure/auth/local_auth_repository.dart`

**Checkpoint**: Foundation ready — user story implementation and testing can now proceed

---

## Phase 3: User Story 1 - Registro Atómico de Rol y Vinculación Sin Duplicidad (Priority: P1) 🎯 MVP

**Goal**: Guarantee atomic cloud persistence of account roles (`active_role`, `authorized_roles`) and non-duplicating `document_id` linking for `player` and `referee` via `vifutboldev.complete_role_profile`.

**Independent Test**: Verify `SupabaseAuthRepository.completeRoleOnboarding` and `updateRoleProfile` call the atomic RPC, map returned `UserAccount` + `RoleProfileData`, map `DOCUMENT_ALREADY_LINKED` to `DocumentAlreadyLinkedFailure`, and pass all unit tests.

### Tests for User Story 1

- [X] T008 [P] [US1] Write unit tests for `UserAccount.isProfileCompleteForActiveRole`, `RoleProfileData` serialization, and role-based completeness rules across all 5 roles + guest fan in `test/domain/entities/user_account_test.dart`
- [X] T009 [P] [US1] Write/extend unit tests for `SupabaseAuthRepository` covering atomic `completeRoleOnboarding`, `updateRoleProfile` RPC payload/response mapping, `DocumentAlreadyLinkedFailure` translation, and offline `NetworkFailure` guard in `test/infrastructure/auth/supabase_auth_repository_test.dart`

### Implementation for User Story 1

- [X] T010 [US1] Extend `SupabaseUserProfileDataSource` and `_PostgrestUserProfileDataSource` with `completeRoleProfile(...)` RPC call and `fetchRoleProfileDetails(...)` in `lib/infrastructure/auth/supabase_auth_repository.dart`
- [X] T011 [US1] Update `SupabaseAuthRepository.completeRoleOnboarding`, `registerAccount`, `signIn`, `mapRowToUserAccount`, error translation (`DOCUMENT_ALREADY_LINKED` -> `DocumentAlreadyLinkedFailure`), and implement `SupabaseAuthRepository.updateRoleProfile` in `lib/infrastructure/auth/supabase_auth_repository.dart`
- [X] T012 [US1] Add `updateRoleProfile` method to `AuthController` updating `authControllerProvider` session state and surfacing failures in `lib/application/controllers/auth_controller.dart`

**Checkpoint**: User Story 1 is independently testable via `flutter test test/domain/entities/user_account_test.dart test/infrastructure/auth/supabase_auth_repository_test.dart`

---

## Phase 4: User Story 2 - Detección Visual y Completado Adaptativo de Perfil Incompleto (Priority: P1)

**Goal**: Show amber `"Datos incompletos"` badge and `"Completar mi perfil"` banner in `ProfileTabView` for authenticated users missing required fields, and provide an adaptive `CompleteProfileDialog` that syncs online and immediately transitions the badge to green `"Perfil completo"`.

**Independent Test**: Render `ProfileTabView` and `CompleteProfileDialog` in widget tests across incomplete, complete, guest, offline, and conflict states and verify badge transitions and form validation.

### Tests for User Story 2

- [X] T013 [P] [US2] Write widget tests verifying `"Datos incompletos"` amber badge + `"Completar mi perfil"` banner when incomplete, `"Perfil completo"` green badge when complete, and banner/badge exclusion for guest fans in `test/presentation/shell/profile_tab_view_test.dart`
- [X] T014 [P] [US2] Write widget tests for `CompleteProfileDialog` verifying adaptive fields per active role (`player`, `referee`, `coach`, `organizer`, `fan`), inline validation, offline/conflict error preservation without closing, and immediate badge update on save in `test/presentation/shell/complete_profile_dialog_test.dart`

### Implementation for User Story 2

- [X] T015 [US2] Create adaptive `CompleteProfileDialog` supporting role-specific fields, pre-filled initial values, Spanish inline validation, loading state, and error preservation on offline/conflict failures in `lib/presentation/shell/tabs/complete_profile_dialog.dart`
- [X] T016 [US2] Update `ProfileTabView` to display amber `"Datos incompletos"` / green `"Perfil completo"` `KickPulseBadge`, conditional warning banner with `"Completar mi perfil"` CTA (hidden for `isGuestFan` and complete profiles), and launch `CompleteProfileDialog` in `lib/presentation/shell/tabs/profile_tab_view.dart`

**Checkpoint**: User Stories 1 and 2 work end-to-end and pass widget + unit tests independently

---

## Phase 5: User Story 3 - Fichas Satélite Dedicadas para Directivos y Aficionados (Priority: P2)

**Goal**: Ensure `coach` (`club_name`, `license_level`), `organizer` (`organization_name`, `base_city`), and `fan` (`city`, `preferences`) satellite profiles are hydrated on login/session restore and recalculated accurately when switching active roles in `ProfileTabView`.

**Independent Test**: Hydrate a multi-role user session, switch active role in `ProfileTabView`, and verify satellite profile fields pre-populate `CompleteProfileDialog` and update `isProfileCompleteForActiveRole`.

### Tests for User Story 3

- [X] T017 [P] [US3] Add unit/widget tests verifying satellite profile hydration (`coach_profiles`, `organizer_profiles`, `fan_profiles`) and dynamic completeness re-evaluation on active role switch in `test/infrastructure/auth/supabase_auth_repository_test.dart` and `test/presentation/shell/profile_tab_view_test.dart`

### Implementation for User Story 3

- [X] T018 [US3] Ensure `_ensureProfileForUser` and `switchActiveRole` in `SupabaseAuthRepository` fetch and merge satellite profile attributes (`coach_profiles`, `organizer_profiles`, `fan_profiles`) into `UserAccount.roleProfile` and persist them in local cache in `lib/infrastructure/auth/supabase_auth_repository.dart`

**Checkpoint**: All three user stories are complete and independently verified

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Code generation, static analysis, full test suite verification, and quickstart validation

- [X] T019 Regenerate localization files (`flutter gen-l10n`) and verify generated `lib/l10n/app_localizations*.dart`
- [X] T020 Run `flutter analyze` and resolve any lint/analyzer warnings across modified files
- [X] T021 Run all feature unit and widget tests (`flutter test test/domain/entities/user_account_test.dart test/infrastructure/auth/supabase_auth_repository_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/shell/complete_profile_dialog_test.dart`) and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — `T001`, `T002`, `T003` can run in parallel.
- **Foundational (Phase 2)**: Depends on `T002` and `T003`; `T004`–`T007` must finish before User Stories 1–3.
- **User Story 1 (Phase 3 — P1 MVP)**: Depends on Phase 2.
- **User Story 2 (Phase 4 — P1)**: Depends on Phase 2 and `T012` (`AuthController.updateRoleProfile`).
- **User Story 3 (Phase 5 — P2)**: Depends on Phase 3 & Phase 4.
- **Polish (Phase 6)**: Depends on Phases 1–5.

### Parallel Opportunities

- `T001`, `T002`, `T003` can run in parallel.
- `T008` and `T009` can run in parallel.
- `T013` and `T014` can run in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1 (Setup) + Phase 2 (Foundational SQL migration + `UserAccount` + `AuthRepository`).
2. Complete Phase 3 (US1: Atomic RPC persistence + `player`/`referee` document linking).
3. Complete Phase 4 (US2: `"Datos incompletos"` badge/banner + `CompleteProfileDialog`).
4. Complete Phase 5 (US3: Satellite hydration & role-switch completeness) + Phase 6 (Polish & tests).
