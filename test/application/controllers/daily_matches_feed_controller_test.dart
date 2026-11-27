import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';

void main() {
  group('DailyMatchesDateState', () {
    test('initializes with today by default', () {
      final now = ColombiaTimeUtils.todayColombia();
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
      final yesterday = ColombiaTimeUtils.todayColombia().subtract(
        const Duration(days: 1),
      );

      expect(state.activeTab, equals(MatchesDailyTab.yesterday));
      expect(state.selectedDate.day, equals(yesterday.day));
      expect(state.isCustomDate, isFalse);
    });

    test('selects tomorrow tab and updates date accordingly', () {
      final state = DailyMatchesDateState.today().withTab(
        MatchesDailyTab.tomorrow,
      );
      final tomorrow = ColombiaTimeUtils.todayColombia().add(
        const Duration(days: 1),
      );

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

    test('excludes unscheduled matches (scheduledStartTime == null)', () {
      final matches = [
        ChampionshipMatch(
          id: 'm-unscheduled',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'h1',
          awayTeamId: 'a1',
          scheduledStartTime: null,
          status: MatchStatus.pendingSchedule,
        ),
      ];

      final groups = groupMatchesByActiveTournaments(
        matches: matches,
        tournaments: [tActive1],
        targetDate: targetDate,
      );

      expect(groups, isEmpty);
    });

    test(
      'groups 9:00 PM Colombia match (02:00 AM UTC next day) on the Colombia evening date',
      () {
        final lateEveningUtc = DateTime.utc(2026, 11, 20, 2, 0); // 09:00 PM Colombia on Nov 19
        final matches = [
          ChampionshipMatch(
            id: 'm-late-col',
            tournamentId: 'tour-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'h1',
            awayTeamId: 'a1',
            scheduledStartTime: lateEveningUtc,
            scheduledEndTime: lateEveningUtc.add(const Duration(minutes: 105)),
            status: MatchStatus.scheduled,
          ),
        ];

        final groupsNov19 = groupMatchesByActiveTournaments(
          matches: matches,
          tournaments: [tActive1],
          targetDate: DateTime(2026, 11, 19),
        );
        final groupsNov20 = groupMatchesByActiveTournaments(
          matches: matches,
          tournaments: [tActive1],
          targetDate: DateTime(2026, 11, 20),
        );

        expect(groupsNov19.length, 1);
        expect(groupsNov19.first.matches.first.id, 'm-late-col');
        expect(groupsNov20, isEmpty);
      },
    );
  });

  group('DailyMatchesFeedController cloud hydration', () {
    test(
      'refreshFromCloud loads tournaments, teams, and matches and reactively updates feed',
      () async {
        final today = ColombiaTimeUtils.todayColombia();
        final tournament = ChampionshipTournament(
          id: 't-cloud-1',
          name: 'Liga Cloud',
          category: 'Libre',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.add(const Duration(days: 30)),
          format: TournamentFormat.league,
          status: TournamentStatus.openRegistration,
          updatedAt: today,
        );
        final scheduledToday = ChampionshipMatch(
          id: 'm-today',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          scheduledStartTime: today.add(const Duration(hours: 15)),
          scheduledEndTime: today.add(const Duration(hours: 16, minutes: 45)),
          status: MatchStatus.scheduled,
        );

        final fakeTournaments = _StubTournamentsController([tournament]);
        final fakeTeams = _StubTeamsController();
        final fakeMatches = _StubMatchesCatalogController([scheduledToday]);

        final container = ProviderContainer(
          overrides: [
            tournamentsControllerProvider.overrideWith((_) => fakeTournaments),
            teamsControllerProvider.overrideWith((_) => fakeTeams),
            matchesCatalogControllerProvider.overrideWith((_) => fakeMatches),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(dailyMatchesFeedControllerProvider.notifier)
            .refreshFromCloud();

        expect(fakeTournaments.loadCalls, 1);
        expect(fakeTeams.loadCalls, 1);
        expect(fakeMatches.loadAllCalls, 1);

        final feedState = container.read(dailyMatchesFeedControllerProvider);
        expect(feedState.tournamentGroups.length, 1);
        expect(feedState.tournamentGroups.first.matches.first.id, 'm-today');
      },
    );
  });
}

class _StubTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _StubTournamentsController(this._items)
    : super(TournamentsCatalogState(viewState: UiSuccessState(const [])));

  final List<ChampionshipTournament> _items;
  int loadCalls = 0;

  @override
  Future<void> loadCatalog() async {
    loadCalls++;
    state = state.copyWith(
      tournaments: _items,
      viewState: UiSuccessState(_items),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _StubTeamsController() : super(const TeamsCatalogState());

  int loadCalls = 0;

  @override
  Future<void> loadTeams() async {
    loadCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _StubMatchesCatalogController(this._items)
    : super(const MatchesCatalogState());

  final List<ChampionshipMatch> _items;
  int loadAllCalls = 0;

  @override
  Future<void> loadAllMatches({bool silent = false}) async {
    loadAllCalls++;
    state = state.copyWith(matches: _items);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
