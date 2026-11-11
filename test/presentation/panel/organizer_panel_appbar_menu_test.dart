import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/models/organizer_menu_action.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_appbar_menu.dart';

Widget _buildMenuTestApp({void Function(OrganizerMenuAction)? onSelected}) {
  return ProviderScope(
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        appBar: AppBar(
          actions: [OrganizerPanelAppBarMenu(onActionSelected: onSelected)],
        ),
        body: const SizedBox.expand(),
      ),
    ),
  );
}

void main() {
  group('OrganizerPanelAppBarMenu Component Tests (Foundational T002)', () {
    testWidgets(
      'renders PopupMenuButton with key organizer_panel_appbar_menu',
      (tester) async {
        await tester.pumpWidget(_buildMenuTestApp());
        await tester.pumpAndSettle();

        final menuButton = find.byKey(const Key('organizer_panel_appbar_menu'));
        expect(menuButton, findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      },
    );

    testWidgets(
      'tapping menu displays exactly two items with icons and text: publishNews and backup',
      (tester) async {
        await tester.pumpWidget(_buildMenuTestApp());
        await tester.pumpAndSettle();

        // Tap the menu button to open popup
        await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
        await tester.pumpAndSettle();

        // Verify "Publicar Noticia" item
        final publishItem = find.byKey(
          const Key('organizer_menu_publish_news'),
        );
        expect(publishItem, findsOneWidget);
        expect(find.text('Publicar Noticia'), findsOneWidget);
        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);

        // Verify "Copia de Seguridad" item
        final backupItem = find.byKey(const Key('organizer_menu_backup'));
        expect(backupItem, findsOneWidget);
        expect(find.text('Copia de Seguridad'), findsOneWidget);
        expect(find.byIcon(Icons.backup_outlined), findsOneWidget);

        // Verify total menu items count is exactly 2
        expect(
          find.byType(PopupMenuItem<OrganizerMenuAction>),
          findsNWidgets(2),
        );
      },
    );

    testWidgets('selecting publishNews notifies callback or triggers action', (
      tester,
    ) async {
      OrganizerMenuAction? selectedAction;
      await tester.pumpWidget(
        _buildMenuTestApp(onSelected: (action) => selectedAction = action),
      );
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
      await tester.pumpAndSettle();

      // Tap publish news
      await tester.tap(find.byKey(const Key('organizer_menu_publish_news')));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(OrganizerMenuAction.publishNews));
    });

    testWidgets('selecting backup notifies callback or triggers action', (
      tester,
    ) async {
      OrganizerMenuAction? selectedAction;
      await tester.pumpWidget(
        _buildMenuTestApp(onSelected: (action) => selectedAction = action),
      );
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
      await tester.pumpAndSettle();

      // Tap backup
      await tester.tap(find.byKey(const Key('organizer_menu_backup')));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(OrganizerMenuAction.backup));
    });
  });
}
