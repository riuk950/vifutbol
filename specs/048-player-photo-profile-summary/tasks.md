# Tasks: Player Photo Capture, Profile Avatar, and Personal Data Summary Page

**Input**: Design documents from `/specs/048-player-photo-profile-summary/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/storage_and_rpc_contract.md, quickstart.md

**Tests**: Automated unit and widget tests are included per project Constitution (Principle III: Automated Tests as Quality Gate) and `spec.md` (`SC-005`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Localization & Shared Strings)

**Purpose**: Prepare centralized Spanish/English localization keys for photo capture, profile completeness transitions, and the personal data summary screen.

- [x] T001 [P] Add Spanish `l10n` keys for profile photo capture ("Tomar Foto de Perfil", camera/gallery options, permission message) and summary screen sections ("Datos Personales", "Editar Datos", age format, demographics, tactical profile, documentation, zoom close) in lib/l10n/app_es.arb
- [x] T002 [P] Add matching English fallback `l10n` keys in lib/l10n/app_en.arb
- [x] T003 Regenerate localization classes via `flutter gen-l10n` verifying zero ARB syntax errors in lib/l10n/

---

## Phase 2: Foundational (Database, Domain & Offline-First Storage)

**Purpose**: Core database migration, domain entity extensions, storage adapters, and auth repository updates that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Create SQL migration adding `photo_url` to `vifutboldev.players` and `vifutboldev.user_accounts`, creating `player-avatars` bucket (`public = true`, `file_size_limit = 5242880`, MIME `image/jpeg,image/png,image/webp`) with owner-scoped write RLS and public read RLS, and updating `vifutboldev.complete_role_profile` to 27 parameters in supabase/migrations/202611170004_player_profile_avatar.sql
- [x] T005 [P] Add `photoUrl` (`String?`) to `RoleProfileData` (including `copyWith`, `toJson`, `fromJson` reading `photoUrl`/`photo_url`, `==`, `hashCode`) in lib/domain/entities/role_profile_data.dart
- [x] T006 [P] Update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.player` to require `_hasText(roleProfile?.photoUrl)` alongside existing mandatory fields (photo optional on form save, required for "Perfil completo") in lib/domain/entities/user_account.dart
- [x] T007 [P] Extend `DocumentStorageRepository` interface with `uploadPlayerAvatar({required String userId, required String localPath, String? existingPhotoUrl})` and `getSignedDocumentUrl({required String storagePath, int expiresInSeconds = 300})` in lib/domain/repositories/document_storage_repository.dart
- [x] T008 Implement `uploadPlayerAvatar` (bucket `player-avatars`, path `$userId/avatar.jpg`, `upsert: true`, public URL return) and `getSignedDocumentUrl` (`player-documents` signed URL) in `SupabaseDocumentStorageRepository` and `LocalDocumentStorageRepository` in lib/infrastructure/storage/supabase_document_storage_repository.dart (depends on T007)
- [x] T009 [P] Update `SupabaseAuthRepository` to pass `p_photo_url` to the 27-parameter `vifutboldev.complete_role_profile` RPC and map `photo_url` in responses in lib/infrastructure/auth/supabase_auth_repository.dart (depends on T004, T005)
- [x] T010 [P] Update `LocalAuthRepository` to persist and restore `photoUrl` offline inside `RoleProfileData` in lib/infrastructure/auth/local_auth_repository.dart (depends on T005)
- [x] T011 [P] Add unit tests verifying `UserAccount.isProfileCompleteForActiveRole` requires `photoUrl` for `UserRole.player` and `RoleProfileData` serialization of `photoUrl` in test/domain/entities/user_account_test.dart (depends on T005, T006)

**Checkpoint**: Foundation ready — database schema, domain completeness rules, and offline-first storage adapters are in place.

---

## Phase 3: User Story 1 - Capture Player Profile Photograph in Personal Data Form (Priority: P1) 🎯 MVP

**Goal**: Allow players to capture/select a profile photograph inside `PlayerPersonalDataScreen`, preview it in a circular carnet frame, and persist it offline-first alongside personal data (without blocking form submission if photo is omitted).

**Independent Test**: Open `PlayerPersonalDataScreen`, tap *"Tomar Foto de Perfil"*, select camera/gallery, verify circular preview renders, save the form both with and without a photo, and verify persistence via `authControllerProvider` and `DocumentStorageRepository`.

### Tests for User Story 1

- [x] T012 [P] [US1] Add widget tests for circular profile photo preview, *"Tomar Foto de Perfil"* picker modal, permission error handling, and optional-photo form submission in test/presentation/shell/player_personal_data_screen_test.dart
 
### Implementation for User Story 1

- [x] T013 [US1] Add circular carnet profile avatar preview widget and *"Tomar Foto de Perfil"* action button with camera/gallery bottom sheet (`image_picker` with `maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85`), local persistence copy, and permission error SnackBar in lib/presentation/shell/tabs/player_personal_data_screen.dart
- [x] T014 [US1] Integrate `uploadPlayerAvatar` (online) and local `photoUrl` fallback (offline) into `_handleSave` in lib/presentation/shell/tabs/player_personal_data_screen.dart (depends on T008, T009, T010, T013)

