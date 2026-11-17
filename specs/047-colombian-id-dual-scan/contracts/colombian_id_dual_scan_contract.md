# Contracts: Escaneo Dual de Cédula Colombiana (HU 21.2)

**Feature**: `047-colombian-id-dual-scan`

## 1. Domain Parser & Service Contracts

### `ColombianIdParser` (`lib/domain/services/colombian_id_parser.dart`)
- `static ColombianIdScanResult parsePdf417(String rawPayload)`:
  - Parsea tramas oficiales de cédula amarilla colombiana (`PubDSK_` / offsets fijos / tokens separados por `\x00`).
  - Limpia ceros a la izquierda del número de documento, normaliza capitalización/espacios de nombres y apellidos, convierte sexo `'M'`/`'F'` a `PlayerSex`, fecha `YYYYMMDD` a `DateTime`, y RH a `BloodType`.
- `static ColombianIdScanResult parseMrzAndOcr(String fullOcrText, {DateTime? referenceDate})`:
  - Detecta bloque ICAO 9303 TD1 de 3 líneas (`I<COL...` / `IDCOL...`), limpia ruido OCR (`«` → `<`), extrae apellidos/nombres separados por `<<` y `<`, fecha `YYMMDD` con inferencia de siglo contra `referenceDate ?? DateTime.now()`, sexo, y NUIP.
  - Aplica heurísticas OCR sobre el texto impreso complementario para recuperar NUIP (si no viene completo en línea 1 MRZ) y grupo sanguíneo / RH (`(O|A|B|AB)\s*[+-]`).
- `static ColombianIdScanResult mergeResults(ColombianIdScanResult primary, ColombianIdScanResult secondary)`:
  - Combina resultados priorizando `primary` (PDF417) y rellenando campos faltantes desde `secondary` (MRZ/OCR).

### `ColombianIdScannerService` (`lib/domain/repositories/colombian_id_scanner_service.dart`)
```dart
abstract class ColombianIdScannerService {
  /// Captures a live camera photo for the given document side ('front' or 'back').
  /// Returns local file path or null if user cancelled.
  /// Throws [CameraPermissionDeniedFailure] if camera permission is denied.
  Future<String?> captureDocumentPhoto({required bool isFront});

  /// Processes captured front and/or back image paths using dual ML Kit strategy
  /// (PDF417 barcode priority + Latin OCR/MRZ).
  Future<ColombianIdScanResult> scanDocumentImages({
    String? frontImagePath,
    String? backImagePath,
  });

  /// Opens OS app settings when camera permission is permanently denied.
  Future<void> openCameraSettings();
}
```

### `DocumentStorageRepository` (`lib/domain/repositories/document_storage_repository.dart`)
```dart
abstract class DocumentStorageRepository {
  /// Uploads front and back document photos to private user-scoped storage
  /// and returns their persisted storage paths/URLs.
  Future<({String frontUrl, String backUrl})> uploadPlayerIdDocuments({
    required String userId,
    String? frontLocalPath,
    String? backLocalPath,
    String? existingFrontUrl,
    String? existingBackUrl,
  });
}
```

## 2. UI Component & Widget Keys Contract

En `PlayerPersonalDataScreen` (`lib/presentation/shell/tabs/player_personal_data_screen.dart`) y `IdDocumentCaptureCard` (`lib/presentation/shell/widgets/id_document_capture_card.dart`):
- Botón principal de inicio de escaneo/captura: `Key('player_form_scan_id_button')` (texto l10n `"Escanear / Capturar Cédula"`).
- Tarjeta / sección de captura de ambas caras: `Key('player_form_id_capture_card')`
- Miniatura / botón de captura cara frontal: `Key('player_form_id_front_preview')` y botón repetir/capturar `Key('player_form_id_front_capture_btn')`
- Miniatura / botón de captura cara posterior: `Key('player_form_id_back_preview')` y botón repetir/capturar `Key('player_form_id_back_capture_btn')`
- Indicador de procesamiento ML Kit: `Key('player_form_id_scanning_indicator')`
- Mensaje de error de validación cuando faltan caras al guardar: `Key('player_form_id_images_error')`
- Banner/alerta de permiso de cámara denegado con acceso a configuración: `Key('player_form_camera_permission_banner')` y `Key('player_form_open_settings_button')`
- Feedback de escaneo exitoso o parcial: `Key('player_form_id_scan_feedback')`

## 3. Repository & Controller Integration

- `AuthRepository.updateRoleProfile` y `AuthController.updateRoleProfile` reciben `RoleProfileData` con `documentFrontUrl` y `documentBackUrl`.
- Al guardar en `PlayerPersonalDataScreen`:
  1. Valida todos los campos obligatorios de HU 21.1 **y** que `capture.isComplete` (`hasFront && hasBack`).
  2. Si hay archivos locales recién capturados, invoca `DocumentStorageRepository.uploadPlayerIdDocuments(...)` antes de `updateRoleProfile(...)`.
  3. En `SupabaseAuthRepository`: verifica conectividad primero; sube al bucket privado `player-documents` (`<auth_uid>/document_front.jpg` y `<auth_uid>/document_back.jpg`) con `upsert: true`, pasa `documentFrontUrl` y `documentBackUrl` al RPC `complete_role_profile`.
  4. En `LocalAuthRepository` (modo local/offline): conserva las rutas locales en `documentFrontUrl` / `documentBackUrl` dentro de `RoleProfileData`.
