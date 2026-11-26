# Tasks: Perfil Completo del Entrenador (Cédula Colombiana, Escaneo Dual y Fotos por Ambos Lados)

**Input**: Documentos de diseño en `/specs/061-coach-profile-colombian-id/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/coach-profile-contracts.md`, `quickstart.md`

**Tests**: Incluidos explícitamente según el checklist técnico de HU 27.1 (pruebas unitarias y pruebas de widget para formulario, resumen y navegación desde Perfil).

**Organization**: Las tareas están organizadas por fase y por Historia de Usuario (US1–US4) para permitir implementación y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencia de tareas incompletas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`, `[US4]`).
- Todas las tareas incluyen la ruta exacta del archivo objetivo.

---

## Phase 1: Setup (Localización en Español)

**Purpose**: Centralizar todos los textos visibles en español antes de construir las pantallas y pruebas.

- [X] T001 Add Spanish localization keys for coach personal data form, age ≥ 18 validation message, `"Independiente"` club hint, `"Sin licencia"` and license level options, dual-side ID capture labels, coach summary screen titles/sections, and `ProfileTabView` coach personal data tile in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)

---

## Phase 2: Foundational (Base de Datos, Dominio e Infraestructura Remota)

**Purpose**: Prerrequisitos bloqueantes que habilitan persistencia atómica, hidratación remota y criterio estricto de perfil completo para `UserRole.coach`.

**⚠️ CRITICAL**: Completar esta fase antes de iniciar las historias de usuario.

- [X] T003 Create idempotent SQL migration in `supabase/migrations/202611260001_coach_profile_personal_data_and_documents.sql` adding nullable columns `first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date` (`date`), `blood_type`, `department`, `municipality`, `document_front_url`, and `document_back_url` to `vifutboldev.coach_profiles`; updating `vifutboldev.complete_role_profile` (preserving its 28-parameter signature) to upsert all coach fields atomically in `p_active_role = 'coach'` (allowing explicit clearing of optional `second_name`/`second_surname` when passed as empty string) and hydrate `v_coach_row` fields in `role_profile` (prioritizing `v_coach_row` when `p_active_role = 'coach'`); and ending with `NOTIFY pgrst, 'reload schema'`
- [X] T004 [P] Update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.coach` in `lib/domain/entities/user_account.dart` to require non-empty `phone`, `documentId`, `firstName`, `firstSurname`, `sex`, non-null `birthDate` (age ≥ 18 years via `PlayerPersonalDataUtils.calculateAge`), `bloodType`, `department`, `municipality`, `clubName`, `licenseLevel`, `documentFrontUrl`, and `documentBackUrl` (keeping `secondName` and `secondSurname` optional)
- [X] T005 [P] Update `SupabaseAuthRemoteDataSource.fetchRoleProfileDetails` in `lib/infrastructure/auth/supabase_auth_repository.dart` to select `club_name, license_level, first_name, second_name, first_surname, second_surname, sex, birth_date, blood_type, department, municipality, document_front_url, document_back_url` from `coach_profiles` and merge them into `role_profile`
- [X] T006 [P] Create unit tests in `test/unit/coach_profile_completeness_test.dart` verifying `UserAccount.isProfileCompleteForActiveRole` for `UserRole.coach` (all 13 required fields, optional `secondName`/`secondSurname`, legacy partial coach profile with only `clubName`/`licenseLevel`, and `RoleProfileData.fromJson`/`toJson` roundtrip)

**Checkpoint**: Migración lista, dominio actualizado e hidratación remota validada por pruebas unitarias.

---

## Phase 3: User Story 1 — Completar Perfil del Entrenador con Datos de Cédula Colombiana y Datos Técnicos (Priority: P1) 🎯 MVP

**Goal**: Ofrecer el formulario dedicado de datos personales y técnicos del entrenador accesible desde la pestaña Perfil con validaciones estrictas en español (incluyendo mayoría de edad ≥ 18 años, `"Independiente"` y `"Sin licencia"`).

**Independent Test**: Iniciar sesión como entrenador con perfil incompleto, pulsar `Completar perfil` en `ProfileTabView`, verificar precarga de datos existentes, selector dependiente departamento → municipio, rechazo de edad < 18 años y validación de todos los campos obligatorios.

### Implementation for User Story 1

