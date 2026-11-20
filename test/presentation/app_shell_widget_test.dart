import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  UserRole role = UserRole.fan,
  AppShellSection? initialSection,
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
      activeUserRoleProvider.overrideWith((ref) => role),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
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
      home: AppShellScreen(initialSection: initialSection),
    ),
  );
}

void main() {
  group('AppShellScreen & Spanish Localization Widget Tests', () {
    testWidgets(
      'renders exactly 3 bottom navigation tabs in 100% Spanish across all 5 roles and hides Explorar',
      (tester) async {
        for (final role in UserRole.values) {
          await tester.pumpWidget(createTestApp(role: role));
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Partidos'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Noticias'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Perfil'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Explorar'),
            ),
            findsNothing,
          );
          expect(find.byType(NavigationDestination), findsNWidgets(3));
          expect(find.text('Sedes'), findsNothing);
        }
      },
    );

    testWidgets('switches sections when tapping bottom navigation bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Noticias'),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Perfil'),
        ),
      );
      await tester.pumpAndSettle();

      final navBarAfterProfile = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBarAfterProfile.selectedIndex, 2);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Partidos'),
        ),
      );
      await tester.pumpAndSettle();

      final navBarAfterMatches = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBarAfterMatches.selectedIndex, 0);
    });

    testWidgets(
      'safely handles AppShellSection.explore fallback by showing Partidos',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialSection: AppShellSection.explore),
        );
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);
        expect(find.text('Explorar'), findsNothing);
      },
    );

    testWidgets(
      'renders at compact 320x640 viewport and 130% text scaling across all 3 tabs without overflows',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestApp(textScaleFactor: 1.3));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Tab 1: Partidos (active by default)
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Partidos'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Tab 2: Noticias
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Noticias'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Tab 3: Perfil
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Perfil'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets(
      'app_bar_news_filter_action is visible only on Noticias tab and opens NewsFilterBottomSheet',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Initially on Partidos: news filter action must NOT be present
        expect(
          find.byKey(const Key('app_bar_news_filter_action')),
          findsNothing,
        );

        // Switch to Noticias tab
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Noticias'),
          ),
        );
        await tester.pumpAndSettle();

        // Now on Noticias: news filter action must be present
        expect(
          find.byKey(const Key('app_bar_news_filter_action')),
          findsOneWidget,
        );

        // Tap the news filter action to open bottom sheet
        await tester.tap(find.byKey(const Key('app_bar_news_filter_action')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('news_filter_bottom_sheet')),
          findsOneWidget,
        );

        // Close bottom sheet
        await tester.tap(find.byKey(const Key('news_filter_close_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('news_filter_bottom_sheet')), findsNothing);

        // Switch to Perfil tab: news filter action must disappear
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Perfil'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('app_bar_news_filter_action')),
          findsNothing,
        );
      },
    );
  });
}
