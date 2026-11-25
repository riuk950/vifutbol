# Tasks: Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen

**Input**: Design documents from `/specs/058-referee-avatar-profile-summary/`

**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/referee_avatar_summary_contract.md`, `quickstart.md`

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and HU 25.2 checklist.

**Organization**: Tasks are grouped by user story (`US1`–`US4`) so each increment can be implemented and tested independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (`US1`, `US2`, `US3`, `US4`)
- Exact repository-relative file paths included in every task description

---

## Phase 1: Setup (Localization & Database Migration)

**Purpose**: Prepare Spanish localization strings and idempotent SQL migration for `match_referees.photo_url`.

- [X] T001 Add the 15 Spanish localization keys defined in `contracts/referee_avatar_summary_contract.md` (`refereeAvatarSectionTitle`, `refereeAvatarSectionSubtitle`, `refereeAvatarCameraButton`, `refereeAvatarGalleryButton`, `refereeAvatarChangeButton`, `refereeAvatarPermissionDeniedError`, `refereeAvatarGalleryPermissionDeniedError`, `refereeAvatarLoadError`, `refereePersonalDataSummaryTitle`, `refereePersonalDataSummarySubtitle`, `refereeSummaryCertificationTitle`, `refereeSummaryCertificationSubtitle`, `refereeSummaryPhoneLabel`, `refereeSummaryCertificationDocLabel`, `refereeSummaryDocLoadFallback`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate Flutter localization delegates via `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)
- [X] T003 [P] Create idempotent SQL migration `supabase/migrations/202611250003_referee_avatar_photo_url.sql` adding `photo_url text` to `vifutboldev.match_referees`, updating `vifutboldev.complete_role_profile` referee `UPDATE`/`INSERT` branches to persist `photo_url`, updating `vifutboldev.delete_my_account()` to clear `photo_url = NULL` on `match_referees`, and executing `NOTIFY pgrst, 'reload schema'`

---

## Phase 2: Foundational (Repository Photo Persistence Check)

**Purpose**: Ensure auth repositories consistently pass and hydrate `photoUrl` for `UserRole.referee` across cloud and local adapters.

- [X] T004 Verify and ensure `completeRoleProfile` and session/profile hydration preserve `photoUrl` for `UserRole.referee` without requiring `photoUrl` in `isProfileCompleteForActiveRole` in `lib/infrastructure/auth/supabase_auth_repository.dart` and `lib/infrastructure/auth/local_auth_repository.dart`

**Checkpoint**: Localization, database migration, and auth repository photo persistence are ready; user story work can begin.

---

## Phase 3: User Story 1 - Captura y actualización de fotografía de avatar del árbitro (Priority: P1) 🎯 MVP

**Goal**: Allow referees to capture/select a profile avatar from camera or gallery in `RefereePersonalDataScreen`, see a live circular preview, replace it before saving, upload it to `player-avatars` with cache-buster, and persist it atomically.

**Independent Test**: Open `RefereePersonalDataScreen`, pick an avatar from camera or gallery, verify the circular preview and replacement, tap save, and verify `uploadPlayerAvatar` + `completeRoleProfile(..., photoUrl: ...)` are invoked with single-flight protection and offline form preservation.

### Implementation for User Story 1

- [X] T005 [US1] Add circular avatar capture section (`ValueKey('referee_form_profile_avatar')`, `ValueKey('referee_avatar_camera_button')`, `ValueKey('referee_avatar_gallery_button')`) with Spanish `Semantics` labels, `ImagePicker` (`maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85`) with optional `avatarPickerOverride` callback for tests, live `FileImage`/`NetworkImage` circular preview, replace flow, and `_isDirty = true` state tracking in `lib/presentation/shell/tabs/referee_personal_data_screen.dart`
- [X] T006 [US1] Integrate `DocumentStorageRepository.uploadPlayerAvatar` into `_handleSave` (single-flight lock, preserving `_localAvatarPath` and form inputs on `OfflineAuthOperationFailure`) and pass the resolved `photoUrl` to `AuthController.completeRoleProfile` in `lib/presentation/shell/tabs/referee_personal_data_screen.dart` (depends on T005)

