import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';

import '../../test_helpers/teams_eligibility_test_helper.dart';

class _FakeMatchesRepository implements TournamentMatchesRepository {
  final Map<String, ChampionshipMatch> matches = {};

  @override
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  ) async {
    return matches.values.where((m) => m.tournamentId == tournamentId).toList();
  }

  Future<void> saveMatches(List<ChampionshipMatch> matchesToSave) async {
    for (final m in matchesToSave) {
      matches[m.id] = m;
    }
  }

  @override
  Future<void> replaceMatchesForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  ) async {
    this.matches.removeWhere((_, m) => m.tournamentId == tournamentId);
    for (final m in matches) {
      this.matches[m.id] = m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMatchesRepository matchesRepository;
  late FixtureSchedulingUseCase useCase;

  setUp(() {
    matchesRepository = _FakeMatchesRepository();
    useCase = FixtureSchedulingUseCase(matchesRepository: matchesRepository);
  });

  group('FixtureSchedulingUseCase Eligibility Filter Tests (HU 16.3 / US3)', () {
    test(
      'throws FixtureScheduleValidationFailure with canonical message when eligible teams < 2',
      () async {
        final tournament = createTestTournament(minPlayers: 11);
        final eligibleTeam = createTestTeam(
          id: 'team-1',
          tournamentId: tournament.id,
          playerCount: 11,
          status: TeamEligibilityStatus.eligible,
        );
        final pendingTeam = createTestTeam(
          id: 'team-2',
          tournamentId: tournament.id,
          playerCount: 9,
          status: TeamEligibilityStatus.pendingVerification,
        );

        expect(
          () => useCase.generateRoundRobinFixture(
            tournament: tournament,
            teams: [eligibleTeam, pendingTeam],
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>()
                .having(
                  (f) => f.code,
                  'code',
                  FixtureScheduleErrorCode.insufficientTeams,
                )
                .having(
                  (f) => f.message,
                  'message',
                  equals(
                    'Se requieren al menos dos equipos habilitados con nómina completa',
                  ),
                ),
          ),
        );
      },
    );

    test(
      'successfully generates fixture taking exclusively eligible teams',
      () async {
        final tournament = createTestTournament(minPlayers: 11);
        final eligible1 = createTestTeam(
          id: 'team-e1',
          tournamentId: tournament.id,
          playerCount: 11,
          status: TeamEligibilityStatus.eligible,
        );
        final eligible2 = createTestTeam(
          id: 'team-e2',
          tournamentId: tournament.id,
          playerCount: 12,
          status: TeamEligibilityStatus.eligible,
        );
        final pending3 = createTestTeam(
          id: 'team-p3',
          tournamentId: tournament.id,
          playerCount: 10,
          status: TeamEligibilityStatus.pendingVerification,
        );

        final matches = await useCase.generateRoundRobinFixture(
          tournament: tournament,
          teams: [eligible1, eligible2, pending3],
          userRole: UserRole.organizer,
        );

        expect(matches, isNotEmpty);
        for (final match in matches) {
          expect([eligible1.id, eligible2.id], contains(match.homeTeamId));
          expect([eligible1.id, eligible2.id], contains(match.awayTeamId));
          expect(match.homeTeamId, isNot(equals(pending3.id)));
          expect(match.awayTeamId, isNot(equals(pending3.id)));
        }
      },
    );
  });
}
