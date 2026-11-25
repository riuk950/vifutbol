# Research Findings: Eliminación de Cuenta con Borrado en Cascada (HU 24.3)

**Feature**: `056-account-cascade-deletion`  
**Date**: 2026-11-25

## Decision 1: Procedimiento RPC `SECURITY DEFINER` (`vifutboldev.delete_my_account()`) para borrado atómico en Supabase

- **Decision**: Implementar una migración SQL `supabase/migrations/202611250001_delete_user_account_cascade.sql` que define `vifutboldev.delete_my_account()` como `SECURITY DEFINER` con `SET search_path = vifutboldev, public, auth, storage`, otorgando `EXECUTE` únicamente al rol `authenticated`.
- **Rationale**:
  - Un cliente móvil con `anonKey` + JWT de usuario NO tiene permisos directos para ejecutar `DELETE FROM auth.users`, pero un RPC `SECURITY DEFINER` que valida `auth.uid()` garantiza que un usuario solo pueda eliminar su propia cuenta de forma atómica en una sola transacción SQL.
  - Sigue exactamente el patrón ya establecido en el proyecto (`complete_role_profile` en migraciones `202611170003` y `202611170004`).
- **Alternatives considered**:
  - *Supabase Edge Function con Service Role Key*: Añade despliegue e infraestructura externa adicional innecesaria cuando el proyecto ya centraliza su lógica transaccional en RPCs de `supabase/migrations/`.

## Decision 2: Matriz exacta de cascada (`DELETE` vs `SET NULL`) en `vifutboldev`

- **Decision**: Tras inspeccionar todas las migraciones existentes (`202611110002`, `202611130001`, `202611170001`, `202611170003`, `202611170004`):
  - **Eliminados en cascada (`DELETE`)**:
    - `vifutboldev.players` donde `user_account_id = v_account_id AND tournament_id IS NULL` (jugadores agente libre sin participación en torneos).
    - `vifutboldev.user_accounts` (`id = v_account_id`), que dispara automáticamente `ON DELETE CASCADE` sobre:
      - `vifutboldev.coach_profiles`
      - `vifutboldev.organizer_profiles`
      - `vifutboldev.fan_profiles`
      - `vifutboldev.fan_favorite_teams`
      - `vifutboldev.team_join_requests` (como `coach_account_id` o `player_account_id`)
    - `storage.objects` en los buckets `player-avatars` y `player-documents` pertenecientes al usuario (`owner = v_auth_uid` o prefijo `v_auth_uid::text || '/%'`).
    - `auth.users` (`id = v_auth_uid`).
  - **Desvinculados / anonimizados (`SET NULL`) para preservar historia compartida (Q2=A)**:
    - `vifutboldev.players` inscritos en torneos (`user_account_id = v_account_id AND tournament_id IS NOT NULL`): `SET user_account_id = NULL, phone = NULL, document_front_url = NULL, document_back_url = NULL, photo_url = NULL`.
    - `vifutboldev.match_referees` (`user_account_id = v_account_id`): `SET user_account_id = NULL, phone = NULL`.
    - Automáticos vía `ON DELETE SET NULL` existentes al eliminar `user_accounts`: `sports_venues.organizer_id`, `tournaments.organizer_id`, `tournament_news.author_user_id`, `teams.coach_id`, `digital_match_reports.closed_by_user_id`.
- **Rationale**: Garantiza 0 datos personales/documentos huérfanos y 100% de integridad referencial en tablas de posiciones y actas oficiales históricas (Principio II).
- **Alternatives considered**:
  - *Borrar en cascada `tournaments` y `teams`*: Descartado explícitamente en `/speckit-clarify` (Q2=A).

## Decision 3: Purga total del almacenamiento local (`storage.clearNamespace()`) y archivos locales

- **Decision**: En `SupabaseAuthRepository.deleteAccount` (solo después de que el RPC remoto retorne éxito) y en `LocalAuthRepository.deleteAccount`:
  1. Eliminar archivos locales de imagen si `photoUrl`, `documentFrontUrl` o `documentBackUrl` apuntan a archivos existentes en disco (no URLs `http`/`https`).
  2. Ejecutar `await storage.clearNamespace()` — en `HiveLocalStorageRepository` esto limpia toda la caja del entorno activo (`${prefix}_preferences`), eliminando simultáneamente `auth_session`, `auth_accounts`, `auth_passwords`, `sync_outbox_items_v1` y todos los cachés de repositorios locales del namespace.
  3. En `SupabaseAuthRepository`, ejecutar `try { await client.auth.signOut(); } catch (_) {}` para invalidar el cliente en memoria (tolerando errores si `auth.users` ya fue borrado).
- **Rationale**: `HiveSyncOutboxRepository` y todos los repositorios locales (`local_*_repository.dart`) persisten en el mismo `LocalStorageRepository`, por lo que `clearNamespace()` garantiza una limpieza atómica y completa sin olvidar ninguna clave.
- **Alternatives considered**:
  - *Borrar claves una por una (`auth_session`, `sync_outbox_items_v1`, etc.)*: Propenso a dejar cachés huérfanos cuando se agregan nuevos repositorios locales.

## Decision 4: Protección `single-flight`, verificación offline y manejo de errores

- **Decision**:
  - `SupabaseAuthRepository.deleteAccount` invoca `_ensureConnectivity('Se requiere conexión a internet para eliminar tu cuenta.')` antes del RPC; si está offline, lanza `OfflineConnectivityFailure` sin modificar nada.
  - Si el RPC falla, `_translateError` convierte la excepción en un `AppFailure` en español (sin tokens ni trazas técnicas) y la relanza **antes** de ejecutar `clearNamespace()`, manteniendo intacta la sesión local.
  - `AuthController.deleteAccount()` revisa `if (state.isSubmitting) return false;`, activa `isSubmitting: true`, invoca `DeleteAccountUseCase` (o `authRepository.deleteAccount`) y en éxito emite `AuthFlowState(status: AuthStatus.unauthenticated, session: null, isSubmitting: false, lastFailure: null)`.
  - `DeleteAccountDialog` usa un estado local `_isDeleting` + `PopScope(canPop: !_isDeleting)` para bloquear botones y cierre durante la ejecución, mostrando `CircularProgressIndicator` en el botón destructivo y un `SnackBar` en `ProfileTabView` si retorna `false` con `lastFailure`.
- **Rationale**: Cumple FR-003 a FR-010 y todos los escenarios Gherkin de HU 24.3.
