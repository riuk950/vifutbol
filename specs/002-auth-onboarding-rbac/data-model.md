# Phase 1 Data Model: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Feature**: `002-auth-onboarding-rbac`  
**Date**: 2026-11-03

---

## 1. Domain Entities & Enums (`lib/domain/entities/`)

### 1.1 `UserRole` (`lib/domain/entities/user_role.dart`)
Representa los cinco roles oficiales del ecosistema deportivo (`FR-003`):
- `organizer` (*Organizador*)
- `coach` (*Entrenador*)
- `referee` (*Árbitro*)
- `player` (*Jugador*)
- `fan` (*Aficionado*)

**Properties / Helpers**:
- `requiresAuthorizationCodeInProd`: `true` para `organizer` y `referee`; `false` para `coach`, `player` y `fan`.

---

### 1.2 `RoleCapability` & `RolePermissionMatrix` (`lib/domain/entities/role_permission_matrix.dart`)
Define las capacidades operativas y la matriz determinista de control de acceso (`FR-004`, `FR-009`):

**`RoleCapability` (Enum)**:
- `manageTournaments`: Crear y configurar campeonatos (ligas y copas eliminatorias).
- `manageVenues`: Registrar y editar sedes y canchas geolocalizadas.
- `approveRegistrations`: Aprobar inscripciones de equipos y jugadores.
- `assignReferees`: Designar árbitros para encuentros del calendario.
- `manageTeamRoster`: Inscribir y gestionar la plantilla del propio equipo.
- `manageLineups`: Registrar convocatorias y alineaciones del equipo.
- `recordMatchEvents`: Registrar goles, asistencias y tarjetas en vivo.
- `closeMatchReport`: Cerrar y firmar el acta oficial del partido.
- `viewPersonalStats`: Consultar métricas personales y convocatorias propias.
- `viewPublicContent`: Consultar jornadas, resultados, tablas de posiciones y sedes.

**Matriz de Permisos por Rol (`RolePermissionMatrix.capabilitiesForRole(UserRole role)`)**:

| Capacidad (`RoleCapability`) | `organizer` | `coach` | `referee` | `player` | `fan` |
|------------------------------|:-----------:|:-------:|:---------:|:--------:|:-----:|
| `manageTournaments` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `manageVenues` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `approveRegistrations` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `assignReferees` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `manageTeamRoster` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `manageLineups` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `recordMatchEvents` | ✅ | ❌ | ✅ | ❌ | ❌ |
| `closeMatchReport` | ✅ | ❌ | ✅ | ❌ | ❌ |
| `viewPersonalStats` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `viewPublicContent` | ✅ | ✅ | ✅ | ✅ | ✅ |

---

### 1.3 `UserAccount` (`lib/domain/entities/user_account.dart`)
Representa la identidad de un usuario dentro del campeonato (`FR-001`, `FR-003`):

| Field | Type | Required | Validation / Description |
|-------|------|----------|--------------------------|
| `id` | `String` | Yes | Identificador único inmutable (`UUID`). |
| `fullName` | `String` | Yes | Nombre completo (`>= 2` caracteres). |
| `email` | `String` | Yes | Correo electrónico normalizado en minúsculas (o vacío en sesión anónima de `fan`). |
| `activeRole` | `UserRole` | Yes | Rol deportivo activo en la sesión actual. |
| `authorizedRoles` | `Set<UserRole>` | Yes | Conjunto de roles habilitados para la cuenta (siempre contiene `activeRole` y `UserRole.fan`). |
| `isGuestFan` | `bool` | Yes | `true` cuando ingresa mediante *"Continuar como Aficionado"* sin registro de cuenta. |
| `onboardingCompleted` | `bool` | Yes | `true` tras confirmar el rol inicial en el paso de *Onboarding*. |

---

### 1.4 `AuthSession` (`lib/domain/entities/auth_session.dart`)
Representa la sesión persistente en el dispositivo (`FR-005`, `FR-008`, `FR-010`):

| Field | Type | Required | Validation / Description |
|-------|------|----------|--------------------------|
| `sessionId` | `String` | Yes | Identificador único de sesión (`UUID`). |
| `user` | `UserAccount` | Yes | Cuenta de usuario o visitante asociada. |
| `sessionToken` | `String` | Yes | Token de sesión (redactado como `[REDACTED]` en `toString()` y diagnósticos). |
| `authenticatedAt` | `DateTime` | Yes | Marca de tiempo de inicio de sesión. |

**Invariants**:
- `toString()` y cualquier mapa de diagnóstico NUNCA deben incluir `sessionToken` en texto plano (`FR-010`).

---

### 1.5 `AuthFlowState` (`lib/domain/entities/auth_flow_state.dart`)
Representa el estado reactivo del flujo de autenticación y bloqueo por intentos fallidos (`FR-001`, `FR-006`):

- **`AuthStatus` (Enum)**:
  - `initializing`: Rehidratando sesión local en el arranque.
  - `unauthenticated`: Sin sesión activa; muestra `WelcomeAuthScreen`.
  - `needsOnboarding`: Cuenta creada pendiente de confirmar rol deportivo en `RoleOnboardingScreen`.
  - `authenticated`: Sesión activa lista; muestra `AppShellScreen`.
- **Campos de `AuthFlowState`**:
  - `status`: `AuthStatus`
  - `session`: `AuthSession?`
  - `isSubmitting`: `bool` (bloqueo *single-flight*)
  - `failedAttempts`: `int` (contador de fallos consecutivos de login)
  - `lockedUntil`: `DateTime?` (bloqueo de `60s` tras alcanzar `5` intentos fallidos)
  - `draftEmail`: `String` (conservado ante errores o paso a segundo plano)
  - `draftFullName`: `String` (conservado en registro ante paso a segundo plano)
  - `lastFailure`: `AppFailure?`

**State Transitions**:
```text
[App Start] ──> initializing
initializing ──(stored session valid & onboardingCompleted)──> authenticated
initializing ──(stored session valid & !onboardingCompleted)──> needsOnboarding
initializing ──(no stored session)──> unauthenticated
unauthenticated ──(Continue as Guest Fan)──> authenticated (isGuestFan: true, role: fan)
unauthenticated ──(Register valid)──> needsOnboarding
needsOnboarding ──(Complete Role Onboarding)──> authenticated
unauthenticated ──(Login valid)──> authenticated
unauthenticated ──(5th consecutive invalid login)──> unauthenticated (lockedUntil = now + 60s)
authenticated ──(Switch Active Role in Profile)──> authenticated (updated activeRole)
authenticated ──(Logout)──> unauthenticated (clears stored session & sensitive cache)
```
