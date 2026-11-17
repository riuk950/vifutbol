---

description: "Actionable task list for HU 21.2: Escaneo Dual de Cédula Colombiana (PDF417 + MRZ OCR), Autocompletado y Captura por Ambos Lados"
---

# Tasks: Escaneo Dual de Cédula Colombiana, Autocompletado y Captura por Ambos Lados (HU 21.2)

**Input**: Design documents from `/specs/047-colombian-id-dual-scan/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/colombian_id_dual_scan_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III (`Pruebas Automatizadas como Puerta de Calidad`) and HU 21.2 Definition of Done.

**Organization**: Tasks are grouped by phase and user story (`US1`, `US2`, `US3`) to enable independent verification and incremental delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Dependencies, Permissions, Localization & Database Migration)

**Purpose**: Install ML Kit & camera packages, verify native camera permissions, centralize Spanish UI strings in `l10n`, and prepare the SQL/Storage migration.

- [X] T001 Add `google_mlkit_barcode_scanning`, `google_mlkit_text_recognition`, `image_picker`, and `permission_handler` dependencies in `pubspec.yaml` and run `flutter pub get`
- [X] T002 [P] Verify/add `CAMERA` permission in `android/app/src/main/AndroidManifest.xml` and `NSCameraUsageDescription` (in Spanish) in `ios/Runner/Info.plist`
- [X] T003 Add Spanish localization keys for dual ID capture button (`"Escanear / Capturar Cédula"`), front/back side labels, recapture buttons, camera permission denied banner & settings button, scanning progress indicator, scan success/partial/empty feedback, and mandatory dual-side validation error in `lib/l10n/app_es.arb`
- [X] T004 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`
- [X] T005 [P] Create idempotent SQL migration adding `document_front_url` and `document_back_url` to `vifutboldev.players`, creating private bucket `player-documents` with owner-scoped RLS policies (`auth.uid()`), and updating `vifutboldev.complete_role_profile` RPC (adding `p_document_front_url` and `p_document_back_url`) in `supabase/migrations/202611170003_player_document_images.sql`

---

## Phase 2: Foundational (Core Domain Entities, Failures, Repository Ports & Providers)

**Purpose**: Establish clean-architecture domain models, failure types, completeness rules, and persistence updates required across all user stories.

**⚠️ CRITICAL**: Complete this phase before implementing User Story components

