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
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/fan_panel_restricted_content.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/player_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/referee_panel_content.dart';

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

Widget createPanelTestApp({UserRole role = UserRole.organizer}) {
  return ProviderScope(
    key: UniqueKey(),
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
      home: const PanelScreen(),
    ),
  );
}

void main() {
  group('PanelScreen Dynamic Router Widget Tests (HU 12.2)', () {
    testWidgets(
      'renders dynamic AppBar titles and subpanels across all 5 roles',
      (tester) async {
        // 1. Organizer
        await tester.pumpWidget(createPanelTestApp(role: UserRole.organizer));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('panel_screen')), findsOneWidget);
        expect(find.text('Panel de Organización'), findsOneWidget);
        expect(find.byType(OrganizerPanelContent), findsOneWidget);
        expect(find.byKey(const Key('panel_back_button')), findsOneWidget);

        // 2. Coach
        await tester.pumpWidget(createPanelTestApp(role: UserRole.coach));
        await tester.pumpAndSettle();
        expect(find.text('Panel Técnico'), findsOneWidget);
        expect(find.byType(CoachPanelContent), findsOneWidget);

        // 3. Referee
        await tester.pumpWidget(createPanelTestApp(role: UserRole.referee));
        await tester.pumpAndSettle();
        expect(find.text('Panel Arbitral'), findsOneWidget);
        expect(find.byType(RefereePanelContent), findsOneWidget);

        // 4. Player
        await tester.pumpWidget(createPanelTestApp(role: UserRole.player));
        await tester.pumpAndSettle();
        expect(find.text('Ficha del Jugador'), findsOneWidget);
        expect(find.byType(PlayerPanelContent), findsOneWidget);

        // 5. Fan
        await tester.pumpWidget(createPanelTestApp(role: UserRole.fan));
        await tester.pumpAndSettle();
        expect(find.text('Panel'), findsOneWidget);
        expect(find.byType(FanPanelRestrictedContent), findsOneWidget);
      },
    );

    testWidgets('BackButton pops screen when tapped', (tester) async {
      final key = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
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
            activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
          ],
          child: MaterialApp(
            navigatorKey: key,
            theme: KickPulseTheme.darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es')],
            home: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_panel_button'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PanelScreen()),
                  );
                },
                child: const Text('Open Panel'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_panel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('panel_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelScreen), findsNothing);
      expect(find.byKey(const Key('open_panel_button')), findsOneWidget);
    });
  });
}
