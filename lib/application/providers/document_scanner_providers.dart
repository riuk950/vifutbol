// lib/application/providers/document_scanner_providers.dart

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_environment.dart';
import '../../domain/repositories/colombian_id_scanner_service.dart';
import '../../domain/repositories/document_storage_repository.dart';
import '../../infrastructure/scanner/mlkit_colombian_id_scanner_service.dart';
import '../../infrastructure/storage/supabase_document_storage_repository.dart';
import 'foundation_providers.dart';
import 'supabase_providers.dart';

/// Provider exposing the [ColombianIdScannerService] implementation.
final colombianIdScannerServiceProvider =
    Provider<ColombianIdScannerService>((ref) {
  return MlkitColombianIdScannerService();
});

/// Provider exposing the [DocumentStorageRepository] implementation.
final documentStorageRepositoryProvider =
    Provider<DocumentStorageRepository>((ref) {
  final config = ref.watch(environmentConfigProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final connectivity = ref.watch(connectivityRepositoryProvider);

  if (config.environment == AppEnvironment.development &&
      config.supabase.isConfigured &&
      supabaseClient != null) {
    return SupabaseDocumentStorageRepository(
      client: supabaseClient,
      connectivity: connectivity,
    );
  }

  return const LocalDocumentStorageRepository();
});

/// Asynchronously resolves an image reference (which can be a local filesystem path,
/// an existing HTTP(S) URL, or a private Supabase Storage relative path) into a displayable
/// URL or local path.
final resolveDocumentUrlProvider =
    FutureProvider.family<String?, String?>((ref, rawPath) async {
  if (rawPath == null || rawPath.trim().isEmpty) return null;
  final path = rawPath.trim();
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final localFile = File(path);
  if (localFile.existsSync()) {
    return path;
  }
  final storageRepo = ref.watch(documentStorageRepositoryProvider);
  return await storageRepo.getSignedDocumentUrl(
    storagePath: path,
    expiresInSeconds: 3600,
  );
});
