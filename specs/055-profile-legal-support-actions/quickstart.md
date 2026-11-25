# Quickstart Validation Guide: HU 24.2 — Botones de Quitar Anuncios, Términos, Políticas y FAQ en Perfil

**Feature**: `055-profile-legal-support-actions`  
**Contract**: [profile_legal_support_contract.md](./contracts/profile_legal_support_contract.md)  
**Data Model**: [data-model.md](./data-model.md)

## Prerequisites

- Ejecutar `flutter gen-l10n` tras agregar las llaves en `lib/l10n/app_es.arb`.

## Automated Validation Commands

1. **Análisis estático (cero errores y cero advertencias)**:
   ```sh
   flutter analyze lib/presentation/shell/tabs/ lib/presentation/navigation/app_router.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart
   ```
   **Expected**: `No issues found!`

2. **Pruebas de widget de Perfil y flujo de autenticación**:
   ```sh
   flutter test test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart
   ```
   **Expected**: Todas las pruebas pasan (`All tests passed!`), verificando:
   - Presencia y orden vertical exacto de los 4 botones debajo de "Permisos y capacidades del rol" y antes del botón de cierre/inicio de sesión.
   - Visibilidad para los 5 roles y modo visitante.
   - Navegación a `ProfileLegalDocumentScreen` (Términos y Políticas) y `ProfileFaqScreen` (FAQ) con contenido en español y retorno limpio al Perfil.
   - Apertura de `RemoveAdsDialog` con información en español y estado "Próximamente".
   - Protección contra doble tap (solo 1 instancia abierta ante taps rápidos repetidos).
   - Escalado de texto `1.5x` sin errores de overflow.

## Manual Mobile Validation (Android / iOS)

1. Ejecutar la app en modo avión (sin conexión):
   ```sh
   flutter run --flavor dev -t lib/env/main.dev.dart
   ```
2. Ir a la pestaña **Perfil** y desplazarse debajo de **Permisos y capacidades del rol**.
3. Verificar los 4 botones en orden, abrir cada destino, hacer scroll en los documentos legales y FAQ, probar el botón atrás del sistema y comprobar que el estado del Perfil permanece intacto.
