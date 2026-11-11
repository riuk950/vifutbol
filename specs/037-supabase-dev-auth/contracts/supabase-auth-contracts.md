# Contracts: Repositorio Remoto de Autenticación y Trigger `auth.users` (HU 17.3)

**Feature**: `037-supabase-dev-auth`  
**Date**: 2026-11-11  

---

## 1. Trigger SQL de Creación Automática de Perfil (`supabase/migrations/202611110005_auth_user_accounts_trigger.sql`)

```sql
CREATE OR REPLACE FUNCTION vifutboldev.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_full_name text;
  v_email text;
BEGIN
  v_email := lower(trim(COALESCE(NEW.email, '')));
  v_full_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    NULLIF(split_part(v_email, '@', 1), ''),
    'Usuario KickPulse'
  );

  INSERT INTO vifutboldev.user_accounts (
    id,
    auth_user_id,
    full_name,
    email,
    active_role,
    authorized_roles,
    is_guest_fan,
    onboarding_completed
  )
  VALUES (
    NEW.id,
    NEW.id,
    v_full_name,
    v_email,
    'fan',
    ARRAY['fan']::text[],
    false,
    false
  )
  ON CONFLICT (auth_user_id) DO NOTHING;

  RETURN NEW;
END;
$$;
```
- Trigger `on_auth_user_created_vifutboldev` (`AFTER INSERT ON auth.users FOR EACH ROW`), protegido con `DROP TRIGGER IF EXISTS ...` para idempotencia.
- Revoca `EXECUTE` de `PUBLIC, anon, authenticated` sobre `vifutboldev.handle_new_auth_user()`.

---

## 2. Contrato de `SupabaseAuthRepository` (`lib/infrastructure/auth/supabase_auth_repository.dart`)

```dart
abstract class SupabaseUserProfileDataSource {
  Future<Map<String, dynamic>?> fetchByAuthUserId(String authUserId);
  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateRoleState({
    required String authUserId,
    required String activeRole,
    required List<String> authorizedRoles,
    required bool onboardingCompleted,
  });
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this.client,
    required this.storage,
    required this.connectivity,
    required this.config,
    SupabaseUserProfileDataSource? profileDataSource,
    String? schema,
  });
}
```

### Reglas de Comportamiento por Método
1. **`signInWithEmail(email, password)`**:
   - Verifica `connectivity.checkConnectivity()`; si desconectado lanza `OfflineAuthOperationFailure`.
   - Ejecuta `client.auth.signInWithPassword(email: normalizedEmail, password: password)`.
   - Obtiene o asegura perfil en `vifutboldev.user_accounts` (`id = user.id`, `auth_user_id = user.id`), persiste caché `AuthSession` en `storage` (`auth_session`) y retorna `AuthSession`.
2. **`registerAccount(fullName, email, password)`**:
   - Verifica conectividad; lanza `OfflineAuthOperationFailure` si desconectado.
   - Ejecuta `client.auth.signUp(email: normalizedEmail, password: password, data: {'full_name': trimmedName})`.
   - Si `response.session == null`: lanza `EmailVerificationRequiredFailure` sin guardar sesión local.
   - Si `response.session != null`: asegura perfil en `vifutboldev.user_accounts` (`onboarding_completed = false`), persiste caché local y retorna `AuthSession`.
3. **`restoreSession()`**:
   - Revisa `client.auth.currentSession`:
     - Si existe: refresca si expiró y hay conectividad (`refreshSession()`), consulta/sincroniza perfil en `vifutboldev.user_accounts` (si falla por red, usa el caché `auth_session`), guarda copia actualizada en `storage` y retorna `AuthSession`.
     - Si `currentSession == null`: busca caché local; si `session.isGuestFan` es `true`, la retorna; de lo contrario retorna `null`.
4. **`completeRoleOnboarding(userId, selectedRole, authorizationCode)`**:
   - Valida `officialAuthorizationCode` en `AppEnvironment.production` para roles oficiales.
   - En DEV permite seleccionar cualquiera de los 5 roles.
   - Actualiza `active_role`, `authorized_roles`, `onboarding_completed = true` en `vifutboldev.user_accounts` y actualiza caché local.
5. **`switchActiveRole(userId, targetRole)`**:
   - En `AppEnvironment.production`, verifica que `targetRole` exista en `authorizedRoles` (`UnauthorizedRoleFailure`).
   - En DEV permite alternar libremente persistiendo el cambio en `vifutboldev.user_accounts` y caché local.
6. **`continueAsGuestFan()`**:
   - Opera offline sin llamar a `client.auth`, creando sesión `UserAccount.guestFan` persistida localmente.
7. **`signOut()`**:
   - Intenta `client.auth.signOut()` tolerando fallo de conectividad y limpia siempre el caché `auth_session`.
8. **Traductor de Errores (`_mapAuthException`)**:
   - `invalid_credentials` / `'invalid login credentials'` → `InvalidCredentialsFailure('Correo o contraseña incorrectos.')`
   - `user_already_exists` / `'already registered'` → `InvalidCredentialsFailure('Este correo ya se encuentra registrado.')`
   - `email_not_confirmed` / `'email not confirmed'` → `EmailVerificationRequiredFailure('Debes confirmar tu correo electrónico antes de iniciar sesión.')`
   - `over_request_rate_limit` / status `429` → `AuthRateLimitFailure`
   - Errores de red/timeout → `OfflineAuthOperationFailure`

---

## 3. Contrato de Escucha Reactiva y DI (`authRepositoryProvider` / `AuthController`)

- `AuthRepository` mantiene su contrato base estable y agrega opcionalmente `Stream<AuthSession?> get onSessionStateChanged => const Stream.empty();` (con implementación por defecto no disruptiva en la interfaz abstracta).
- `SupabaseAuthRepository` expone eventos de `client.auth.onAuthStateChange` (`signedOut` -> `null`, `tokenRefreshed` -> sesión actualizada sin exponer token en logs).
- `AuthController` se suscribe limpiamente cancelando en `dispose()`.
- `authRepositoryProvider` selecciona `SupabaseAuthRepository` cuando `config.environment == AppEnvironment.development && config.supabase.isConfigured && supabaseClient != null`; en otro caso retorna `LocalAuthRepository`.
