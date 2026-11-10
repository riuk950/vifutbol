import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';

void main() {
  Widget buildTestableWidget({
    required List<ChampionshipTournament> tournaments,
    VoidCallback? onCreatePressed,
  }) {
    return ProviderScope(
      overrides: [
        organizerTournamentsProvider.overrideWithValue(tournaments),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrganizerCompetitionsSection(
              onCreateTournament: onCreatePressed,
            ),
          ),
        ),
      ),
    );
  }

  group('OrganizerCompetitionsSection Widget Tests', () {
    testWidgets('renders empty state when organizer has no tournaments', (
      tester,
    ) async {
      var createPressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          tournaments: const [],
          onCreatePressed: () => createPressed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('organizer_competitions_empty_state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_action_empty_create_competition')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('organizer_action_empty_create_competition')),
      );
      await tester.pump();

      expect(createPressed, isTrue);
    });

    testWidgets('renders tournament cards and menu when tournaments exist', (
      tester,
    ) async {
      final sampleTournaments = [
        ChampionshipTournament(
          id: 'tourn-1',
          name: 'Liga de Campeones Local',
          category: 'Libre',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 8, 30),
          format: TournamentFormat.league,
          status: TournamentStatus.openRegistration,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 5, 1),
          organizerId: 'org-test',
        ),
        ChampionshipTournament(
          id: 'tourn-2',
          name: 'Copa Élite',
          category: 'Veteranos',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 9, 30),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.inProgress,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 6, 1),
          organizerId: 'org-test',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(tournaments: sampleTournaments),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('organizer_competitions_section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_action_create_competition')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_competition_card_tourn-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_competition_card_tourn-2')),
        findsOneWidget,
      );

      expect(find.text('Liga de Campeones Local'), findsOneWidget);
      expect(find.text('Copa Élite'), findsOneWidget);

      expect(
        find.byKey(const Key('organizer_competition_status_badge_tourn-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_competition_status_badge_tourn-2')),
        findsOneWidget,
      );

      expect(
        find.byKey(const Key('organizer_competition_menu_button_tourn-1')),
        findsOneWidget,
      );
    });
  });
}