### Tests for User Story 1

- [X] T007 [P] [US1] Add widget tests for camera/gallery avatar selection, live circular preview, replacement before save, unsaved-changes dirty confirmation, single-flight guard, and offline error preservation in `test/presentation/shell/referee_personal_data_screen_test.dart` (depends on T006)

**Checkpoint**: User Story 1 is independently functional and tested.

---

## Phase 4: User Story 2 - Visualización reactiva del avatar y estado en la pestaña Perfil (Priority: P1)

**Goal**: Display the referee's real avatar reactively in `ProfileTabView` along with `Perfil completo`, with clean visual fallback when absent, and route the referee personal data tile conditionally to summary vs form.

**Independent Test**: Render `ProfileTabView` for a referee with and without `photoUrl` and with complete vs incomplete profile; verify `profile_identity_avatar`, `profile_completeness_badge`, and conditional navigation on `profile_referee_personal_data_tile`.

### Implementation for User Story 2

- [X] T008 [US2] Update `Key('profile_referee_personal_data_tile')` in `lib/presentation/shell/tabs/profile_tab_view.dart` to show `l10n.refereePersonalDataSummarySubtitle` and navigate to `/profile/referee-personal-data/summary` when `user?.isProfileCompleteForActiveRole == true`, and to `/profile/referee-personal-data` with `l10n.refereePersonalDataSubtitle` when incomplete, verifying `_buildUserAvatar` renders referee `photoUrl` reactively with fallback icon

### Tests for User Story 2

- [X] T009 [P] [US2] Add widget tests in `test/presentation/shell/profile_tab_view_test.dart` verifying referee avatar rendering (photo vs fallback icon), `Perfil completo` badge both with and without avatar, and `profile_referee_personal_data_tile` routing to `/profile/referee-personal-data/summary` (complete) vs `/profile/referee-personal-data` (incomplete) (depends on T008)

**Checkpoint**: User Stories 1 and 2 deliver reactive avatar capture and Profile display.

---

## Phase 5: User Story 3 - Pantalla resumen del perfil arbitral y acceso a edición (Priority: P2)

**Goal**: Provide a read-only summary screen (`RefereePersonalDataSummaryScreen`) for referees showing avatar, personal/location data, certification level, and zoomable previews of both ID sides and the certification document, with an `Editar` AppBar button.

**Independent Test**: Navigate to `/profile/referee-personal-data/summary` for a referee with complete profile; verify all sections, 3 document previews, zoom dialog, reactive updates after editing, and `Editar` button navigation to `/profile/referee-personal-data`.

### Implementation for User Story 3

- [X] T010 [US3] Create `RefereePersonalDataSummaryScreen` in `lib/presentation/shell/tabs/referee_personal_data_summary_screen.dart` implementing the contract keys (`referee_summary_edit_action`, `referee_summary_header_card`, `referee_summary_avatar`, `referee_summary_full_name`, `referee_summary_document_id`, `referee_summary_age`, `referee_summary_demographics_card`, `referee_summary_certification_card`, `referee_summary_certification_doc_preview`, `referee_summary_documentation_card`, `referee_summary_doc_front_preview`, `referee_summary_doc_back_preview`), Spanish `Semantics` labels on avatar, edit button, and document previews, signed/local document preview loading with zoom dialog, and `Editar` navigation to `/profile/referee-personal-data`
- [X] T011 [US3] Register `/profile/referee-personal-data/summary` route returning `RefereePersonalDataSummaryScreen` in `lib/presentation/navigation/app_router.dart` (depends on T010)

### Tests for User Story 3

- [X] T012 [P] [US3] Create widget test suite `test/presentation/shell/referee_personal_data_summary_screen_test.dart` covering header/avatar display, demographics/location/phone/certification level rows, signed/local previews for front ID, back ID, and certification document, zoom dialog, and `Editar` navigation to `/profile/referee-personal-data` (depends on T010, T011)

