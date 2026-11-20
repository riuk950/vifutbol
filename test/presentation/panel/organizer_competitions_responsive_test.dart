import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_delete_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_edit_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_lifecycle_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';

void main() {
  final sampleTournaments = [
    ChampionshipTournament(
      id: 'tourn-compact-1',
      name: 'Gran Torneo de Fútbol 8 Nocturno Metropolitano 2026',
      category: 'Libre Masculino Categoría A',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 8, 30),
      format: TournamentFormat.mixedGroupsAndKnockout,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(),
      updatedAt: DateTime(2026, 5, 1),
      organizerId: 'org-compact',
    ),
    ChampionshipTournament(
      id: 'tourn-compact-2',
      name: 'Copa Élite Relámpago Regional',
      category: 'Veteranos Mayores de 45',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 9, 30),
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      rules: const TournamentRulesConfig(),
      updatedAt: DateTime(2026, 6, 1),
      organizerId: 'org-compact',
    ),
  ];

  Widget buildCompactTestWidget(
    Widget child, {
    List<ChampionshipTournament>? tournaments,
  }) {
    return ProviderScope(
      overrides: [
        if (tournaments != null)
          organizerTournamentsProvider.overrideWithValue(tournaments),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  group(
    'Organizer Competitions Responsive Tests (320x640 @ 130% text scale)',
    () {
      testWidgets(
        'OrganizerCompetitionsSection renders without overflow on compact screen',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            buildCompactTestWidget(
              const OrganizerCompetitionsSection(),
              tournaments: sampleTournaments,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('organizer_competitions_section')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'CompetitionEditDialog renders without overflow on compact screen',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            buildCompactTestWidget(
              CompetitionEditDialog(tournament: sampleTournaments.first),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('competition_edit_save_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'CompetitionLifecycleDialog renders without overflow on compact screen',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            buildCompactTestWidget(
              CompetitionLifecycleDialog(
                tournament: sampleTournaments.first,
                enrolledTeamsCount: 1,
                hasGeneratedFixture: false,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('competition_lifecycle_target_select')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'CompetitionDeleteDialog renders without overflow on compact screen',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            buildCompactTestWidget(
              CompetitionDeleteDialog(
                tournament: sampleTournaments.first,
                canDelete: true,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('competition_delete_confirm_button')),
            findsOneWidget,
          );
        },
      );
    },
  );
}
