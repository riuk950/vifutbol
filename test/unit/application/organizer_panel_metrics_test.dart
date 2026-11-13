import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
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
  });
}
