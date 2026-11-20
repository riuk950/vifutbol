import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/sync_status_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> store = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => store[key];

  @override
  Future<void> writeString(String key, String value) async {
    store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => store.clear();
}

class _FakeConnectivity implements ConnectivityRepository {
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
}

class _DummyCloudSyncService implements CloudSyncService {
  @override
  Future<void> discardItem({
    required String userId,
    required String itemId,
  }) async {}

  @override
  Future<SyncFlushResult> flushOutbox({required String userId}) async =>
      const SyncFlushResult(
        syncedCount: 0,
        remainingPendingCount: 0,
        errorCount: 0,
      );

  @override
  Future<SyncFlushResult> retryErroredItem({
    required String userId,
    required String itemId,
  }) async => const SyncFlushResult(
    syncedCount: 0,
    remainingPendingCount: 0,
    errorCount: 0,
  );

  @override
  void setActiveUser(String? userId) {}

  @override
  Stream<bool> watchIsSyncing() => const Stream<bool>.empty();
}

class _ControllableSyncController extends SyncStatusController {
  _ControllableSyncController(SyncSummaryState initial)
    : super(
        outboxRepository: HiveSyncOutboxRepository(
          storage: _InMemoryLocalStorage(),
        ),
        connectivityRepository: _FakeConnectivity(),
        cloudSyncService: _DummyCloudSyncService(),
      ) {
    state = initial;
  }

  void setSummary(SyncSummaryState next) {
    state = next;
  }
}

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required UserRole role,
    required bool isGuest,
    SyncSummaryState syncState = const SyncSummaryState(),
    _ControllableSyncController? controllerOverride,
    double textScaleFactor = 1.0,
  }) async {
    final storage = _InMemoryLocalStorage();
    final ctrl = controllerOverride ?? _ControllableSyncController(syncState);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(),
          ),
          localStorageRepositoryProvider.overrideWithValue(storage),
          connectivityRepositoryProvider.overrideWithValue(_FakeConnectivity()),
          activeSyncUserContextProvider.overrideWithValue((
            userId: isGuest ? null : 'user-1',
            isGuest: isGuest,
          )),
          activeUserRoleProvider.overrideWith((ref) => role),
          activeRoleCapabilitiesProvider.overrideWith(
            (ref) => RolePermissionMatrix.capabilitiesForRole(role),
          ),
          syncStatusControllerProvider.overrideWith((ref) => ctrl),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          ),
          home: const AppShellScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('AppBar SyncStatusAppBarAction visibility and states (US3)', () {
    for (final role in [UserRole.organizer, UserRole.coach, UserRole.referee]) {
      testWidgets('renders sync indicator for operational role ${role.name}', (
        tester,
      ) async {
        await pumpShell(tester, role: role, isGuest: false);
        final finder = find.byKey(const Key('app_bar_sync_status_action'));
        expect(finder, findsOneWidget);

        // Verify >= 44x44 accessible tap target
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      });
    }

    for (final role in [UserRole.player, UserRole.fan]) {
      testWidgets('hides sync indicator for consumer role ${role.name}', (
        tester,
      ) async {
        await pumpShell(tester, role: role, isGuest: false);
        expect(
          find.byKey(const Key('app_bar_sync_status_action')),
          findsNothing,
        );
      });
    }

    testWidgets('hides sync indicator for guest fan even under dev setup', (
      tester,
    ) async {
      await pumpShell(tester, role: UserRole.organizer, isGuest: true);
      expect(find.byKey(const Key('app_bar_sync_status_action')), findsNothing);
    });

    testWidgets(
      'displays 4 distinct states (synced, pending+badge, syncing, offlineOrError) cleanly at 130% text scale',
      (tester) async {
        final controller = _ControllableSyncController(
          const SyncSummaryState(status: SyncStatus.synced, isConnected: true),
        );

        await pumpShell(
          tester,
          role: UserRole.organizer,
          isGuest: false,
          controllerOverride: controller,
          textScaleFactor: 1.3,
        );
        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);

        // Pending with numeric badge 3
        controller.setSummary(
          const SyncSummaryState(
            status: SyncStatus.pending,
            pendingCount: 3,
            isConnected: true,
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // Syncing animated icon
        controller.setSummary(
          const SyncSummaryState(
            status: SyncStatus.syncing,
            pendingCount: 3,
            isSyncing: true,
            isConnected: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byIcon(Icons.sync), findsOneWidget);

        // Offline or Error
        controller.setSummary(
          const SyncSummaryState(
            status: SyncStatus.offlineOrError,
            errorCount: 1,
            isConnected: true,
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      },
    );
  });
}
