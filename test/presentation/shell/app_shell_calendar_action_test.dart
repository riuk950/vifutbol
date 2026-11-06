import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

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

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

List<Override> _testOverrides() => [
  environmentConfigProvider.overrideWithValue(EnvironmentConfig.development()),
  localStorageRepositoryProvider.overrideWithValue(
    _FakeLocalStorageRepository(),
  ),
  connectivityRepositoryProvider.overrideWithValue(
    _FakeConnectivityRepository(),
  ),
  activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
];

void main() {
  testWidgets('shows calendar action icon in AppBar when in matchday section', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: AppShellScreen(initialSection: AppShellSection.matchday),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app_bar_calendar_action')), findsOneWidget);
  });

  testWidgets('hides calendar action icon in AppBar when in profile section', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _testOverrides());
    container
        .read(appShellControllerProvider.notifier)
        .setSection(AppShellSection.profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: AppShellScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app_bar_calendar_action')), findsNothing);
  });
}
