import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_edit_dialog.dart';

void main() {
  final sampleTournament = ChampionshipTournament(
    id: 'tourn-edit-1',
    name: 'Torneo Metropolitano',
    category: 'Libre Masculino',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 8, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    rules: const TournamentRulesConfig(pointsForWin: 3, pointsForDraw: 1),
    updatedAt: DateTime(2026, 5, 1),
    organizerId: 'org-test',
  );

  Widget buildTestableWidget({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('CompetitionEditDialog Widget Tests', () {
    testWidgets('renders pre-populated tournament fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionEditDialog(tournament: sampleTournament),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_edit_name_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('competition_edit_category_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('competition_edit_save_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('competition_edit_cancel_button')),
        findsOneWidget,
      );

      expect(find.text('Torneo Metropolitano'), findsOneWidget);
      expect(find.text('Libre Masculino'), findsOneWidget);
    });

    testWidgets('blocks submission when name is invalid', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionEditDialog(tournament: sampleTournament),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('competition_edit_name_input')),
        'A',
      );
      await tester.tap(find.byKey(const Key('competition_edit_save_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre debe tener al menos 3 caracteres'),
        findsOneWidget,
      );
    });
  });
}
