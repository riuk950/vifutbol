import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

import '../../test_helpers/teams_eligibility_test_helper.dart';

class _FakeTeamsRepository implements TeamsRepository {
  final Map<String, TournamentTeam> teams = {};

  @override
  Future<List<TournamentTeam>> loadTeams() async => teams.values.toList();

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId) async {
    return teams.values.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async {
    teams[team.id] = team;
    return team;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    teams.remove(teamId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;

  setUp(() {
    repository = _FakeTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);
  });

  group('ManageTeamsEligibilityUseCase Revocation & Auto-Demotion Tests (HU 16.3 / US3)', () {
    test('organizer successfully revokes eligible team reverting to pendingVerification', () async {
      final tournament = createTestTournament(minPlayers: 11);
      final eligibleTeam = createTestTeam(
        id: 'team-rev',
        tournamentId: tournament.id,
        playerCount: 12,
        status: TeamEligibilityStatus.eligible,
      );
      await repository.saveTeam(eligibleTeam);

      final revoked = await useCase.revokeTeamEligibility(
        teamId: eligibleTeam.id,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(revoked.eligibilityStatus, equals(TeamEligibilityStatus.pendingVerification));
      expect(revoked.isEligible, isFalse);
      expect(revoked.players.every((p) => !p.isEligible), isTrue);

      final stored = await repository.loadTeamsForTournament(tournament.id);
      expect(stored.first.eligibilityStatus, equals(TeamEligibilityStatus.pendingVerification));
    });

    test('rejects non-organizer roles attempting to revoke team eligibility', () async {
      final tournament = createTestTournament(minPlayers: 11);
      final eligibleTeam = createTestTeam(
        id: 'team-rev',
        tournamentId: tournament.id,
        playerCount: 11,
        status: TeamEligibilityStatus.eligible,
      );
      await repository.saveTeam(eligibleTeam);

      for (final nonOrganizer in [
        UserRole.coach,
        UserRole.referee,
        UserRole.player,
        UserRole.fan,
      ]) {
        expect(
          () => useCase.revokeTeamEligibility(
            teamId: eligibleTeam.id,
            tournament: tournament,
            actorRole: nonOrganizer,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
          reason: 'Role $nonOrganizer must be blocked from revoking eligibility',
        );
      }
    });

    test('auto-demotes eligible team to pendingVerification when squad drops below 11 players', () async {
      final tournament = createTestTournament(minPlayers: 11);
      final teamWith11 = createTestTeam(
        id: 'team-11',
        tournamentId: tournament.id,
        playerCount: 11,
        status: TeamEligibilityStatus.eligible,
      );
      await repository.saveTeam(teamWith11);

      final playerToRemove = teamWith11.players.first.id;

      final updated = await useCase.removePlayer(
        teamId: teamWith11.id,
        playerId: playerToRemove,
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      expect(updated.players.length, equals(10));
      expect(updated.eligibilityStatus, equals(TeamEligibilityStatus.pendingVerification));
      expect(updated.isEligible, isFalse);
    });
  });
}
