import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

void main() {
  group('DailyMatchesDateState', () {
    test('initializes with today by default', () {
      final now = DateTime.now();
      final state = DailyMatchesDateState.today();

      expect(state.activeTab, equals(MatchesDailyTab.today));
      expect(state.selectedDate.year, equals(now.year));
      expect(state.selectedDate.month, equals(now.month));
      expect(state.selectedDate.day, equals(now.day));
      expect(state.isCustomDate, isFalse);
    });

    test('selects yesterday tab and updates date accordingly', () {
      final state = DailyMatchesDateState.today().withTab(
        MatchesDailyTab.yesterday,
      );
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(state.activeTab, equals(MatchesDailyTab.yesterday));
      expect(state.selectedDate.day, equals(yesterday.day));
      expect(state.isCustomDate, isFalse);
    });

    test('selects tomorrow tab and updates date accordingly', () {
      final state = DailyMatchesDateState.today().withTab(
        MatchesDailyTab.tomorrow,
      );
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(state.activeTab, equals(MatchesDailyTab.tomorrow));
      expect(state.selectedDate.day, equals(tomorrow.day));
      expect(state.isCustomDate, isFalse);
    });

    test('selects custom date outside yesterday/today/tomorrow', () {
      final custom = DateTime(2026, 12, 25);
      final state = DailyMatchesDateState.today().withCustomDate(custom);

      expect(state.activeTab, equals(MatchesDailyTab.customDate));
      expect(state.selectedDate, equals(DateTime(2026, 12, 25)));
      expect(state.isCustomDate, isTrue);
    });
  });

  group('groupMatchesByActiveTournaments', () {
    final tActive1 = ChampionshipTournament(
      id: 'tour-1',
      name: 'Liga Apertura',
      category: 'Libre',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      updatedAt: DateTime(2026, 1, 1),
    );

    final tActive2 = ChampionshipTournament(
      id: 'tour-2',
      name: 'Copa Ciudad',
      category: 'Senior',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      format: TournamentFormat.knockoutCup,
      status: TournamentStatus.openRegistration,
      updatedAt: DateTime(2026, 1, 1),
    );

    final tFinished = ChampionshipTournament(
      id: 'tour-finished',
      name: 'Torneo Finalizado',
      category: 'Juvenil',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      format: TournamentFormat.league,
      status: TournamentStatus.finished,
      updatedAt: DateTime(2026, 1, 1),
    );

    final targetDate = DateTime(2026, 11, 6);

    test('excludes tournaments in closed or finished statuses', () {
      final matches = [
        ChampionshipMatch(
          id: 'm-finished',
          tournamentId: 'tour-finished',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'h1',
          awayTeamId: 'a1',
          scheduledStartTime: DateTime(2026, 11, 6, 15, 0),
          status: MatchStatus.scheduled,
        ),
      ];

      final groups = groupMatchesByActiveTournaments(
        matches: matches,
        tournaments: [tFinished],
        targetDate: targetDate,
      );

      expect(groups, isEmpty);
    });

    test(
      'excludes matches without scheduledStartTime or on different date',
      () {
        final matches = [
          ChampionshipMatch(
            id: 'm-pending',
            tournamentId: 'tour-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'h1',
            awayTeamId: 'a1',
            status: MatchStatus.pendingSchedule,
          ),
          ChampionshipMatch(
            id: 'm-other-day',
            tournamentId: 'tour-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'h1',
            awayTeamId: 'a1',
            scheduledStartTime: DateTime(2026, 11, 7, 10, 0),
            status: MatchStatus.scheduled,
          ),
        ];

        final groups = groupMatchesByActiveTournaments(
          matches: matches,
          tournaments: [tActive1],
          targetDate: targetDate,
        );

        expect(groups, isEmpty);
      },
    );

    test('groups matches and puts live tournaments first', () {
      final matches = [
        ChampionshipMatch(
          id: 'm-sched-tour1',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'h1',
          awayTeamId: 'a1',
          scheduledStartTime: DateTime(2026, 11, 6, 18, 0),
          status: MatchStatus.scheduled,
        ),
        ChampionshipMatch(
          id: 'm-live-tour2',
          tournamentId: 'tour-2',
          roundNumber: 1,
          roundName: 'Cuartos',
          homeTeamId: 'h2',
          awayTeamId: 'a2',
          scheduledStartTime: DateTime(2026, 11, 6, 16, 0),
          status: MatchStatus.inProgress,
        ),
      ];

      final groups = groupMatchesByActiveTournaments(
        matches: matches,
        tournaments: [tActive1, tActive2],
        targetDate: targetDate,
      );

      expect(groups.length, equals(2));
      expect(
        groups.first.tournament.id,
        equals('tour-2'),
      ); // Live tournament goes first
      expect(groups.first.hasLiveMatches, isTrue);
      expect(groups[1].tournament.id, equals('tour-1'));
    });
  });
}
