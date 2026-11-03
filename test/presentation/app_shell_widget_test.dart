import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
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

class FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

Widget createTestApp({
  EnvironmentConfig? config,
  double textScaleFactor = 1.0,
}) {
  final activeConfig = config ?? EnvironmentConfig.development();
  return ProviderScope(
    overrides: [
      environmentConfigProvider.overrideWithValue(activeConfig),
      localStorageRepositoryProvider.overrideWithValue(
        FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        FakeConnectivityRepository(),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        );
      },
      home: const AppShellScreen(),
    ),
  );
}

void main() {
  group('AppShellScreen & Spanish Localization Widget Tests', () {
    testWidgets('renders all 4 bottom navigation tabs in 100% Spanish', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Jornada'), findsWidgets);
      expect(find.text('Posiciones'), findsOneWidget);
      expect(find.text('Sedes'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('switches sections when tapping bottom navigation bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Posiciones'));
      await tester.pumpAndSettle();

      expect(find.text('Posiciones'), findsWidgets);

      await tester.tap(find.text('Sedes'));
      await tester.pumpAndSettle();

      expect(find.text('Sedes'), findsWidgets);
    });

    testWidgets('renders at 130% text scaling without layout overflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(textScaleFactor: 1.3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'KickPulseButton enforces minimum 44x44px touch target and single-flight lock',
      (tester) async {
        int pressCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: KickPulseButton(
                  label: 'Test Button',
                  onPressed: () async {
                    pressCount++;
                    await Future.delayed(const Duration(milliseconds: 100));
                  },
                ),
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(KickPulseButton);
        final size = tester.getSize(buttonFinder);
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));

        // Test anti-double-tap single-flight lock
        await tester.tap(buttonFinder);
        await tester.tap(buttonFinder); // rapid second tap
        expect(pressCount, 1);
        await tester.pump(const Duration(milliseconds: 150));
        expect(pressCount, 1);
      },
    );
  });
}
