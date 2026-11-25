# Research Findings: Deshabilitar Cambio de Rol Activo en el Perfil (HU 24.1)

**Feature**: `054-disable-profile-role-switch`  
**Date**: 2026-11-25

## Decision 1: Eliminación completa de la sección de cambio de rol en `ProfileTabView`

- **Decision**: Eliminar el bloque `// Role Switcher Section` completo (encabezado `l10n.profileSwitchRole`, `KickPulseCard`, textos condicionales `isDev` y lista de `ChoiceChip` con llamada a `authControllerProvider.notifier.switchActiveRole`) de `lib/presentation/shell/tabs/profile_tab_view.dart`, conservando únicamente la insignia `KickPulseBadge` de solo lectura del rol activo en la tarjeta de identidad superior.
- **Rationale**: Confirmado explícitamente durante `/speckit-clarify` (Opción B). Elimina por completo cualquier superficie interactiva de cambio de rol, suprime el texto hardcoded de entorno `dev`, limpia la pantalla de Perfil y cumple FR-001 a FR-005.
- **Alternatives considered**:
  - *Mantener `ChoiceChip` deshabilitados (`onSelected: null`)*: Descartado por decisión de producto (Opción B) para evitar controles muertos en pantalla.
  - *Reemplazar por tarjeta informativa de solo lectura*: Descartado porque la tarjeta de identidad superior ya comunica el rol activo con `KickPulseBadge`.

## Decision 2: Conservar `AuthController.switchActiveRole` y contratos de dominio/repositorio

- **Decision**: Mantener intactos `AuthController.switchActiveRole`, `ManageSessionUseCase.switchActiveRole` y las implementaciones de `AuthRepository.switchActiveRole` (`LocalAuthRepository`, `SupabaseAuthRepository`).
- **Rationale**: Existen pruebas unitarias e infraestructura dedicadas (`test/infrastructure/supabase_auth_repository_test.dart`) que validan la política RBAC a nivel de repositorio, y la especificación (Assumptions) establece explícitamente que esta historia deshabilita el cambio de rol desde la pantalla de Perfil sin eliminar lógica de dominio subyacente.
- **Alternatives considered**:
  - *Eliminar `switchActiveRole` de toda la base de código*: Descartado por estar fuera del alcance de HU 24.1 y rompería pruebas de infraestructura y posibles flujos internos.

## Decision 3: Actualización de pruebas heredadas e incorporación de matriz de pruebas completa

- **Decision**:
  1. Actualizar la prueba heredada en `test/presentation/auth_flow_widget_test.dart` (`ProfileTabView displays active role badge and allows switching`) para verificar el nuevo contrato: muestra la insignia de rol activo en solo lectura, NO renderiza `ChoiceChip` ni `Cambiar rol activo`, y garantiza `verifyNever(() => mockAuthRepository.switchActiveRole(...))`.
  2. Agregar un grupo de pruebas en `test/presentation/shell/profile_tab_view_test.dart` que valide:
     - Los 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) + modo visitante en entorno `dev` y en entorno `prod`.
     - Usuarios con múltiples `authorizedRoles` sin posibilidad de cambiar de rol.
     - Pulsaciones repetidas sobre la insignia de rol activo sin invocaciones a `switchActiveRole`.
     - Accesibilidad / escalado de texto ampliado (`textScaler: TextScaler.linear(1.5)`) sin overflow y con semántica de solo lectura.
     - Regresión cero en acciones existentes (completitud de perfil, datos personales de jugador, matriz de permisos y cierre de sesión).
- **Rationale**: Garantiza cumplimiento estricto de la Constitución (Principio III y VII) y de todos los criterios de aceptación (SC-001 a SC-004).
- **Alternatives considered**:
  - *Solo agregar pruebas nuevas sin actualizar `auth_flow_widget_test.dart`*: Inviable porque `auth_flow_widget_test.dart` fallaría inmediatamente al desaparecer el `ChoiceChip`.

## Decision 4: Limpieza de imports y claves `l10n`

- **Decision**:
  - En `lib/presentation/shell/tabs/profile_tab_view.dart`, eliminar las variables locales sin uso (`config`, `isDev`, `availableRoles`) y los imports que queden sin uso (`foundation_providers.dart`, `app_environment.dart`) para cumplir análisis estático con cero advertencias.
  - Conservar la clave `profileSwitchRole` en `lib/l10n/app_es.arb` (o verificar si otro archivo la referencia) — dado que no genera advertencias de analizador y evita regenerar artefactos `l10n` innecesariamente, se mantendrá sin cambios a menos que se requiera alguna nueva etiqueta de accesibilidad en español.
  - Agregar `Key('profile_active_role_badge')` y semántica explícita (`Semantics(readOnly: true, ...)`) a la insignia de rol activo en la tarjeta de identidad para facilitar pruebas deterministas y lectores de pantalla (FR-007).
- **Rationale**: Mantiene el diff mínimo, limpio y con 0 advertencias en `flutter analyze`.
- **Alternatives considered**:
  - *Eliminar `profileSwitchRole` de `app_es.arb` y regenerar `app_localizations*.dart`*: Innecesario para esta historia y aumenta la superficie del diff sin beneficio funcional.
