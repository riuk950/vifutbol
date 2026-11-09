import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/match_center_card.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';

void main() {
  testWidgets('renders scheduled match with start time', (tester) async {
    final scheduledMatch = ChampionshipMatch(
      id: 'm-sched',
      tournamentId: 't-1',
      roundNumber: 1,
      roundName: 'Jornada 1',
      homeTeamId: 'Real Madrid',
      awayTeamId: 'Borussia Dortmund',
      scheduledStartTime: DateTime(2026, 11, 6, 18, 30),
      status: MatchStatus.scheduled,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(body: MatchCenterCard(match: scheduledMatch)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Real Madrid'), findsOneWidget);
    expect(find.text('Borussia Dortmund'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
  });

  testWidgets('renders live match with score and EN VIVO badge', (
    tester,
  ) async {
    final liveMatch = ChampionshipMatch(
      id: 'm-live',
      tournamentId: 't-1',
      roundNumber: 1,
      roundName: 'Jornada 1',
      homeTeamId: 'Arsenal',
      awayTeamId: 'Chelsea',
      scheduledStartTime: DateTime(2026, 11, 6, 16, 0),
      homeScore: 2,
      awayScore: 1,
      status: MatchStatus.inProgress,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(body: MatchCenterCard(match: liveMatch)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('Chelsea'), findsOneWidget);
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('EN VIVO'), findsOneWidget);
  });

  testWidgets(
    'tapping home/away team triggers team navigation while center triggers onTap',
    (tester) async {
      bool matchCenterTapped = false;
      final match = ChampionshipMatch(
        id: 'm-tap',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-home',
        awayTeamId: 'team-away',
        scheduledStartTime: DateTime(2026, 11, 6, 16, 0),
        status: MatchStatus.scheduled,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamMatchSummaryProvider('team-home').overrideWithValue(
              const TeamMatchSummary(team: null, tournament: null),
            ),
            teamMatchSummaryProvider('team-away').overrideWithValue(
              const TeamMatchSummary(team: null, tournament: null),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            home: Scaffold(
              body: MatchCenterCard(
                match: match,
                onTap: () => matchCenterTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap home team area
      await tester.tap(find.byKey(const Key('match_card_home_team_m-tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_detail_screen')), findsOneWidget);
      expect(matchCenterTapped, isFalse);

      // Pop back to card
      await tester.tap(find.byKey(const Key('team_detail_back_button')));
      await tester.pumpAndSettle();

      // Tap away team area
      await tester.tap(find.byKey(const Key('match_card_away_team_m-tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_detail_screen')), findsOneWidget);
      expect(matchCenterTapped, isFalse);

      // Pop back
      await tester.tap(find.byKey(const Key('team_detail_back_button')));
      await tester.pumpAndSettle();

      // Tap center score/hub area
      await tester.tap(find.text('16:00'));
      await tester.pumpAndSettle();

      expect(matchCenterTapped, isTrue);
    },
  );
}
