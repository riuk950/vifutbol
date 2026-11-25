# Quickstart Validation Guide: HU 25.1 — Perfil Completo del Árbitro y Certificación Arbitral

**Feature**: `057-referee-profile-id-certification`  
**Contract**: [referee_profile_contract.md](./contracts/referee_profile_contract.md)  
**Data Model**: [data-model.md](./data-model.md)

## Prerequisites

- Ejecutar `flutter gen-l10n` tras agregar las llaves en `lib/l10n/app_es.arb`.
- Aplicar la migración `supabase/migrations/202611250002_referee_profile_and_certification_doc.sql` en el servidor Supabase (`supabase-db`).

## Automated Validation Commands

1. **Análisis estático (cero errores y cero advertencias)**:
   ```sh
   flutter analyze lib/domain/entities/role_profile_data.dart lib/domain/entities/user_account.dart lib/domain/repositories/document_storage_repository.dart lib/infrastructure/storage/supabase_document_storage_repository.dart lib/infrastructure/auth/supabase_auth_repository.dart lib/presentation/navigation/app_router.dart lib/presentation/shell/tabs/profile_tab_view.dart lib/presentation/shell/tabs/referee_personal_data_screen.dart test/domain/entities/user_account_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/shell/referee_personal_data_screen_test.dart
   ```
   **Expected**: `No issues found!`

2. **Suite de pruebas unitarias y de widget**:
   ```sh
   flutter test test/domain/entities/user_account_test.dart test/presentation/shell/referee_personal_data_screen_test.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/shell/player_personal_data_screen_test.dart
   ```
   **Expected**: Todas las pruebas pasan (`All tests passed!`), verificando:
   - `UserAccount.isProfileCompleteForActiveRole` para `UserRole.referee` exige todos los campos personales, ubicación, nivel arbitral, ambas caras de cédula y documento de certificación arbitral.
   - Navegación desde `ProfileTabView` a `/profile/referee-personal-data`.
   - Escaneo dual de cédula, captura de frente/reverso, captura/reemplazo de documento de certificación arbitral, validaciones en español, bloqueo `single-flight` y guardado exitoso.
   - Cero regresiones en `PlayerPersonalDataScreen` y demás roles.

## Manual Mobile Validation (Android / iOS)

1. Iniciar sesión como `Árbitro` en `dev` (`flutter run --flavor dev -t lib/env/main.dev.dart`).
2. Abrir **Perfil** → pulsar **Completar mi perfil** → verificar secciones de Datos Personales, Ubicación en Colombia, Cédula (ambos lados) y Certificación Arbitral.
3. Escanear cédula colombiana y capturar frente, reverso y documento de certificación arbitral desde cámara o galería.
4. Guardar y confirmar que el Perfil muestra la insignia verde **Perfil completo**.
