---

description: "Actionable task list for HU 24.3 — Eliminación de Cuenta con Borrado en Cascada (Local y Nube)"
---

# Tasks: Eliminación de Cuenta con Borrado en Cascada (Local y Nube)

**Input**: Design documents from `/specs/056-account-cascade-deletion/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/delete_account_contract.md`, `quickstart.md`

**Tests**: Incluidas de forma obligatoria según Principio III de la Constitución y checklist técnico de HU 24.3.

**Organization**: Las tareas están agrupadas por fases y por historia de usuario (`US1`, `US2`, `US3`) para habilitar implementación y verificación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias sobre tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (`[US1]`, `[US2]`, `[US3]`)
- Todas las tareas incluyen rutas exactas de archivo relativas al repositorio

---

## Phase 1: Setup (Localization & SQL Migration)

**Purpose**: Preparar las llaves de localización en español y la migración SQL del RPC `SECURITY DEFINER` antes de cablear las capas de la app

- [X] T001 [P] Add Spanish localization keys for the delete account button (`Eliminar cuenta`), irreversible confirmation dialog title/warning/buttons, loading state, offline connectivity error, and generic failure message in `lib/l10n/app_es.arb`
- [X] T002 [P] Create idempotent SQL migration defining `SECURITY DEFINER` RPC `vifutboldev.delete_my_account()` (validating `auth.uid()`, unlinking PII via `SET NULL` on tournament-enrolled `players` and `match_referees`, deleting free-agent `players`, deleting `user_accounts` with FK cascades, deleting `storage.objects` in `player-avatars` and `player-documents`, and deleting `auth.users`, granted only to `authenticated` and `service_role`) in `supabase/migrations/202611250001_delete_user_account_cascade.sql`
- [X] T003 Regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` by running `flutter gen-l10n` (depends on T001)

**Checkpoint**: Localización y migración SQL listas.

---

## Phase 2: Foundational (Domain Contract & Use Case)

**Purpose**: Extender el contrato de dominio y crear el caso de uso dedicado de eliminación de cuenta antes de implementar los adaptadores y la UI

- [X] T004 Add `Future<void> deleteAccount({required String userId});` to `AuthRepository` contract in `lib/domain/repositories/auth_repository.dart`
- [X] T005 Create `DeleteAccountUseCase` rejecting guest sessions (`user.isGuestFan == true`) with `InvalidCredentialsFailure` and delegating to `authRepository.deleteAccount(userId: user.id)` in `lib/application/use_cases/delete_account_use_case.dart` (depends on T004)
- [X] T006 Wire `deleteAccountUseCaseProvider` and pass it (optional/defaulted for test compatibility) to `AuthController` in `lib/application/providers/auth_providers.dart` (depends on T005)

**Checkpoint**: Contrato de dominio y caso de uso listos.

---

## Phase 3: User Story 1 - Eliminación Permanente de Cuenta en Cascada (Nube y Local) (Priority: P1) 🎯 MVP

**Goal**: Ejecutar el borrado en cascada en la nube (`delete_my_account` RPC) y la purga total del almacenamiento local (`storage.clearNamespace()` + borrado de archivos locales), transicionando a `AuthStatus.unauthenticated` y mostrando el botón destructivo `Eliminar cuenta` únicamente a usuarios autenticados en `ProfileTabView`.

**Independent Test**: Con un usuario autenticado y conexión a internet, confirmar la eliminación en `ProfileTabView`, verificar la llamada al RPC remoto, la limpieza total de Hive/namespace y archivos locales, y la transición a `AuthStatus.unauthenticated` (y confirmar que el botón está oculto en modo visitante).

### Implementation for User Story 1

- [X] T007 [P] [US1] Implement `deleteAccount({required String userId})` in `SupabaseAuthRepository` (adding `deleteAccount()` to its profile data source invoking `rpc('delete_my_account')`, checking connectivity first, deleting local avatar/document files on success, invoking `storage.clearNamespace()`, and best-effort `client.auth.signOut()`) in `lib/infrastructure/auth/supabase_auth_repository.dart`
- [X] T008 [P] [US1] Implement `deleteAccount({required String userId})` in `LocalAuthRepository` (verifying non-guest active session, deleting existing local avatar/document files, and invoking `storage.clearNamespace()` to purge session, local accounts, passwords, outbox, and caches) in `lib/infrastructure/auth/local_auth_repository.dart`
- [X] T009 [US1] Implement `deleteAccount()` in `AuthController` (guarding `session != null`, `!isGuestFan`, and `single-flight` via `state.isSubmitting`; invoking `DeleteAccountUseCase`/`authRepository.deleteAccount`; transitioning to `AuthFlowState(status: AuthStatus.unauthenticated, session: null, isSubmitting: false, lastFailure: null)` on success and preserving session with translated `lastFailure` on error) in `lib/application/controllers/auth_controller.dart` (depends on T005, T007, T008)

### Tests for User Story 1

- [X] T010 [P] [US1] Add unit tests for `SupabaseAuthRepository.deleteAccount` verifying remote RPC invocation followed by `storage.clearNamespace()` and `signOut` on success, plus unit tests for `LocalAuthRepository.deleteAccount` verifying complete local namespace purge (session, accounts, passwords, outbox) and local file cleanup in `test/infrastructure/supabase_auth_repository_test.dart` and `test/infrastructure/local_auth_repository_test.dart`
- [X] T011 [P] [US1] Add unit tests for `AuthController.deleteAccount` verifying unauthenticated transition on success and rejection of guest sessions in `test/application/auth_controller_test.dart`

**Checkpoint**: Lógica de borrado en cascada nube + local implementada y cubierta por pruebas unitarias.

---

## Phase 4: User Story 2 - Confirmación Irreversible, Cancelación Segura y Protección contra Doble Envío (Priority: P2)

**Goal**: Presentar en `ProfileTabView` el botón destructivo `Eliminar cuenta` (solo usuarios autenticados) y el diálogo `DeleteAccountDialog` con advertencia irreversible en español, cancelación segura, estado de carga con `PopScope(canPop: false)` y bloqueo `single-flight`.

**Independent Test**: Verificar en `ProfileTabView` que el botón `profile_delete_account_button` solo aparece para usuarios autenticados (oculto a visitantes), que `Cancelar` cierra el diálogo sin mutaciones y que pulsaciones repetidas sobre `Eliminar cuenta` en el diálogo ejecutan exactamente 1 llamada a `deleteAccount`.

### Implementation for User Story 2

- [X] T012 [US2] Create `DeleteAccountDialog` (`ValueKey('delete_account_dialog')`) with Spanish irreversible warning, `Cancelar` (`ValueKey('delete_account_cancel_button')`) and destructive `Eliminar cuenta` (`ValueKey('delete_account_confirm_button')`) buttons, local `_isDeleting` single-flight guard, loading indicator, and `PopScope(canPop: !_isDeleting)` in `lib/presentation/shell/tabs/widgets/delete_account_dialog.dart` (depends on T003, T009)
- [X] T013 [US2] Add destructive `Eliminar cuenta` `KickPulseButton` (`Key('profile_delete_account_button')`, visible only when `!isGuest && user != null`, placed below `profile_logout_action_button`) opening `DeleteAccountDialog` and displaying a Spanish `SnackBar` on failure in `lib/presentation/shell/tabs/profile_tab_view.dart` (depends on T012)

### Tests for User Story 2

- [X] T014 [US2] Add widget tests verifying `profile_delete_account_button` visibility for authenticated users (and hidden for guest fan), safe cancellation in `DeleteAccountDialog` with 0 repository calls, loading + single-flight protection against repeated confirmation taps, and 0 overflow at `TextScaler.linear(1.5)` in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: User Stories 1 y 2 integradas en UI y verificadas de forma independiente.

---

## Phase 5: User Story 3 - Resiliencia Offline y Manejo Seguro de Fallos Remotos (Priority: P3)

**Goal**: Garantizar que ante ausencia de conectividad o error en el servidor remoto durante el borrado en la nube, el borrado local se aborte por completo, la sesión local permanezca intacta y el usuario reciba un mensaje claro en español.

**Independent Test**: Simular estado offline y error del servidor remoto en `SupabaseAuthRepository`, `AuthController` y `ProfileTabView`, comprobando que `storage.clearNamespace()` tiene 0 invocaciones, la sesión permanece autenticada y se muestra el mensaje de error en español.

### Tests for User Story 3

- [X] T015 [P] [US3] Add unit tests in `test/infrastructure/supabase_auth_repository_test.dart` and `test/application/auth_controller_test.dart` verifying offline connectivity throws `OfflineConnectivityFailure` without calling RPC or `clearNamespace()`, remote RPC failure aborts local deletion and preserves session, and concurrent `deleteAccount()` calls are blocked (`single-flight`)
- [X] T016 [P] [US3] Add widget tests in `test/presentation/shell/profile_tab_view_test.dart` verifying offline and remote server errors display a Spanish `SnackBar` message while keeping the authenticated session intact

**Checkpoint**: Todas las historias de usuario (US1, US2, US3) verificadas de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación final de calidad, análisis estático con cero advertencias y ejecución de la suite de `quickstart.md`

- [X] T017 Run static analysis (`flutter analyze lib/domain/repositories/auth_repository.dart lib/application/use_cases/delete_account_use_case.dart lib/application/providers/auth_providers.dart lib/application/controllers/auth_controller.dart lib/infrastructure/auth/ lib/presentation/shell/tabs/ test/application/auth_controller_test.dart test/infrastructure/local_auth_repository_test.dart test/infrastructure/supabase_auth_repository_test.dart test/presentation/shell/profile_tab_view_test.dart`) and resolve any issues so 0 errors and 0 warnings remain
- [X] T018 Run full validation suite per `specs/056-account-cascade-deletion/quickstart.md` (`flutter test test/application/auth_controller_test.dart test/infrastructure/local_auth_repository_test.dart test/infrastructure/supabase_auth_repository_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart`) and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: `T001` y `T002` en paralelo; `T003` depende de `T001`.
- **Phase 2 (Foundational)**: `T004` → `T005` → `T006`.
- **Phase 3 (US1 - P1 MVP)**: `T007` y `T008` en paralelo tras `T004`; `T009` depende de `T005`/`T007`/`T008`; `T010` y `T011` en paralelo tras `T009`.
- **Phase 4 (US2 - P2)**: `T012` → `T013` → `T014`.
- **Phase 5 (US3 - P3)**: `T015` y `T016` en paralelo tras `T013`.
- **Phase 6 (Polish)**: `T017` y `T018` al completar `T001`–`T016`.

### Parallel Opportunities

- `T001` (`app_es.arb`) y `T002` (migración SQL) corren en paralelo.
- `T007` (`supabase_auth_repository.dart`) y `T008` (`local_auth_repository.dart`) corren en paralelo.
- `T010`, `T011`, `T015`, `T016` cubren archivos de prueba distintos y pueden escribirse por lotes en paralelo.

---

## Implementation Strategy

### MVP First (User Story 1)

1. Completar `T001`–`T006` (l10n, migración SQL RPC, dominio y caso de uso).
2. Completar `T007`–`T011` (borrado en cascada nube + local y pruebas unitarias).

### Incremental Delivery

1. MVP (`US1`: `T001`–`T011`) → Borrado en cascada nube/local operativo y probado en capas de dominio, aplicación e infraestructura.
2. Incremento 2 (`US2`: `T012`–`T014`) → Botón destructivo en Perfil, diálogo de confirmación irreversible, cancelación y `single-flight`.
3. Incremento 3 (`US3`: `T015`–`T016`) → Cobertura explícita de modo offline y aborto seguro ante fallos remotos.
4. Cierre (`T017`–`T018`) → Análisis estático y suite completa de pruebas.
