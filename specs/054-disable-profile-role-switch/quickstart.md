# Quickstart Validation Guide: HU 24.1 — Deshabilitar Cambio de Rol Activo en el Perfil

**Feature**: `054-disable-profile-role-switch`  
**Contract**: [profile_role_display_contract.md](./contracts/profile_role_display_contract.md)  
**Data Model**: [data-model.md](./data-model.md)

## Prerequisites

- Flutter SDK configurado en el proyecto (`flutter pub get` ejecutado).
- Entorno local listo para análisis estático y pruebas de widget.

## Automated Validation Commands

1. **Análisis estático (cero errores y cero advertencias)**:
   ```sh
   flutter analyze lib/presentation/shell/tabs/profile_tab_view.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart
   ```
   **Expected**: `No issues found!`

2. **Pruebas de widget de Perfil y flujo de autenticación**:
   ```sh
   flutter test test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart
   ```
   **Expected**: Todas las pruebas pasan (`All tests passed!`), verificando:
   - Ausencia total de `ChoiceChip` y del texto `Cambiar rol activo` para los 5 roles + invitado en `dev` y `prod`.
   - Presencia de `ValueKey('profile_active_role_badge')` con el rol activo correcto en español.
   - 0 invocaciones a `switchActiveRole` tras toques repetidos en el perfil.
   - Sin desbordamiento visual con escalado de texto ampliado.
   - Sin regresiones en completitud de perfil, datos personales de jugador, matriz de permisos y cierre de sesión.

3. **Regresión de suite de infraestructura de autenticación**:
   ```sh
   flutter test test/infrastructure/supabase_auth_repository_test.dart
   ```
   **Expected**: Todas las pruebas pasan sin alteraciones.

## Manual Mobile Validation (Android / iOS)

1. Ejecutar en entorno `dev`:
   ```sh
   flutter run --flavor dev -t lib/env/main.dev.dart
   ```
2. Iniciar sesión con cualquier rol (o como visitante) y abrir la pestaña **Perfil**.
3. Confirmar que:
   - La insignia del rol activo aparece en la tarjeta de identidad superior en modo solo lectura.
   - No existe la sección `Cambiar rol activo` ni chips de roles.
   - Al tocar repetidamente la insignia del rol, enviar la app a segundo plano y volver, o activar modo avión, el rol activo permanece intacto.
   - Aumentar el tamaño de fuente del dispositivo no recorta la insignia ni los textos de la tarjeta de identidad.
