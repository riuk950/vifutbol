# Quickstart & Validation Guide: Escaneo Dual de Cédula Colombiana (HU 21.2)

**Feature**: `047-colombian-id-dual-scan`

## 1. Requisitos de Dependencias y Permisos Nativos

- En `pubspec.yaml`:
  - `google_mlkit_barcode_scanning`
  - `google_mlkit_text_recognition`
  - `image_picker`
  - `permission_handler`
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  - Verificar `<uses-permission android:name="android.permission.CAMERA" />`.
- **iOS** (`ios/Runner/Info.plist`):
  - Verificar `<key>NSCameraUsageDescription</key>` con descripción en español explicando el uso para escanear la cédula de ciudadanía.

## 2. Escenarios de Validación

1. **Parsers Unitarios (`ColombianIdParser`)**:
   - Trama PDF417 con tildes/`Ñ` y relleno nulo → extracción exacta de documento, 4 partes de nombre, sexo, fecha `YYYYMMDD` y RH.
   - Bloque MRZ TD1 de 3 líneas (`I<COL...`) + texto OCR complementario → extracción exacta de apellidos, nombres, NUIP, fecha `YYMMDD` con siglo correcto, sexo y RH.
2. **Flujo UI en `PlayerPersonalDataScreen`**:
   - Presionar `"Escanear / Capturar Cédula"` (`Key('player_form_scan_id_button')`) → captura frontal y posterior con cámara en vivo.
   - Visualizar miniaturas de ambas caras y opción de repetir cualquiera.
   - Autocompletado reactivo mediante `applyDocumentScanData(...)` conservando campos manuales previos (teléfono, ubicación, posiciones) y recalculando edad al instante.
   - Intentar guardar sin ambas caras muestra `Key('player_form_id_images_error')`.
   - Permiso de cámara denegado muestra `Key('player_form_camera_permission_banner')` con botón a configuración y sin bloquear edición manual.
   - Responsividad verificada en 320px y escala de texto al 130%.

## 3. Comandos de Verificación

```bash
flutter gen-l10n
flutter analyze
flutter test test/unit/domain/colombian_id_parser_test.dart \
  test/domain/entities/user_account_test.dart \
  test/infrastructure/auth/supabase_auth_repository_test.dart \
  test/presentation/shell/player_personal_data_screen_test.dart
```
