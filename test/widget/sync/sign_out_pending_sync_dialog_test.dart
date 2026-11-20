import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/sync_status_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/services/cloud_sync_service.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

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

class _MockAuthRepository extends Mock implements AuthRepository {}

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

class _TestSyncStatusController extends SyncStatusController {
  _TestSyncStatusController(
    SyncSummaryState initial, {
    required this.flushResult,
  }) : super(
         outboxRepository: HiveSyncOutboxRepository(
           storage: _InMemoryLocalStorage(),
         ),
         connectivityRepository: _FakeConnectivity(),
         cloudSyncService: _DummyCloudSyncService(),
         initialState: initial,
         autoInitialize: false,
       );

  final SyncFlushResult flushResult;
  int syncNowCalls = 0;

  @override
  Future<SyncFlushResult?> syncNow() async {
    syncNowCalls++;
    return flushResult;
  }
}

void main() {
  final organizer = UserAccount(
    id: 'org-1',
    fullName: 'Carlos Organizador',
    email: 'org@test.com',
    activeRole: UserRole.organizer,
    authorizedRoles: {UserRole.organizer, UserRole.fan},
    onboardingCompleted: true,
  );

  final session = AuthSession(
    sessionId: 'sess-1',
    user: organizer,
    sessionToken: 'tok-1',
    authenticatedAt: DateTime.utc(2026, 11, 11, 12, 0),
  );

  Future<(_MockAuthRepository, _TestSyncStatusController)> pumpProfile(
    WidgetTester tester, {
    required int pendingCount,
    bool isConnected = true,
    SyncFlushResult flushResult = const SyncFlushResult(
      syncedCount: 1,
      remainingPendingCount: 0,
      errorCount: 0,
    ),
  }) async {
    final mockAuth = _MockAuthRepository();
    when(() => mockAuth.restoreSession()).thenAnswer((_) async => session);
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    final syncCtrl = _TestSyncStatusController(
      SyncSummaryState(
        status: pendingCount > 0 ? SyncStatus.pending : SyncStatus.synced,
        pendingCount: pendingCount,
        isConnected: isConnected,
      ),
      flushResult: flushResult,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(),
          ),
          localStorageRepositoryProvider.overrideWithValue(
            _InMemoryLocalStorage(),
          ),
          connectivityRepositoryProvider.overrideWithValue(_FakeConnectivity()),
          authRepositoryProvider.overrideWithValue(mockAuth),
          syncStatusControllerProvider.overrideWith((ref) => syncCtrl),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(body: ProfileTabView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (mockAuth, syncCtrl);
  }

  group('SignOutPendingSyncDialog & ProfileTabView sign-out guard (Q3)', () {
    testWidgets(
      'shows 3-option guard dialog when pendingCount > 0 and supports Cancel',
      (tester) async {
        final (mockAuth, syncCtrl) = await pumpProfile(tester, pendingCount: 2);

        final logoutBtn = find.text('Cerrar sesión');
        await tester.ensureVisible(logoutBtn);
        await tester.tap(logoutBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Cambios pendientes sin sincronizar'), findsOneWidget);
        expect(
          find.byKey(const Key('logout_sync_and_exit_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('logout_keep_pending_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('logout_cancel_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('logout_cancel_button')));
        await tester.pumpAndSettle();
        verifyNever(() => mockAuth.signOut());
        expect(syncCtrl.syncNowCalls, 0);
      },
    );

    testWidgets(
      'executes flushOutbox before signing out on Sincronizar y salir',
      (tester) async {
        final (mockAuth, syncCtrl) = await pumpProfile(tester, pendingCount: 1);

        final logoutBtn = find.text('Cerrar sesión');
        await tester.ensureVisible(logoutBtn);
        await tester.tap(logoutBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('logout_sync_and_exit_button')));
        await tester.pumpAndSettle();

        expect(syncCtrl.syncNowCalls, 1);
        verify(() => mockAuth.signOut()).called(1);
      },
    );

    testWidgets(
      'signs out without clearing queue on Salir conservando pendientes',
      (tester) async {
        final (mockAuth, syncCtrl) = await pumpProfile(
          tester,
          pendingCount: 2,
          isConnected: false,
        );

        final logoutBtn = find.text('Cerrar sesión');
        await tester.ensureVisible(logoutBtn);
        await tester.tap(logoutBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Sync & Exit button must be disabled while disconnected
        final syncAndExit = tester.widget<ElevatedButton>(
          find.byKey(const Key('logout_sync_and_exit_button')),
        );
        expect(syncAndExit.onPressed, isNull);

        await tester.tap(find.byKey(const Key('logout_keep_pending_button')));
        await tester.pumpAndSettle();

        expect(syncCtrl.syncNowCalls, 0);
        verify(() => mockAuth.signOut()).called(1);
      },
    );

    testWidgets(
      'falls back to standard confirmation dialog when pendingCount == 0',
      (tester) async {
        final (mockAuth, _) = await pumpProfile(tester, pendingCount: 0);

        final logoutBtn = find.text('Cerrar sesión');
        await tester.ensureVisible(logoutBtn);
        await tester.tap(logoutBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Cambios pendientes sin sincronizar'), findsNothing);
        expect(
          find.byKey(const Key('logout_keep_pending_button')),
          findsNothing,
        );
        verifyNever(() => mockAuth.signOut());
      },
    );
  });
}
