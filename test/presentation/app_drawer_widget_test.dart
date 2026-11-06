import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';
import 'package:vifutbol/presentation/shell/widgets/app_navigation_drawer.dart';

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

Widget createDrawerTestApp({
  UserRole role = UserRole.fan,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      onGenerateRoute: AppRouter.router.generator,
      home: const AppShellScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    AppRouter.setupRouter();
  });

  group('AppNavigationDrawer Widget Tests', () {
    testWidgets(
      'renders hamburger menu button in AppBar and opens drawer across all 5 roles',
      (tester) async {
        for (final role in UserRole.values) {
          await tester.pumpWidget(createDrawerTestApp(role: role));
          await tester.pumpAndSettle();

          // 1. Verify hamburger icon exists on AppBar leading
          final menuButtonFinder = find.byKey(
            const Key('app_bar_drawer_button'),
          );
          expect(menuButtonFinder, findsOneWidget);

          // 2. Tap hamburger button to open drawer
          await tester.tap(menuButtonFinder);
          await tester.pumpAndSettle();

          // 3. Verify AppNavigationDrawer is displayed
          expect(find.byType(AppNavigationDrawer), findsOneWidget);
          expect(find.byKey(const Key('app_drawer_header')), findsOneWidget);

          // 4. Verify all 4 destinations exist
          expect(
            find.byKey(const Key('drawer_destination_competitions')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('drawer_destination_teams')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('drawer_destination_players')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('drawer_destination_venues')),
            findsOneWidget,
          );

          // Close drawer for next role iteration
          final scaffoldState = tester.state<ScaffoldState>(
            find.byType(Scaffold).first,
          );
          scaffoldState.closeDrawer();
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('closes drawer automatically when tapping a destination', (
      tester,
    ) async {
      await tester.pumpWidget(createDrawerTestApp(role: UserRole.organizer));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AppNavigationDrawer), findsOneWidget);

      // Tap 'Competiciones'
      await tester.tap(
        find.byKey(const Key('drawer_destination_competitions')),
      );
      await tester.pumpAndSettle();

      // Drawer is popped (not on top anymore) and new screen is displayed
      expect(find.byType(AppNavigationDrawer), findsNothing);
      expect(find.text('Competiciones'), findsWidgets);
    });

    testWidgets('tapping Venues navigates to Venues screen with back button', (
      tester,
    ) async {
      await tester.pumpWidget(createDrawerTestApp(role: UserRole.fan));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
      await tester.pumpAndSettle();

      // Tap 'Sedes'
      await tester.tap(find.byKey(const Key('drawer_destination_venues')));
      await tester.pumpAndSettle();

      // Screen shows 'Sedes Deportivas' and has a back button
      expect(find.text('Sedes Deportivas'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      // Tap back button returns to AppShellScreen
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppShellScreen), findsOneWidget);
    });

    testWidgets(
      'renders Panel item in position 0 for operational roles (organizer, coach, referee, player)',
      (tester) async {
        const operationalRoles = [
          UserRole.organizer,
          UserRole.coach,
          UserRole.referee,
          UserRole.player,
        ];

        for (final role in operationalRoles) {
          await tester.pumpWidget(createDrawerTestApp(role: role));
          await tester.pumpAndSettle();

          // Open drawer
          await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
          await tester.pumpAndSettle();

          // Verify Panel item exists and displays "Panel"
          final panelFinder = find.byKey(const Key('drawer_destination_panel'));
          expect(panelFinder, findsOneWidget);
          expect(
            find.descendant(of: panelFinder, matching: find.text('Panel')),
            findsOneWidget,
          );

          // Verify Panel is above Competiciones (position 0)
          final competitionsFinder = find.byKey(
            const Key('drawer_destination_competitions'),
          );
          expect(competitionsFinder, findsOneWidget);

          final panelDy = tester.getTopLeft(panelFinder).dy;
          final competitionsDy = tester.getTopLeft(competitionsFinder).dy;
          expect(panelDy, lessThan(competitionsDy));

          // Close drawer
          final scaffoldState = tester.state<ScaffoldState>(
            find.byType(Scaffold).first,
          );
          scaffoldState.closeDrawer();
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('hides Panel item completely for fan role', (tester) async {
      await tester.pumpWidget(createDrawerTestApp(role: UserRole.fan));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
      await tester.pumpAndSettle();

      // Verify Panel item is absent
      expect(find.byKey(const Key('drawer_destination_panel')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppNavigationDrawer),
          matching: find.text('Panel'),
        ),
        findsNothing,
      );

      // Verify other destinations remain
      expect(
        find.byKey(const Key('drawer_destination_competitions')),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Panel closes drawer and navigates to PanelScreen with BackButton',
      (tester) async {
        await tester.pumpWidget(createDrawerTestApp(role: UserRole.organizer));
        await tester.pumpAndSettle();

        // Open drawer
        await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
        await tester.pumpAndSettle();

        // Tap Panel item
        await tester.tap(find.byKey(const Key('drawer_destination_panel')));
        await tester.pumpAndSettle();

        // Verify drawer is closed and PanelScreen is mounted
        expect(find.byType(AppNavigationDrawer), findsNothing);
        expect(find.byType(PanelScreen), findsOneWidget);
        expect(find.byKey(const Key('panel_back_button')), findsOneWidget);

        // Tap BackButton returns to AppShellScreen
        await tester.tap(find.byKey(const Key('panel_back_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AppShellScreen), findsOneWidget);
        expect(find.byType(PanelScreen), findsNothing);
      },
    );
  });
}
