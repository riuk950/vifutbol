// lib/domain/repositories/colombian_id_scanner_service.dart

import '../entities/colombian_id_scan_result.dart';

/// Contract for scanning and capturing Colombian identity documents.
abstract class ColombianIdScannerService {
  /// Captures a live camera photo for the given document side ([isFront]).
  ///
  /// Returns the local file path of the captured image, or `null` if the user cancelled.
  /// Throws [CameraPermissionDeniedFailure] if camera permission is denied.
  Future<String?> captureDocumentPhoto({required bool isFront});

  /// Processes captured front and/or back image paths using on-device ML Kit
  /// (PDF417 barcode scanning and Latin text recognition / MRZ).
  Future<ColombianIdScanResult> scanDocumentImages({
    String? frontImagePath,
    String? backImagePath,
  });

  /// Opens OS application settings when camera permission is permanently denied.
  Future<void> openCameraSettings();
}
