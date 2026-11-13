import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/sync_status_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/repositories/sync_outbox_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';
import 'package:vifutbol/infrastructure/sync/supabase_cloud_sync_service.dart';

/// Shared offline-first execution coordinator used by all 10 hybrid repositories.
final hybridRepositorySupportProvider = Provider<HybridRepositorySupport>((
  ref,
) {
  final connectivity = ref.watch(connectivityRepositoryProvider);
  final outbox = ref.watch(syncOutboxRepositoryProvider);
  return HybridRepositorySupport(
    connectivity: connectivity,
    outbox: outbox,
    userContextReader: () => ref.read(activeSyncUserContextProvider),
  );
});

/// Whether cloud Supabase hybrid sync is enabled for the active environment.
final isRemoteCloudSyncEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(environmentConfigProvider);
  final client = ref.watch(supabaseClientProvider);
  return config.environment == AppEnvironment.development &&
      config.supabase.isConfigured &&
      client != null;
});

/// Persistent FIFO [SyncOutboxRepository] provider.
final syncOutboxRepositoryProvider = Provider<SyncOutboxRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  return HiveSyncOutboxRepository(storage: storage);
});

/// Concrete [SupabaseCloudSyncService] exposed internally so hybrid repositories
/// can register replay handlers without leaking concrete types to UI layers.
final supabaseCloudSyncServiceProvider = Provider<SupabaseCloudSyncService>((
  ref,
) {
  final outbox = ref.watch(syncOutboxRepositoryProvider);
  final connectivity = ref.watch(connectivityRepositoryProvider);
  final service = SupabaseCloudSyncService(
    outboxRepository: outbox,
    connectivityRepository: connectivity,
  );
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

/// Centralized [CloudSyncService] contract provider.
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return ref.watch(supabaseCloudSyncServiceProvider);
});

/// Helper provider exposing the active user context `(userId, isGuestFan)` safely even
/// in isolated tests where `authRepositoryProvider` may not be overridden.
final activeSyncUserContextProvider =
    Provider<({String? userId, bool isGuest})>((ref) {
      try {
        final authState = ref.watch(authControllerProvider);
        final user = authState.session?.user;
        return (userId: user?.id, isGuest: user?.isGuestFan ?? true);
      } catch (_) {
        return (userId: null, isGuest: true);
      }
    });

/// Global reactive [SyncSummaryState] controller provider bound to the authenticated user.
final syncStatusControllerProvider =
    StateNotifierProvider<SyncStatusController, SyncSummaryState>((ref) {
      final outbox = ref.watch(syncOutboxRepositoryProvider);
      final connectivity = ref.watch(connectivityRepositoryProvider);
      final syncService = ref.watch(cloudSyncServiceProvider);

      final controller = SyncStatusController(
        outboxRepository: outbox,
        connectivityRepository: connectivity,
        cloudSyncService: syncService,
      );

      final initialUser = ref.read(activeSyncUserContextProvider);
      unawaited(
        controller.bindUser(
          userId: initialUser.userId,
          isGuestFan: initialUser.isGuest,
        ),
      );

      ref.listen<({String? userId, bool isGuest})>(
        activeSyncUserContextProvider,
        (previous, next) {
          unawaited(
            controller.bindUser(userId: next.userId, isGuestFan: next.isGuest),
          );
        },
      );

      return controller;
    });
