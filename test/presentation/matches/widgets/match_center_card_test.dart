import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/match_center_card.dart';

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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: MatchCenterCard(match: scheduledMatch)),
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: MatchCenterCard(match: liveMatch)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('Chelsea'), findsOneWidget);
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('EN VIVO'), findsOneWidget);
  });
}
