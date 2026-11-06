import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/fan_panel_restricted_content.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

Widget createFanPanelApp({ProviderContainer? container}) {
  return UncontrolledProviderScope(
    container:
        container ??
        ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(),
            ),
            localStorageRepositoryProvider.overrideWithValue(
              _FakeLocalStorageRepository(),
            ),
            connectivityRepositoryProvider.overrideWithValue(
              _FakeConnectivityRepository(),
            ),
            activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
          ],
        ),
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      initialRoute: '/panel',
      routes: {
        '/panel': (context) => const PanelScreen(),
        '/matches': (context) => const Scaffold(
          body: Center(child: Text('Matches Screen Destination')),
        ),
      },
    ),
  );
}

void main() {
  group('FanPanelRestrictedContent', () {
    testWidgets('renders restriction view when user role is fan', (
      tester,
    ) async {
      await tester.pumpWidget(createFanPanelApp());
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.byKey(const Key('panel_screen_title')), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);

      // Verify Fan Restricted Content
      expect(find.byType(FanPanelRestrictedContent), findsOneWidget);
      expect(
        find.byKey(const Key('fan_panel_restricted_content')),
        findsOneWidget,
      );
      expect(find.text('Acceso Restringido'), findsOneWidget);
      expect(
        find.text(
          'El Panel Administrativo está reservado exclusivamente para Organizadores, Entrenadores, Árbitros y Jugadores federados.',
        ),
        findsOneWidget,
      );

      // Verify Return Action Button
      expect(
        find.byKey(const Key('fan_restricted_return_matches_button')),
        findsOneWidget,
      );
      expect(find.text('Volver a Partidos'), findsOneWidget);
    });

    testWidgets(
      'tapping "Volver a Partidos" sets shell section to matches and navigates to /matches',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(),
            ),
            localStorageRepositoryProvider.overrideWithValue(
              _FakeLocalStorageRepository(),
            ),
            connectivityRepositoryProvider.overrideWithValue(
              _FakeConnectivityRepository(),
            ),
            activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
          ],
        );

        // Precondition: Shell section is not matches
        container
            .read(appShellControllerProvider.notifier)
            .setSection(AppShellSection.news);
        expect(
          container.read(appShellControllerProvider).activeSection,
          AppShellSection.news,
        );

        await tester.pumpWidget(createFanPanelApp(container: container));
        await tester.pumpAndSettle();

        final returnButton = find.byKey(
          const Key('fan_restricted_return_matches_button'),
        );
        expect(returnButton, findsOneWidget);

        await tester.tap(returnButton);
        await tester.pumpAndSettle();

        // Verify shell section was updated to matches
        expect(
          container.read(appShellControllerProvider).activeSection,
          AppShellSection.matches,
        );

        // Verify navigation reached /matches destination
        expect(find.text('Matches Screen Destination'), findsOneWidget);
      },
    );
  });
}
