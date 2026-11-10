# Feature Specification: Conexión e Integración del Backend Supabase DEV (Self-Hosted Docker en Oracle Cloud) (HU 17.1)

**Feature Branch**: `031-supabase-dev-backend`  
**Created**: 2026-11-10  
**Status**: Draft  
**Notion Target**: [Épica 17] HU 17.1 (Page ID: `4148442e-3f49-81d8-b6b2-f8c412c1475b`)  
**Input**: Petición de usuario: "speckit-specify de Notion HU 17.1 en curso"

---

## Clarifications

### Session 2026-11-10

- Q: ¿Cómo debe comportarse la aplicación durante el arranque (`bootstrapApp`) si un desarrollador ejecuta la aplicación en modo desarrollo sin suministrar las variables `--dart-define` de Supabase? → A: Conmutar automáticamente a modo local (Hive), registrando un aviso informativo en los logs de depuración sin bloquear la app ni fallar el arranque (*Graceful Fallback*).
- Q: ¿Qué endpoint o estrategia de sondeo debe consultar el caso de uso `CheckSupabaseBackendHealthUseCase` para validar el handshake con la instancia self-hosted en Oracle Cloud? → A: Petición HTTP GET a la raíz de PostgREST (`/rest/v1/`) con cabecera `apikey: anonKey`, verificando simultáneamente Kong y PostgreSQL sin requerir tablas creadas previamente.
- Q: ¿Cuándo y de qué manera debe ejecutarse la comprobación de salud (`CheckSupabaseBackendHealthUseCase`) del backend self-hosted? → A: Ejecución asíncrona en segundo plano tras el renderizado inicial (`runApp`), garantizando un arranque visual inmediato (<500 ms) sin bloquear la interfaz.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inicialización y Configuración Segura de Supabase DEV (Priority: P1) 🎯 MVP

Como **desarrollador de KickPulse (vifutbol)**,  
quiero configurar e inicializar el cliente oficial `supabase_flutter` durante el arranque de la aplicación apuntando a la instancia self-hosted de desarrollo en Oracle Cloud (`https://supabase.artbusinesstechnology.com`), inyectando las credenciales de forma segura mediante `--dart-define`,  
para disponer de un cliente Supabase centralizado y reactivo mediante Riverpod sin exponer claves en el repositorio de código.

**Why this priority**: Es la base fundacional de la Épica 17 (Persistencia y Cloud Backend). Sin un cliente inicializado de forma segura y accesible mediante la jerarquía de Riverpod, ninguna de las capacidades de sincronización o autenticación remota puede operar.

**Independent Test**: Ejecutar la aplicación o la suite de pruebas unitarias suministrando `--dart-define=SUPABASE_URL=...` y `--dart-define=SUPABASE_ANON_KEY=...` en entorno `AppEnvironment.development`; comprobar que `supabaseClientProvider` expone una instancia activa de `SupabaseClient` con la URL y headers configurados, y que en ausencia de variables sensibles el código no contiene credenciales quemadas.

**Acceptance Scenarios**:

1. **Given** que la aplicación arranca bajo `AppEnvironment.development`,  
   **And** las variables de entorno `SUPABASE_URL` y `SUPABASE_ANON_KEY` son suministradas vía `--dart-define`,  
   **When** se ejecuta el ciclo de arranque en `bootstrapApp`,  
   **Then** `supabase_flutter` inicializa su cliente apuntando a `https://supabase.artbusinesstechnology.com`,  
   **And** el proveedor `supabaseClientProvider` queda registrado y disponible para toda la jerarquía de Riverpod.

2. **Given** que el proyecto se compila o analiza estáticamente con `flutter analyze` o `git diff`,  
   **When** se auditan los archivos de `lib/` y el historial de Git,  
   **Then** no existe ningún valor sensible de `SUPABASE_ANON_KEY` quemado en código duro,  
   **And** existe un archivo `.env.example` documentado como plantilla de referencia.

---

### User Story 2 - Verificación de Conectividad y Health Check con el Host Self-Hosted (Priority: P2)

Como **desarrollador o administrador del sistema**,  
quiero verificar mediante un handshake o health check ligero que la instancia de Supabase corriendo en el contenedor Docker sobre Ubuntu en Oracle Cloud responda satisfactoriamente,  
para confirmar que el API Gateway (Kong), GoTrue y PostgREST están operativos y registrar el estado en los logs de depuración.

