# Research: Autenticación de Usuarios y Perfil en Supabase DEV (HU 17.3)

**Feature**: `037-supabase-dev-auth`  
**Date**: 2026-11-11  
**Branch**: `develop`

---

## 1. Configuración Real de GoTrue en el Servidor DEV (`157.137.227.250`)

- **Decision**: Implementar `SupabaseAuthRepository` usando `supabase.auth` (`GoTrueClient`) para `signInWithPassword`, `signUp`, `currentSession`, `refreshSession`, `signOut` y `onAuthStateChange`, contemplando emisión inmediata de sesión (`AUTOCONFIRM=true`) y confirmación pendiente (`session == null`) mediante `EmailVerificationRequiredFailure`.
- **Rationale**:
  - Inspección verificada sobre `supabase-auth` en Oracle Cloud DEV:
    - `GOTRUE_MAILER_AUTOCONFIRM=true`
    - `GOTRUE_DISABLE_SIGNUP=false`
  - En DEV las cuentas nuevas quedan confirmadas al instante (`response.session != null`), pero mantener el manejo explícito de `session == null` -> `EmailVerificationRequiredFailure` protege la app ante futuros entornos con verificación por correo activa sin modificar la firma `Future<AuthSession> registerAccount(...)` de `AuthRepository` (Clarificación Q2).
- **Alternatives Considered**:
  - *Cambiar `AuthRepository.registerAccount` a `Future<AuthSession?>`*: Descartado en Clarificación Q2 por generar cascada innecesaria sobre `LocalAuthRepository`, `AuthenticateUserUseCase`, `AuthController` y pruebas existentes.

---

## 2. Sincronización Dual entre `auth.users` y `vifutboldev.user_accounts`

- **Decision**: Combinar:
  1. Migración SQL idempotente `202611110005_auth_user_accounts_trigger.sql` en `supabase/migrations/` creando la función trigger `SECURITY DEFINER` (`SET search_path = ''`) `vifutboldev.handle_new_auth_user()` sobre `AFTER INSERT ON auth.users`, asignando `id = NEW.id`, `auth_user_id = NEW.id`, `email = lower(trim(NEW.email))`, `full_name = COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''), split_part(NEW.email, '@', 1))`, `active_role = 'fan'`, `authorized_roles = ARRAY['fan']::text[]`, `is_guest_fan = false`, `onboarding_completed = false` con `ON CONFLICT DO NOTHING`.
  2. Respaldo idempotente en `SupabaseAuthRepository`: al ejecutar `signInWithEmail`, `registerAccount` (si hay sesión) o `restoreSession`, consultar `vifutboldev.user_accounts` por `auth_user_id = user.id`; si no existiera fila (p. ej. usuario creado manualmente en Studio antes del trigger), realizar `upsert` seguro del perfil base.
- **Rationale**:
  - Cumple la Clarificación Q1 garantizando consistencia atómica incluso cuando la sesión aún no existe (`AUTOCONFIRM=false`) y tolerando usuarios creados por consola sin romper RLS (`auth_user_id = (select auth.uid())`).
  - Usar un nombre específico de trigger (`on_auth_user_created_vifutboldev`) evita cualquier colisión con triggers de otros esquemas compartidos en el servidor (`app_futboleros`, `app_vihome`, `public`).
- **Alternatives Considered**:
  - *Solo trigger SQL o solo `upsert` en cliente*: Descartado en Clarificación Q1.

---

## 3. Estrategia de Inyección de Dependencias, Caché Local y `onAuthStateChange`

- **Decision**:
  - En `authRepositoryProvider` (`lib/application/providers/auth_providers.dart`), inyectar `SupabaseAuthRepository` cuando `config.environment == AppEnvironment.development && config.supabase.isConfigured && ref.watch(supabaseClientProvider) != null`; en cualquier otro caso (sin credenciales, offline no inicializado o tests unitarios/widget sin Supabase), retornar `LocalAuthRepository`.
  - Mantener persistencia espejo de `AuthSession` en `LocalStorageRepository` (clave aislada `auth_session`) para permitir fallback offline en `restoreSession()` cuando hay conectividad caída temporalmente, siempre limpiando este caché en `signOut()` o ante evento `AuthChangeEvent.signedOut`.
  - Escuchar `supabase.auth.onAuthStateChange` en `AuthController` (o vía stream callback opcional en `AuthRepository` / `AuthController`) para reaccionar limpiamente ante expiraciones de JWT o cierres remotos de sesión sin acoplar `AuthController` al SDK de Supabase.
- **Rationale**:
  - Preserva 100% de la arquitectura limpia (Principio IV): `AuthController` sigue dependiendo únicamente del contrato de dominio `AuthRepository` (más un stream opcional de invalidación/cambio de sesión sin importar `supabase_flutter` en `domain/`).
  - Permite ejecutar toda la suite existente de pruebas unitarias/widget de `LocalAuthRepository` y `AuthController` sin regresiones.
- **Alternatives Considered**:
  - *Importar `supabase_flutter` directamente en `AuthController`*: Rechazado por violar el Principio IV (Arquitectura Limpia).

---

## 4. Traducción de Errores y Seguridad en Logs

- **Decision**: Mapear `AuthException` (GoTrue) y excepciones de red (`SocketException`, `TimeoutException`, `ClientException`) a fallos tipados de dominio en español (`InvalidCredentialsFailure`, `AuthRateLimitFailure`, `EmailVerificationRequiredFailure`, `OfflineAuthOperationFailure`, `UnauthorizedRoleFailure`) sin incluir JWTs, refresh tokens ni contraseñas en `message` ni en `AuthSession.toSafeDiagnosticMap()`.
- **Rationale**:
  - Cumple los Principios VI (textos de usuario en español) y VII (resiliencia móvil y privacidad en logs) además de `FR-009` y `FR-010`.
