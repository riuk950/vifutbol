import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_delete_dialog.dart';

void main() {
  final sampleTournament = ChampionshipTournament(
    id: 'tourn-del-1',
    name: 'Torneo Eliminable',
    category: 'Libre',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 8, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 5, 1),
    organizerId: 'org-test',
  );

  Widget buildTestableWidget({
    required Widget child,
  }) {
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

  group('CompetitionDeleteDialog Widget Tests', () {
    testWidgets('renders blocked state when canDelete is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionDeleteDialog(
            tournament: sampleTournament,
            canDelete: false,
            blockReason: 'No se puede eliminar una competición en curso o finalizada.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se puede eliminar una competición en curso o finalizada.'), findsOneWidget);
      expect(find.byKey(const Key('competition_delete_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('competition_delete_confirm_button')), findsNothing);
    });

    testWidgets('renders confirmation state and triggers deletion when canDelete is true', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionDeleteDialog(
            tournament: sampleTournament,
            canDelete: true,
            onConfirmed: () async => confirmed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competition_delete_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('competition_delete_cancel_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('competition_delete_confirm_button')));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });
}
