---

description: "Actionable, dependency-ordered task list for HU 17.3 (Supabase DEV Auth & vifutboldev profile)"
---

# Tasks: Autenticación de Usuarios y Obtención de Sesión / Perfil en Supabase DEV (HU 17.3)

**Input**: Design documents from `/specs/037-supabase-dev-auth/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/supabase-auth-contracts.md`, `quickstart.md`

**Tests**: Se incluyen tareas de pruebas unitarias automatizadas con `mocktail` por historia de usuario, exigidas por el Principio III de la Constitución y los criterios de éxito `SC-001`–`SC-004` de `spec.md`.

**Organization**: Las tareas están agrupadas por historia de usuario (`US1`–`US4`) para habilitar implementación y verificación independientes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias sobre tareas incompletas).
- **[Story]**: Historia de usuario a la que pertenece la tarea (`[US1]`, `[US2]`, `[US3]`, `[US4]`). Solo en fases de User Stories.
- Todas las descripciones incluyen rutas exactas de archivo.

## Path Conventions

- **Código Flutter/Dart**: `lib/domain/`, `lib/application/`, `lib/infrastructure/`
- **Migraciones SQL**: `supabase/migrations/` (requiere aplicadas previamente las migraciones `202611110001`–`0004` de HU 17.2 para ejecución en vivo sobre DEV)
- **Pruebas automatizadas**: `test/infrastructure/`, `test/application/`, `test/presentation/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar la estructura de migraciones y validar dependencias/herramientas base de Flutter y mocks antes de tocar contratos de dominio o repositorio.

- [X] T001 Create SQL migrations directory if absent and verify `supabase_flutter` and `mocktail` dependencies in `pubspec.yaml` and `supabase/migrations/`
- [X] T002 Verify current auth baseline passes (`flutter analyze` and `flutter test test/infrastructure/local_auth_repository_test.dart test/application/auth_controller_test.dart test/presentation/auth_flow_widget_test.dart`) before edits

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Definir contratos de dominio mínimos, fallo tipado de verificación de correo, trigger SQL idempotente y esqueleto/delegado PostgREST de `SupabaseAuthRepository` que bloquean todas las historias `US1`–`US4`.

**⚠️ CRITICAL**: Ninguna historia de usuario (`US1`–`US4`) puede implementarse sin completar esta fase.

- [X] T003 [P] Add `EmailVerificationRequiredFailure extends AppFailure` with default Spanish message `'Cuenta creada. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.'` in `lib/domain/failures/app_failure.dart`
- [X] T004 [P] Add non-disruptive optional getter `Stream<AuthSession?> get onSessionStateChanged => const Stream.empty();` to `AuthRepository` without altering existing method signatures in `lib/domain/repositories/auth_repository.dart`
- [X] T005 [P] Create idempotent SQL migration defining `vifutboldev.handle_new_auth_user()` (`SECURITY DEFINER`, `SET search_path = ''`, inserting `id = NEW.id`, `auth_user_id = NEW.id`, `email = lower(trim(COALESCE(NEW.email, '')))`, `full_name` fallback to email prefix or `'Usuario KickPulse'`, `active_role = 'fan'`, `authorized_roles = ARRAY['fan']::text[]`, `is_guest_fan = false`, `onboarding_completed = false`, `ON CONFLICT (auth_user_id) DO NOTHING`), trigger `on_auth_user_created_vifutboldev` (`AFTER INSERT ON auth.users`), and `REVOKE EXECUTE` from `PUBLIC, anon, authenticated` in `supabase/migrations/202611110005_auth_user_accounts_trigger.sql`
- [X] T006 Define `SupabaseUserProfileDataSource` abstract interface, default PostgREST implementation (`client.schema(schema).from('user_accounts')`), `SupabaseAuthRepository` constructor skeleton (`client`, `storage`, `connectivity`, `config`, optional `profileDataSource`, optional `schema`), and bidirectional `UserAccount` ↔ `vifutboldev.user_accounts` row mapper enforcing `id = auth_user_id`, normalized `email`, `active_role` in `{organizer, coach, referee, player, fan}` default `'fan'`, `authorized_roles` always including `active_role` and `'fan'`, `is_guest_fan = false`, and `onboarding_completed` in `lib/infrastructure/auth/supabase_auth_repository.dart` (depends on T003, T004)

**Checkpoint**: Fundación lista (`EmailVerificationRequiredFailure`, `AuthRepository.onSessionStateChanged`, trigger SQL `202611110005`, y mapeo `UserAccount` ↔ `vifutboldev.user_accounts` compilando limpiamente).

---

## Phase 3: User Story 1 - Inicio de Sesión en la Nube, Mapeo de Perfil y Gestión de Roles en `vifutboldev` (Priority: P1) 🎯 MVP

**Goal**: Permitir que cualquier usuario en DEV inicie sesión vía `GoTrue`, obtenga o inicialice su perfil en `vifutboldev.user_accounts`, complete onboarding o alterne roles libremente en DEV, y cablear `authRepositoryProvider` automáticamente al backend remoto cuando DEV está configurado.

**Independent Test**: Con `SupabaseClient` y `SupabaseUserProfileDataSource` mockeados, ejecutar `signInWithEmail`, `completeRoleOnboarding` y `switchActiveRole` verificando persistencia en `vifutboldev.user_accounts` y caché local `auth_session`, más selección automática de `SupabaseAuthRepository` en `authRepositoryProvider`.

### Tests for User Story 1

> **NOTE: Escribir primero estas pruebas y confirmar que fallan antes de implementar `US1`**

- [X] T007 [P] [US1] Write unit tests for `signInWithEmail` (normalized email login, fetching existing `vifutboldev.user_accounts` row, idempotent fallback `upsert` when profile row is missing, caching `AuthSession` in `auth_session`), `completeRoleOnboarding` (free 5-role selection in `AppEnvironment.development` vs `officialAuthorizationCode` in `AppEnvironment.production`), and `switchActiveRole` (persisting `active_role`, `authorized_roles`, `onboarding_completed` to `vifutboldev.user_accounts` and local cache) in `test/infrastructure/supabase_auth_repository_test.dart`
- [X] T008 [P] [US1] Create provider DI tests verifying `authRepositoryProvider` selects `SupabaseAuthRepository` when `AppEnvironment.development && config.supabase.isConfigured && supabaseClient != null`, and falls back to `LocalAuthRepository` when unconfigured, `supabaseClient == null`, or non-DEV mode in `test/application/auth_providers_test.dart`

### Implementation for User Story 1

- [X] T009 [US1] Implement `signInWithEmail`, idempotent `_ensureProfileForUser` (query `fetchByAuthUserId` and fallback `upsertProfile` with `id = user.id`, `auth_user_id = user.id`, `is_guest_fan = false`), and `auth_session` cache persistence in `lib/infrastructure/auth/supabase_auth_repository.dart`
- [X] T010 [US1] Implement `completeRoleOnboarding` and `switchActiveRole` in `lib/infrastructure/auth/supabase_auth_repository.dart`, validating `officialAuthorizationCode` (`'VIFUTBOL-PRO-2026'`) only under `AppEnvironment.production`, allowing free selection/switching across all 5 `UserRole` values in `AppEnvironment.development`, ensuring `authorized_roles` always includes `active_role` and `'fan'`, persisting `onboarding_completed = true` via `updateRoleState`, and updating `LocalStorageRepository` (`auth_session`)
- [X] T011 [US1] Update `authRepositoryProvider` to watch `supabaseClientProvider` and return `SupabaseAuthRepository` when `config.environment == AppEnvironment.development && config.supabase.isConfigured && supabaseClient != null` (preserving `LocalAuthRepository` fallback otherwise) in `lib/application/providers/auth_providers.dart` (depends on T009, T010)

**Checkpoint**: User Story 1 funcional y validable independientemente (`signInWithEmail`, perfil `vifutboldev.user_accounts`, roles DEV y DI condicional pasando pruebas unitarias).

---

## Phase 4: User Story 2 - Registro de Cuenta Nueva y Creación Consistente de Perfil en `vifutboldev` (Priority: P1) 🎯 MVP

**Goal**: Registrar cuentas nuevas en `GoTrue` enviando `full_name` en metadata, garantizar la creación consistente del perfil en `vifutboldev.user_accounts` (`onboarding_completed = false`, `active_role = 'fan'`) y manejar limpiamente tanto auto-confirmación DEV como confirmación pendiente por correo (`EmailVerificationRequiredFailure`).

**Independent Test**: Simular `registerAccount` con sesión inmediata (auto-confirmación) y con `response.session == null` (verificación requerida); validar metadata enviado, creación idempotente de fila en `vifutboldev.user_accounts`, devolución de `AuthSession` en el primer caso y lanzamiento de `EmailVerificationRequiredFailure` sin guardar caché local en el segundo.

### Tests for User Story 2

- [X] T012 [P] [US2] Add unit tests for `registerAccount` covering trimmed `full_name` metadata + normalized email `signUp`, immediate session (`AUTOCONFIRM=true`) ensuring `vifutboldev.user_accounts` profile (`active_role = 'fan'`, `authorized_roles = ['fan']`, `onboarding_completed = false`) and `auth_session` cache, plus pending verification (`response.session == null`) throwing `EmailVerificationRequiredFailure` without writing local cache in `test/infrastructure/supabase_auth_repository_test.dart`

### Implementation for User Story 2

- [X] T013 [US2] Implement `registerAccount` in `lib/infrastructure/auth/supabase_auth_repository.dart`: verify active connectivity, invoke `client.auth.signUp(email: normalizedEmail, password: password, data: {'full_name': trimmedName})`, throw `EmailVerificationRequiredFailure` without persisting `auth_session` when `response.session == null`, or run `_ensureProfileForUser` and cache/return `AuthSession` when `response.session != null` (depends on T009)

**Checkpoint**: User Stories 1 y 2 completas: el flujo MVP de registro, inicio de sesión, creación/lectura de perfil en `vifutboldev` y onboarding de rol funciona de principio a fin.

---

## Phase 5: User Story 3 - Restauración Automática de Sesión, Modo Invitado y Cierre de Sesión (Priority: P2)

**Goal**: Restaurar y refrescar sesiones activas al abrir la app sincronizando el perfil remoto desde `vifutboldev.user_accounts` (con fallback seguro al caché local si hay desconexión), mantener operativo el modo "Aficionado Invitado" sin red, y limpiar sesión remota y caché local en `signOut`.

**Independent Test**: Probar `restoreSession` conectado (con refresh y prevalencia de cambios de rol remotos), `restoreSession` offline (retornando caché `auth_session` sin expulsar al usuario), `restoreSession` sin sesión remota pero con invitado local (`isGuestFan == true`), `continueAsGuestFan` offline y `signOut` tolerando fallo de red y borrando `auth_session`.

### Tests for User Story 3

- [X] T014 [P] [US3] Add unit tests for `restoreSession` (active `currentSession` + `refreshSession` when expired/near expiry + remote profile sync overriding stale local role, offline fallback returning cached `auth_session`, guest local fallback when `currentSession == null` and `isGuestFan == true`, returning `null` when absent), `continueAsGuestFan` (offline creation without `GoTrue` calls), and `signOut` (calling remote `signOut()` + always clearing `auth_session` even when network throws) in `test/infrastructure/supabase_auth_repository_test.dart`

### Implementation for User Story 3

- [X] T015 [US3] Implement `restoreSession` in `lib/infrastructure/auth/supabase_auth_repository.dart` checking `client.auth.currentSession`, refreshing expired/expiring JWT via `refreshSession()` when connected, syncing `vifutboldev.user_accounts` (remote state takes precedence), falling back to `LocalStorageRepository` `auth_session` on network/timeout errors, and restoring local guest session (`isGuestFan == true`) when `currentSession == null` (depends on T009)
- [X] T016 [US3] Implement `continueAsGuestFan` (local `UserAccount.guestFan` persisted only in `LocalStorageRepository` without calling `client.auth`) and `signOut` (invoking `client.auth.signOut()` safely ignoring offline exceptions while always clearing `auth_session` cache) in `lib/infrastructure/auth/supabase_auth_repository.dart`

**Checkpoint**: User Story 3 completa: continuidad móvil con conectividad intermitente, invitados offline y cierre de sesión limpio garantizados.

---

## Phase 6: User Story 4 - Manejo Seguro de Errores, Expiración Reactiva y Privacidad en Diagnósticos (Priority: P2)

**Goal**: Traducir toda excepción de `GoTrue`, PostgREST o red a fallos tipados de dominio en español, propagar eventos reactivos de expiración/cierre remoto de sesión (`onAuthStateChange`) hacia `AuthController` sin acoplarlo al SDK Supabase, y garantizar redacción estricta (`[REDACTED]`) de tokens y contraseñas.

**Independent Test**: Simular `AuthException` (`invalid_credentials`, `user_already_exists`, `email_not_confirmed`, `over_request_rate_limit`/429) y `SocketException`/`TimeoutException`, verificar eventos `AuthChangeEvent.signedOut` / `tokenRefreshed` actualizando `AuthController` y cancelar suscripción en `dispose()`, y comprobar que `toSafeDiagnosticMap()`, `toString()` y mensajes de fallo jamás incluyen JWTs o contraseñas.

### Tests for User Story 4

- [X] T017 [P] [US4] Add unit tests for error translation (`_mapAuthException` & network/timeout mapping to `InvalidCredentialsFailure`, `EmailVerificationRequiredFailure`, `AuthRateLimitFailure`, `OfflineAuthOperationFailure`), reactive `onSessionStateChanged` bridging `client.auth.onAuthStateChange` (`signedOut` -> `null` + clears cache, `tokenRefreshed` -> updated `AuthSession`), and strict JWT/password redaction (`[REDACTED]` in `toSafeDiagnosticMap()`, `toString()`, and `AppFailure.message`) in `test/infrastructure/supabase_auth_repository_test.dart`
- [X] T018 [P] [US4] Add unit tests verifying `AuthController` subscribes to `authRepository.onSessionStateChanged`, transitions to unauthenticated state when remote `null` arrives, updates session when refreshed session arrives, and cancels the subscription on `dispose()` in `test/application/auth_controller_test.dart`

### Implementation for User Story 4

- [X] T019 [US4] Implement `_mapAuthException` and connectivity/timeout error translator (`invalid_credentials`/`Invalid login credentials` -> `InvalidCredentialsFailure`, `user_already_exists`/`already registered` -> `InvalidCredentialsFailure`, `email_not_confirmed`/`Email not confirmed` -> `EmailVerificationRequiredFailure`, `over_request_rate_limit`/HTTP `429` -> `AuthRateLimitFailure`, `SocketException`/`TimeoutException` -> `OfflineAuthOperationFailure`, stripping any raw token/password strings) in `lib/infrastructure/auth/supabase_auth_repository.dart`
- [X] T020 [US4] Implement `onSessionStateChanged` stream in `lib/infrastructure/auth/supabase_auth_repository.dart` bridging `client.auth.onAuthStateChange` (`AuthChangeEvent.signedOut` -> clears `auth_session` and emits `null`, `AuthChangeEvent.tokenRefreshed` -> emits refreshed `AuthSession` and updates cache without logging raw JWTs)
- [X] T021 [US4] Subscribe `AuthController` to `authRepository.onSessionStateChanged` during initialization and cancel the `StreamSubscription` cleanly in `dispose()` in `lib/application/controllers/auth_controller.dart` (depends on T004, T020)

**Checkpoint**: Todas las historias (`US1`–`US4`) están completas y protegidas contra fugas de credenciales y sesiones expiradas.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verificación integral de formato, análisis estático, regresión completa de autenticación y checklist E2E documentado.

- [X] T022 Run `dart format --output=none --set-exit-if-changed lib/ test/` and `flutter analyze` resolving any lint or formatting findings across modified files
- [X] T023 Execute consolidated automated auth test suite (`flutter test test/infrastructure/supabase_auth_repository_test.dart test/infrastructure/local_auth_repository_test.dart test/application/auth_providers_test.dart test/application/auth_controller_test.dart test/presentation/auth_flow_widget_test.dart`) and confirm 100% pass rate
- [X] T024 Update/verify end-to-end validation steps in `specs/037-supabase-dev-auth/quickstart.md` confirming exact alignment with implemented migration `202611110005_auth_user_accounts_trigger.sql` and repository behavior (noting prerequisite deployment of HU 17.2 migrations `202611110001`–`0004` before live DEV DB run)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — inicia inmediatamente (`T001` → `T002`).
- **Foundational (Phase 2)**: Depende de Setup — **BLOQUEA** todas las historias `US1`–`US4` (`T003`, `T004`, `T005` en paralelo → `T006`).
- **User Stories (Phase 3–6)**: Todas dependen de completar Foundational (Phase 2):
  - **US1 (P1)**: `T007`/`T008` (tests) → `T009` → `T010` → `T011`.
  - **US2 (P1)**: Depende de `T009` (`_ensureProfileForUser` y manejo de sesión) — `T012` → `T013`.
  - **US3 (P2)**: Depende de `T009` (`_ensureProfileForUser` y caché local) — `T014` → `T015`/`T016`.
  - **US4 (P2)**: Depende de `T004`/`T006` y puede ejecutarse tras o en paralelo con US2/US3 respetando archivos compartidos (`T017`/`T018` → `T019` → `T020` → `T021`).
- **Polish (Phase 7)**: Depende de todas las historias completadas (`T022` → `T023` → `T024`).

### Within Each User Story

1. Escribir las pruebas unitarias primero y confirmar fallo esperado (TDD / Principio III).
2. Implementar helpers/métodos en `SupabaseAuthRepository` (`lib/infrastructure/auth/supabase_auth_repository.dart`).
3. Integrar con capa `application/` (`auth_providers.dart`, `auth_controller.dart`) según corresponda.
4. Confirmar pruebas verdes antes de pasar a la siguiente historia.

### Parallel Opportunities

- **Foundational**: `T003` (`app_failure.dart`), `T004` (`auth_repository.dart`) y `T005` (`202611110005_auth_user_accounts_trigger.sql`) tocan archivos totalmente distintos y pueden ejecutarse en paralelo.
- **User Story 1**: `T007` (`supabase_auth_repository_test.dart`) y `T008` (`auth_providers_test.dart`) son paralelizables.
- **User Story 4**: `T017` (`supabase_auth_repository_test.dart`) y `T018` (`auth_controller_test.dart`) pueden redactarse en paralelo antes de implementar `T019`–`T021`.

---

## Parallel Example: Foundational & User Story 1

```bash
# Foundational parallel batch (3 distinct files):
Task T003: "Add EmailVerificationRequiredFailure in lib/domain/failures/app_failure.dart"
Task T004: "Add onSessionStateChanged getter in lib/domain/repositories/auth_repository.dart"
Task T005: "Create SQL trigger migration in supabase/migrations/202611110005_auth_user_accounts_trigger.sql"

