import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

class _FakeTeamsRepository implements TeamsRepository {
  final List<TournamentTeam> _teams = [];

  @override
  Future<List<TournamentTeam>> loadTeams() async => List.unmodifiable(_teams);

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    return _teams.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async {
    _teams.add(team);
    return team;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;
  late ChampionshipTournament sampleTournament;

  setUp(() {
    repository = _FakeTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);

    sampleTournament = ChampionshipTournament(
      id: 'tourn-gov-1',
      name: 'Torneo Gobernanza',
      category: 'Primera',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 12, 1),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(),
      updatedAt: DateTime(2026, 7, 1),
    );
  });

  group('ManageTeamsEligibilityUseCase Governance Role Enforcement (US3)', () {
    const expectedErrorMessage =
        'Solo los entrenadores pueden registrar equipos o futbolistas';

    final testTeam = TournamentTeam(
      id: 'team-gov-1',
      tournamentId: 'tourn-gov-1',
      name: 'Club Atlético Viña',
      shortCode: 'CAV',
    );

    const testPlayer = RegisteredPlayer(
      id: 'p-1',
      fullName: 'Marcelo Salas',
      documentId: '11223344-5',
      shirtNumber: 11,
      position: PlayerPosition.forward,
    );

    final nonCoachRoles = [
      UserRole.organizer,
      UserRole.referee,
      UserRole.player,
      UserRole.fan,
    ];

    for (final role in nonCoachRoles) {
      test(
        'registerOrUpdateTeam throws UnauthorizedRoleFailure with exact message for ${role.name}',
        () async {
          expect(
            () => useCase.registerOrUpdateTeam(
              team: testTeam,
              tournament: sampleTournament,
              actorRole: role,
            ),
            throwsA(
              isA<UnauthorizedRoleFailure>().having(
                (f) => f.message,
                'message',
                equals(expectedErrorMessage),
              ),
            ),
          );
        },
      );

      test(
        'registerOrUpdateTeam (autonomous club) throws UnauthorizedRoleFailure for ${role.name}',
        () async {
          expect(
            () => useCase.registerOrUpdateTeam(
              team: testTeam,
              tournament: null,
              actorRole: role,
            ),
            throwsA(
              isA<UnauthorizedRoleFailure>().having(
                (f) => f.message,
                'message',
                equals(expectedErrorMessage),
              ),
            ),
          );
        },
      );

      test(
        'enrollOrUpdatePlayer throws UnauthorizedRoleFailure with exact message for ${role.name}',
        () async {
          expect(
            () => useCase.enrollOrUpdatePlayer(
              teamId: testTeam.id,
              player: testPlayer,
              tournament: sampleTournament,
              actorRole: role,
            ),
            throwsA(
              isA<UnauthorizedRoleFailure>().having(
                (f) => f.message,
                'message',
                equals(expectedErrorMessage),
              ),
            ),
          );
        },
      );

      test(
        'removePlayer throws UnauthorizedRoleFailure with exact message for ${role.name}',
        () async {
          expect(
            () => useCase.removePlayer(
              teamId: testTeam.id,
              playerId: testPlayer.id,
              tournament: sampleTournament,
              actorRole: role,
            ),
            throwsA(
              isA<UnauthorizedRoleFailure>().having(
                (f) => f.message,
                'message',
                equals(expectedErrorMessage),
              ),
            ),
          );
        },
      );
    }

    test(
      'UserRole.coach succeeds for team registration and autonomous creation',
      () async {
        final createdInTournament = await useCase.registerOrUpdateTeam(
          team: testTeam,
          tournament: sampleTournament,
          actorRole: UserRole.coach,
        );
        expect(createdInTournament.name, equals('Club Atlético Viña'));
        expect(createdInTournament.tournamentId, equals(sampleTournament.id));

        final createdAutonomous = await useCase.registerOrUpdateTeam(
          team: TournamentTeam(
            id: 'team-auto-1',
            name: 'Club Autónomo',
            shortCode: 'AUT',
          ),
          tournament: null,
          actorRole: UserRole.coach,
        );
        expect(createdAutonomous.name, equals('Club Autónomo'));
        expect(createdAutonomous.tournamentId, equals(''));
      },
    );
  });
}