**Checkpoint**: User Story 1 is functional and independently testable — players can capture/preview/save their profile photo inside the personal data form.

---

## Phase 4: User Story 2 - Reactive Avatar and Profile Completeness Action in Profile Tab (Priority: P1)

**Goal**: Render the player's real profile photograph reactively in `ProfileTabView`'s identity card avatar, update the completeness badge (*"Datos incompletos"* ↔ *"Perfil completo"*), and route *"Datos Personales"* to the summary screen when complete (or *"Completar Datos Personales"* to the form when incomplete).

**Independent Test**: Render `ProfileTabView` for a `player` with incomplete vs. complete profile (with local file path, remote URL, and broken URL), verify avatar rendering, badge label, and tap navigation target.

### Tests for User Story 2

- [x] T015 [P] [US2] Update/add widget tests in test/presentation/shell/tabs/profile_tab_view_test.dart verifying reactive avatar rendering (local file, network URL, error fallback icon), *"Perfil completo"* vs *"Datos incompletos"* badge, and contextual navigation to `/profile/personal-data` vs `/profile/personal-data/summary`

### Implementation for User Story 2

- [x] T016 [US2] Update `ProfileTabView` identity card `CircleAvatar` to render the player's `photoUrl` reactively (`FileImage` for local paths, `NetworkImage` for HTTP(S) URLs, graceful `onBackgroundImageError` fallback to role icon) in lib/presentation/shell/tabs/profile_tab_view.dart
- [x] T017 [US2] Update `ProfileTabView` player personal data tile/button to show *"Datos Personales"* navigating to `/profile/personal-data/summary` when `user.isProfileCompleteForActiveRole` is true, and *"Completar Datos Personales"* navigating to `/profile/personal-data` when incomplete in lib/presentation/shell/tabs/profile_tab_view.dart

**Checkpoint**: User Stories 1 and 2 work together end-to-end — saving a photo updates `ProfileTabView` reactively and enables direct access to the summary page.

---

## Phase 5: User Story 3 - Dedicated Personal Data Summary Page & Edit Flow (Priority: P2)

**Goal**: Deliver `PlayerPersonalDataSummaryScreen` showing the player's complete dossier (header with photo, name, document, calculated age; demographics; tactical position chips; front/back ID card previews with interactive zoom viewer) and an *"Editar Datos"* action in the AppBar.

**Independent Test**: Navigate to `/profile/personal-data/summary` with a populated `UserAccount`, verify calculated age, demographic fields, position chips, front/back ID thumbnails, tapping a thumbnail to open the enlarged zoom viewer, and tapping *"Editar Datos"* to navigate to `/profile/personal-data`.

### Tests for User Story 3

- [x] T018 [P] [US3] Create widget tests covering all 4 sections (header + age calculation, demographics, position chips, front/back ID previews + interactive zoom dialog) and *"Editar Datos"* navigation in test/presentation/shell/tabs/player_personal_data_summary_screen_test.dart

### Implementation for User Story 3

- [x] T019 [US3] Create `PlayerPersonalDataSummaryScreen` with AppBar *"Editar Datos"* action, identity header (avatar, full name, document ID, deterministic age calculation), demographics card, tactical position chips card, and dual-side ID documentation card with `InteractiveViewer` enlarged modal viewer in lib/presentation/shell/tabs/player_personal_data_summary_screen.dart
- [x] T020 [US3] Register route `/profile/personal-data/summary` pointing to `PlayerPersonalDataSummaryScreen` in lib/presentation/navigation/app_router.dart (depends on T019)

**Checkpoint**: All user stories (US1, US2, US3) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, full test suite verification, accessibility/overflow checks, and database migration validation.

- [x] T021 Run `flutter analyze` and resolve any warnings or lint issues across all modified and new files
- [x] T022 Run full `flutter test` suite and verify 100% pass rate with zero regressions
- [x] T023 Validate `specs/048-player-photo-profile-summary/quickstart.md` scenarios and confirm `202611170004_player_profile_avatar.sql` is ready for cloud database deployment

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (`T001`, `T002` in parallel → `T003`).
- **Foundational (Phase 2)**: Depends on Setup (`T003`) — BLOCKS all user stories (`T004`–`T011`).
- **User Story 1 (Phase 3)**: Depends on Phase 2 (`T008`, `T009`, `T010`).
- **User Story 2 (Phase 4)**: Depends on Phase 2 (`T005`, `T006`). Can run in parallel with US1 if desired, or right after US1.
- **User Story 3 (Phase 5)**: Depends on Phase 2 (`T005`, `T008`). Can run in parallel with US1/US2.
- **Polish (Phase 6)**: Depends on Phases 3, 4, and 5 completion.

### Parallel Opportunities

- Phase 1: `T001` and `T002` in parallel.
- Phase 2: `T005`, `T006`, `T007` in parallel; after `T004`/`T005`, `T009`, `T010`, `T011` in parallel.
- Phase 3–5: Widget test files (`T012`, `T015`, `T018`) can be authored in parallel with or prior to their corresponding screen implementations.