- [X] T007 [US1] Create `CoachPersonalDataScreen` in `lib/presentation/shell/tabs/coach_personal_data_screen.dart` with KickPulse form sections for Colombian ID identity (`documentId`, `firstName`, optional `secondName`, `firstSurname`, optional `secondSurname`, `sex` via `PlayerSex`, `birthDate` validating age ≥ 18 years and non-future dates via `PlayerPersonalDataUtils.calculateAge`, `bloodType`, `phone`), Colombia location (`department` and dependent `municipality` via `SearchableLocationPickerSheet`, clearing municipality when department changes), coach technical fields (`clubName` mandatory with `"Independiente"` helper/hint, `licenseLevel` mandatory selector with `"Sin licencia"`, `"Licencia C"`, `"Licencia B"`, `"Licencia A"`, `"Licencia PRO"`, `"Otra"` plus backwards compatibility for existing stored values), pre-filling existing account/profile values, and `PopScope` unsaved-changes confirmation dialog in Spanish
- [X] T008 [P] [US1] Register `/profile/coach-personal-data` route handler in `lib/presentation/navigation/app_router.dart`
- [X] T009 [US1] Update `ProfileTabView` in `lib/presentation/shell/tabs/profile_tab_view.dart` so tapping `ValueKey('profile_complete_action_button')` when `activeRole == UserRole.coach` navigates to `/profile/coach-personal-data` instead of `CompleteProfileDialog`

**Checkpoint**: Un entrenador con perfil incompleto navega al formulario dedicado con todos los campos de cédula, ubicación y datos técnicos validados.

---

## Phase 4: User Story 2 — Escaneo Dual de Cédula Colombiana y Fotografía por Ambos Lados (Priority: P1)

**Goal**: Integrar el escaneo dual de cédula colombiana (PDF417 + MRZ OCR) con autocompletado y la captura/previsualización de cara frontal y posterior en el formulario del entrenador.

**Independent Test**: Desde `CoachPersonalDataScreen`, ejecutar escaneo dual (mockeado/real) verificando autocompletado editable de documento, nombres, apellidos, sexo, fecha de nacimiento y RH, captura y previsualización de frente y reverso, manejo resiliente de permisos cámara/galería y bloqueo al omitir alguna foto.

### Implementation for User Story 2

- [X] T010 [US2] Integrate `colombianIdScannerProvider` (`MlkitColombianIdScannerService` PDF417 + MRZ OCR) into `lib/presentation/shell/tabs/coach_personal_data_screen.dart` to autocomplete `documentId`, `firstName`, `secondName`, `firstSurname`, `secondSurname`, `birthDate`, `sex`, and `bloodType` while keeping fields editable, handling camera/gallery permission denials with Spanish guidance to device settings, and preserving entered fields on scan failure or cancellation
- [X] T011 [US2] Integrate `IdDocumentCaptureCard` and `PlayerDocumentCapture` into `lib/presentation/shell/tabs/coach_personal_data_screen.dart` for capturing/selecting and previewing front and back Colombian ID photos, supporting selective replacement in edit mode and displaying clear Spanish validation errors when either side is missing

**Checkpoint**: Escaneo dual y captura por ambos lados completamente funcionales en el formulario del entrenador.

---

## Phase 5: User Story 3 — Persistencia Atómica, Almacenamiento Privado y Criterio de Perfil Completo (Priority: P1)

**Goal**: Subir ambas fotografías al bucket privado `player-documents` (RLS por `auth.uid()`), guardar atómicamente vía `complete_role_profile` con bloqueo `single-flight`, y actualizar inmediatamente el estado de perfil a `Perfil completo`.

**Independent Test**: Completar todos los campos y ambas caras de la cédula, pulsar `Guardar perfil` (probando toques repetidos y falla de red), verificar subida selectiva a `player-documents`, llamada atómica a `completeRoleProfile`, preservación de estado ante error y transición a `Perfil completo`.

### Implementation for User Story 3

- [X] T012 [US3] Implement the atomic save flow in `lib/presentation/shell/tabs/coach_personal_data_screen.dart`: enforce single-flight `_isSaving` lock with loading indicator, upload only newly captured local front/back images via `documentStorageServiceProvider.uploadDocumentImage` to private bucket `player-documents` (preserving existing remote URLs when unchanged), invoke `authControllerProvider.notifier.completeRoleProfile(...)` with `UserRole.coach` and `RoleProfileData`, keep form and selected photos intact on network/upload failure with Spanish error feedback, and navigate back cleanly on success
- [X] T013 [P] [US3] Create widget tests in `test/widget/coach_personal_data_screen_test.dart` covering US1, US2, and US3: rendering all sections, pre-filling partial coach profile, department-to-municipality reset, rejecting birth date < 18 years, accepting `"Independiente"` and `"Sin licencia"`, dual scan autocomplete, blocking submit when front/back photo or mandatory field is missing, single-flight double-tap prevention, private upload + atomic save success, preserving inputs on error, and unsaved changes confirmation dialog

**Checkpoint**: Flujo completo de registro y actualización del perfil de entrenador validado de extremo a extremo.

---

## Phase 6: User Story 4 — Pantalla Resumen y Edición del Perfil del Entrenador (Priority: P2)

**Goal**: Permitir al entrenador con perfil completo consultar desde la pestaña Perfil una pantalla resumen con sus datos personales, técnicos y miniaturas en línea (URL firmada temporal + zoom) de ambas caras de la cédula, y abrir el formulario en modo edición.

