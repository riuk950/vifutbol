# Contracts: Conexión e Integración del Backend Supabase DEV (HU 17.1)

**Feature**: `031-supabase-dev-backend`  
**Date**: 2026-11-10  

---

## 1. Contrato de Inyección de Entorno (--dart-define)

| Variable de Entorno | Tipo | Valor Predeterminado (DEV) | Requerido | Descripción |
|---|---|---|---|---|
| `SUPABASE_URL` | `String` | `https://supabase.artbusinesstechnology.com` | No | URL pública del API Gateway (Kong) en Oracle Cloud. |
| `SUPABASE_ANON_KEY` | `String` | `""` | Sí (para modo remoto) | Clave pública anónima (*anon public key*) generada por el servidor self-hosted. |

---

## 2. Contrato de Sonda HTTP (Health Check Handshake)

- **Método**: `GET`
- **URL**: `${supabaseUrl}/rest/v1/`
- **Cabeceras HTTP**:
  - `apikey`: `<supabaseAnonKey>`
  - `Accept`: `application/openapi+json, application/json`
- **Timeout**: `5000 ms`
- **Códigos de Respuesta**:
  - `200 OK`: Éxito. El API Gateway (Kong) y el motor PostgREST están activos y conectados a PostgreSQL.
  - `401 Unauthorized`: Error de autenticación (la clave anon suministrada no es válida para la instancia).
  - `502 / 503 / 504`: Fallo de gateway / Contenedor de Docker en Oracle Cloud detenido.
  - `SocketException / TimeoutException`: Host inalcanzable, firewall OCI bloqueando puertos o sin conexión a internet.

---

## 3. Contratos de Interfaz en Dart

### Caso de Uso: `CheckSupabaseBackendHealthUseCase`

```dart
abstract class CheckSupabaseBackendHealthUseCase {
  /// Ejecuta el handshake contra el backend y retorna el resultado detallado.
  Future<BackendHealthCheckResult> call({
    Duration timeout = const Duration(seconds: 5),
  });
}
```

### Contrato de Providers (Riverpod)

```dart
/// Expone la configuración activa de Supabase.
final supabaseConfigProvider = Provider<SupabaseConfig>((ref) { ... });

/// Expone el cliente Supabase oficial inicializado, o null si está en modo local.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) { ... });

/// Expone el estado reactivo del health check con el backend.
final backendHealthStatusProvider = StateNotifierProvider<BackendHealthNotifier, BackendHealthCheckResult>((ref) { ... });
```

---

## 4. Contrato de Inicialización en `app_bootstrap.dart`

```dart
Future<void> bootstrapApp(EnvironmentConfig config) async {
  ...
  // Inicialización condicional no bloqueante de Supabase
  if (config.supabase.isConfigured) {
    try {
      await Supabase.initialize(
        url: config.supabase.url,
        anonKey: config.supabase.anonKey,
      );
    } catch (e) {
      // Captura excepciones sin abortar el arranque de la app
    }
  }
  ...
  runApp(...);

  // Ejecución en segundo plano del health check tras el renderizado inicial
  if (config.supabase.isConfigured) {
    container.read(backendHealthStatusProvider.notifier).checkHealth();
  }
}
```