**Checkpoint**: Complete referee profile summary and edit roundtrip are functional and verified.

---

## Phase 6: User Story 4 - Manejo resiliente de permisos y errores de imagen (Priority: P2)

**Goal**: Ensure camera/gallery permission denials, user cancellations, and image load errors display clear Spanish messages and visual fallbacks without crashing or losing form data.

**Independent Test**: Simulate `camera_access_denied` / `photo_access_denied` exceptions, null picker cancellations, and failed signed URL/image loads; verify Spanish guidance banner, `openCameraSettings()` action, zero data loss, and clean fallbacks.

### Implementation for User Story 4

- [X] T013 [US4] Add resilient camera/gallery permission denial handling (`PlatformException` / `CameraPermissionDeniedFailure`) with Spanish guidance banner (`ValueKey('referee_avatar_permission_banner')`) and settings action, silent picker cancellation handling, and image load error fallbacks in `lib/presentation/shell/tabs/referee_personal_data_screen.dart` and `lib/presentation/shell/tabs/referee_personal_data_summary_screen.dart`

### Tests for User Story 4

- [X] T014 [P] [US4] Add widget tests for denied camera/gallery permissions, silent picker cancellation preserving form data, and offline/failed document preview fallback in `test/presentation/shell/referee_personal_data_screen_test.dart` and `test/presentation/shell/referee_personal_data_summary_screen_test.dart` (depends on T013)

**Checkpoint**: All 4 user stories are complete and resilient under mobile error conditions.

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: Final static analysis and full regression test verification per `quickstart.md`.

- [X] T015 Run `flutter analyze` on `lib/presentation/navigation/app_router.dart`, `lib/presentation/shell/tabs/profile_tab_view.dart`, `lib/presentation/shell/tabs/referee_personal_data_screen.dart`, `lib/presentation/shell/tabs/referee_personal_data_summary_screen.dart`, `test/presentation/shell/profile_tab_view_test.dart`, `test/presentation/shell/referee_personal_data_screen_test.dart`, and `test/presentation/shell/referee_personal_data_summary_screen_test.dart` and resolve any issues
- [X] T016 Run `flutter test test/presentation/shell/referee_personal_data_screen_test.dart test/presentation/shell/referee_personal_data_summary_screen_test.dart test/presentation/shell/profile_tab_view_test.dart test/domain/entities/user_account_test.dart` and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately (`T001` → `T002`; `T003` runs in parallel).
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T004`).
- **Phase 3 (US1)**, **Phase 4 (US2)**, **Phase 5 (US3)**: Depend on Phase 1–2; `US1` (`referee_personal_data_screen.dart`), `US2` (`profile_tab_view.dart`), and `US3` (`referee_personal_data_summary_screen.dart`, `app_router.dart`) touch separate files and can be implemented in parallel.
- **Phase 6 (US4)**: Builds on `US1` (`T005`) and `US3` (`T010`).
- **Phase 7 (Polish)**: Runs after `T001`–`T014` complete.

### Parallel Opportunities

- `T001` (`app_es.arb`) and `T003` (SQL migration) can execute in parallel.
- `T005`/`T006` (US1 form), `T008` (US2 profile tab), and `T010`/`T011` (US3 summary screen & router) target independent files and can run in parallel.
- `T007`, `T009`, `T012`, and `T014` test suites target independent test files and can run in parallel once their target screens are ready.

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1 (`T001`–`T003`) and Phase 2 (`T004`).
2. Complete Phase 3 (`US1`: avatar capture & persistence) and Phase 4 (`US2`: reactive Profile display).
3. Validate avatar capture + immediate display in `ProfileTabView`.

### Incremental Delivery

1. Add Phase 5 (`US3`: `RefereePersonalDataSummaryScreen` + `/profile/referee-personal-data/summary`).
2. Add Phase 6 (`US4`: permission & error resilience).
3. Run Phase 7 (`T015`–`T016`: `flutter analyze` and `flutter test`).
