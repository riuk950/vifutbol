---

description: "Actionable task list for HU 21.1: Formulario de Datos Personales, Ubicación en Colombia y Posiciones Múltiples del Jugador"
---

# Tasks: Formulario de Datos Personales, Ubicación en Colombia y Posiciones Múltiples del Jugador (HU 21.1)

**Input**: Design documents from `/specs/046-player-personal-data-form/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/player_personal_data_contract.md`, `quickstart.md`

**Tests**: Included per Project Constitution Principle III (`Pruebas Automatizadas como Puerta de Calidad`) and HU 21.1 Definition of Done.

**Organization**: Tasks are grouped by phase and user story (`US1`, `US2`, `US3`) to enable independent verification and incremental delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths.

---

## Phase 1: Setup (Localization & Database Schema Migration)

**Purpose**: Centralize all Spanish UI strings in `l10n` and prepare the idempotent Postgres schema/RPC migration for `vifutboldev.players`

- [X] T001 Add Spanish localization keys for player personal data screen, fields (`document`, `phone`, `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `age`, `bloodType`, `department`, `municipality`, `positions`), sex labels (`Masculino`, `Femenino`, `Otro`), all 15 detailed football position names, searchable location picker labels, `"Datos Personales"` profile tile, unsaved-changes dialog, and validation messages in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`
- [X] T003 [P] Create idempotent SQL migration adding `first_name`, `second_name`, `first_surname`, `second_surname`, `sex` (`CHECK (sex IS NULL OR sex IN ('male', 'female', 'other'))`), `birth_date` (`date`), `blood_type` (`CHECK (blood_type IS NULL OR blood_type IN ('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'))`), `department`, `municipality`, and `secondary_positions` (`text[] NOT NULL DEFAULT '{}'::text[]`) to `vifutboldev.players`, and updating `vifutboldev.complete_role_profile` RPC to persist, link by `normalized_document_id` (raising `DOCUMENT_ALREADY_LINKED` on conflict), update harmonized `full_name`, and return all fields in `role_profile` JSONB in `supabase/migrations/202611170002_player_personal_profile_fields.sql`

---

## Phase 2: Foundational (Core Domain Entities, Services & Auth Persistence Pipeline)

**Purpose**: Core domain types, Colombia DANE catalog, utilities, and auth/repository persistence updates required across all user stories

**⚠️ CRITICAL**: Complete this phase before implementing User Story UI screens

- [X] T004 [P] Create `PlayerSex` (`male`, `female`, `other`, tolerant `fromRaw` supporting `'M'`/`'F'`/`'Masculino'`/`'Femenino'`/`'Otro'`) and `BloodType` (`O+`, `O-`, `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`) enums in `lib/domain/entities/player_personal_enums.dart`
- [X] T005 [P] Create `DetailedFootballPosition` enum containing all 15 official positions (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`) with `code`, `tacticalLine` (`PlayerPosition`), and `fromCode` parser in `lib/domain/entities/detailed_football_position.dart`
- [X] T006 [P] Create complete static DANE catalog of all 32 departments of Colombia + `Bogotá, D.C.` and their ~1,122 official municipalities in `lib/domain/data/colombia_municipalities_data.dart` and query/search service `ColombiaLocationCatalog` (`departments`, `municipalitiesFor`, accent-insensitive `searchDepartments`, `searchMunicipalities`, `isValidPair`) in `lib/domain/entities/colombia_location_catalog.dart`
- [X] T007 [P] Create `PlayerPersonalDataUtils` with exact completed-years `calculateAge(birthDate, {referenceDate})`, `composeFullName({firstName, secondName, firstSurname, secondSurname})` (trimming & omitting empty optionals without double spaces), and `derivePrimaryPosition(List<DetailedFootballPosition>)` in `lib/domain/services/player_personal_data_utils.dart`
- [X] T008 Extend `RoleProfileData` with `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `primaryPosition`, and `secondaryPositions` (`List<String>`, default `const []`) including `copyWith`, `toJson`, `fromJson` (camel & snake keys), and equality in `lib/domain/entities/role_profile_data.dart`, and update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.player` to require `phone`, `documentId`, `firstName`, `firstSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, and `secondaryPositions.isNotEmpty` in `lib/domain/entities/user_account.dart`
- [X] T009 Add optional `String? fullName` parameter to `AuthRepository.updateRoleProfile` in `lib/domain/repositories/auth_repository.dart` and forward it in `AuthController.updateRoleProfile` in `lib/application/controllers/auth_controller.dart`
- [X] T010 [P] Update `LocalAuthRepository.updateRoleProfile` in `lib/infrastructure/auth/local_auth_repository.dart` to persist `fullName` and merge all new player `RoleProfileData` fields into local session & stored accounts
- [X] T011 [P] Update `SupabaseAuthRepository` (`_PostgrestUserProfileDataSource.completeRoleProfile`, `fetchRoleProfileDetails`, and `updateRoleProfile`) in `lib/infrastructure/auth/supabase_auth_repository.dart` to pass `fullName` and all 11 player fields to the `complete_role_profile` RPC and hydrate them from `vifutboldev.players`

**Checkpoint**: Foundation ready — domain models, DANE catalog, age/name utilities, and persistence layers are complete

---

## Phase 3: User Story 1 - Diligenciamiento y Guardado de Ficha Personal y Deportiva Completa (Priority: P1) 🎯 MVP

**Goal**: Deliver the dedicated full-screen `PlayerPersonalDataScreen` accessible from `"Completar mi perfil"` and the permanent `"Datos Personales"` tile in `ProfileTabView`, supporting form validation, preloading existing values, harmonized `fullName` update, document linking/conflict feedback, offline guard, unsaved-changes confirmation, and anti-double-submit protection.

**Independent Test**: Open `/profile/personal-data` as `UserRole.player` from `ProfileTabView`, fill all mandatory fields (document ≥5 chars, phone ≥7 digits, firstName, firstSurname, sex, birthDate, bloodType, department, municipality, ≥1 position), save, verify `UserAccount.isProfileCompleteForActiveRole` becomes `true`, harmonized `fullName` updates without double spaces, and reopening preloads saved values.

### Tests for User Story 1

- [X] T012 [P] [US1] Update and expand unit tests for `UserAccount.isProfileCompleteForActiveRole` (verifying `UserRole.player` requires phone + all mandatory HU 21.1 fields while other roles remain unaffected) and `RoleProfileData` serialization in `test/domain/entities/user_account_test.dart`
- [X] T013 [P] [US1] Update and expand infrastructure unit tests verifying `SupabaseAuthRepository.updateRoleProfile` forwards `fullName` and all player personal/tactical fields to `complete_role_profile`, hydrates them on `restoreSession`, enforces connectivity (`OfflineAuthOperationFailure`), and maps `DOCUMENT_ALREADY_LINKED` -> `DocumentAlreadyLinkedFailure` in `test/infrastructure/auth/supabase_auth_repository_test.dart`

### Implementation for User Story 1

- [X] T014 [US1] Create `PlayerPersonalDataScreen` with all required widget keys (`player_personal_data_screen`, `player_form_document_field`, `player_form_phone_field`, `player_form_first_name_field`, `player_form_second_name_field`, `player_form_first_surname_field`, `player_form_second_surname_field`, `player_form_sex_selector`, `player_form_birth_date_field`, `player_form_age_field`, `player_form_blood_type_selector`, `player_form_department_selector`, `player_form_municipality_selector`, `player_form_save_button`, `player_personal_data_error_banner`), existing-data preload, `PopScope` unsaved-changes guard, double-submit lock, and future-ready `applyDocumentScanData(...)` helper in `lib/presentation/shell/tabs/player_personal_data_screen.dart`
- [X] T015 [US1] Register `/profile/personal-data` route in `lib/presentation/navigation/app_router.dart` and update `lib/presentation/shell/tabs/profile_tab_view.dart` so `UserRole.player` navigates to `/profile/personal-data` from both `"Completar mi perfil"` (`profile_complete_action_button`) and the permanent `"Datos Personales"` card (`Key('profile_personal_data_tile')`), keeping `CompleteProfileDialog` for all other roles
- [X] T016 [US1] Create widget tests covering `PlayerPersonalDataScreen` (rendering all fields, mandatory field validation, harmonized `fullName` submission, preloading existing values, unsaved-changes confirmation dialog, offline & document-conflict error banners, and 320px/130% text-scale layout without overflow) in `test/presentation/shell/player_personal_data_screen_test.dart`, and update existing player profile button test expectations in `test/presentation/shell/complete_profile_dialog_test.dart`

**Checkpoint**: User Story 1 delivers the full dedicated screen and persistence flow independently

---

## Phase 4: User Story 2 - Cálculo Reactivo de Edad y Selección en Cascada de Ubicación en Colombia (Priority: P1)

**Goal**: Provide instant, exact read-only Age calculation on birth-date selection and searchable cascading selection over all 32 Colombian departments + Bogotá D.C. (~1,122 DANE municipalities), automatically clearing any incompatible municipality when the department changes.

**Independent Test**: Verify `PlayerPersonalDataUtils.calculateAge` across before/on/after birthday boundaries, verify `ColombiaLocationCatalog` returns all 33 territorial entities with accent-insensitive search, and verify in widget tests that selecting a birth date immediately updates read-only Age and changing Department resets Municipality and filters the Municipality picker exclusively to the chosen department.

### Tests for User Story 2

- [X] T017 [P] [US2] Create unit tests verifying `PlayerPersonalDataUtils.calculateAge` (birthday not yet reached in current year, exact birthday day, birthday passed, leap-year Feb 29) and `composeFullName` (omitting empty secondName/secondSurname, trimming extra spaces) in `test/unit/domain/player_personal_data_utils_test.dart`
- [X] T018 [P] [US2] Create unit tests verifying `ColombiaLocationCatalog` contains 33 entries (32 departments + `Bogotá, D.C.`), >1,100 total municipalities, cascading lookup (`municipalitiesFor`), accent-insensitive search (`"medellin"` -> `"Medellín"`, `"bogota"` -> `"Bogotá, D.C."`), and `isValidPair` in `test/unit/domain/colombia_location_catalog_test.dart`

### Implementation for User Story 2

- [X] T019 [US2] Create reusable `SearchableLocationPickerSheet` modal bottom sheet (`Key('location_picker_search_field')`, `Key('location_picker_list')`, `Key('location_picker_empty_state')`) in `lib/presentation/shell/widgets/searchable_location_picker_sheet.dart` and integrate reactive birth-date -> read-only Age calculation plus cascading searchable Department -> Municipality selection (clearing municipality on department change) inside `lib/presentation/shell/tabs/player_personal_data_screen.dart`
- [X] T020 [US2] Add widget tests verifying reactive read-only Age updates upon birth-date change and cascading searchable Department -> Municipality selection (filtering by department and resetting municipality on department change) in `test/presentation/shell/player_personal_data_screen_test.dart`

**Checkpoint**: User Story 2 verified at unit and widget levels

---

## Phase 5: User Story 3 - Selección Múltiple de Posiciones Específicas de Fútbol y Derivación de Línea Táctica (Priority: P1)

**Goal**: Allow players to select one or more of the 15 official football positions (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`), enforce at least one position selected, and deterministically derive `primaryPosition` (`PlayerPosition`) for squad/roster compatibility.

**Independent Test**: Verify unit mappings for all 15 `DetailedFootballPosition` values to the 4 `PlayerPosition` lines; in widget tests, attempt to submit with zero positions (seeing `Key('player_form_positions_error')`), then toggle multiple chips (e.g. `LD` + `CAD`) and confirm `primaryPosition == PlayerPosition.defender` and `secondaryPositions == ['LD', 'CAD']` are passed to `updateRoleProfile`.

### Tests for User Story 3

- [X] T021 [P] [US3] Create unit tests verifying all 15 `DetailedFootballPosition` values, code parsing (`fromCode`), mapping to `PlayerPosition` (`goalkeeper`, `defender`, `midfielder`, `forward`), and `PlayerPersonalDataUtils.derivePrimaryPosition` in `test/unit/domain/detailed_football_position_test.dart`

### Implementation for User Story 3

- [X] T022 [US3] Wire multi-select `FilterChip` position groups (`Key('player_form_position_chip_<CODE>')` grouped by Portero / Defensas / Mediocampistas / Delanteros), mandatory ≥1 validation message (`Key('player_form_positions_error')`), and primary tactical line derivation in `lib/presentation/shell/tabs/player_personal_data_screen.dart`
- [X] T023 [US3] Add widget tests verifying multi-position chip toggling, validation rejection when zero positions are selected, and correct `primaryPosition` + `secondaryPositions` persistence payload in `test/presentation/shell/player_personal_data_screen_test.dart`

**Checkpoint**: All 3 user stories (US1, US2, US3) pass independently and together

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Static analysis, regression verification, and final quality gate

- [X] T024 Run `flutter analyze` and resolve any warnings or errors across the repository
- [X] T025 Run full automated test suite (`flutter test test/unit/domain/player_personal_data_utils_test.dart test/unit/domain/colombia_location_catalog_test.dart test/unit/domain/detailed_football_position_test.dart test/domain/entities/user_account_test.dart test/infrastructure/auth/supabase_auth_repository_test.dart test/presentation/shell/complete_profile_dialog_test.dart test/presentation/shell/player_personal_data_screen_test.dart`) and verify 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: `T001` -> `T002`; `T003` [P] runs in parallel with `T001`/`T002`.
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T004`, `T005`, `T006`, `T007` run in parallel -> `T008` -> `T009` -> `T010` [P] & `T011` [P]).
- **Phase 3 (US1)**, **Phase 4 (US2)**, **Phase 5 (US3)**: Depend on Phase 2 completion. Note: `T019` (SearchableLocationPickerSheet) and `T022` (multi-position chips) integrate into `player_personal_data_screen.dart` sequentially alongside `T014` (or `T019` can be built immediately before `T014` so the screen compiles cleanly in one cohesive pass).
- **Phase 6 (Polish)**: Depends on Phases 1–5 (`T024` -> `T025`).

### Parallel Opportunities

- **Phase 1**: `T003` (SQL migration) in parallel with `T001` (l10n keys).
- **Phase 2**: `T004`, `T005`, `T006`, `T007` all create independent domain files in parallel; `T010` and `T011` update independent repository adapters in parallel.
- **Unit tests across stories**: `T012`, `T013`, `T017`, `T018`, `T021` target independent test files and can run in parallel.

### Implementation Strategy

1. Complete **Phase 1** (l10n + SQL migration) and **Phase 2** (domain primitives, Colombia DANE catalog, `RoleProfileData`/`UserAccount`, auth repositories).
2. Build `SearchableLocationPickerSheet` (`T019`) and `PlayerPersonalDataScreen` (`T014` + `T022`) + routing/profile integration (`T015`), ensuring all 3 P1 user stories work cohesively.
3. Verify all unit, infrastructure, widget, and responsive tests (`T012`, `T013`, `T016`, `T017`, `T018`, `T020`, `T021`, `T023`) and close with `T024` (`flutter analyze`) and `T025` (full `flutter test` suite).
