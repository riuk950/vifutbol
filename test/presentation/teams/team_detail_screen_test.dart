import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/team_detail_screen.dart';

void main() {
  final testTeam = TournamentTeam(
    id: 'team-1',
    tournamentId: 'tour-1',
    name: 'Atlético Norte FC',
    shortCode: 'ATN',
    crestShape: TeamCrestShape.shield,
    primaryColorHex: 0xFF00E676,
    secondaryColorHex: 0xFF0A0E17,
    eligibilityStatus: TeamEligibilityStatus.eligible,
  );

  final opponentTeam = TournamentTeam(
    id: 'team-2',
    tournamentId: 'tour-1',
    name: 'Deportivo Sur',
    shortCode: 'DPS',
    crestShape: TeamCrestShape.circle,
    primaryColorHex: 0xFF38BDF8,
    secondaryColorHex: 0xFF0A0E17,
    eligibilityStatus: TeamEligibilityStatus.eligible,
  );

  final testTournament = ChampionshipTournament(
    id: 'tour-1',
    name: 'Liga de Apertura 2026',
    category: 'Primera División',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 6, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    updatedAt: DateTime(2026, 3, 1),
  );

  Widget createTestWidget({
    required String teamId,
    required TeamMatchSummary summary,
  }) {
    return ProviderScope(
      overrides: [teamMatchSummaryProvider(teamId).overrideWithValue(summary)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: TeamDetailScreen(teamId: teamId),
      ),
    );
  }

  group('TeamDetailScreen Widget Tests', () {
    testWidgets('renders team identity in AppBar and 3 horizontal tabs', (
      tester,
    ) async {
      final summary = TeamMatchSummary(
        team: testTeam,
        tournament: testTournament,
      );

      await tester.pumpWidget(
        createTestWidget(teamId: 'team-1', summary: summary),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_detail_screen')), findsOneWidget);
      expect(
        find.byKey(const Key('team_detail_app_bar_crest')),
        findsOneWidget,
      );
      expect(find.text('Atlético Norte FC'), findsWidgets);
      expect(find.text('ATN'), findsWidgets);
      expect(find.text('Liga de Apertura 2026'), findsWidgets);
      expect(
        find.byKey(const Key('team_detail_eligibility_badge')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('team_detail_tab_info')), findsOneWidget);
      expect(find.byKey(const Key('team_detail_tab_matches')), findsOneWidget);
      expect(find.byKey(const Key('team_detail_tab_squad')), findsOneWidget);
    });

    testWidgets(
      'renders club profile, last match, and next match cards in Info tab',
      (tester) async {
        final lastMatch = ChampionshipMatch(
          id: 'm-last',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 5, 15, 0),
          homeScore: 3,
          awayScore: 1,
          pitchName: 'Cancha Central',
        );

        final nextMatch = ChampionshipMatch(
          id: 'm-next',
          tournamentId: 'tour-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-2',
          awayTeamId: 'team-1',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 12, 17, 30),
          pitchName: 'Estadio Olímpico',
        );

        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
          lastPlayedMatch: lastMatch,
          lastMatchOpponent: opponentTeam,
          isLastMatchHome: true,
          nextScheduledMatch: nextMatch,
          nextMatchOpponent: opponentTeam,
          isNextMatchHome: false,
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary),
        );
        await tester.pumpAndSettle();

        // Club Profile Card
        expect(find.byKey(const Key('team_club_profile_card')), findsOneWidget);
        expect(
          find.byKey(const Key('team_primary_color_swatch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('team_secondary_color_swatch')),
          findsOneWidget,
        );

        // Last Match Card
        expect(find.byKey(const Key('team_last_match_card')), findsOneWidget);
        expect(
          find.byKey(const Key('team_last_match_content')),
          findsOneWidget,
        );
        expect(find.text('3 - 1'), findsOneWidget);
        expect(find.text('FT'), findsOneWidget);

        // Next Match Card
        expect(find.byKey(const Key('team_next_match_card')), findsOneWidget);
        expect(
          find.byKey(const Key('team_next_match_content')),
          findsOneWidget,
        );
        expect(find.text('@ Deportivo Sur'), findsOneWidget);
        expect(find.text('Visitante'), findsOneWidget);
      },
    );

    testWidgets(
      'renders empty states when no previous or upcoming matches exist',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
          lastPlayedMatch: null,
          nextScheduledMatch: null,
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_last_match_empty_state')),
          findsOneWidget,
        );
        expect(find.text('Sin partidos previos disputados'), findsOneWidget);

        expect(
          find.byKey(const Key('team_next_match_empty_state')),
          findsOneWidget,
        );
        expect(find.text('Sin próximos partidos agendados'), findsOneWidget);
      },
    );

    testWidgets(
      'allows switching between tabs and renders placeholders for matches and squad',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary),
        );
        await tester.pumpAndSettle();

        // Tap on "Partidos" tab
        await tester.tap(find.byKey(const Key('team_detail_tab_matches')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_matches_tab_placeholder')),
          findsOneWidget,
        );
        expect(find.text('Calendario del Equipo'), findsOneWidget);

        // Tap on "Plantilla" tab
        await tester.tap(find.byKey(const Key('team_detail_tab_squad')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_squad_tab_placeholder')),
          findsOneWidget,
        );
        expect(find.text('Plantilla Oficial'), findsOneWidget);

        // Return to "Información"
        await tester.tap(find.byKey(const Key('team_detail_tab_info')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_club_profile_card')), findsOneWidget);
      },
    );

    testWidgets('renders not-found state when team is null', (tester) async {
      const summary = TeamMatchSummary(team: null, tournament: null);

      await tester.pumpWidget(
        createTestWidget(teamId: 'unknown-id', summary: summary),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('team_detail_not_found_state')),
        findsOneWidget,
      );
      expect(find.text('Equipo no encontrado'), findsWidgets);
    });
  });
}
