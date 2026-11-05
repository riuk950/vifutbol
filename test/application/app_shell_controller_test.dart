import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';

Widget wrapWithLocalization(Widget child) {
  return MaterialApp(
    theme: KickPulseTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppShellController Unit Tests', () {
    test('cycles through all four bottom navigation sections', () {
      final controller = AppShellController();

      expect(controller.state.activeSection, AppShellSection.matches);

      controller.setSection(AppShellSection.explore);
      expect(controller.state.activeSection, AppShellSection.explore);

      controller.setSection(AppShellSection.news);
      expect(controller.state.activeSection, AppShellSection.news);

      controller.setSection(AppShellSection.profile);
      expect(controller.state.activeSection, AppShellSection.profile);

      controller.setSectionByIndex(0);
      expect(controller.state.activeSection, AppShellSection.matches);

      // Verify out-of-bounds indexing does not alter state
      controller.setSectionByIndex(-1);
      expect(controller.state.activeSection, AppShellSection.matches);

      controller.setSectionByIndex(4);
      expect(controller.state.activeSection, AppShellSection.matches);
    });
  });

  group('KickPulseStateView 5-State Rendering Tests', () {
    testWidgets('renders LoadingState with indicator and Spanish label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const KickPulseStateView<String>(state: UiLoadingState()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando datos deportivos...'), findsOneWidget);
    });

    testWidgets('renders ContentState with custom builder', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          KickPulseStateView<String>(
            state: const UiContentState('Partido Inaugural'),
            contentBuilder: (context, data) => Text('Contenido: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contenido: Partido Inaugural'), findsOneWidget);
    });

    testWidgets('renders EmptyState with explanation and icon', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const KickPulseStateView<String>(state: UiEmptyState()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay registros disponibles'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders ErrorState with retry button and calls onRetry', (
      tester,
    ) async {
      bool retryClicked = false;
      await tester.pumpWidget(
        wrapWithLocalization(
          KickPulseStateView<String>(
            state: const UiErrorState(
              DataLoadFailure('No se pudo conectar al servidor.'),
              canRetry: true,
            ),
            onRetry: () async {
              retryClicked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ocurrió un problema'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(retryClicked, isTrue);
    });

    testWidgets('renders SuccessState with check icon', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const KickPulseStateView<String>(state: UiSuccessState('ok')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operación completada'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
