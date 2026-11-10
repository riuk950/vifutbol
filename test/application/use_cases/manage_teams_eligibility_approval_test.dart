import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
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
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
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

  group(
    'ManageTeamsEligibilityUseCase.approveTeamEligibility Tests (HU 16.3 / US1)',
    () {
      test(
        'rejects team approval when player count < 11 with exact canonical message',
        () async {
          final tournament = createTestTournament(minPlayers: 11);
          final teamWith9 = createTestTeam(
            id: 'team-9',
            tournamentId: tournament.id,
            playerCount: 9,
            status: TeamEligibilityStatus.pendingVerification,
          );
          await repository.saveTeam(teamWith9);

          expect(
            () => useCase.approveTeamEligibility(
              teamId: teamWith9.id,
              tournament: tournament,
              actorRole: UserRole.organizer,
            ),
            throwsA(
              isA<TeamEligibilityValidationFailure>()
                  .having(
                    (f) => f.code,
                    'code',
                    TeamEligibilityErrorCode.insufficientPlayersForApproval,
                  )
                  .having(
                    (f) => f.message,
                    'message',
                    equals(
                      'El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: 9)',
                    ),
                  ),
            ),
          );
        },
      );

      test(
        'successfully approves team when player count >= 11 and transitions to eligible',
        () async {
          final tournament = createTestTournament(minPlayers: 11);
          final teamWith11 = createTestTeam(
            id: 'team-11',
            tournamentId: tournament.id,
            playerCount: 11,
            status: TeamEligibilityStatus.pendingVerification,
          );
          await repository.saveTeam(teamWith11);

          final approved = await useCase.approveTeamEligibility(
            teamId: teamWith11.id,
            tournament: tournament,
            actorRole: UserRole.organizer,
          );

          expect(
            approved.eligibilityStatus,
            equals(TeamEligibilityStatus.eligible),
          );
          expect(approved.isEligible, isTrue);
          expect(approved.players.every((p) => p.isEligible), isTrue);

          final stored = await repository.loadTeamsForTournament(tournament.id);
          expect(stored.first.isEligible, isTrue);
        },
      );

      test('rejects non-organizer roles attempting to approve team', () async {
        final tournament = createTestTournament(minPlayers: 11);
        final teamWith11 = createTestTeam(
          id: 'team-11',
          tournamentId: tournament.id,
          playerCount: 11,
        );
        await repository.saveTeam(teamWith11);

        for (final nonOrganizerRole in [
          UserRole.coach,
          UserRole.referee,
          UserRole.player,
          UserRole.fan,
        ]) {
          expect(
            () => useCase.approveTeamEligibility(
              teamId: teamWith11.id,
              tournament: tournament,
              actorRole: nonOrganizerRole,
            ),
            throwsA(isA<UnauthorizedRoleFailure>()),
            reason: 'Role $nonOrganizerRole must be rejected',
          );
        }
      });

      test('rejects approval on finished tournament', () async {
        final finishedTournament = createTestTournament(
          status: TournamentStatus.finished,
        );
        final teamWith11 = createTestTeam(
          id: 'team-11',
          tournamentId: finishedTournament.id,
          playerCount: 11,
        );
        await repository.saveTeam(teamWith11);

        expect(
          () => useCase.approveTeamEligibility(
            teamId: teamWith11.id,
            tournament: finishedTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TeamEligibilityValidationFailure>().having(
              (f) => f.code,
              'code',
              TeamEligibilityErrorCode.tournamentRegistrationsClosed,
            ),
          ),
        );
      });
    },
  );
}
