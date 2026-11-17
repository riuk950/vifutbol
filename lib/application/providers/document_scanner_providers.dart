// lib/application/providers/document_scanner_providers.dart

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