**Why this priority**: Al tratarse de un backend self-hosted desplegado sobre una máquina virtual de Oracle Cloud (detrás de reverse proxy y firewall OCI), es fundamental contar con un mecanismo determinista de validación de conexión que distinga problemas de red/puertos/SSL de errores de lógica de aplicación.

**Independent Test**: Invocar el caso de uso o servicio de comprobación de salud contra el endpoint configurado; verificar que al recibir respuesta HTTP exitosa (200 OK) se emite el log `[SupabaseDev] Conectado exitosamente al host self-hosted` y el mapa de diagnóstico oculta la clave anon (`[REDACTED]`).

**Acceptance Scenarios**:

1. **Given** que el contenedor Docker de Supabase está activo en Oracle Cloud con certificados SSL válidos,  
   **When** el cliente realiza la comprobación de salud o la primera petición diagnóstica al API Gateway (`https://supabase.artbusinesstechnology.com`),  
   **Then** el servidor responde con estado exitoso (HTTP 200 OK),  
   **And** la aplicación registra en los logs de depuración: `[SupabaseDev] Conectado exitosamente al host self-hosted`.

2. **Given** que se consulta el estado de configuración mediante `EnvironmentConfig.toSafeDiagnosticMap()`,  
   **When** se inspeccionan las propiedades de Supabase,  
   **Then** la URL se visualiza legible (`https://supabase.artbusinesstechnology.com`),  
   **And** el valor de `supabaseAnonKey` se muestra redactado como `[REDACTED]`.

---

### User Story 3 - Resiliencia y Modo Fuera de Línea (Offline-First Fallback) (Priority: P3)

Como **usuario o desarrollador de la aplicación**,  
quiero que si el dispositivo pierde la conexión a internet o el host de Supabase en Oracle Cloud se encuentra temporalmente detenido,  
la aplicación continúe funcionando sin interrupciones ni excepciones no controladas recurriendo al almacenamiento local (Hive / repositorios locales),  
para garantizar la alta disponibilidad del sistema bajo cualquier condición de red (Principio I de la Constitución).

**Why this priority**: Protege la experiencia de usuario y la integridad operativa de KickPulse ante caídas del servidor cloud o cortes de conectividad móvil, garantizando que el funcionamiento local nunca se bloquee.

**Independent Test**: Desconectar la conectividad o configurar un host inalcanzable; arrancar la app y ejecutar operaciones de lectura de torneos, partidos o equipos; verificar que los datos se sirven desde la caché local sin bloqueos ni crashes.

**Acceptance Scenarios**:

1. **Given** que el dispositivo carece de conexión a internet o el contenedor de Supabase se encuentra temporalmente no disponible,  
   **When** la aplicación inicia o intenta comunicarse con el backend remoto,  
   **Then** el cliente captura el error de conectividad sin provocar un crash o fallo fatal,  
   **And** el sistema conmuta de forma transparente a la persistencia local de Hive, emitiendo un estado controlado de advertencia.

---

### Edge Cases

