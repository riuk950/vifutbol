# Quickstart Validation Guide: HU 25.2 Referee Avatar & Profile Summary

**Feature**: `058-referee-avatar-profile-summary`
**Contracts**: [referee_avatar_summary_contract.md](contracts/referee_avatar_summary_contract.md)
**Data Model**: [data-model.md](data-model.md)

## Prerequisites

- Flutter SDK configurado en el workspace (`/Volumes/DATA/Development/FlutterProjects/vifutbol`).
- Migración SQL `supabase/migrations/202611250003_referee_avatar_photo_url.sql` lista (y aplicada en `supabase-db` para pruebas contra nube).

## Automated Validation Commands

1. Regenerar localizaciones tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```
2. Ejecutar análisis estático sobre los archivos modificados y nuevos:
   ```bash
   flutter analyze lib/presentation/navigation/app_router.dart \
     lib/presentation/shell/tabs/profile_tab_view.dart \
     lib/presentation/shell/tabs/referee_personal_data_screen.dart \
     lib/presentation/shell/tabs/referee_personal_data_summary_screen.dart \
     test/presentation/shell/profile_tab_view_test.dart \
     test/presentation/shell/referee_personal_data_screen_test.dart \
     test/presentation/shell/referee_personal_data_summary_screen_test.dart
   ```
   **Resultado esperado**: `No issues found!`.
3. Ejecutar la suite de pruebas de widget y regresión:
   ```bash
   flutter test test/presentation/shell/referee_personal_data_screen_test.dart \
     test/presentation/shell/referee_personal_data_summary_screen_test.dart \
     test/presentation/shell/profile_tab_view_test.dart \
     test/domain/entities/user_account_test.dart
   ```
   **Resultado esperado**: 100% de pruebas aprobadas.

## End-to-End Verification Scenarios

1. **Captura de avatar y guardado**:
   - Iniciar sesión como árbitro, abrir formulario de perfil, seleccionar foto de cámara o galería, confirmar vista previa circular y guardar → verifica llamada a `uploadPlayerAvatar` y `completeRoleProfile` con `photoUrl` con cache-buster.
2. **Visualización reactiva en `ProfileTabView`**:
   - Regresar a Perfil → verifica avatar real en `profile_identity_avatar` y badge `Perfil completo`.
3. **Pantalla resumen y edición**:
   - Tocar `profile_referee_personal_data_tile` con perfil completo → abre `RefereePersonalDataSummaryScreen` con avatar, datos personales, ubicación, nivel de certificación y vistas previas de cédula (ambos lados) + certificación arbitral.
   - Tocar `Editar` (`referee_summary_edit_action`) → abre `RefereePersonalDataScreen` precargado; al guardar un cambio, el resumen refleja el valor actualizado.
4. **Permisos y modo offline**:
   - Simular rechazo de permiso de cámara/galería → muestra mensaje claro en español sin perder los datos del formulario.
   - Simular guardado offline → muestra error de conectividad en español manteniendo la vista previa local y el formulario intactos.
