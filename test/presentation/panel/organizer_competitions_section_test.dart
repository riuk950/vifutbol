import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
    String? selectedTournamentId,
  }) : super(
         TournamentsCatalogState(
           tournaments: tournaments,
           selectedTournamentId: selectedTournamentId,
           viewState: UiContentState(tournaments),
         ),
       );

  String? lastSelectedTournamentId;

  @override
  void selectTournament(String tournamentId) {
    lastSelectedTournamentId = tournamentId;
    state = state.copyWith(selectedTournamentId: tournamentId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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

  Widget buildTestableWidget({
    required List<ChampionshipTournament> tournaments,
    VoidCallback? onCreatePressed,
    ValueChanged<ChampionshipTournament>? onTapTournament,
    _FakeTournamentsController? controller,
  }) {
    final tournamentsController =
        controller ?? _FakeTournamentsController(tournaments: tournaments);

    return ProviderScope(
      overrides: [
        organizerTournamentsProvider.overrideWithValue(tournaments),
        tournamentsControllerProvider.overrideWith(
          (ref) => tournamentsController,
        ),
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
        onGenerateRoute: (settings) {
          if (settings.name != null &&
              settings.name!.startsWith('/competitions/')) {
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) => Scaffold(
                appBar: AppBar(
                  leading: const BackButton(
                    key: Key('competition_detail_back_button'),
                  ),
                  title: Text('Detail: ${settings.name}'),
                ),
                body: const Center(child: Text('Competition Detail Body')),
              ),
            );
          }
          return null;
        },
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrganizerCompetitionsSection(
              onCreateTournament: onCreatePressed,
              onTapTournament: onTapTournament,
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

    testWidgets(
      'tapping tournament card selects tournament and navigates to competition detail (/competitions/:id)',
      (tester) async {
        final controller = _FakeTournamentsController(
          tournaments: sampleTournaments,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            tournaments: sampleTournaments,
            controller: controller,
          ),
        );
        await tester.pumpAndSettle();

        // Tap tournament card
        await tester.tap(
          find.byKey(const Key('organizer_competition_card_tourn-1')),
        );
        await tester.pumpAndSettle();

        // Verify state synchronization
        expect(controller.lastSelectedTournamentId, equals('tourn-1'));

        // Verify navigation to /competitions/:id
        expect(find.text('Detail: /competitions/tourn-1'), findsOneWidget);
        expect(find.text('Competition Detail Body'), findsOneWidget);

        // Tap back button to return to panel
        await tester.tap(
          find.byKey(const Key('competition_detail_back_button')),
        );
        await tester.pumpAndSettle();

        // Panel view is preserved
        expect(
          find.byKey(const Key('organizer_competitions_section')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping 3-dots menu button opens popup menu without triggering card navigation',
      (tester) async {
        var cardNavigated = false;

        await tester.pumpWidget(
          buildTestableWidget(
            tournaments: sampleTournaments,
            onTapTournament: (t) => cardNavigated = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap the 3-dots options menu button on tourn-1
        await tester.tap(
          find.byKey(const Key('organizer_competition_menu_button_tourn-1')),
        );
        await tester.pumpAndSettle();

        // Card navigation must NOT have been triggered
        expect(cardNavigated, isFalse);

        // Popup menu options should be visible
        expect(
          find.byKey(const Key('organizer_competition_menu_edit_tourn-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_competition_menu_status_tourn-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_competition_menu_delete_tourn-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'rapid successive taps (< 500ms) on a tournament card trigger navigation only once (debouncing)',
      (tester) async {
        var tapCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            tournaments: sampleTournaments,
            onTapTournament: (t) => tapCount++,
          ),
        );
        await tester.pumpAndSettle();

        final cardFinder = find.byKey(
          const Key('organizer_competition_card_tourn-1'),
        );

        // First tap
        await tester.tap(cardFinder);
        // Rapid second tap without settling or waiting 500ms
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();

        // Debounce guard must allow only 1 navigation
        expect(tapCount, equals(1));
      },
    );
  });
}
