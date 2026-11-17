// lib/infrastructure/storage/supabase_document_storage_repository.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../../domain/repositories/document_storage_repository.dart';

/// Concrete [DocumentStorageRepository] adapter uploading identity document photos
/// to the private Supabase Storage bucket `player-documents` with owner-scoped RLS.
class SupabaseDocumentStorageRepository implements DocumentStorageRepository {
  SupabaseDocumentStorageRepository({
    required this.client,
    required this.connectivity,
    this.bucketName = 'player-documents',
  });

  final SupabaseClient client;
  final ConnectivityRepository connectivity;
  final String bucketName;

  @override
  Future<({String frontUrl, String backUrl})> uploadPlayerIdDocuments({
    required String userId,
    String? frontLocalPath,
    String? backLocalPath,
    String? existingFrontUrl,
    String? existingBackUrl,
  }) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw const OfflineAuthOperationFailure(
        'Se requiere conexión a internet para subir los documentos de identidad.',
      );
    }

    String resolvedFrontUrl = existingFrontUrl ?? '';
    String resolvedBackUrl = existingBackUrl ?? '';

    try {
      final storage = client.storage.from(bucketName);

      if (frontLocalPath != null && frontLocalPath.isNotEmpty) {
        final frontFile = File(frontLocalPath);
        if (await frontFile.exists()) {
          final frontPath = '$userId/document_front.jpg';
          await storage.upload(
            frontPath,
            frontFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
          resolvedFrontUrl = frontPath;
        }
      }

      if (backLocalPath != null && backLocalPath.isNotEmpty) {
        final backFile = File(backLocalPath);
        if (await backFile.exists()) {
          final backPath = '$userId/document_back.jpg';
          await storage.upload(
            backPath,
            backFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
          resolvedBackUrl = backPath;
        }
      }

      return (frontUrl: resolvedFrontUrl, backUrl: resolvedBackUrl);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw DocumentUploadFailure(
        'Error al subir las imágenes de la cédula. Inténtalo nuevamente.',
        e,
      );
    }
  }
}

/// Local fallback [DocumentStorageRepository] for testing or offline-first development.
class LocalDocumentStorageRepository implements DocumentStorageRepository {
  const LocalDocumentStorageRepository();

  @override
  Future<({String frontUrl, String backUrl})> uploadPlayerIdDocuments({
    required String userId,
    String? frontLocalPath,
    String? backLocalPath,
    String? existingFrontUrl,
    String? existingBackUrl,
  }) async {
    return (
      frontUrl: frontLocalPath ?? existingFrontUrl ?? '',
      backUrl: backLocalPath ?? existingBackUrl ?? '',
    );
  }
}
