# Phase 0 Research: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Feature**: `002-auth-onboarding-rbac`  
**Date**: 2026-11-03

---

## 1. Persistencia de Sesión Aislada por Entorno y Rehidratación Offline (`FR-001`, `FR-005`, `FR-008`)

- **Decision**: Persistir el estado de sesión (`AuthSession`) y el catálogo local de cuentas del entorno a través del contrato existente `LocalStorageRepository` (`HiveLocalStorageRepository` con prefijos aislados `vifutbol_dev` y `vifutbol_prod`), utilizando serialización JSON determinista y sanitización de tokens/contraseñas en `toString()`.
- **Rationale**:
  - Garantiza rehidratación instantánea (`< 2s`) al abrir la aplicación sin conexión a internet (*offline*) para cualquier usuario previamente autenticado o que haya elegido *"Continuar como Aficionado"*.
  - Mantiene el aislamiento total entre los entornos `dev` y `prod` establecido en la **HU 1.1**, y permite limpiar en `< 1s` las credenciales de la sesión al ejecutar `logout()`.
- **Alternatives considered**:
  - *Requerir validación de red en cada arranque*: Descartado porque bloquea a árbitros, entrenadores y organizadores en canchas sin cobertura móvil (`SC-003`).

---

## 2. Matriz Determinista de Control de Acceso Basado en Roles (`FR-003`, `FR-004`, `FR-009`)

- **Decision**: Implementar una entidad de dominio pura `RolePermissionMatrix` que mapea cada `UserRole` (`organizer`, `coach`, `referee`, `player`, `fan`) al conjunto exacto de capacidades operativas (`RoleCapability`), junto con reglas de habilitación de roles según el entorno (`AppEnvironment`).
- **Rationale**:
  - Al residir en `lib/domain/`, la matriz de permisos no depende de la interfaz gráfica ni del almacenamiento y puede probarse unitariamente al 100% para las `5 x N` combinaciones de roles y acciones (`SC-002`).
  - Cumple la regla clarificada en `/speckit-clarify`: en `AppEnvironment.development` los 5 roles están habilitados para pruebas integrales; en `AppEnvironment.production` los roles `fan`, `player` y `coach` son de selección libre y los roles oficiales (`organizer`, `referee`) requieren código de autorización válido.
- **Alternatives considered**:
  - *Validar permisos con condicionales dispersos en los widgets*: Descartado porque viola el Principio IV (*Arquitectura Limpia*) y el Principio V (*Segregación de Roles*).

---

## 3. Protección contra Fuerza Bruta y Frontera Online/Offline en Login (`FR-005`, `FR-006`, `FR-010`)

- **Decision**: En `AuthController`, verificar conectividad activa (`ConnectivityRepository`) antes de procesar nuevos inicios de sesión con contraseña o registros de cuenta nueva; contabilizar intentos fallidos consecutivos (`failedAttempts`) y activar una ventana de bloqueo temporal (`lockedUntil = now + 60s`) al alcanzar `5` intentos fallidos seguidos.
- **Rationale**:
  - Satisface directamente la clarificación de seguridad (`Q3`) y protege contra intentos repetidos de adivinación de contraseñas sin bloquear la rehidratación offline de sesiones ya autenticadas.
  - Los errores de autenticación devuelven fallos tipados (`InvalidCredentialsFailure`, `AuthRateLimitFailure`, `OfflineAuthOperationFailure`) cuyos mensajes provienen de `AppLocalizations` en español y jamás incluyen contraseñas ni tokens en logs.
- **Alternatives considered**:
  - *Permitir intentos ilimitados de contraseña*: Descartado por incumplir la política de bloqueo de `60s` tras `5` intentos fallidos.

---

## 4. Puerta de Entrada Reactiva (`AuthGate`), Foco de Teclado y Conservación en Ciclo de Vida (`FR-001`, `FR-006`, `FR-007`)

- **Decision**: Incorporar un widget raíz reactivo `AuthGate` en `App` que dirija automáticamente entre `WelcomeAuthScreen` (login/registro/acceso `Aficionado`), `RoleOnboardingScreen` (selección inicial de rol cuando `onboardingCompleted == false`) y `AppShellScreen` (con `ProfileTabView` enriquecido para ver permisos, cambiar entre roles autorizados y cerrar sesión).
- **Rationale**:
  - Conserva los campos no sensibles del formulario (`email`, `fullName`, `selectedRole`) en memoria del controlador durante transiciones de segundo plano (`WidgetsBindingObserver`) y solicita confirmación al intentar salir del registro con cambios sin guardar.
  - Configura `TextInputAction.next` y `TextInputAction.done` en los campos de texto y envuelve los formularios en `SingleChildScrollView` con relleno dinámico de teclado para soportar pantallas compactas y texto al `130%` (`SC-005`).
- **Alternatives considered**:
  - *Navegación imperativa manual sin puerta reactiva*: Descartado porque dificulta la redirección inmediata al cerrar sesión o rehidratar en frío.
