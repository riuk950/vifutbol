# Quickstart Validation Guide: HU 24.3 — Eliminación de Cuenta con Borrado en Cascada (Local y Nube)

**Feature**: `056-account-cascade-deletion`  
**Contract**: [delete_account_contract.md](./contracts/delete_account_contract.md)  
**Data Model**: [data-model.md](./data-model.md)

## Prerequisites

- Ejecutar `flutter gen-l10n` tras agregar las llaves en `lib/l10n/app_es.arb`.
- (Para entorno real con Supabase) Aplicar la migración `supabase/migrations/202611250001_delete_user_account_cascade.sql` en el proyecto Supabase.

## Automated Validation Commands

1. **Análisis estático (cero errores y cero advertencias)**:
   ```sh
   flutter analyze lib/domain/repositories/auth_repository.dart lib/application/use_cases/delete_account_use_case.dart lib/application/providers/auth_providers.dart lib/application/controllers/auth_controller.dart lib/infrastructure/auth/ lib/presentation/shell/tabs/ test/application/auth_controller_test.dart test/infrastructure/local_auth_repository_test.dart test/infrastructure/supabase_auth_repository_test.dart test/presentation/shell/profile_tab_view_test.dart
   ```
   **Expected**: `No issues found!`

2. **Suite de pruebas unitarias y de widget**:
   ```sh
   flutter test test/application/auth_controller_test.dart test/infrastructure/local_auth_repository_test.dart test/infrastructure/supabase_auth_repository_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart
   ```
   **Expected**: Todas las pruebas pasan (`All tests passed!`), verificando:
   - Borrado exitoso en cascada (RPC remoto + limpieza completa de Hive/namespace + redirección a `AuthStatus.unauthenticated`).
   - Cancelación en diálogo sin mutaciones.
   - Modo offline: mensaje en español y 0 borrados locales.
   - Fallo remoto: mensaje en español y aborto del borrado local.
   - Bloqueo `single-flight` ante múltiples confirmaciones rápidas.
   - Botón `Eliminar cuenta` oculto en modo visitante y visible para todos los roles autenticados.

## Manual Mobile Validation (Android / iOS)

1. Iniciar sesión con una cuenta de prueba en `dev` (`flutter run --flavor dev -t lib/env/main.dev.dart`).
2. En **Perfil**, activar modo avión, pulsar **Eliminar cuenta** y confirmar → verificar aviso en español y que la sesión sigue activa.
3. Restablecer conexión, pulsar **Eliminar cuenta** → **Cancelar** → verificar que nada cambia.
4. Pulsar **Eliminar cuenta** → confirmar → verificar indicador de carga, redirección a `WelcomeAuthScreen`, y al reiniciar la app confirmar que no se restaura sesión ni datos locales.