- **Ausencia total de variables `--dart-define` en desarrollo local**: Si un desarrollador ejecuta `flutter run` sin proveer `SUPABASE_ANON_KEY`, la aplicación no debe crashear; debe inicializar el entorno local con un cliente inactivo/modo local emitiendo una advertencia clara en consola.
- **Formato inválido de URL o clave malformada**: Si la URL no es un URI HTTPS bien formado o la clave es un string vacío, el sistema debe rechazar la configuración con un `EnvironmentValidationFailure` descriptivo antes de intentar inicializar el SDK.
- **Aislamiento estricto de producción**: Si `AppEnvironment.production` detecta un prefijo o URL correspondiente a desarrollo (`dev`, `supabase.artbusinesstechnology.com`), la inicialización debe fallar de inmediato para evitar contaminación de entornos.
- **Tiempo de espera agotado (Timeout) en Oracle Cloud**: Si el firewall de OCI o iptables bloquea el tráfico entrante a los puertos 80/443, la petición de health check debe respetar un timeout corto (máximo 5 segundos) y conmutar a modo offline sin congelar la interfaz de usuario.
- **Soporte multiplataforma (Móvil y Web)**: Si la aplicación corre en Flutter Web, la configuración de CORS en el backend self-hosted debe permitir peticiones originadas desde `localhost` sin bloquear el handshake.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El proyecto DEBE incorporar la dependencia oficial `supabase_flutter` (versión compatible con Flutter 3.x / Dart 3.x) en `pubspec.yaml`.
- **FR-002**: La clase `EnvironmentConfig` DEBE integrar un contenedor inmutable de configuración `SupabaseConfig` que encapsule `url`, `anonKey`, y el indicador booleano `isConfigured`.
- **FR-003**: Las credenciales de Supabase DEBEN leerse exclusivamente de variables de entorno mediante `String.fromEnvironment` (`SUPABASE_URL` y `SUPABASE_ANON_KEY`), prohibiendo terminantemente secretos quemados en el código fuente de `lib/`.
- **FR-004**: En el entorno `AppEnvironment.development`, el valor por defecto de `SUPABASE_URL` DEBE ser `https://supabase.artbusinesstechnology.com`.
- **FR-005**: En `bootstrapApp` (`lib/app_bootstrap.dart`), el sistema DEBE inicializar condicionalmente `Supabase.initialize(...)` cuando `isConfigured` sea verdadero; si no se suministran credenciales en desarrollo local, DEBE conmutar automáticamente a modo local con Hive registrando un aviso informativo en los logs sin bloquear la aplicación ni fallar el arranque.
- **FR-006**: El sistema DEBE exponer el proveedor Riverpod `supabaseClientProvider` que retorne la instancia activa de `SupabaseClient` (o `null` en caso de modo offline/no configurado).
- **FR-007**: El sistema DEBE implementar un servicio o caso de uso de comprobación de salud (`CheckSupabaseBackendHealthUseCase`) que valide el handshake HTTP mediante una petición GET a la raíz de PostgREST (`/rest/v1/`) incluyendo la cabecera `apikey: anonKey` y un timeout máximo de 5 segundos, verificando la operatividad de Kong y PostgreSQL sin depender de tablas creadas previamente.
- **FR-008**: La comprobación de salud DEBE ejecutarse de forma asíncrona en segundo plano tras el arranque de la interfaz (`runApp`) o bajo demanda, y al verificar la conexión exitosa con código HTTP 200, DEBE registrar en logs de depuración el mensaje estandarizado: `[SupabaseDev] Conectado exitosamente al host self-hosted`.
- **FR-009**: El método `toSafeDiagnosticMap()` de `EnvironmentConfig` DEBE ofuscar el `supabaseAnonKey` sustituyéndolo siempre por `[REDACTED]`.
- **FR-010**: El sistema DEBE proveer un archivo `.env.example` en la raíz del proyecto y actualizar la documentación en `README.md` con las instrucciones precisas para ejecutar la aplicación con `--dart-define`.
- **FR-011**: El entorno `AppEnvironment.production` DEBE mantener su propio esquema de configuración completamente desacoplado del host de desarrollo self-hosted.

---

### Key Entities *(include if feature involves data)*

- **`SupabaseConfig`**: Objeto de valor inmutable dentro de `EnvironmentConfig` con los atributos `url`, `anonKey`, `isConfigured`, y método `toSafeDiagnosticMap()`.
- **`BackendHealthStatus`**: Enumeración o modelo que representa el estado del handshake con el backend:
  - `healthy`: Servidor responde 200 OK.
  - `unreachable`: Servidor no responde o falla la red (timeout/error de conexión).
  - `unconfigured`: No se suministraron credenciales de inicialización.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El cliente `supabase_flutter` se inicializa en menos de 500 ms durante el arranque de la aplicación en modo desarrollo.
- **SC-002**: 0 secretos sensibles, tokens GoTrue o anon keys comiteados en el repositorio Git auditado con herramientas estáticas.
- **SC-003**: 100% de tolerancia a fallos offline: la aplicación inicia y opera con persistencia local en Hive aun cuando el backend en Oracle Cloud no responda.
- **SC-004**: Cobertura de pruebas unitarias superior al 95% para `SupabaseConfig`, inicialización de cliente y `CheckSupabaseBackendHealthUseCase`.
- **SC-005**: `flutter analyze` reporta 0 advertencias y 0 errores tras la integración.

---

## Assumptions

- La instancia self-hosted de Supabase en Oracle Cloud está desplegada con Docker Compose, y su contenedor Kong escucha en los puertos 80/443 con certificado SSL válido para el dominio `supabase.artbusinesstechnology.com`.
- Para desarrollo local en emuladores o dispositivos físicos, los desarrolladores proveerán `--dart-define=SUPABASE_ANON_KEY=...` durante la ejecución (`flutter run`).
- Las historias de usuario subsiguientes de la Épica 17 implementarán la migración y sincronización de tablas específicas (competiciones, equipos, partidos, actas y noticias) sobre este cliente base.