**Independent Test**: Con un entrenador de perfil completo, verificar badge `Perfil completo` en `ProfileTabView`, tocar `profile_coach_personal_data_tile`, comprobar todas las tarjetas y miniaturas firmadas en `CoachPersonalDataSummaryScreen`, probar zoom a pantalla completa y navegar a `/profile/coach-personal-data` al pulsar `Editar`.

### Implementation for User Story 4

- [X] T014 [P] [US4] Create `CoachPersonalDataSummaryScreen` in `lib/presentation/shell/tabs/coach_personal_data_summary_screen.dart` displaying header card (`ValueKey('coach_summary_header_card')` with full name, `CC`, and age), demographics & Colombia location card (`ValueKey('coach_summary_demographics_card')`), technical accreditation card (`ValueKey('coach_summary_technical_card')` with `clubName` and `licenseLevel`), documentation card (`ValueKey('coach_summary_documentation_card')`) rendering inline thumbnails of front/back ID via `documentStorageServiceProvider.createSignedUrl` with full-screen tap-to-zoom viewer, and AppBar `Edit` button (`ValueKey('coach_summary_edit_action')`) navigating to `/profile/coach-personal-data`
- [X] T015 [US4] Register `/profile/coach-personal-data/summary` route handler in `lib/presentation/navigation/app_router.dart` and add the coach personal data tile (`Key('profile_coach_personal_data_tile')`) to `lib/presentation/shell/tabs/profile_tab_view.dart` (visible for `UserRole.coach`, routing to `/profile/coach-personal-data/summary` when complete and `/profile/coach-personal-data` when incomplete)
- [X] T016 [P] [US4] Create widget tests in `test/widget/coach_personal_data_summary_screen_test.dart` covering `CoachPersonalDataSummaryScreen` (all 4 cards, signed-URL inline thumbnails, tap-to-zoom viewer, Edit button navigation) and `ProfileTabView` coach routing (incomplete → `/profile/coach-personal-data`, complete → `/profile/coach-personal-data/summary`)

**Checkpoint**: Ciclo completo (completar → resumen con miniaturas firmadas → editar conservando fotos) funcionando y cubierto por pruebas.

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: Verificación integral de análisis estático, suite de pruebas completa y directrices móviles.

- [X] T017 Run `flutter analyze` and execute targeted and global `flutter test` suites (`test/unit/coach_profile_completeness_test.dart`, `test/widget/coach_personal_data_screen_test.dart`, `test/widget/coach_personal_data_summary_screen_test.dart`, plus global `flutter test`) per `specs/061-coach-profile-colombian-id/quickstart.md`
- [X] T018 Audit Spanish-only UI copy in `lib/l10n/app_es.arb`, vertical scrolling / large text scaling accessibility, and PII safety (no document numbers/URLs logged) across `lib/presentation/shell/tabs/coach_personal_data_screen.dart` and `lib/presentation/shell/tabs/coach_personal_data_summary_screen.dart`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Sin dependencias; inicia de inmediato (`T001` → `T002`).
- **Phase 2 (Foundational)**: Depende de Phase 1 (para tests/compilación); **bloquea** Phases 3–6. `T003`, `T004`, `T005`, `T006` pueden ejecutarse en paralelo (`T006` tras `T004`).
- **Phase 3 (US1)** → **Phase 4 (US2)** → **Phase 5 (US3)**: Secuenciales sobre `coach_personal_data_screen.dart` (`T007` → `T010` → `T011` → `T012`), con `T008` y `T013` paralelizables en sus respectivos archivos.
- **Phase 6 (US4)**: Puede iniciar en paralelo una vez completada Phase 2 (`T014` es independiente de `T007`–`T012`), integrando rutas y `ProfileTabView` en `T015` y pruebas en `T016`.
- **Phase 7 (Polish)**: Depende de Phases 1–6.

### Parallel Opportunities
- **Phase 2**: `T003` (SQL), `T004` (`user_account.dart`) y `T005` (`supabase_auth_repository.dart`) en paralelo.
- **Phase 3 & Phase 6**: `T007` (`coach_personal_data_screen.dart`) y `T014` (`coach_personal_data_summary_screen.dart`) en paralelo.
- **Tests**: `T006` (unit), `T013` (widget formulario) y `T016` (widget resumen + `ProfileTabView`) en archivos separados.

## Implementation Strategy

- **MVP (Phases 1–5)**: Entrega el formulario completo del entrenador con datos de cédula colombiana, escaneo dual, captura de ambas caras, subida privada a `player-documents`, guardado atómico y transición a `Perfil completo`.
- **Incremento Final (Phases 6–7)**: Añade la pantalla resumen con miniaturas firmadas + zoom, acceso a edición desde `ProfileTabView` y verificación global con `flutter analyze` y `flutter test`.
