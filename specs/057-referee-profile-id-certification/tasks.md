---

description: "Actionable task list for HU 25.1 — Perfil Completo del Árbitro: Cédula Colombiana por Ambos Lados y Documento de Certificación Arbitral"
---

# Tasks: Perfil Completo del Árbitro: Cédula Colombiana por Ambos Lados y Documento de Certificación Arbitral

**Input**: Design documents from `/specs/057-referee-profile-id-certification/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/referee_profile_contract.md`, `quickstart.md`

**Tests**: Incluidas de forma obligatoria según Principio III de la Constitución y checklist técnico de HU 25.1.

**Organization**: Las tareas están agrupadas por fases y por historia de usuario (`US1`, `US2`, `US3`) para habilitar implementación y verificación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias sobre tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (`[US1]`, `[US2]`, `[US3]`)
- Todas las tareas incluyen rutas exactas de archivo relativas al repositorio

---

## Phase 1: Setup (Localization & SQL Migration)

**Purpose**: Preparar llaves de localización en español y la migración SQL de `match_referees` + `complete_role_profile` + `delete_my_account` antes de implementar las capas Flutter

- [X] T001 [P] Add Spanish localization keys for referee personal data screen title, certification section header, certification level label/hint, capture/replace certification document CTA, validation messages, and profile referee tile in `lib/l10n/app_es.arb`
- [X] T002 [P] Create idempotent SQL migration adding `first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date`, `blood_type`, `department`, `municipality`, `document_front_url`, `document_back_url`, and `certification_document_url` to `vifutboldev.match_referees`, updating `vifutboldev.complete_role_profile` (28 params including `p_certification_document_url`) to persist and hydrate all referee fields without duplicating records, and updating `vifutboldev.delete_my_account()` to clear new PII columns on `match_referees` in `supabase/migrations/202611250002_referee_profile_and_certification_doc.sql`
- [X] T003 Regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` by running `flutter gen-l10n` (depends on T001)

**Checkpoint**: Localización y migración SQL listas.

---

## Phase 2: Foundational (Domain Entities, Storage & Auth Hydration)

**Purpose**: Extender entidades de dominio, contrato/implementación de almacenamiento privado y capa de autenticación Supabase antes de construir la pantalla del árbitro

- [X] T004 [P] Add `certificationDocumentUrl` (`certificationDocumentUrl` / `certification_document_url`) to `RoleProfileData` constructor, `copyWith`, `toJson`, `fromJson`, `==`, and `hashCode` in `lib/domain/entities/role_profile_data.dart`
- [X] T005 [P] Add `Future<String> uploadRefereeCertificationDocument({required String userId, required String localPath, String? existingDocumentUrl});` to `DocumentStorageRepository` in `lib/domain/repositories/document_storage_repository.dart`
- [X] T006 Update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.referee` to require `phone`, `documentId`, `firstName`, `firstSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `certificationLevel`, `documentFrontUrl`, `documentBackUrl`, and `certificationDocumentUrl` without altering other roles in `lib/domain/entities/user_account.dart` (depends on T004)
- [X] T007 [P] Implement `uploadRefereeCertificationDocument` uploading to private bucket `player-documents` at `$userId/referee_certification.jpg` (checking connectivity first and preserving `existingDocumentUrl` if unchanged) in `SupabaseDocumentStorageRepository` and `LocalDocumentStorageRepository` in `lib/infrastructure/storage/supabase_document_storage_repository.dart` (depends on T005)
- [X] T008 [P] Update `SupabaseAuthRepository` to pass `'p_certification_document_url'` in `completeRoleProfile` RPC, fetch and hydrate all new `match_referees` columns in `fetchRoleProfileDetails` / `mapRowToUserAccount`, and delete local `certificationDocumentUrl` file during `deleteAccount` in `lib/infrastructure/auth/supabase_auth_repository.dart` (depends on T004)

**Checkpoint**: Dominio, almacenamiento privado e hidratación remota listos.

---

## Phase 3: User Story 1 - Formulario Dedicado de Identidad y Ubicación del Árbitro con Escaneo Dual de Cédula Colombiana (Priority: P1) 🎯 MVP

**Goal**: Crear `RefereePersonalDataScreen` con paridad completa de campos de identidad y ubicación en Colombia, escaneo dual de cédula colombiana (`MlkitColombianIdScannerService` + `IdDocumentCaptureCard`), y conectar la navegación desde `ProfileTabView` y `AppRouter`.

**Independent Test**: Abrir `ProfileTabView` como `UserRole.referee`, navegar a `/profile/referee-personal-data`, escanear/autocompletar cédula colombiana y capturar frente y reverso con vista previa y reemplazo.

### Implementation for User Story 1

- [X] T009 [US1] Create `RefereePersonalDataScreen` with personal identity fields (document, first/second name, first/second surname, sex, birth date, RH blood type, phone), Colombia department/municipality selector (`SearchableLocationPickerSheet`), Colombian ID dual scanner (`MlkitColombianIdScannerService`), and front/back ID capture (`IdDocumentCaptureCard`), plus unsaved-changes `PopScope` confirmation dialog in `lib/presentation/shell/tabs/referee_personal_data_screen.dart` (depends on T003, T006, T007)
- [X] T010 [P] [US1] Register `/profile/referee-personal-data` route pointing to `RefereePersonalDataScreen` in `lib/presentation/navigation/app_router.dart` (depends on T009)
- [X] T011 [P] [US1] Connect `ProfileTabView` so `profile_complete_action_button` navigates to `/profile/referee-personal-data` when `activeRole == UserRole.referee` and render a dedicated `Key('profile_referee_personal_data_tile')` tile for referee users in `lib/presentation/shell/tabs/profile_tab_view.dart` (depends on T003, T009)

**Checkpoint**: User Story 1 (MVP) operativa con escaneo dual y captura de cédula por ambos lados.

---

## Phase 4: User Story 2 - Captura del Documento de Certificación Arbitral y Categoría (Priority: P2)

**Goal**: Incorporar en `RefereePersonalDataScreen` la sección obligatoria de **Certificación Arbitral** con campo de categoría (`certificationLevel`) y captura/vista previa/reemplazo de imagen (`JPEG`/`PNG`/`WEBP`) desde cámara o galería con subida al almacenamiento privado.

**Independent Test**: En `RefereePersonalDataScreen`, capturar o seleccionar una imagen de certificación arbitral, verificar vista previa y reemplazo, completar la categoría arbitral y confirmar que al guardar se invoca `uploadRefereeCertificationDocument` y `updateRoleProfile` con `certificationDocumentUrl`.

### Implementation for User Story 2

- [X] T012 [US2] Add the Certificación Arbitral section (`Key('referee_certification_level_field')`, `Key('referee_certification_capture_card')`, `Key('referee_certification_capture_button')`) supporting camera/gallery image capture, local/signed remote preview, replacement, and camera/gallery permission handling in Spanish to `lib/presentation/shell/tabs/referee_personal_data_screen.dart` (depends on T009)

**Checkpoint**: User Stories 1 y 2 completas en `RefereePersonalDataScreen`.

---

## Phase 5: User Story 3 - Validación de Completitud, Guardado Atómico, Protección contra Doble Envío y Resiliencia Móvil (Priority: P3)

**Goal**: Validar todos los campos obligatorios y las 3 capturas documentales antes de enviar, aplicar bloqueo `single-flight` durante subida/guardado, conservar los datos ante fallos de red y cubrir todas las capas con pruebas unitarias y de widget.

**Independent Test**: Intentar guardar sin cédula o sin documento arbitral (verificando errores en español), pulsar repetidamente `referee_save_profile_button` (verificando 1 sola ejecución), simular error de red (verificando retención de datos) y ejecutar guardado exitoso validando `isProfileCompleteForActiveRole == true`.

### Implementation for User Story 3

- [X] T013 [US3] Implement mandatory validation (personal fields, Colombia location, certification level, front/back ID images, and certification document image), single-flight `_isSaving` lock on `Key('referee_save_profile_button')`, selective cloud uploads (`uploadPlayerIdDocuments` + `uploadRefereeCertificationDocument`), atomic `updateRoleProfile(role: UserRole.referee, ...)`, and error retention in `lib/presentation/shell/tabs/referee_personal_data_screen.dart` (depends on T012)

### Tests for User Story 1, 2 & 3

- [X] T014 [P] [US3] Update and expand unit tests for `UserAccount.isProfileCompleteForActiveRole` (verifying `UserRole.referee` requires all personal fields, location, certification level, both ID sides, and `certificationDocumentUrl`, while keeping other roles intact) in `test/domain/entities/user_account_test.dart`
- [X] T015 [P] [US3] Add widget tests for `RefereePersonalDataScreen` covering section rendering, dual ID scan autofill, front/back ID and certification document capture/replace, mandatory validation blocking in Spanish, single-flight save invoking storage upload + `updateRoleProfile`, offline error retention, and 0 overflow at `TextScaler.linear(1.5)` in `test/presentation/shell/referee_personal_data_screen_test.dart`
- [X] T016 [P] [US1] Add widget test in `test/presentation/shell/profile_tab_view_test.dart` verifying referee user navigates to `/profile/referee-personal-data` from `profile_complete_action_button` and `profile_referee_personal_data_tile`

**Checkpoint**: Todas las historias de usuario (US1, US2, US3) verificadas con pruebas automatizadas.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación final de calidad, análisis estático con cero advertencias y ejecución de la suite de `quickstart.md`

- [X] T017 Run static analysis (`flutter analyze lib/domain/entities/role_profile_data.dart lib/domain/entities/user_account.dart lib/domain/repositories/document_storage_repository.dart lib/infrastructure/storage/supabase_document_storage_repository.dart lib/infrastructure/auth/supabase_auth_repository.dart lib/presentation/navigation/app_router.dart lib/presentation/shell/tabs/profile_tab_view.dart lib/presentation/shell/tabs/referee_personal_data_screen.dart test/domain/entities/user_account_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/shell/referee_personal_data_screen_test.dart`) and resolve any issues so 0 errors and 0 warnings remain
- [X] T018 Run full validation suite per `specs/057-referee-profile-id-certification/quickstart.md` (`flutter test test/domain/entities/user_account_test.dart test/presentation/shell/referee_personal_data_screen_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/shell/player_personal_data_screen_test.dart`) and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: `T001` y `T002` en paralelo; `T003` depende de `T001`.
- **Phase 2 (Foundational)**: `T004` y `T005` en paralelo; `T006` depende de `T004`; `T007` depende de `T005`; `T008` depende de `T004`.
- **Phase 3–5 (US1–US3)**: `T009` → `T012` → `T013` en `referee_personal_data_screen.dart`; `T010` y `T011` en paralelo tras `T009`; `T014`, `T015`, `T016` en paralelo tras `T013`.
- **Phase 6 (Polish)**: `T017` y `T018` al completar `T001`–`T016`.

### Implementation Strategy

- Implementar `RefereePersonalDataScreen` (`T009` + `T012` + `T013`) de manera cohesiva en una sola creación limpia del archivo para evitar ediciones fragmentadas, luego conectar `AppRouter` (`T010`) y `ProfileTabView` (`T011`), y ejecutar la batería completa de pruebas (`T014`–`T018`).
