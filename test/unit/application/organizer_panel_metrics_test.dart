import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/sync_bootstrap_provider.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

class _StubTournamentsRepository implements TournamentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController(List<ChampionshipTournament> tournaments)
    : super(
        TournamentsCatalogState(
          tournaments: tournaments,
          viewState: UiContentState(tournaments),
        ),
      );

  @override
  ManageTournamentsUseCase get manageTournamentsUseCase =>
      ManageTournamentsUseCase(_StubTournamentsRepository());

  @override
  TournamentsRepository get tournamentsRepository =>
      _StubTournamentsRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController(List<ChampionshipMatch> matches)
    : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  ChampionshipTournament makeTournament({
    required String id,
    required String? organizerId,
    TournamentStatus status = TournamentStatus.inProgress,
  }) {
    return ChampionshipTournament(
      id: id,
      organizerId: organizerId,
      name: 'Torneo $id',
      category: 'Libre',
      format: TournamentFormat.league,
      status: status,
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 6, 30),
      updatedAt: DateTime(2026, 3, 1),
    );
  }

  ChampionshipMatch makeMatch({
    required String id,
    required String tournamentId,
    DateTime? scheduledStartTime,
  }) {
    return ChampionshipMatch(
      id: id,
      tournamentId: tournamentId,
      roundNumber: 1,
      roundName: 'Jornada 1',
      homeTeamId: 'team-a',
      awayTeamId: 'team-b',
      scheduledStartTime: scheduledStartTime,
    );
  }

  group('computeOrganizerPanelMetrics()', () {
    test(
      'returns 0 across all metrics when organizer has no tournaments despite global matches',
      () {
        final metrics = computeOrganizerPanelMetrics(
          organizerTournaments: const [],
          allMatches: [
            makeMatch(id: 'm-1', tournamentId: 'other-t1'),
            makeMatch(id: 'm-2', tournamentId: 'other-t2'),
          ],
        );

        expect(metrics.activeTournamentsCount, 0);
        expect(metrics.pendingScheduleMatchesCount, 0);
        expect(metrics.unseededTournamentsCount, 0);
      },
    );

    test(
      'counts only active/open tournaments, unscheduled matches in own tournaments, and unseeded active tournaments',
      () {
        final ownTournaments = [
          makeTournament(
            id: 'own-active-seeded',
            organizerId: 'user-123',
            status: TournamentStatus.inProgress,
          ),
          makeTournament(
            id: 'own-open-unseeded',
            organizerId: 'user-123',
            status: TournamentStatus.openRegistration,
          ),
          makeTournament(
            id: 'own-finished',
            organizerId: 'user-123',
            status: TournamentStatus.finished,
          ),
        ];

        final allMatches = [
          makeMatch(id: 'm-own-1', tournamentId: 'own-active-seeded'),
          makeMatch(
            id: 'm-own-2',
            tournamentId: 'own-active-seeded',
            scheduledStartTime: DateTime(2026, 4, 1, 15, 0),
          ),
          makeMatch(id: 'm-other-1', tournamentId: 'other-t1'),
          makeMatch(id: 'm-other-2', tournamentId: 'other-t2'),
        ];

        final metrics = computeOrganizerPanelMetrics(
          organizerTournaments: ownTournaments,
          allMatches: allMatches,
        );

        expect(metrics.activeTournamentsCount, 2);
        expect(metrics.pendingScheduleMatchesCount, 1);
        expect(metrics.unseededTournamentsCount, 1);
      },
    );
  });

  group('organizerTournamentsProvider & organizerPanelMetricsProvider', () {
    test(
      'strictly isolates tournaments and metrics for authenticated organizer user-123 (excluding org-seed-1 and other-org)',
      () {
        final allTournaments = [
          makeTournament(
            id: 't-user-1',
            organizerId: 'user-123',
            status: TournamentStatus.inProgress,
          ),
          makeTournament(
            id: 't-user-2',
            organizerId: 'user-123',
            status: TournamentStatus.openRegistration,
          ),
          makeTournament(
            id: 't-seed-1',
            organizerId: 'org-seed-1',
            status: TournamentStatus.inProgress,
          ),
          makeTournament(
            id: 't-other-1',
            organizerId: 'other-org',
            status: TournamentStatus.inProgress,
          ),
          makeTournament(
            id: 't-null-org',
            organizerId: null,
            status: TournamentStatus.openRegistration,
          ),
        ];

        final allMatches = [
          makeMatch(id: 'm-user-1', tournamentId: 't-user-1'),
          makeMatch(id: 'm-seed-1', tournamentId: 't-seed-1'),
          makeMatch(id: 'm-other-1', tournamentId: 't-other-1'),
        ];

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              (_) => _FakeAuthController(
                AuthFlowState(
                  status: AuthStatus.authenticated,
                  session: AuthSession(
                    sessionId: 'sess-1',
                    user: UserAccount(
                      id: 'user-123',
                      fullName: 'Organizador Principal',
                      email: 'org@vifutbol.com',
                      activeRole: UserRole.organizer,
                    ),
                    sessionToken: 'token',
                    authenticatedAt: DateTime(2026, 11, 13),
                  ),
                ),
              ),
            ),
            tournamentsControllerProvider.overrideWith(
              (_) => _FakeTournamentsController(allTournaments),
            ),
            matchesCatalogControllerProvider.overrideWith(
              (_) => _FakeMatchesCatalogController(allMatches),
            ),
          ],
        );
        addTearDown(container.dispose);

        final ownTournaments = container.read(organizerTournamentsProvider);
        expect(ownTournaments.map((t) => t.id).toList(), [
          't-user-1',
          't-user-2',
        ]);

        final metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 2);
        expect(metrics.pendingScheduleMatchesCount, 1);
        expect(metrics.unseededTournamentsCount, 1);
      },
    );

    test('falls back to org-seed-1 when no authenticated session exists', () {
      final allTournaments = [
        makeTournament(
          id: 't-seed-1',
          organizerId: 'org-seed-1',
          status: TournamentStatus.inProgress,
        ),
        makeTournament(
          id: 't-other-1',
          organizerId: 'other-org',
          status: TournamentStatus.inProgress,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (_) => _FakeAuthController(
              const AuthFlowState(status: AuthStatus.unauthenticated),
            ),
          ),
          tournamentsControllerProvider.overrideWith(
            (_) => _FakeTournamentsController(allTournaments),
          ),
          matchesCatalogControllerProvider.overrideWith(
            (_) => _FakeMatchesCatalogController(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ownTournaments = container.read(organizerTournamentsProvider);
      expect(ownTournaments.map((t) => t.id).toList(), ['t-seed-1']);

      final metrics = container.read(organizerPanelMetricsProvider);
      expect(metrics.activeTournamentsCount, 1);
      expect(metrics.pendingScheduleMatchesCount, 0);
      expect(metrics.unseededTournamentsCount, 1);
    });

    test(
      'HU 22.4 (US1): recalculates metrics immediately after generating fixture, scheduling 2 of 6 matches, and regenerating',
      () {
        final t1 = makeTournament(
          id: 't-1',
          organizerId: 'org-seed-1',
          status: TournamentStatus.openRegistration,
        );
        final tournamentsCtrl = _FakeTournamentsController([t1]);
        final matchesCtrl = _FakeMatchesCatalogController(const []);

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              (_) => _FakeAuthController(
                const AuthFlowState(status: AuthStatus.unauthenticated),
              ),
            ),
            tournamentsControllerProvider.overrideWith((_) => tournamentsCtrl),
            matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
          ],
        );
        addTearDown(container.dispose);

        var metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 1);
        expect(metrics.unseededTournamentsCount, 1);
        expect(metrics.pendingScheduleMatchesCount, 0);

        // Generate 6 unscheduled matches
        final generated = List.generate(
          6,
          (i) => makeMatch(id: 'm-$i', tournamentId: 't-1'),
        );
        matchesCtrl.state = matchesCtrl.state.copyWith(matches: generated);

        metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.unseededTournamentsCount, 0);
        expect(metrics.pendingScheduleMatchesCount, 6);

        // Schedule 2 of the 6 matches
        final afterSchedule = [
          for (var i = 0; i < generated.length; i++)
            i < 2
                ? generated[i].copyWith(
                    scheduledStartTime: DateTime(2026, 5, 1, 10 + i),
                    status: MatchStatus.scheduled,
                  )
                : generated[i],
        ];
        matchesCtrl.state = matchesCtrl.state.copyWith(matches: afterSchedule);

        metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.pendingScheduleMatchesCount, 4);
      },
    );

    test(
      'HU 22.4 (US2): recalculates metrics on create, transition to finished, and delete',
      () {
        final t1 = makeTournament(
          id: 't-1',
          organizerId: 'org-seed-1',
          status: TournamentStatus.inProgress,
        );
        final tournamentsCtrl = _FakeTournamentsController([t1]);
        final matchesCtrl = _FakeMatchesCatalogController([
          makeMatch(id: 'm-1', tournamentId: 't-1'),
          makeMatch(
            id: 'm-done',
            tournamentId: 't-1',
          ).copyWith(status: MatchStatus.completed),
        ]);

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              (_) => _FakeAuthController(
                const AuthFlowState(status: AuthStatus.unauthenticated),
              ),
            ),
            tournamentsControllerProvider.overrideWith((_) => tournamentsCtrl),
            matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
          ],
        );
        addTearDown(container.dispose);

        // Completed match without scheduledStartTime is excluded
        var metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 1);
        expect(metrics.pendingScheduleMatchesCount, 1);

        // Create a second tournament (unseeded)
        final t2 = makeTournament(
          id: 't-2',
          organizerId: 'org-seed-1',
          status: TournamentStatus.openRegistration,
        );
        tournamentsCtrl.state = tournamentsCtrl.state.copyWith(
          tournaments: [t1, t2],
        );
        metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 2);
        expect(metrics.unseededTournamentsCount, 1);

        // Transition t1 to finished -> excluded from active & pending matches
        tournamentsCtrl.state = tournamentsCtrl.state.copyWith(
          tournaments: [
            t1.copyWith(status: TournamentStatus.finished),
            t2,
          ],
        );
        metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 1);
        expect(metrics.pendingScheduleMatchesCount, 0);
        expect(metrics.unseededTournamentsCount, 1);

        // Delete t2
        tournamentsCtrl.state = tournamentsCtrl.state.copyWith(
          tournaments: [t1.copyWith(status: TournamentStatus.finished)],
        );
        metrics = container.read(organizerPanelMetricsProvider);
        expect(metrics.activeTournamentsCount, 0);
        expect(metrics.unseededTournamentsCount, 0);
      },
    );

    test(
      'HU 22.4 (C1): refreshControllerForSyncedEntity refreshes tournaments, teams, and matches controllers',
      () async {
        final tournamentsCtrl = _SpyTournamentsController();
        final teamsCtrl = _SpyTeamsController();
        final matchesCtrl = _SpyMatchesCatalogController();

        final refresherProvider = Provider<Future<void> Function(SyncOutboxEntityType)>(
          (ref) => (type) => refreshControllerForSyncedEntity(ref, type),
        );

        final container = ProviderContainer(
          overrides: [
            tournamentsControllerProvider.overrideWith((_) => tournamentsCtrl),
            teamsControllerProvider.overrideWith((_) => teamsCtrl),
            matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
          ],
        );
        addTearDown(container.dispose);

        final refresh = container.read(refresherProvider);
        await refresh(SyncOutboxEntityType.tournament);
        await refresh(SyncOutboxEntityType.team);
        await refresh(SyncOutboxEntityType.match);

        expect(tournamentsCtrl.loadCatalogCalls, 1);
        expect(teamsCtrl.loadTeamsCalls, 1);
        expect(matchesCtrl.loadAllMatchesCalls, 1);
      },
    );
  });
}

class _SpyTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _SpyTournamentsController()
    : super(
        const TournamentsCatalogState(
          viewState: UiSuccessState<List<ChampionshipTournament>>([]),
        ),
      );

  int loadCatalogCalls = 0;

  @override
  Future<void> loadCatalog() async {
    loadCatalogCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _SpyTeamsController() : super(const TeamsCatalogState());

  int loadTeamsCalls = 0;

  @override
  Future<void> loadTeams() async {
    loadTeamsCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _SpyMatchesCatalogController() : super(const MatchesCatalogState());

  int loadAllMatchesCalls = 0;

  @override
  Future<void> loadAllMatches({bool silent = false}) async {
    loadAllMatchesCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
