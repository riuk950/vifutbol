import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';

Widget createPanelTestApp({UserRole role = UserRole.organizer}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [activeUserRoleProvider.overrideWith((ref) => role)],
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
  group('PanelScreen Widget Tests (HU 12.1)', () {
    testWidgets('renders AppBar with "Panel" title and BackButton', (
      tester,
    ) async {
      await tester.pumpWidget(createPanelTestApp(role: UserRole.organizer));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('panel_screen')), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);
      expect(find.byKey(const Key('panel_back_button')), findsOneWidget);
    });

    testWidgets(
      'displays placeholder content and correct role badge for all roles',
      (tester) async {
        final roleLabels = {
          UserRole.organizer: 'Organizador',
          UserRole.coach: 'Entrenador',
          UserRole.referee: 'Árbitro',
          UserRole.player: 'Jugador',
        };

        for (final entry in roleLabels.entries) {
          await tester.pumpWidget(createPanelTestApp(role: entry.key));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('panel_placeholder_content')),
            findsOneWidget,
          );
          expect(find.text('Panel de Control Operativo'), findsOneWidget);
          expect(
            find.text(
              'Herramientas de gestión y métricas disponibles para tu rol deportivo.',
            ),
            findsOneWidget,
          );
          expect(find.text(entry.value), findsOneWidget);
        }
      },
    );

    testWidgets('BackButton pops screen when tapped', (tester) async {
      final key = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // Navigate to PanelScreen
      await tester.tap(find.byKey(const Key('open_panel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelScreen), findsOneWidget);

      // Tap BackButton
      await tester.tap(find.byKey(const Key('panel_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PanelScreen), findsNothing);
      expect(find.byKey(const Key('open_panel_button')), findsOneWidget);
    });
  });
}
