# Implementation Plan: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Branch**: `002-auth-onboarding-rbac` | **Date**: 2026-11-03 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/002-auth-onboarding-rbac/spec.md)

**Input**: Feature specification from `/specs/002-auth-onboarding-rbac/spec.md`

## Summary

Implementar el sistema de autenticación, onboarding de rol deportivo, persistencia/rehidratación offline de sesión y control de acceso basado en los cinco roles del campeonato (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) cumpliendo la Constitución v2.0.0:
1. Puerta de entrada inicial reactiva (`AuthGate`) que presenta `WelcomeAuthScreen` (*Iniciar sesión*, *Crear cuenta* o *"Continuar como Aficionado"*), `RoleOnboardingScreen` (selección inicial de rol deportivo con código de autorización para `Organizador`/`Árbitro` en `prod` y acceso libre a los 5 roles en `dev`) y `AppShellScreen`.
2. Matriz determinista de dominio (`RolePermissionMatrix`) y guarda visual (`KickPulseRoleGuard`) que hacen cumplir estrictamente los permisos de lectura y escritura de cada uno de los 5 roles, integrando en la pestaña *Perfil* (`ProfileTabView`) la insignia del rol activo, el selector de cambio entre roles autorizados, el panel de permisos activos y el cierre de sesión seguro.
3. Rehidratación offline automática (`< 2s`) de sesiones previamente autenticadas mediante el almacenamiento local aislado por entorno (`vifutbol_dev` / `vifutbol_prod`), exigencia de conectividad activa para nuevos inicios de sesión o registros, bloqueo temporal de `60s` tras `5` intentos fallidos consecutivos, conservación de datos no sensibles en formularios ante paso a segundo plano y cero exposición de contraseñas o tokens en logs.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter `>=3.11.0`

**Primary Dependencies**: `flutter_localizations` (SDK), `intl`, `flutter_riverpod`, `fluro`, `hive` + `hive_flutter`, `connectivity_plus`, `uuid`

**Storage**: Persistencia local aislada por entorno (`vifutbol_dev` / `vifutbol_prod`) mediante `LocalStorageRepository` (`HiveLocalStorageRepository`) con fallback resiliente en memoria.

**Testing**: `flutter_test` (SDK), `mocktail` y `fake_async` para pruebas unitarias de dominio (matriz RBAC y entidades), infraestructura (repositorio de sesión y cuentas), aplicación (`AuthController` y bloqueo de 60s) y pruebas de widgets (`WelcomeAuthScreen`, `RoleOnboardingScreen`, `ProfileTabView`).

**Target Platform**: iOS y Android (Smartphones en orientación vertical *Portrait*).

**Project Type**: `mobile-app` (Aplicación móvil deportiva *Offline-First*).

**Performance Goals**: Rehidratación de sesión en frío `< 2s` (online y offline); cierre de sesión y limpieza de datos sensibles `< 1s`; transición fluida a `60 fps`.

**Constraints**: Rehidratación *Offline-First* para sesiones activas; red activa requerida para nuevo login/registro; bloqueo de `60s` tras `5` intentos fallidos; objetivos táctiles `>= 44x44px` con bloqueo *single-flight*; 0 textos *hardcoded* fuera de `l10n`; 0 contraseñas/tokens en logs.

