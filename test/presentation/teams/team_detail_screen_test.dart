import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/models/team_matches_schedule.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';
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
    TeamMatchesSchedule? schedule,
    TeamSquadRoster? roster,
  }) {
    final effectiveSchedule =
        schedule ??
        TeamMatchesSchedule(
          teamId: teamId,
          upcomingMatches: const [],
          completedMatches: const [],
        );
    final effectiveRoster =
        roster ??
        TeamSquadRoster(
          teamId: teamId,
          team: summary.team,
          goalkeepers: const [],
          defenders: const [],
          midfielders: const [],
          forwards: const [],
          allProfiles: const [],
        );

    return ProviderScope(
      overrides: [
        teamMatchSummaryProvider(teamId).overrideWithValue(summary),
        teamMatchesScheduleProvider(
          teamId,
        ).overrideWithValue(effectiveSchedule),
        teamSquadRosterProvider(teamId).overrideWithValue(effectiveRoster),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
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
        final nextMatchCard = find.byKey(const Key('team_next_match_card'));
        await tester.scrollUntilVisible(
          nextMatchCard,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(nextMatchCard, findsOneWidget);
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
      'allows switching between tabs and renders matches tab view and squad tab view',
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
          find.byKey(const Key('team_matches_empty_state')),
          findsOneWidget,
        );
        expect(find.text('Sin partidos en el calendario'), findsOneWidget);

        // Tap on "Plantilla" tab
        await tester.tap(find.byKey(const Key('team_detail_tab_squad')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_squad_empty_state')), findsOneWidget);
        expect(find.text('Plantilla sin jugadores inscritos'), findsOneWidget);

        // Return to "Información"
        await tester.tap(find.byKey(const Key('team_detail_tab_info')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('team_club_profile_card')), findsOneWidget);
      },
    );

    testWidgets(
      'renders upcoming matches in chronological order in Partidos tab (US1)',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
        );

        final upcomingMatch = ChampionshipMatch(
          id: 'm-up-1',
          tournamentId: 'tour-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 20, 16, 0),
          pitchName: 'Cancha 1 - Principal',
        );

        final schedule = TeamMatchesSchedule(
          teamId: 'team-1',
          upcomingMatches: [
            TeamScheduledMatchItem(
              match: upcomingMatch,
              homeTeam: testTeam,
              awayTeam: opponentTeam,
              isHome: true,
              outcome: null,
            ),
          ],
          completedMatches: const [],
        );

        await tester.pumpWidget(
          createTestWidget(
            teamId: 'team-1',
            summary: summary,
            schedule: schedule,
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Partidos tab
        await tester.tap(find.byKey(const Key('team_detail_tab_matches')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_upcoming_matches_header')),
          findsOneWidget,
        );
        expect(find.text('Próximos Partidos'), findsOneWidget);
        expect(
          find.byKey(const Key('team_upcoming_match_item_m-up-1')),
          findsOneWidget,
        );
        expect(find.text('Jornada 3'), findsOneWidget);
        expect(find.text('Cancha 1 - Principal'), findsOneWidget);
        expect(find.text('Local'), findsOneWidget);
        expect(find.text('Deportivo Sur'), findsOneWidget);
      },
    );

    testWidgets(
      'renders completed matches with semantic outcome badges in Partidos tab (US2)',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
        );

        final matchWin = ChampionshipMatch(
          id: 'm-win',
          tournamentId: 'tour-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 10, 14, 0),
          homeScore: 3,
          awayScore: 1,
          pitchName: 'Cancha 2',
        );

        final matchDraw = ChampionshipMatch(
          id: 'm-draw',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-2',
          awayTeamId: 'team-1',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 3, 10, 0),
          homeScore: 1,
          awayScore: 1,
          pitchName: 'Cancha 1',
        );

        final schedule = TeamMatchesSchedule(
          teamId: 'team-1',
          upcomingMatches: const [],
          completedMatches: [
            TeamScheduledMatchItem(
              match: matchWin,
              homeTeam: testTeam,
              awayTeam: opponentTeam,
              isHome: true,
              outcome: TeamMatchOutcome.win,
            ),
            TeamScheduledMatchItem(
              match: matchDraw,
              homeTeam: opponentTeam,
              awayTeam: testTeam,
              isHome: false,
              outcome: TeamMatchOutcome.draw,
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            teamId: 'team-1',
            summary: summary,
            schedule: schedule,
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Partidos tab
        await tester.tap(find.byKey(const Key('team_detail_tab_matches')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_completed_matches_header')),
          findsOneWidget,
        );
        expect(find.text('Resultados Anteriores'), findsOneWidget);
        expect(
          find.byKey(const Key('team_completed_match_item_m-win')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('team_completed_match_item_m-draw')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('team_match_outcome_badge_m-win')),
          findsOneWidget,
        );
        expect(find.text('Victoria'), findsOneWidget);
        expect(
          find.byKey(const Key('team_match_outcome_badge_m-draw')),
          findsOneWidget,
        );
        expect(find.text('Empate'), findsOneWidget);
      },
    );

    testWidgets(
      'opens match detail modal when tapping match card in Partidos tab (US3)',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
        );

        final match = ChampionshipMatch(
          id: 'm-detail',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 5, 15, 30),
          homeScore: 2,
          awayScore: 0,
          pitchName: 'Estadio Metropolitano',
          refereeName: 'Carlos Gómez',
        );

        final schedule = TeamMatchesSchedule(
          teamId: 'team-1',
          upcomingMatches: const [],
          completedMatches: [
            TeamScheduledMatchItem(
              match: match,
              homeTeam: testTeam,
              awayTeam: opponentTeam,
              isHome: true,
              outcome: TeamMatchOutcome.win,
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            teamId: 'team-1',
            summary: summary,
            schedule: schedule,
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Partidos tab
        await tester.tap(find.byKey(const Key('team_detail_tab_matches')));
        await tester.pumpAndSettle();

        // Tap on the match card (center content hub)
        await tester.tap(find.text('2 - 0'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_match_detail_modal')),
          findsOneWidget,
        );
        expect(find.text('Atlético Norte FC vs Deportivo Sur'), findsOneWidget);
        expect(find.text('Estadio Metropolitano'), findsWidgets);
        expect(find.text('Árbitro designado: Carlos Gómez'), findsOneWidget);
      },
    );

    testWidgets(
      'renders partial empty state when only upcoming matches exist (US3)',
      (tester) async {
        final summary = TeamMatchSummary(
          team: testTeam,
          tournament: testTournament,
        );

        final upcomingMatch = ChampionshipMatch(
          id: 'm-up',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.scheduled,
        );

        final schedule = TeamMatchesSchedule(
          teamId: 'team-1',
          upcomingMatches: [
            TeamScheduledMatchItem(
              match: upcomingMatch,
              homeTeam: testTeam,
              awayTeam: opponentTeam,
              isHome: true,
              outcome: null,
            ),
          ],
          completedMatches: const [],
        );

        await tester.pumpWidget(
          createTestWidget(
            teamId: 'team-1',
            summary: summary,
            schedule: schedule,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('team_detail_tab_matches')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_upcoming_match_item_m-up')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('team_completed_matches_empty_state')),
          findsOneWidget,
        );
        expect(
          find.text('Sin partidos finalizados registrados'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders registered squad players in ascending shirtNumber order with position and eligibility badges (US1)',
      (tester) async {
        final players = [
          const RegisteredPlayer(
            id: 'p-gk',
            fullName: 'Marc-André ter Stegen',
            documentId: 'DOC-1',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-def',
            fullName: 'Ronald Araújo',
            documentId: 'DOC-2',
            shirtNumber: 4,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-mid',
            fullName: 'Pedri González',
            documentId: 'DOC-3',
            shirtNumber: 8,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-fwd',
            fullName: 'Robert Lewandowski',
            documentId: 'DOC-4',
            shirtNumber: 9,
            position: PlayerPosition.forward,
            isEligible: false,
          ),
        ];

        final squadTeam = TournamentTeam(
          id: 'team-1',
          tournamentId: 'tour-1',
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
          players: players,
        );

        final summary = TeamMatchSummary(
          team: squadTeam,
          tournament: testTournament,
        );

        final roster = TeamSquadRoster.fromCatalog(
          teamId: 'team-1',
          teams: [squadTeam],
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary, roster: roster),
        );
        await tester.pumpAndSettle();

        // Switch to "Plantilla" tab
        await tester.tap(find.byKey(const Key('team_detail_tab_squad')));
        await tester.pumpAndSettle();

        // Player 1 (GK)
        expect(
          find.byKey(const Key('team_squad_player_item_p-gk')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('team_squad_player_shirt_p-gk')),
          findsOneWidget,
        );
        expect(find.text('#1'), findsOneWidget);
        expect(find.text('Marc-André ter Stegen'), findsOneWidget);
        expect(
          find.byKey(const Key('team_squad_player_position_badge_p-gk')),
          findsOneWidget,
        );
        expect(find.text('Portero'), findsOneWidget);
        expect(
          find.byKey(const Key('team_squad_player_eligibility_badge_p-gk')),
          findsOneWidget,
        );
        expect(find.text('Habilitado'), findsNWidgets(3)); // 3 eligible players

        // Player 4 (FWD) - Suspended
        expect(
          find.byKey(const Key('team_squad_player_item_p-fwd')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('team_squad_player_shirt_p-fwd')),
          findsOneWidget,
        );
        expect(find.text('#9'), findsOneWidget);
        expect(find.text('Robert Lewandowski'), findsOneWidget);
        expect(
          find.byKey(const Key('team_squad_player_position_badge_p-fwd')),
          findsOneWidget,
        );
        expect(find.text('Delantero'), findsOneWidget);
        expect(
          find.byKey(const Key('team_squad_player_eligibility_badge_p-fwd')),
          findsOneWidget,
        );
        expect(find.text('Suspendido'), findsOneWidget);
      },
    );

    testWidgets(
      'renders 4 fixed tactical blocks and contextual empty state for line without players (US2)',
      (tester) async {
        final players = [
          const RegisteredPlayer(
            id: 'p-gk',
            fullName: 'Thibaut Courtois',
            documentId: 'DOC-1',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-def',
            fullName: 'David Alaba',
            documentId: 'DOC-2',
            shirtNumber: 4,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-mid',
            fullName: 'Luka Modric',
            documentId: 'DOC-3',
            shirtNumber: 10,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
          // Notice: 0 Forwards
        ];

        final squadTeam = TournamentTeam(
          id: 'team-1',
          tournamentId: 'tour-1',
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
          players: players,
        );

        final summary = TeamMatchSummary(
          team: squadTeam,
          tournament: testTournament,
        );

        final roster = TeamSquadRoster.fromCatalog(
          teamId: 'team-1',
          teams: [squadTeam],
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary, roster: roster),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('team_detail_tab_squad')));
        await tester.pumpAndSettle();

        // Section Headers
        expect(
          find.byKey(const Key('team_squad_header_goalkeeper')),
          findsOneWidget,
        );
        expect(find.text('Porteros'), findsOneWidget);

        expect(
          find.byKey(const Key('team_squad_header_defender')),
          findsOneWidget,
        );
        expect(find.text('Defensas'), findsOneWidget);

        expect(
          find.byKey(const Key('team_squad_header_midfielder')),
          findsOneWidget,
        );
        expect(find.text('Centrocampistas'), findsOneWidget);

        expect(
          find.byKey(const Key('team_squad_header_forward')),
          findsOneWidget,
        );
        expect(find.text('Delanteros'), findsOneWidget);

        // Forward section is empty
        expect(
          find.byKey(const Key('team_squad_empty_forward')),
          findsOneWidget,
        );
        expect(
          find.text('Sin jugadores registrados en esta posición'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'opens player performance profile sheet on card tap and supports squad switcher (US3)',
      (tester) async {
        final players = [
          const RegisteredPlayer(
            id: 'p-1',
            fullName: 'Player Alpha',
            documentId: 'DOC-1',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: true,
          ),
          const RegisteredPlayer(
            id: 'p-2',
            fullName: 'Player Beta',
            documentId: 'DOC-2',
            shirtNumber: 10,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
        ];

        final squadTeam = TournamentTeam(
          id: 'team-1',
          tournamentId: 'tour-1',
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
          players: players,
        );

        final summary = TeamMatchSummary(
          team: squadTeam,
          tournament: testTournament,
        );

        final roster = TeamSquadRoster.fromCatalog(
          teamId: 'team-1',
          teams: [squadTeam],
        );

        await tester.pumpWidget(
          createTestWidget(teamId: 'team-1', summary: summary, roster: roster),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('team_detail_tab_squad')));
        await tester.pumpAndSettle();

        // Tap Player Alpha card
        await tester.tap(find.byKey(const Key('team_squad_player_item_p-1')));
        await tester.pumpAndSettle();

        // Bottom sheet opened
        expect(
          find.byKey(const Key('player_performance_profile_card')),
          findsOneWidget,
        );
        expect(find.text('Player Alpha'), findsWidgets);
        expect(
          find.byKey(const Key('player_disciplinary_badge')),
          findsOneWidget,
        );

        // Switch to Player Beta via squad switcher chip
        final switcherBeta = find.byKey(const Key('player_switcher_chip_p-2'));
        expect(switcherBeta, findsOneWidget);
        await tester.tap(switcherBeta);
        await tester.pumpAndSettle();

        expect(find.text('Player Beta'), findsWidgets);

        // Close modal
        final closeButton = find.byKey(
          const Key('close_player_profile_button'),
        );
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('player_performance_profile_card')),
          findsNothing,
        );
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