- [X] T006 [P] Create `ColombianIdScanSource`, `ColombianIdScanResult`, and `PlayerDocumentCapture` entities in `lib/domain/entities/colombian_id_scan_result.dart`
- [X] T007 [P] Add `CameraPermissionDeniedFailure` and `DocumentUploadFailure` to `lib/domain/failures/app_failure.dart`
- [X] T008 [P] Define `ColombianIdScannerService` port in `lib/domain/repositories/colombian_id_scanner_service.dart` and `DocumentStorageRepository` port in `lib/domain/repositories/document_storage_repository.dart`
- [X] T009 Extend `RoleProfileData` with `documentFrontUrl` and `documentBackUrl` (`toJson`, `fromJson`, `copyWith`, equality) in `lib/domain/entities/role_profile_data.dart` and update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.player` to require non-empty `documentFrontUrl` and `documentBackUrl` in `lib/domain/entities/user_account.dart`
- [X] T010 [P] Update `LocalAuthRepository.updateRoleProfile` in `lib/infrastructure/auth/local_auth_repository.dart` to merge and persist `documentFrontUrl` and `documentBackUrl`
- [X] T011 [P] Update `SupabaseAuthRepository` (`_PostgrestUserProfileDataSource.completeRoleProfile` and `fetchRoleProfileDetails`) in `lib/infrastructure/auth/supabase_auth_repository.dart` to pass `p_document_front_url` / `p_document_back_url` and hydrate them from `vifutboldev.players`
- [X] T012 Create Riverpod providers for `colombianIdScannerServiceProvider` and `documentStorageRepositoryProvider` in `lib/application/providers/document_scanner_providers.dart`

**Checkpoint**: Foundation ready — domain models, completeness rules, ports, and auth repository serialization are complete.

---

## Phase 3: User Story 1 - Captura Fotográfica por Ambos Lados y Previsualización con Opción de Recaptura (Priority: P1) 🎯 MVP

**Goal**: Enable live camera-only capture of both front and back sides of the Colombian ID from `PlayerPersonalDataScreen`, displaying thumbnails of both faces with individual recapture actions and camera-permission handling.

**Independent Test**: Tap `"Escanear / Capturar Cédula"` (`Key('player_form_scan_id_button')`), capture front and back photos via mocked `ColombianIdScannerService`, verify both thumbnails render (`Key('player_form_id_front_preview')`, `Key('player_form_id_back_preview')`), retake one side, and verify camera-denied banner displays with settings shortcut without blocking manual editing.

### Implementation for User Story 1

- [X] T013 [US1] Implement `MlkitColombianIdScannerService.captureDocumentPhoto` (live rear camera via `image_picker`, `ImageSource.camera` only, handling denied camera permissions & `openCameraSettings`) in `lib/infrastructure/scanner/mlkit_colombian_id_scanner_service.dart`
- [X] T014 [US1] Create `IdDocumentCaptureCard` widget displaying `"Escanear / Capturar Cédula"` (`Key('player_form_scan_id_button')`), front/back preview thumbnails (`Key('player_form_id_front_preview')`, `Key('player_form_id_back_preview')`), individual capture/retake buttons (`Key('player_form_id_front_capture_btn')`, `Key('player_form_id_back_capture_btn')`), scanning indicator (`Key('player_form_id_scanning_indicator')`), permission banner (`Key('player_form_camera_permission_banner')`, `Key('player_form_open_settings_button')`), and validation error (`Key('player_form_id_images_error')`) in `lib/presentation/shell/widgets/id_document_capture_card.dart`
- [X] T015 [US1] Integrate `IdDocumentCaptureCard` into the Identification section of `PlayerPersonalDataScreen` (`lib/presentation/shell/tabs/player_personal_data_screen.dart`), enforcing mandatory both-sides check before saving and anti-double-tap guard during capture

**Checkpoint**: User Story 1 delivers guided dual-side camera capture, previews, and recapture independently.

---

## Phase 4: User Story 2 - Autocompletado Inteligente Dual (Código Bidimensional PDF417 y MRZ TD1 + OCR) (Priority: P1)

**Goal**: Automatically decode PDF417 barcodes (yellow hologram ID) and ICAO 9303 TD1 3-line MRZ + printed OCR fields (digital polycarbonate ID), populating `PlayerPersonalDataScreen` via `applyDocumentScanData(...)` with immediate Age calculation and partial-read fallback.

**Independent Test**: Run `flutter test test/unit/domain/colombian_id_parser_test.dart` against real-structure PDF417 and TD1 MRZ/OCR payloads; verify in widget tests that scanning populates documentId, names, surnames, sex, birthDate, bloodType, and reactive Age while preserving unrelated manual fields (phone, location, positions).

### Tests for User Story 2

- [X] T016 [P] [US2] Create comprehensive unit tests for `ColombianIdParser` covering PDF417 positional & token extraction (accents/`Ñ`, leading zeros, `M`/`F`, `YYYYMMDD`, RH), ICAO 9303 TD1 3-line MRZ parsing (century inference, `<<`/`<` split, OCR noise normalization), OCR heuristics (NUIP, RH), and `mergeResults` in `test/unit/domain/colombian_id_parser_test.dart`

### Implementation for User Story 2

- [X] T017 [US2] Implement pure domain `ColombianIdParser` (`parsePdf417`, `parseMrzAndOcr`, `mergeResults`) in `lib/domain/services/colombian_id_parser.dart`
- [X] T018 [US2] Complete `MlkitColombianIdScannerService.scanDocumentImages` integrating `google_mlkit_barcode_scanning` (`BarcodeFormat.pdf417`) and `google_mlkit_text_recognition` (`TextRecognitionScript.latin`) delegating to `ColombianIdParser` without logging raw sensitive ID payloads in `lib/infrastructure/scanner/mlkit_colombian_id_scanner_service.dart`
- [X] T019 [US2] Wire automatic dual ML Kit scanning upon dual-side capture completion in `PlayerPersonalDataScreen` (`lib/presentation/shell/tabs/player_personal_data_screen.dart`), invoking `applyDocumentScanData(...)`, showing `Key('player_form_id_scan_feedback')`, and keeping manual editing unlocked on partial/empty reads
- [X] T020 [US2] Add widget tests verifying automatic form population (PDF417/MRZ/partial read), reactive Age recalculation, preservation of existing phone/location/positions, and camera permission denied handling in `test/presentation/shell/player_personal_data_screen_test.dart`

**Checkpoint**: User Story 2 verified at unit and widget levels.

---

## Phase 5: User Story 3 - Persistencia Local y Sincronización Remota de Imágenes Documentales (Priority: P1)

**Goal**: Upload newly captured front/back ID images to private Supabase Storage (`player-documents` with RLS), persist `document_front_url` and `document_back_url` in `vifutboldev.players` and local cache, and preserve form + photos intact on offline/upload failure.

**Independent Test**: Update `user_account_test.dart` and `supabase_auth_repository_test.dart` verifying mandatory front/back URLs for player completeness and RPC forwarding; verify in widget tests that saving calls `uploadPlayerIdDocuments` -> `updateRoleProfile` with both URLs, rejects saving if a side is missing (`Key('player_form_id_images_error')`), and preserves local photos + form state on upload/network failure.

### Tests for User Story 3

- [X] T021 [P] [US3] Update `test/domain/entities/user_account_test.dart` to verify `UserAccount.isProfileCompleteForActiveRole` for `UserRole.player` requires `documentFrontUrl` and `documentBackUrl` alongside HU 21.1 fields
- [X] T022 [P] [US3] Update `test/infrastructure/auth/supabase_auth_repository_test.dart` to verify `documentFrontUrl` and `documentBackUrl` forwarding to `complete_role_profile` and hydration from `players`

### Implementation for User Story 3

- [X] T023 [US3] Implement `SupabaseDocumentStorageRepository` uploading front/back files to private bucket `player-documents` (`<auth_uid>/document_front.jpg`, `<auth_uid>/document_back.jpg`, `upsert: true`) in `lib/infrastructure/storage/supabase_document_storage_repository.dart` and wire it in `lib/application/providers/document_scanner_providers.dart`
- [X] T024 [US3] Wire upload-before-save flow in `PlayerPersonalDataScreen` (`lib/presentation/shell/tabs/player_personal_data_screen.dart`), preloading existing `documentFrontUrl`/`documentBackUrl` and preserving local photos + form inputs on upload or offline failure
- [X] T025 [US3] Add widget tests verifying mandatory dual-side validation (`Key('player_form_id_images_error')`), upload-before-save persistence, error banner on upload failure, and 320px/130% responsive layout with `IdDocumentCaptureCard` in `test/presentation/shell/player_personal_data_screen_test.dart`

**Checkpoint**: All 3 user stories (US1, US2, US3) work cohesively and pass independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, full regression verification, and final quality gate.

- [X] T026 Run `flutter analyze` across the entire repository and resolve all warnings or errors
- [X] T027 Run full automated test suite (`flutter test test/unit/domain/colombian_id_parser_test.dart test/unit/domain/player_personal_data_utils_test.dart test/unit/domain/colombian_id_parser_test.dart test/domain/entities/user_account_test.dart test/infrastructure/auth/supabase_auth_repository_test.dart test/presentation/shell/player_personal_data_screen_test.dart test/presentation/shell/profile_tab_view_test.dart`) and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: `T001` & `T002` -> `T003` -> `T004`; `T005` [P] runs in parallel.
- **Phase 2 (Foundational)**: `T006`, `T007`, `T008` in parallel -> `T009` -> `T010` [P], `T011` [P], `T012`.
- **Phase 3 (US1)**, **Phase 4 (US2)**, **Phase 5 (US3)**: Depend on Phase 2 completion. `IdDocumentCaptureCard` (`T014`) and `ColombianIdParser` (`T017`) can be developed cleanly before wiring `PlayerPersonalDataScreen` (`T015`, `T019`, `T024`).
- **Phase 6 (Polish)**: Depends on Phases 1–5 (`T026` -> `T027`).

### Parallel Opportunities

- `T002` (manifest/Info.plist), `T003` (l10n), and `T005` (SQL migration) target separate files.
- `T006`, `T007`, `T008` in Phase 2 create independent domain files in parallel.
- `T016`, `T021`, `T022` test files can be authored in parallel with independent targets.
