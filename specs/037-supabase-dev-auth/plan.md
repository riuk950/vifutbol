# Implementation Plan: Autenticación de Usuarios y Obtención de Sesión / Perfil en Supabase DEV (GoTrue + `vifutboldev`)

**Branch**: `develop` (Feature `037-supabase-dev-auth`) | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/037-supabase-dev-auth/spec.md`

## Summary

Implementar [`SupabaseAuthRepository`](../../lib/infrastructure/auth/supabase_auth_repository.dart) cumpliendo el contrato de dominio [`AuthRepository`](../../lib/domain/repositories/auth_repository.dart) contra **Supabase DEV (`GoTrue`)** y la tabla PostgreSQL `vifutboldev.user_accounts` (definida en HU 17.2). Se añade una migración SQL idempotente (`supabase/migrations/202611110005_auth_user_accounts_trigger.sql`) con trigger `AFTER INSERT ON auth.users` más un respaldo `upsert` idempotente en el cliente, un nuevo fallo tipado `EmailVerificationRequiredFailure` para confirmaciones pendientes sin alterar firmas existentes, cambio de rol libre en `AppEnvironment.development`, listener reactivo `onAuthStateChange` desacoplado de la capa de presentación, caché espejo local en `LocalStorageRepository` para fallback offline en `restoreSession()`, y selección condicional en `authRepositoryProvider` manteniendo fallback transparente a [`LocalAuthRepository`](../../lib/infrastructure/auth/local_auth_repository.dart).

## Technical Context

**Language/Version**: Dart 3 / Flutter SDK (project `pubspec.yaml` con `supabase_flutter`, `flutter_riverpod`, `mocktail`, `flutter_test`)  
**Primary Dependencies**: `supabase_flutter` (`SupabaseClient`, `GoTrueClient`, `AuthException`, `AuthChangeEvent`, `PostgrestException`), `flutter_riverpod`, `LocalStorageRepository`, `ConnectivityService`, `AppConfig`  
**Storage**: Remoto en PostgreSQL self-hosted (`supabase-db`, esquema `vifutboldev`, tabla `vifutboldev.user_accounts`, vinculado a `auth.users` via `auth_user_id`); Caché espejo y sesión de invitado en `LocalStorageRepository` (clave `auth_session`)  
**Testing**: `flutter test` con mocks (`mocktail`) sobre `SupabaseClient` / `GoTrueClient` y `SupabaseUserProfileDataSource`, pruebas unitarias de `authRepositoryProvider` y `AuthController`, además de smoke verification end-to-end contra `https://supabase.artbusinesstechnology.com`  
**Target Platform**: Android / iOS / Web (Flutter multiplataforma móvil-first)  
**Project Type**: Mobile app (Clean Architecture por capas: `domain/` -> `application/` -> `infrastructure/` -> `presentation/`) + SQL migration (`supabase/migrations/`)  
**Performance Goals**: Restauración de sesión al arranque con fallback instantáneo ante desconexión y actualización reactiva inmediata ante `AuthChangeEvent.signedOut` / `tokenRefreshed`; cero bloqueo de UI por latencia de red  
**Constraints**:
- Prohibido acoplar `domain/`, `application/` o `presentation/` al SDK `supabase_flutter` (Principio IV).
- Ningún JWT, `accessToken`, `refreshToken` o contraseña debe quedar expuesto en mensajes de error ni en `toSafeDiagnosticMap()` / `toString()` (Principio VII, FR-010).
- Dependencia de despliegue: requiere previamente aplicadas en el servidor DEV las migraciones de HU 17.2 (`202611110001`..`0004`, esquema `vifutboldev`, tabla `user_accounts` y `PGRST_DB_SCHEMAS` actualizado) antes de ejecutar `202611110005_auth_user_accounts_trigger.sql` en vivo.
**Scale/Scope**: 1 repositorio remoto + interface auxiliar `SupabaseUserProfileDataSource`, 1 fallo tipado nuevo, ajuste mínimo en `AuthRepository` / `AuthController` / `authRepositoryProvider`, 1 migración SQL idempotente, y 3 suites de prueba actualizadas/nuevas

## Constitution Check

*GATE: Evaluated before Phase 0 research and re-checked after Phase 1 design.*