# User Story 1 test batch (2 distinct test files):
Task T007: "Write SupabaseAuthRepository US1 unit tests in test/infrastructure/supabase_auth_repository_test.dart"
Task T008: "Write authRepositoryProvider DI tests in test/application/auth_providers_test.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 — P1)

1. Completar **Phase 1: Setup** (`T001`–`T002`) y **Phase 2: Foundational** (`T003`–`T006`).
2. Completar **Phase 3: US1** (`T007`–`T011`) + **Phase 4: US2** (`T012`–`T013`).
3. **STOP & VALIDATE**: Ejecutar pruebas de `supabase_auth_repository_test.dart` y `auth_providers_test.dart`; validar inicio de sesión, registro y persistencia de rol en `vifutboldev.user_accounts`.

### Incremental Delivery (User Stories 3 & 4 — P2)

4. Agregar **Phase 5: US3** (`T014`–`T016`) para restauración de sesión, fallback offline, modo invitado y cierre de sesión.
5. Agregar **Phase 6: US4** (`T017`–`T021`) para traducción completa de errores, listener `onAuthStateChange` y redacción de tokens.
6. Cerrar con **Phase 7: Polish** (`T022`–`T024`) ejecutando formato, análisis estático y toda la suite de autenticación.

---

## Notes

- Todos los archivos en `lib/infrastructure/auth/local_auth_repository.dart` y pruebas existentes de widget (`test/presentation/auth_flow_widget_test.dart`) deben permanecer verdes sin regresiones porque `authRepositoryProvider` mantiene `LocalAuthRepository` cuando Supabase no está configurado o `supabaseClient == null`.
- La ejecución real de `supabase/migrations/202611110005_auth_user_accounts_trigger.sql` sobre la base de datos DEV queda sujeta a haber aplicado primero las migraciones `202611110001`–`0004` de **HU 17.2** (`specs/036-supabase-vifutboldev-schema`).
