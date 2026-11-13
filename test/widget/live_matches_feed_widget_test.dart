import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/match_card.dart';

void main() {
  testWidgets(
    'Live matches feed highlights inProgress match with EN VIVO badge and tabular scores',
    (tester) async {
      final homeTeam = TournamentTeam(
        id: 'team-h',
        tournamentId: 'tour-live-1',
        name: 'Halcones FC',
        shortCode: 'HAL',
        primaryColorHex: 0xFFEF4444,
        secondaryColorHex: 0xFF000000,
      );
      final awayTeam = TournamentTeam(
        id: 'team-a',
        tournamentId: 'tour-live-1',
        name: 'Águilas Doradas',
        shortCode: 'AGU',
        primaryColorHex: 0xFFFFD700,
        secondaryColorHex: 0xFF000000,
      );

      final liveMatch = ChampionshipMatch(
        id: 'match-live-1',
        tournamentId: 'tour-live-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-h',
        awayTeamId: 'team-a',
        status: MatchStatus.inProgress,
        homeScore: 2,
        awayScore: 1,
        scheduledStartTime: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: MatchCard(
              match: liveMatch,
              homeTeam: homeTeam,
              awayTeam: awayTeam,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify EN VIVO badge is displayed
      expect(find.text('EN VIVO'), findsWidgets);

      // Verify Score is displayed
      expect(find.text('2 - 1'), findsWidgets);

      // Verify MatchCard widget exists
      final matchCardFinder = find.byType(MatchCard).first;
      expect(matchCardFinder, findsOneWidget);
    },
  );
}
