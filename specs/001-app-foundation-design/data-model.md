# Phase 1 Data Model: HU 1.1 — Fundación de la Aplicación, Aislamiento de Entornos, Localización y Sistema de Diseño

**Feature**: `001-app-foundation-design`  
**Date**: 2026-11-03

---

## 1. Domain Entities & Value Objects

### 1.1 `AppEnvironment` (Enum)
Identifica el entorno operativo en el que se ejecuta la instancia de la aplicación.
- `development`: Entorno de pruebas y desarrollo (`dev`).
- `production`: Entorno oficial productivo (`prod`).

### 1.2 `EnvironmentConfig` (Entity)
Configuración inmutable de arranque y aislamiento de recursos por entorno.

| Field | Type | Required | Description / Validation Rule |
|-------|------|----------|-------------------------------|
| `environment` | `AppEnvironment` | Yes | `development` o `production`. |
| `appName` | `String` | Yes | Nombre de la instancia (`vifutbol DEV` vs `vifutbol`). |
| `localStoragePrefix` | `String` | Yes | Prefijo no vacío para aislar cajas locales (`vifutbol_dev` vs `vifutbol_prod`). |
| `apiBaseUrl` | `String` | Yes | URL del backend correspondiente al entorno. |
| `apiAnonKey` | `String` | Yes | Clave pública de cliente (nunca debe exponerse en logs ni mensajes de UI). |
| `showEnvironmentBanner` | `bool` | Yes | `true` en `development`, `false` en `production`. |

**Invariants**:
- `localStoragePrefix` para `development` y `production` DEBEN ser distintos (`vifutbol_dev` != `vifutbol_prod`).
- `toString()` / serialización de diagnóstico NO DEBE incluir `apiAnonKey` en texto plano (`FR-010`).

---

### 1.3 `ConnectivityStatus` & `ConnectivityBannerState` (Enums / State Model)

Representan la condición de red del dispositivo y la máquina de estados del banner superior reactivo (`FR-007`).

- **`NetworkConnectionStatus`**:
  - `connected`: El dispositivo cuenta con conexión activa.
  - `disconnected`: El dispositivo no tiene acceso a red.
- **`ConnectivityBannerVisibility`**:
  - `hidden`: Oculto (estado inicial cuando arranca conectado, o 3 segundos después de recuperar conexión).
  - `offline`: Visible de forma persistente mientras `status == disconnected`.
  - `restored`: Visible en color verde (`#22C55E`) durante 3 segundos cuando transiciona de `disconnected` → `connected`.

**State Transitions**:
```text
[Initial Connected] ──> hidden
[Any] ──(network lost)──> offline (persistent)
offline ──(network restored)──> restored (starts 3s timer)
restored ──(3s timer elapsed)──> hidden
restored ──(network lost before 3s)──> offline (cancels timer)
```

---

### 1.4 `AppShellSection` (Enum)
Representa las 4 secciones principales de la barra de navegación inferior del *App Shell* (`FR-006`):
1. `matchday` (*Jornada*)
2. `standings` (*Posiciones*)
3. `venues` (*Sedes*)
4. `profile` (*Perfil*)

---

### 1.5 `UiViewState<T>` (Sealed State Contract)
Modelo genérico e inmutable que representa los 5 estados fundamentales de interfaz exigidos por `docs/MOBILE_GUIDELINES.md` y `FR-006`:
- `UiLoadingState<T>`: Operación inicial o recarga en progreso.
- `UiContentState<T>(T data)`: Datos cargados listos para visualizar.
- `UiEmptyState<T>(String messageKey)`: Sin registros disponibles, con acción opcional.
- `UiErrorState<T>(AppFailure failure, {bool canRetry})`: Fallo controlado con mensaje seguro para el usuario y callback de reintento.
- `UiSuccessState<T>(T data, {String? feedbackMessageKey})`: Operación completada con retroalimentación positiva.

---

### 1.6 `LocalStorageStatus` (Entity)
Representa el estado del adaptador de persistencia local tras el arranque:
- `isPersistent`: `true` si el almacenamiento en disco se inicializó correctamente; `false` si operó el fallback seguro en memoria (`Edge Case: Fallo de inicialización de almacenamiento local`).
- `storageNamespace`: Prefijo aislado activo (`vifutbol_dev` o `vifutbol_prod`).
