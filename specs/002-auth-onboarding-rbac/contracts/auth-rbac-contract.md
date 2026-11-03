# UI & Authorization Contracts: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Feature**: `002-auth-onboarding-rbac`  
**Date**: 2026-11-03

---

## 1. Navigation & Entry Gate Contract (`FR-001`, `FR-005`)

| Route / Screen | Condition | Purpose |
|----------------|-----------|---------|
| `AuthGate` (`lib/presentation/auth/auth_gate.dart`) | Root `home` of `App` | Observa `authControllerProvider` y redirige reactivamente según `AuthStatus`. |
| `WelcomeAuthScreen` (`lib/presentation/auth/welcome_auth_screen.dart`) | `AuthStatus.unauthenticated` | Formulario de *Iniciar sesión* / *Crear cuenta* con teclado fluido (`Siguiente`/`Enviar`), bloqueo *single-flight*, alerta de bloqueo de `60s` tras `5` fallos y botón directo *"Continuar como Aficionado"*. |
| `RoleOnboardingScreen` (`lib/presentation/auth/role_onboarding_screen.dart`) | `AuthStatus.needsOnboarding` | Selección interactiva de los 5 roles deportivos con insignia *KickPulse Mobile*, validación de código de autorización para `Organizador`/`Árbitro` en `prod` y confirmación al intentar retroceder con cambios sin guardar. |
| `AppShellScreen` (`lib/presentation/shell/app_shell_screen.dart`) | `AuthStatus.authenticated` | Contenedor principal de 4 pestañas (*Jornada*, *Posiciones*, *Sedes*, *Perfil*) adaptado al rol activo. |

---

## 2. Role Badge & Visual Identity Contract (`DESIGN.md` — `FR-003`, `FR-007`)

Cada `UserRole` se presenta en la interfaz con su etiqueta localizada en español (`lib/l10n/app_es.arb`) y su variante semántica de `KickPulseBadge`:

| `UserRole` | Spanish Label (`app_es.arb`) | `KickPulseBadgeVariant` | Semantic Accent |
|------------|------------------------------|-------------------------|-----------------|
| `organizer` | `Organizador` | `live` | `#EF4444` (Autoridad oficial del torneo) |
| `coach` | `Entrenador` | `info` | `#38BDF8` (Dirección técnica y táctica) |
| `referee` | `Árbitro` | `warning` | `#F59E0B` (Juez de acta oficial en cancha) |
| `player` | `Jugador` | `dev` / `primary` | `#22C55E` (Protagonista en el terreno de juego) |
| `fan` | `Aficionado` | `neutral` | `#94A3B8` (Consulta pública del campeonato) |

---

## 3. RBAC Guard & Profile Contract (`FR-004`, `FR-007`, `FR-008`, `FR-009`)

1. **`KickPulseRoleGuard` (`lib/presentation/auth/widgets/kick_pulse_role_guard.dart`)**:
   - Recibe `requiredCapability` (`RoleCapability`), `child` (vista o acción permitida) y un modo opcional `fallback` (ocultar el control o mostrar tarjeta explicativa en español *"Acceso restringido para tu rol actual"*).
2. **`ProfileTabView` (`lib/presentation/shell/tabs/profile_tab_view.dart`)**:
   - Muestra el nombre completo, correo electrónico (o indicador de modo visitante `Aficionado`) y la insignia del rol activo.
   - Permite alternar el rol activo entre los roles autorizados del usuario (`authorizedRoles` en `prod`, o cualquiera de los 5 roles en `dev`) actualizando inmediatamente los permisos en toda la aplicación.
   - Lista las capacidades habilitadas y restringidas para el rol activo (`RolePermissionMatrix`) permitiendo verificar interactivamente el bloqueo de acciones no autorizadas.
   - Incluye el botón *"Cerrar sesión"* (o *"Iniciar sesión / Crear cuenta"* si opera como visitante `Aficionado`) con área táctil `>= 44x44px` y limpieza inmediata de la sesión local.
