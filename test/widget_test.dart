import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/presentation/app.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

class MockLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;

  @override
  Future<void> clearNamespace() async {}

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> writeString(String key, String value) async {}
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

  testWidgets('App root smoke test mounts AppShellScreen successfully', (
    WidgetTester tester,
  ) async {
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

    expect(find.byType(AppShellScreen), findsOneWidget);
    expect(find.text('vifutbol'), findsOneWidget);
  });
}
