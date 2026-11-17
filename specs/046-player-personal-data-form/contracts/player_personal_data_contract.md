# UI, Repository & RPC Contracts: Formulario de Datos Personales del Jugador (HU 21.1)

**Feature**: `046-player-personal-data-form`

## 1. Navigation & Entry Points Contract

- **Route**: `/profile/personal-data` registered in `AppRouter` (`lib/presentation/navigation/app_router.dart`) -> renders `PlayerPersonalDataScreen`.
- **Entry Point 1 (Incomplete Profile Banner)**: In `ProfileTabView`, tapping `ValueKey('profile_complete_action_button')` (`"Completar mi perfil"`):
  - When `activeRole == UserRole.player`: navigates via `Navigator.of(context).pushNamed('/profile/personal-data')`.
  - For all other roles: opens `CompleteProfileDialog.show(context, user: user)`.
- **Entry Point 2 (Permanent Tile)**: In `ProfileTabView`, for authenticated users with `activeRole == UserRole.player` (or `authorizedRoles.contains(UserRole.player)`), render card tile `Key('profile_personal_data_tile')` with label `l10n.profilePersonalDataTile` (`"Datos Personales"`) navigating to `/profile/personal-data`.

## 2. UI Component Contract (`PlayerPersonalDataScreen`)

Ubicación: `lib/presentation/shell/tabs/player_personal_data_screen.dart`

### Widget Keys Requeridas
- Screen scroll container: `Key('player_personal_data_screen')`
- Error banner (when save fails): `Key('player_personal_data_error_banner')`
- Form inputs:
  - `Key('player_form_document_field')` — Número de documento (obligatorio, ≥ 5 caracteres)
  - `Key('player_form_phone_field')` — Teléfono (obligatorio, ≥ 7 dígitos)
  - `Key('player_form_first_name_field')` — Primer nombre (obligatorio)
  - `Key('player_form_second_name_field')` — Segundo nombre (opcional)
  - `Key('player_form_first_surname_field')` — Primer apellido (obligatorio)
  - `Key('player_form_second_surname_field')` — Segundo apellido (opcional)
  - `Key('player_form_sex_selector')` — Sexo (`Masculino`, `Femenino`, `Otro`)
  - `Key('player_form_birth_date_field')` — Selector de Fecha de nacimiento
  - `Key('player_form_age_field')` — Campo Edad calculada de solo lectura
  - `Key('player_form_blood_type_selector')` — Selector de Tipo de sangre / RH (8 opciones)
  - `Key('player_form_department_selector')` — Selector buscable de Departamento de Colombia
  - `Key('player_form_municipality_selector')` — Selector buscable de Municipio (cascada)
  - `Key('player_form_position_chip_<CODE>')` — `FilterChip` para cada posición (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`)
  - `Key('player_form_positions_error')` — Mensaje de validación cuando no hay posiciones seleccionadas
  - `Key('player_form_save_button')` — Botón de guardar con estado `isLoading` anti-doble envío

### Searchable Location Picker (`SearchableLocationPickerSheet`)
- `Key('location_picker_search_field')` — Input de búsqueda de texto
- `Key('location_picker_list')` — Lista filtrada de resultados
- `Key('location_picker_empty_state')` — Estado vacío cuando la búsqueda no arroja coincidencias

## 3. Repository & Controller Contract

### `AuthRepository.updateRoleProfile` & `AuthController.updateRoleProfile`
```dart
Future<UserAccount> updateRoleProfile({
  required String userId,
  required UserRole role,
  String? fullName,
  String? phone,
  String? documentId,
  RoleProfileData? roleProfile,
});
```
- Backward compatible: `fullName` is optional (`String?`).
- When `role == UserRole.player`:
  - `SupabaseAuthRepository`: enforces connectivity (`OfflineAuthOperationFailure`), invokes RPC `complete_role_profile` with all player fields, maps `DOCUMENT_ALREADY_LINKED` -> `DocumentAlreadyLinkedFailure`, caches updated `AuthSession`.
  - `LocalAuthRepository`: enforces connectivity check (consistent with existing implementation), updates `fullName`, `phone`, `documentId`, and merges all `RoleProfileData` fields including player personal/tactical attributes into local storage.

## 4. Future Extension Hook (HU 21.2 Readiness)

- `PlayerPersonalDataScreen` state exposes structured helper `applyDocumentScanData(...)` (or clean controller update methods) accepting `documentId`, `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType` so HU 21.2 (PDF417 + MRZ scan) can populate the form and trigger reactive age recalculation with zero refactoring.
