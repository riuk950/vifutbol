# Quickstart Validation Guide: Autenticación DEV Supabase (HU 17.3)

**Feature**: `037-supabase-dev-auth`  
**Branch**: `develop`  

---

## Prerrequisitos

- Migraciones de **HU 17.2** (`202611110001`..`0004`) aplicadas en `vifutboldev` sobre `supabase-db` (especialmente la tabla `vifutboldev.user_accounts` y exposición PostgREST `PGRST_DB_SCHEMAS`).
- Migración de **HU 17.3** (`202611110005_auth_user_accounts_trigger.sql`) aplicada en `supabase-db`.

---

## 1. Validación Automatizada en Flutter (Mocks `SupabaseClient` / `GoTrueClient`)

```bash
dart format --output=none --set-exit-if-changed lib/ test/
flutter analyze
flutter test \
  test/infrastructure/supabase_auth_repository_test.dart \
  test/infrastructure/local_auth_repository_test.dart \
  test/application/auth_controller_test.dart \
  test/application/auth_providers_test.dart \
  test/presentation/auth_flow_widget_test.dart
```

Resultado esperado: **0 issues** en `flutter analyze`, **0 diferencias de formato**, **100% de pruebas aprobadas**.

---

## 2. Validación End-to-End en Supabase DEV (`https://supabase.artbusinesstechnology.com`)

1. Registrar usuario de prueba en GoTrue (`POST /auth/v1/signup`) con `{"full_name": "Prueba Auth DEV"}` en metadata.
2. Verificar creación automática de fila en `vifutboldev.user_accounts` (`id = auth_user_id`, `onboarding_completed = false`, `active_role = 'fan'`).
3. Iniciar sesión (`POST /auth/v1/token?grant_type=password`), obtener JWT válido y consultar `GET /rest/v1/user_accounts` con `Accept-Profile: vifutboldev` + `Authorization: Bearer <jwt>` → `200 OK`.
4. Actualizar rol a `organizer` / `onboarding_completed = true` con el JWT autenticado → `200 OK` bajo RLS.
5. Limpiar el usuario de prueba de `auth.users` y `vifutboldev.user_accounts` al finalizar.