**Scale/Scope**: Cubre los 5 roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`), 3 vistas nuevas/actualizadas (`WelcomeAuthScreen`, `RoleOnboardingScreen`, `ProfileTabView`) y el guardián transversal `KickPulseRoleGuard` para las Épicas 3 a 9.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Gate | Status | Verification Evidence |
|------------------|--------|-----------------------|
| **I. La Spec Manda (Spec-Driven Development)** | PASS | `spec.md` completado, clarificado (`/speckit-clarify` con 3 decisiones) y validado (`16/16` en `requirements.md`) incorporando `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | `AuthSession` y `UserAccount` persisten de forma determinista y aislada por entorno (`vifutbol_dev` vs `vifutbol_prod`) con IDs únicos inmutables. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | Plan incluye pruebas unitarias y de widgets dedicadas en `test/domain/`, `test/infrastructure/`, `test/application/` y `test/presentation/`. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | PASS | `UserRole`, `RolePermissionMatrix`, `UserAccount`, `AuthSession` y `AuthRepository` residen en `lib/domain/` sin dependencias de UI ni paquetes externos. |
| **V. Segregación de Roles y Fidelidad a `DESIGN.md`** | PASS | Matriz exacta para los 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y componentes adheridos a *KickPulse Mobile* (`#080B11`, `#0E1422`, `#22C55E`, `>= 44x44px`). |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | Código técnico, identificadores y tests 100% en inglés; textos visibles, errores y etiquetas de roles 100% en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`MOBILE_GUIDELINES.md`)** | PASS | Contempla rehidratación offline, conservación de borrador no sensible en segundo plano, confirmación al salir con cambios sin guardar, foco de teclado (`Siguiente`/`Enviar`), bloqueo *single-flight* y sanitización de logs. |

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-onboarding-rbac/
├── plan.md              # Este archivo (plan de implementación técnica)
├── research.md          # Decisiones de arquitectura y seguridad (Fase 0)
├── data-model.md        # Entidades de dominio, matriz RBAC y máquina de estados (Fase 1)
├── quickstart.md        # Guía de ejecución y verificación (Fase 1)
├── contracts/
│   └── auth-rbac-contract.md  # Contratos de pantallas, insignias y guardas RBAC (Fase 1)
└── tasks.md             # Lista de tareas ordenadas por dependencias (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                     # Catálogo en español ampliado con textos de Auth, Onboarding y 5 Roles
│   └── app_localizations*.dart                        # Clases regeneradas por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   ├── auth_flow_state.dart                       # Enum AuthStatus y estado inmutable AuthFlowState
│   │   ├── auth_session.dart                          # Entidad AuthSession con redacción de sessionToken
│   │   ├── role_permission_matrix.dart                # Enum RoleCapability y matriz pura RolePermissionMatrix
│   │   ├── user_account.dart                          # Entidad UserAccount (id, email, activeRole, authorizedRoles)
│   │   └── user_role.dart                             # Enum UserRole (organizer, coach, referee, player, fan)
│   ├── failures/
│   │   └── app_failure.dart                           # Ampliado con fallos de autenticación, credenciales, bloqueo 60s y RBAC
│   └── repositories/
│       └── auth_repository.dart                       # Contrato de autenticación, onboarding, cambio de rol y sesión
├── application/
│   ├── controllers/
│   │   └── auth_controller.dart                       # StateNotifier con login, registro, onboarding, bloqueo de 60s y borradores
│   ├── providers/
│   │   └── auth_providers.dart                        # Providers de Riverpod para AuthRepository, AuthController y permisos activos
│   └── use_cases/
│       ├── authenticate_user_use_case.dart            # Caso de uso de login, registro y acceso como Aficionado
│       ├── check_role_permission_use_case.dart        # Caso de uso de validación RBAC y autorización de cambio de rol
│       └── manage_session_use_case.dart               # Caso de uso de rehidratación offline, onboarding y logout seguro
├── infrastructure/
│   └── auth/
│       └── local_auth_repository.dart                 # Adaptador de AuthRepository sobre LocalStorageRepository y ConnectivityRepository
└── presentation/
    ├── app.dart                                       # Actualizado para montar AuthGate como home reactivo
    ├── auth/
    │   ├── auth_gate.dart                             # Enrutador reactivo entre WelcomeAuthScreen, RoleOnboardingScreen y AppShellScreen
    │   ├── role_onboarding_screen.dart                # Pantalla de selección inicial de rol y código de autorización en prod
    │   ├── welcome_auth_screen.dart                   # Pantalla de Bienvenida, Login, Registro y acceso directo Aficionado
    │   └── widgets/
    │       └── kick_pulse_role_guard.dart             # Widget guardián RBAC para proteger vistas y acciones por RoleCapability
    ├── navigation/
    │   └── app_router.dart                            # Rutas ampliadas (/auth, /onboarding) con soporte de guardas
    └── shell/
        └── tabs/
            └── profile_tab_view.dart                  # Pestaña Perfil con insignia de rol, selector de rol activo, permisos y logout

test/
├── domain/
│   └── role_permission_matrix_test.dart               # Pruebas exhaustivas de los 5 roles, capacidades y reglas dev/prod
├── infrastructure/
│   └── local_auth_repository_test.dart                # Pruebas de persistencia aislada, rehidratación offline, sanitización y logout
├── application/
│   └── auth_controller_test.dart                      # Pruebas de login, registro, modo Aficionado, bloqueo de 60s tras 5 fallos y cambio de rol
└── presentation/
    └── auth_flow_widget_test.dart                     # Pruebas de widgets para WelcomeAuthScreen, RoleOnboardingScreen, ProfileTabView y RBAC
```

**Structure Decision**: Se extiende la estructura limpia de proyecto móvil único (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation` y `test/`) establecida en la **HU 1.1**, manteniendo el dominio 100% libre de dependencias de interfaz o infraestructura.

## Complexity Tracking

> **No hay violaciones a la Constitución.** Todas las puertas de verificación (`Constitution Check` pre-investigación y post-diseño) se cumplen al 100%.
