import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/presentation/app.dart';
import 'package:vifutbol/presentation/auth/auth_gate.dart';
import 'package:vifutbol/presentation/auth/welcome_auth_screen.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

class MockLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

  MockLocalStorageRepository([Map<String, String>? initialStore]) {
    if (initialStore != null) {
      _store.addAll(initialStore);
    }
  }

  @override
  bool get isUsingFallbackMemory => false;

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }
}

class MockConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

void main() {
  setUpAll(() {
    AppRouter.setupRouter();
  });

  testWidgets(
    'App root smoke test mounts WelcomeAuthScreen when unauthenticated',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(),
            ),
            localStorageRepositoryProvider.overrideWithValue(
              MockLocalStorageRepository(),
            ),
            connectivityRepositoryProvider.overrideWithValue(
              MockConnectivityRepository(),
            ),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthGate), findsOneWidget);
      expect(find.byType(WelcomeAuthScreen), findsOneWidget);
      expect(find.text('Bienvenido a vifutbol'), findsOneWidget);
    },
  );

  testWidgets(
    'App root smoke test mounts AppShellScreen when session is authenticated',
    (WidgetTester tester) async {
      final activeSession = AuthSession(
        sessionId: 'session-smoke',
        user: UserAccount(
          id: 'user-smoke',
          fullName: 'Diego Armando',
          email: 'diego@vifutbol.com',
          activeRole: UserRole.fan,
          authorizedRoles: const {UserRole.fan},
          isGuestFan: false,
          onboardingCompleted: true,
        ),
        sessionToken: 'token-smoke',
        authenticatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(),
            ),
            localStorageRepositoryProvider.overrideWithValue(
              MockLocalStorageRepository({
                'auth_session': jsonEncode(activeSession.toJson()),
              }),
            ),
            connectivityRepositoryProvider.overrideWithValue(
              MockConnectivityRepository(),
            ),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthGate), findsOneWidget);
      expect(find.byType(AppShellScreen), findsOneWidget);
    },
  );
}
