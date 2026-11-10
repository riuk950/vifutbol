# Tasks: Conexión e Integración del Backend Supabase DEV (Self-Hosted Docker en Oracle Cloud) (HU 17.1)

**Input**: Design documents from `/specs/031-supabase-dev-backend/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/supabase-backend-contracts.md](./contracts/supabase-backend-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes, sin dependencias cruzadas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Shared Dependencies & Environment Templates)

**Purpose**: Incorporar el SDK oficial de Supabase y documentar las plantillas de credenciales para el equipo de desarrollo.

- [X] T001 Add `supabase_flutter: ^2.18.3` to `pubspec.yaml` and run `flutter pub get`
- [X] T002 [P] Create `.env.example` in repo root with `SUPABASE_URL` and `SUPABASE_ANON_KEY` template variables and verify `.env` is ignored in `.gitignore`
- [X] T003 [P] Update `README.md` with instructions for running the application with `--dart-define` and local offline fallback

---

## Phase 2: Foundational (Domain Models & Environment Isolation)

**Purpose**: Modelar la configuración inmutable de Supabase y los estados de salud del backend asegurando aislamiento de entornos y ofuscación de secretos.

**⚠️ CRITICAL**: Ninguna historia de usuario puede arrancar hasta completar esta fase.

- [X] T004 Create `lib/domain/entities/backend_health_status.dart` with `BackendHealthStatus` enum and `BackendHealthCheckResult` value object
- [X] T005 Update `lib/domain/entities/app_environment.dart` to implement `SupabaseConfig`, integrate it into `EnvironmentConfig`, enforce production isolation, and implement `toSafeDiagnosticMap()` with `[REDACTED]`
- [X] T006 [P] Add unit tests in `test/unit/infrastructure/supabase_config_test.dart` verifying `SupabaseConfig`, `EnvironmentConfig` resolution via `--dart-define`, default dev URL, empty key handling, and redaction in `toSafeDiagnosticMap()`

**Checkpoint**: Modelos de dominio y configuración de entorno listos y testeados; implementación de historias de usuario desbloqueada.

---

## Phase 3: User Story 1 - Inicialización y Configuración Segura de Supabase DEV (Priority: P1) 🎯 MVP

**Goal**: Inicializar el cliente `supabase_flutter` en `bootstrapApp` bajo `AppEnvironment.development` con variables inyectadas por `--dart-define` y exponer `supabaseClientProvider` en Riverpod.

**Independent Test**: Ejecutar la app con variables `--dart-define` de desarrollo y verificar que `supabaseClientProvider` expone un `SupabaseClient` activo apuntando a `https://supabase.artbusinesstechnology.com`, mientras que en ausencia de variables conmuta limpiamente a modo local (Hive).

### Tests for User Story 1

- [X] T007 [P] [US1] Add unit tests in `test/unit/application/supabase_providers_test.dart` verifying `supabaseConfigProvider` and `supabaseClientProvider` under configured and unconfigured environments

### Implementation for User Story 1

- [X] T008 [US1] Create `lib/application/providers/supabase_providers.dart` defining `supabaseConfigProvider` and `supabaseClientProvider`
- [X] T009 [US1] Update `lib/app_bootstrap.dart` to conditionally initialize `Supabase.initialize(...)` when `config.supabase.isConfigured` is true, with graceful fallback to local-only Hive mode when credentials are missing or on failure

**Checkpoint**: `SupabaseClient` disponible en Riverpod e inicializado sin secretos quemados en el código.

---

## Phase 4: User Story 2 - Verificación de Conectividad y Health Check con el Host Self-Hosted (Priority: P2)

**Goal**: Implementar el handshake HTTP contra la raíz de PostgREST (`/rest/v1/`) con cabecera `apikey: anonKey` y registrar `[SupabaseDev] Conectado exitosamente al host self-hosted` al confirmar código 200 OK.

**Independent Test**: Invocar `CheckSupabaseBackendHealthUseCase` con mocks de respuesta 200, 401 y timeout; verificar que emite el log correcto y actualiza `BackendHealthStatus`.

### Tests for User Story 2

- [X] T010 [P] [US2] Add unit tests in `test/unit/application/check_supabase_backend_health_use_case_test.dart` verifying handshake against PostgREST `/rest/v1/` with 200 OK, 401 Unauthorized, 500 error, SocketException, and TimeoutException

