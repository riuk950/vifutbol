// lib/infrastructure/scanner/mlkit_colombian_id_scanner_service.dart

import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/colombian_id_scan_result.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/colombian_id_scanner_service.dart';
import '../../domain/services/colombian_id_parser.dart';

/// Concrete adapter implementing [ColombianIdScannerService] using:
/// - `image_picker` (strictly live rear camera per Q2)
/// - `permission_handler` for OS camera permissions
/// - `google_mlkit_barcode_scanning` for PDF417 barcode decoding
/// - `google_mlkit_text_recognition` for ICAO 9303 TD1 MRZ & Latin OCR
class MlkitColombianIdScannerService implements ColombianIdScannerService {
  MlkitColombianIdScannerService({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> captureDocumentPhoto({required bool isFront}) async {
    try {
      final cameraStatus = await Permission.camera.status;

      if (cameraStatus.isPermanentlyDenied) {
        throw const CameraPermissionDeniedFailure(
          'Se requiere permiso de cámara para capturar la cédula.',
          true,
        );
      }

      if (cameraStatus.isDenied || cameraStatus.isRestricted) {
        final requestResult = await Permission.camera.request();
        if (requestResult.isPermanentlyDenied) {
          throw const CameraPermissionDeniedFailure(
            'Se requiere permiso de cámara para capturar la cédula.',
            true,
          );
        }
        if (requestResult.isDenied || requestResult.isRestricted) {
          throw const CameraPermissionDeniedFailure(
            'Se requiere permiso de cámara para capturar la cédula.',
            false,
          );
        }
      }

      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );

      return file?.path;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('denied') ||
          code.contains('camera_access') ||
          msg.contains('permission') ||
          msg.contains('denied')) {
        throw CameraPermissionDeniedFailure(
          'Se requiere permiso de cámara para capturar la cédula.',
          false,
          e,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> openCameraSettings() async {
    await openAppSettings();
  }

  @override
  Future<ColombianIdScanResult> scanDocumentImages({
    String? frontImagePath,
    String? backImagePath,
  }) async {
    if ((frontImagePath == null || frontImagePath.isEmpty) &&
        (backImagePath == null || backImagePath.isEmpty)) {
      return ColombianIdScanResult.empty;
    }

    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.pdf417]);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    ColombianIdScanResult backPdfResult = ColombianIdScanResult.empty;
    ColombianIdScanResult backOcrResult = ColombianIdScanResult.empty;
    ColombianIdScanResult frontOcrResult = ColombianIdScanResult.empty;

    try {
      // 1. Process back image (where PDF417 or MRZ usually resides)
      if (backImagePath != null && backImagePath.isNotEmpty) {
        final backInputImage = InputImage.fromFilePath(backImagePath);

        // Barcode scan
        try {
          final barcodes = await barcodeScanner.processImage(backInputImage);
          for (final barcode in barcodes) {
            if (barcode.format == BarcodeFormat.pdf417 &&
                barcode.rawValue != null &&
                barcode.rawValue!.isNotEmpty) {
              final parsed = ColombianIdParser.parsePdf417(barcode.rawValue!);
              if (parsed.hasAnyField) {
                backPdfResult = parsed;
                break;
              }
            }
          }
        } catch (_) {
          // Barcode scan failed or no barcode found
        }

        // Text scan on back
        try {
          final backText = await textRecognizer.processImage(backInputImage);
          if (backText.text.isNotEmpty) {
            backOcrResult = ColombianIdParser.parseMrzAndOcr(backText.text);
          }
        } catch (_) {
          // OCR failed on back image
        }
      }

      // 2. Process front image (MRZ or printed details)
      if (frontImagePath != null && frontImagePath.isNotEmpty) {
        final frontInputImage = InputImage.fromFilePath(frontImagePath);
        try {
          final frontText = await textRecognizer.processImage(frontInputImage);
          if (frontText.text.isNotEmpty) {
            frontOcrResult = ColombianIdParser.parseMrzAndOcr(frontText.text);
          }
        } catch (_) {
          // OCR failed on front image
        }
      }

      // 3. Merge results according to priority:
      // Primary: back PDF417
      // Secondary: back MRZ / OCR
      // Tertiary: front MRZ / OCR
      final ocrCombined = ColombianIdParser.mergeResults(backOcrResult, frontOcrResult);
      final finalResult = ColombianIdParser.mergeResults(backPdfResult, ocrCombined);

      return finalResult;
    } finally {
      await barcodeScanner.close();
      await textRecognizer.close();
    }
  }
}
