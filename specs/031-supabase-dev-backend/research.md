# Phase 0 Research: Conexión e Integración del Backend Supabase DEV (Self-Hosted Docker en Oracle Cloud) (HU 17.1)

**Feature**: `031-supabase-dev-backend`  
**Date**: 2026-11-10  
**Context**: Integración de `supabase_flutter` apuntando a instancia self-hosted Docker en Oracle Cloud (`https://supabase.artbusinesstechnology.com`) con variables de entorno seguras y capacidad offline-first.

---

## 1. Integración de `supabase_flutter` en Flutter 3.x / Dart 3.x

### Decisiones de Biblioteca
- **Paquete oficial**: `supabase_flutter: ^2.18.3`.
- **Compatibilidad**: Probada con `sdk: ^3.12.0` y `flutter_riverpod: ^2.6.1`. Resuelve sin conflictos de dependencias con `connectivity_plus`, `hive` o `fluro`.
- **Inicialización del SDK**:
  ```dart
  await Supabase.initialize(
    url: config.supabase.url,
    anonKey: config.supabase.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );
  ```

### Justificación
`supabase_flutter` es el cliente unificado que encapsula `gotrue` (autenticación), `postgrest` (consultas relacionales), `storage_client` y `realtime_client`. Ofrece soporte automático para refresco de tokens JWT, persistencia de sesión segura y enrutamiento estándar a través de Kong.

---

## 2. Arquitectura Self-Hosted en Oracle Cloud (OCI) & Kong API Gateway

### Topología del Servidor
- **Infraestructura**: Instancia de cómputo en Oracle Cloud Infrastructure (OCI) sobre Ubuntu Linux ejecutando Docker Compose.
- **Reverse Proxy / SSL**: Servidor web inverso (Nginx / Traefik / Caddy) con certificados SSL/TLS válidos terminando en `https://supabase.artbusinesstechnology.com`.
- **API Gateway (Kong)**: Puerto interno expuesto en 8000/8443 y mapeado al reverse proxy público (80/443).
- **Rutas estándar de Kong**:
  - `/rest/v1/*` → Enrutado al microservicio **PostgREST**.
  - `/auth/v1/*` → Enrutado a **GoTrue**.
  - `/realtime/v1/*` → Enrutado a **Realtime Server** (WebSockets).

### Handshake & Health Check Probe
- Para verificar de forma determinista que tanto Kong como PostgREST y la base de datos PostgreSQL están operando sin requerir tablas creadas previamente ni credenciales de usuario:
  - **Endpoint**: `GET https://supabase.artbusinesstechnology.com/rest/v1/`
  - **Cabecera requerida**: `apikey: <anonKey>`
  - **Respuesta esperada**: Código `200 OK` con JSON describiendo el esquema OpenAPI de PostgREST.
  - **Timeout recomendado**: 5 segundos con fallback silencioso a `BackendHealthStatus.unreachable` sin bloquear la UI.

---

## 3. Inyección Segura de Credenciales y Cero Secretos en Git

### Estrategia de Variables
- **Principio**: Prohibición absoluta de quemar `SUPABASE_ANON_KEY` en código fuente de `lib/`.
- **Mecanismo de Inyección**:
  - En compilación / ejecución: `--dart-define=SUPABASE_URL=...` y `--dart-define=SUPABASE_ANON_KEY=...`.
  - Lectura en Dart:
    ```dart
    const defaultDevUrl = 'https://supabase.artbusinesstechnology.com';
    final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: defaultDevUrl);
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    ```
- **Control de Repositorio**:
  - Creación de `.env.example` en la raíz como plantilla documentada.
  - El archivo `.env` ya se encuentra ignorado en `.gitignore`.
  - En `EnvironmentConfig.toSafeDiagnosticMap()`, el atributo `anonKey` se ofusca invariablemente como `'[REDACTED]'`.

---

## 4. Estrategia Offline-First y Graceful Fallback

### Análisis de Fallas y Resiliencia (Principio VII Constitución & Mobile Guidelines)
1. **Desarrollador sin `--dart-define` (Local puro)**:
   - `SupabaseConfig.isConfigured` evalúa a `false`.
   - `bootstrapApp` emite log informativo: `[Supabase] No se suministraron credenciales; operando en modo local (Hive).`
   - `supabaseClientProvider` retorna `null`.
   - La aplicación arranca en <300 ms sin crashes ni excepciones no controladas.

2. **Sin conexión a internet o contenedor Oracle Cloud caído**:
   - `Supabase.initialize` no realiza peticiones de red bloqueantes durante el arranque inicial (solo inicializa clientes y listeners locales).
   - El caso de uso `CheckSupabaseBackendHealthUseCase` corre en segundo plano tras `runApp`. Si falla o expira el timeout de 5s, captura el error de socket/HTTP y actualiza el estado a `BackendHealthStatus.unreachable`.
   - La aplicación opera 100% funcional con los repositorios locales (`HiveLocalStorageRepository`).

---

## 5. Arquitectura Limpia y Ubicación de Componentes

```text
lib/
├── domain/
│   └── entities/
│       ├── app_environment.dart       # Extendido con SupabaseConfig inmutable
│       └── backend_health_status.dart  # Enum / Modelo de estado de salud del backend
├── application/
│   ├── providers/
│   │   └── supabase_providers.dart    # supabaseConfigProvider, supabaseClientProvider, backendHealthProvider
│   └── use_cases/
│       └── check_supabase_backend_health_use_case.dart # Handshake HTTP contra /rest/v1/
├── infrastructure/
│   └── network/
│       └── supabase_health_client.dart # Cliente HTTP ligero para sondeo de PostgREST
└── app_bootstrap.dart                  # Inicialización condicional de Supabase.initialize()
```
