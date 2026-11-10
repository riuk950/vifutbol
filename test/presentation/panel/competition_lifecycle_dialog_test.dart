import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_lifecycle_dialog.dart';

void main() {
  final sampleTournament = ChampionshipTournament(
    id: 'tourn-life-1',
    name: 'Liga de Verano',
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

  group('CompetitionLifecycleDialog Widget Tests', () {
    testWidgets('triggers enroll teams action when clicked', (tester) async {
      var enrollTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionLifecycleDialog(
            tournament: sampleTournament,
            enrolledTeamsCount: 1,
            hasGeneratedFixture: false,
            onEnrollTeamsRequested: () => enrollTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competition_lifecycle_target_select')), findsOneWidget);
      expect(find.byKey(const Key('competition_lifecycle_action_enroll_teams')), findsOneWidget);

      await tester.tap(find.byKey(const Key('competition_lifecycle_action_enroll_teams')));
      await tester.pumpAndSettle();
      expect(enrollTapped, isTrue);
    });

    testWidgets('triggers generate fixture action when clicked', (tester) async {
      var fixtureTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionLifecycleDialog(
            tournament: sampleTournament,
            enrolledTeamsCount: 4,
            hasGeneratedFixture: false,
            onGenerateFixtureRequested: () => fixtureTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competition_lifecycle_action_generate_fixture')), findsOneWidget);

      await tester.tap(find.byKey(const Key('competition_lifecycle_action_generate_fixture')));
      await tester.pumpAndSettle();
      expect(fixtureTapped, isTrue);
    });

    testWidgets('allows status transition when prerequisites are satisfied', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CompetitionLifecycleDialog(
            tournament: sampleTournament,
            enrolledTeamsCount: 4,
            hasGeneratedFixture: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competition_lifecycle_action_enroll_teams')), findsNothing);
      expect(find.byKey(const Key('competition_lifecycle_action_generate_fixture')), findsNothing);
      expect(find.byKey(const Key('competition_lifecycle_confirm_button')), findsOneWidget);
    });
  });
}