| Principio | Evaluación Pre-Research | Evaluación Post-Design | Estado |
|---|---|---|---|
| **I. La Spec Manda (`spec.md` es fuente de verdad)** | Trazabilidad 1:1 hacia US1–US5, FR-001..FR-010 y Clarificaciones Q1–Q3. | Contratos, modelo de datos y plan cubren cada FR y caso borde sin alcance no especificado. | PASS |
| **II. Integridad de Datos y Consistencia** | Requiere trigger atómico en `auth.users` + fallback `upsert` en cliente sobre `vifutboldev.user_accounts`. | `202611110005_auth_user_accounts_trigger.sql` (`SECURITY DEFINER`, `SET search_path = ''`, `ON CONFLICT DO NOTHING`) + `ensureProfile` en Dart garantizan consistencia. | PASS |
| **III. Pruebas Automatizadas como Puerta** | Exige tests unitarios con mocks para todos los flujos GoTrue, errores y DI antes de cerrar HU. | Diseñado `SupabaseUserProfileDataSource` inyectable para testear con `mocktail` sin frágiles mocks de `PostgrestFilterBuilder`, más tests de `authRepositoryProvider` y `AuthController`. | PASS |
| **IV. Arquitectura Limpia** | Prohibido filtrar tipos de `supabase_flutter` fuera de `infrastructure/`. | `AuthRepository` expone únicamente tipos de dominio (`AuthSession`, `UserAccount`, `Stream<AuthSession?>` opcional); `SupabaseAuthRepository` traduce internamente SDK y excepciones. | PASS |
| **V. Segregación de Roles y Diseño** | Mantener regla de roles oficiales en PROD y flexibilidad controlada en DEV. | `completeRoleOnboarding` y `switchActiveRole` validan `officialAuthorizationCode` en `AppEnvironment.production` y permiten alternancia libre en `AppEnvironment.development` (Q3). | PASS |
| **VI. Inglés técnico / Español UI** | Símbolos Dart/SQL/tests en inglés; mensajes visibles al usuario en español. | Clases/métodos/SQL en inglés; `EmailVerificationRequiredFailure` y `_mapAuthException` devuelven mensajes claros en español. | PASS |
| **VII. Resiliencia y Experiencia Móvil** | Soporte de fallback offline en `restoreSession()`, modo invitado local y redacción de tokens. | Caché espejo `auth_session` permite restaurar sesión offline sin desconectar al usuario; `toSafeDiagnosticMap()` mantiene `[REDACTED]`. | PASS |

**Gate Result**: **7/7 PASS** (sin violaciones ni desviaciones).

## Project Structure

### Documentation (this feature)

```text
specs/037-supabase-dev-auth/
├── spec.md                              # Especificación funcional + Clarificaciones Q1-Q3
├── checklists/
│   └── requirements.md                  # Checklist de calidad (16/16 PASS)
├── plan.md                              # Este archivo (/speckit-plan)
├── research.md                          # Decisiones técnicas y hallazgos verificados en DEV
├── data-model.md                        # Mapeo UserAccount <-> vifutboldev.user_accounts y transiciones
├── quickstart.md                        # Guía de verificación unitaria y E2E en Supabase DEV
├── contracts/
│   └── supabase-auth-contracts.md       # Contratos SQL trigger, SupabaseAuthRepository y DI
└── tasks.md                             # Generado posteriormente por /speckit-tasks
```

### Source Code (repository root)

```text
supabase/
└── migrations/
    └── 202611110005_auth_user_accounts_trigger.sql   # NEW: Trigger AFTER INSERT ON auth.users -> vifutboldev.user_accounts

lib/
├── domain/
│   ├── failures/
│   │   └── app_failure.dart                          # MODIFY: Add EmailVerificationRequiredFailure
│   └── repositories/
│       └── auth_repository.dart                      # MODIFY: Add optional default Stream<AuthSession?> get onSessionStateChanged
├── application/
│   ├── controllers/
│   │   └── auth_controller.dart                      # MODIFY: Subscribe/cancel repository.onSessionStateChanged safely
│   └── providers/
│       └── auth_providers.dart                       # MODIFY: Conditional SupabaseAuthRepository vs LocalAuthRepository
└── infrastructure/
    └── auth/
        ├── local_auth_repository.dart                # EXISTING: Fallback repository when Supabase is disabled/unavailable
        └── supabase_auth_repository.dart             # NEW: GoTrue + vifutboldev.user_accounts AuthRepository implementation

test/
├── infrastructure/
│   ├── local_auth_repository_test.dart               # EXISTING: Regression safety check
│   └── supabase_auth_repository_test.dart            # NEW: Unit tests (signIn, signUp, pending email, restore, roles, errors, redaction)
└── application/
    ├── auth_providers_test.dart                      # NEW: Provider DI selection tests (DEV configured vs unconfigured/null client)
    └── auth_controller_test.dart                     # MODIFY: Verify reactive session invalidation via onSessionStateChanged
```

**Structure Decision**: Se mantiene la estructura Clean Architecture existente en `lib/` (`domain/`, `application/`, `infrastructure/`) y la carpeta de migraciones incrementales `supabase/migrations/` iniciada en HU 17.2. Para evitar acoplar `AuthController` al SDK de Supabase y permitir tests deterministas sin red real, se introduce `SupabaseUserProfileDataSource` como delegado interno opcional dentro de `lib/infrastructure/auth/supabase_auth_repository.dart` y un stream de dominio no disruptivo `onSessionStateChanged` con getter por defecto en `AuthRepository`.

## Complexity Tracking

> No hay violaciones a la Constitución; no se requieren justificaciones de complejidad excepcional.
