// lib/infrastructure/storage/supabase_document_storage_repository.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../../domain/repositories/document_storage_repository.dart';

/// Concrete [DocumentStorageRepository] adapter uploading identity document photos
/// to the private Supabase Storage bucket `player-documents` with owner-scoped RLS.
class SupabaseDocumentStorageRepository implements DocumentStorageRepository {
  final SupabaseClient client;
  final ConnectivityRepository connectivity;
  final String bucketName;
  final String avatarBucketName;

  SupabaseDocumentStorageRepository({
    required this.client,
    required this.connectivity,
    this.bucketName = 'player-documents',
    this.avatarBucketName = 'player-avatars',
  });

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

  @override
  Future<String> uploadPlayerAvatar({
    required String userId,
    required String localPath,
    String? existingPhotoUrl,
  }) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw const OfflineAuthOperationFailure(
        'Se requiere conexión a internet para subir la foto de perfil.',
      );
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return existingPhotoUrl ?? '';
      }

      final storage = client.storage.from(avatarBucketName);
      final avatarPath = '$userId/avatar.jpg';
      await storage.upload(
        avatarPath,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final basePublicUrl = storage.getPublicUrl(avatarPath);
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      return '$basePublicUrl?t=$cacheBuster';
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw DocumentUploadFailure(
        'Error al subir la fotografía de perfil. Inténtalo nuevamente.',
        e,
      );
    }
  }

  @override
  Future<String> uploadRefereeCertificationDocument({
    required String userId,
    required String localPath,
    String? existingDocumentUrl,
  }) async {
    return localPath.isNotEmpty ? localPath : (existingDocumentUrl ?? '');
  }

  @override
  Future<String?> getSignedDocumentUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    final cleanPath = storagePath.trim().replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.isEmpty) return null;
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    try {
      final conn = await connectivity.checkConnectivity();
      if (conn.isDisconnected) return null;

      final storage = client.storage.from(bucketName);
      final signedUrl = await storage.createSignedUrl(
        cleanPath,
        expiresInSeconds,
      );
      return signedUrl;
    } catch (_) {
      return null;
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

  @override
  Future<String> uploadPlayerAvatar({
    required String userId,
    required String localPath,
    String? existingPhotoUrl,
  }) async {
    return localPath.isNotEmpty ? localPath : (existingPhotoUrl ?? '');
  }

  @override
  Future<String> uploadRefereeCertificationDocument({
    required String userId,
    required String localPath,
    String? existingDocumentUrl,
  }) async {
    return localPath.isNotEmpty ? localPath : (existingDocumentUrl ?? '');
  }

  @override
  Future<String?> getSignedDocumentUrl({
    required String storagePath,
    int expiresInSeconds = 300,
  }) async {
    return storagePath.isNotEmpty ? storagePath : null;
  }
}