### Implementation for User Story 2

- [X] T011 [P] [US2] Create `lib/infrastructure/network/supabase_health_client.dart` implementing the HTTP probe against PostgREST `/rest/v1/` with `apikey` header and 5-second timeout
- [X] T012 [US2] Create `lib/application/use_cases/check_supabase_backend_health_use_case.dart` and `BackendHealthNotifier` / `backendHealthStatusProvider` in `lib/application/providers/supabase_providers.dart` emitting `[SupabaseDev] Conectado exitosamente al host self-hosted` on 200 OK

**Checkpoint**: Verificación determinista de salud del servidor self-hosted en Oracle Cloud operativa y trazada en logs.

---

## Phase 5: User Story 3 - Resiliencia y Modo Fuera de Línea (Offline-First Fallback) (Priority: P3)

**Goal**: Ejecutar el health check de forma asíncrona no bloqueante en segundo plano tras el arranque de la app, permitiendo continuidad operativa con Hive sin bloqueos ante caídas del servidor cloud o cortes de red.

**Independent Test**: Iniciar la app con un host inalcanzable o sin red; verificar que la aplicación arranca en <500 ms y sirve los datos locales de Hive sin congelar la UI ni lanzar excepciones no controladas.

### Tests for User Story 3

- [X] T013 [P] [US3] Add integration/bootstrap resilience tests in `test/unit/application/supabase_bootstrap_resilience_test.dart` verifying non-blocking startup (<500ms) and local Hive continuity when Supabase host is unreachable or unconfigured

### Implementation for User Story 3

- [X] T014 [US3] Update `lib/app_bootstrap.dart` to trigger `backendHealthStatusProvider.notifier.checkHealth()` asynchronously in the background after `runApp` without stalling the main UI thread

**Checkpoint**: Resiliencia total y soporte offline-first cumpliendo el Principio VII de la Constitución.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verificación de análisis estático, formato de código y ejecución de la suite completa de pruebas de la característica.

- [X] T015 Run static analysis (`flutter analyze`) and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) to verify zero errors and zero warnings
- [X] T016 Run full test suite for feature (`flutter test test/unit/infrastructure/supabase_config_test.dart test/unit/application/supabase_providers_test.dart test/unit/application/check_supabase_backend_health_use_case_test.dart test/unit/application/supabase_bootstrap_resilience_test.dart`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sin dependencias — se ejecuta de inmediato.
- **Phase 2 (Foundational)**: Depende de Phase 1 — bloquea `US1`, `US2` y `US3`.
- **Phase 3 (US1 - P1 MVP)**: Depende de Phase 2.
- **Phase 4 (US2 - P2)**: Depende de Phase 2 y se integra con providers de Phase 3.
- **Phase 5 (US3 - P3)**: Depende de Phase 3 y Phase 4 para orquestación en segundo plano.
- **Phase 6 (Polish)**: Depende de todas las fases anteriores.

### Parallel Opportunities

- En Phase 1: `T002` (.env.example) y `T003` (README.md) son paralelizables.
- En Phase 2: `T006` (pruebas de config) puede correr en paralelo con el diseño de modelos.
- En Phase 3: `T007` (tests de providers) se escribe en paralelo antes de `T008` y `T009`.
- En Phase 4: `T010` (tests de health check) y `T011` (health client HTTP) son paralelizables.
- En Phase 5: `T013` (tests de resiliencia) es paralelizable.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Completar Phase 1: Setup (`T001` - `T003`).
2. Completar Phase 2: Foundational (`T004` - `T006`).
3. Completar Phase 3: User Story 1 (`T007` - `T009`).
4. **Validar MVP**: El cliente Supabase se inicializa de forma segura y expone `supabaseClientProvider` con fallback a Hive.

### Incremental Delivery
1. Añadir User Story 2 (`T010` - `T012`) → Diagnóstico y health check contra PostgREST en Oracle Cloud.
2. Añadir User Story 3 (`T013` - `T014`) → Orquestación asíncrona en segundo plano y resiliencia offline.
3. Polish (`T015` - `T016`) → Análisis estático, formato y pruebas finales.
