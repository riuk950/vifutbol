# Data Model: Autenticación y Perfil en `vifutboldev.user_accounts` (HU 17.3)

**Feature**: `037-supabase-dev-auth`  
**Date**: 2026-11-11  

---

## 1. Mapeo Bidireccional `UserAccount` ↔ `vifutboldev.user_accounts`

| Campo Dart (`UserAccount`) | Columna PostgreSQL (`vifutboldev.user_accounts`) | Tipo SQL | Origen / Regla de Mapeo |
|---|---|---|---|
| `id` | `id` (`PRIMARY KEY`) | `uuid` | Igualado al `auth.users(id)` (`NEW.id`) cuando proviene de GoTrue |
| *(vínculo interno Auth)* | `auth_user_id` (`UNIQUE`) | `uuid` | `auth.uid()` / `user.id` de Supabase Auth (`FK -> auth.users(id)`) |
| `fullName` | `full_name` | `text` | `raw_user_meta_data['full_name']` al registrarse; editable en perfil |
| `email` | `email` (`UNIQUE`) | `text` | Normalizado `trim().toLowerCase()` desde `auth.users.email` |
| `activeRole` | `active_role` | `text` | Enum `UserRole.name` (`organizer`, `coach`, `referee`, `player`, `fan`), default `'fan'` |
| `authorizedRoles` | `authorized_roles` | `text[]` | Array de `UserRole.name`, siempre incluye `active_role` y `'fan'` |
| `isGuestFan` | `is_guest_fan` | `boolean` | `false` para cuentas GoTrue; `true` solo en sesiones locales de invitado |
| `onboardingCompleted` | `onboarding_completed` | `boolean` | `false` al registrarse; `true` tras `completeRoleOnboarding()` |

---

## 2. Mapeo `AuthSession` ↔ Supabase `Session`

| Campo `AuthSession` | Origen Supabase Auth (`GoTrue`) | Notas de Seguridad / Fallback |
|---|---|---|
| `sessionId` | `'supa-${session.user.id}'` o hash/identificador de sesión | Identificador estable sin exponer el JWT completo |
| `user` | Fila de `vifutboldev.user_accounts` + fallback metadata | Prioriza valores de `vifutboldev.user_accounts` |
| `sessionToken` | `session.accessToken` | Redactado siempre como `[REDACTED]` en `toSafeDiagnosticMap()` y `toString()` |
| `authenticatedAt` | `DateTime.now().toUtc()` o timestamp de sesión | Persistido en caché local para fallback offline |

---

## 3. Reglas de Estado y Transiciones

1. **Registro (`registerAccount`)**:
   - Precondición: conectividad activa (`OfflineAuthOperationFailure` si desconectado).
   - `supabase.auth.signUp(email: normalizedEmail, password: password, data: {'full_name': trimmedName})`.
   - Trigger `on_auth_user_created_vifutboldev` inserta en `vifutboldev.user_accounts` con `id = auth_user_id = NEW.id`, `active_role = 'fan'`, `authorized_roles = ['fan']`, `onboarding_completed = false`.
   - Si `response.session == null`: lanza `EmailVerificationRequiredFailure` (no guarda sesión local).
   - Si `response.session != null`: garantiza perfil en `vifutboldev.user_accounts`, guarda `AuthSession` en `LocalStorageRepository` y retorna `AuthSession`.
2. **Inicio de Sesión (`signInWithEmail`)**:
   - Precondición: conectividad activa.
   - `supabase.auth.signInWithPassword(email: normalizedEmail, password: password)`.
   - Obtiene/asegura perfil en `vifutboldev.user_accounts`, persiste caché local y retorna `AuthSession`.
3. **Restauración (`restoreSession`)**:
   - Si `supabase.auth.currentSession` existe:
     - Si conectado y próximo a expirar o expirado, ejecuta `supabase.auth.refreshSession()`.
     - Sincroniza fila de `vifutboldev.user_accounts`, actualiza caché local y retorna `AuthSession`.
     - Si falla por red / timeout estando offline: recurre al caché local (`LocalStorageRepository` `auth_session`) sin cerrar la sesión.
   - Si `currentSession == null`: revisa si existe sesión local de **Aficionado Invitado** (`isGuestFan == true`); si existe, la restaura. En caso contrario retorna `null`.
4. **Onboarding y Cambio de Rol (`completeRoleOnboarding`, `switchActiveRole`)**:
   - En producción valida código oficial para `organizer` y `referee`.
   - En DEV permite seleccionar/cambiar entre los 5 roles libremente (Clarificación Q3).
   - Persiste `active_role`, `authorized_roles` y `onboarding_completed` en `vifutboldev.user_accounts` y actualiza caché local.
5. **Cierre de Sesión (`signOut`)**:
   - Ejecuta `supabase.auth.signOut()` de forma segura (ignorando fallo de red si está offline) y limpia invariablemente `auth_session` en `LocalStorageRepository`.

---

## 4. Fallos Tipados (`lib/domain/failures/app_failure.dart`)

- **`EmailVerificationRequiredFailure`** *(NUEVO)*: `'Cuenta creada. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.'`
- **`InvalidCredentialsFailure`**: credenciales inválidas (`invalid_credentials` / `Invalid login credentials`), correo ya registrado (`user_already_exists` / `already registered`) o sesión no encontrada.
- **`AuthRateLimitFailure`**: límite de intentos excedido (`over_request_rate_limit` / HTTP 429).
- **`OfflineAuthOperationFailure`**: sin conexión (`connectivity.isDisconnected` o `SocketException`/`TimeoutException`).
- **`UnauthorizedRoleFailure`**: intento no autorizado de activar rol en producción.
- **`InvalidAuthorizationCodeFailure`**: código oficial inválido en producción.
