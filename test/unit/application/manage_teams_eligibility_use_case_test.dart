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
    final index = _teams.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      _teams[index] = team;
    } else {
      _teams.add(team);
    }
    return team;
  }
}

void main() {
  late _FakeTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;
  late ChampionshipTournament openTournament;
  late ChampionshipTournament closedTournament;

  setUp(() {
    repository = _FakeTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);

    openTournament = ChampionshipTournament(
      id: 'tour-open',
      name: 'Liga de Apertura 2026',
      category: 'Libre',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 12, 1),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(
        minPlayersPerTeam: 7,
        maxPlayersPerTeam: 18,
      ),
      updatedAt: DateTime(2026, 4, 1),
    );

    closedTournament = openTournament.copyWith(
      id: 'tour-closed',
      status: TournamentStatus.inProgress,
    );
  });

  group('ManageTeamsEligibilityUseCase - Team Registration', () {
    test('organizer and coach can register a valid team', () async {
      final team1 = TournamentTeam(
        id: 'team-1',
        tournamentId: openTournament.id,
        name: 'Atlético Norte FC',
        shortCode: 'atn',
      );

      final saved = await useCase.registerOrUpdateTeam(
        team: team1,
        tournament: openTournament,
        actorRole: UserRole.coach,
      );

      expect(saved.name, equals('Atlético Norte FC'));
      expect(saved.shortCode, equals('ATN'));
    });

    test(
      'unauthorized roles are rejected with UnauthorizedRoleFailure',
      () async {
        final team = TournamentTeam(
          id: 'team-1',
          tournamentId: openTournament.id,
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
        );

        expect(
          () => useCase.registerOrUpdateTeam(
            team: team,
            tournament: openTournament,
            actorRole: UserRole.fan,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );

        expect(
          () => useCase.registerOrUpdateTeam(
            team: team,
            tournament: openTournament,
            actorRole: UserRole.player,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );

        expect(
          () => useCase.registerOrUpdateTeam(
            team: team,
            tournament: openTournament,
            actorRole: UserRole.referee,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'rejects team registration when tournament is not in openRegistration',
      () async {
        final team = TournamentTeam(
          id: 'team-1',
          tournamentId: closedTournament.id,
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
        );

        expect(
          () => useCase.registerOrUpdateTeam(
            team: team,
            tournament: closedTournament,
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
      },
    );

    test('rejects invalid team name or shortCode', () async {
      final shortNameTeam = TournamentTeam(
        id: 'team-1',
        tournamentId: openTournament.id,
        name: 'AB',
        shortCode: 'ATN',
      );

      expect(
        () => useCase.registerOrUpdateTeam(
          team: shortNameTeam,
          tournament: openTournament,
          actorRole: UserRole.organizer,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.invalidTeamName,
          ),
        ),
      );

      final invalidCodeTeam = TournamentTeam(
        id: 'team-2',
        tournamentId: openTournament.id,
        name: 'Atlético Norte FC',
        shortCode: 'TOOLONG',
      );

      expect(
        () => useCase.registerOrUpdateTeam(
          team: invalidCodeTeam,
          tournament: openTournament,
          actorRole: UserRole.organizer,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.invalidShortCode,
          ),
        ),
      );
    });

    test(
      'rejects duplicate team name within the same tournament (case/trim insensitive)',
      () async {
        final team1 = TournamentTeam(
          id: 'team-1',
          tournamentId: openTournament.id,
          name: 'Real Sabana Club',
          shortCode: 'RSC',
        );

        await useCase.registerOrUpdateTeam(
          team: team1,
          tournament: openTournament,
          actorRole: UserRole.organizer,
        );

        final duplicateTeam = TournamentTeam(
          id: 'team-2',
          tournamentId: openTournament.id,
          name: '  real sabana club  ',
          shortCode: 'RS2',
        );

        expect(
          () => useCase.registerOrUpdateTeam(
            team: duplicateTeam,
            tournament: openTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            isA<TeamEligibilityValidationFailure>().having(
              (f) => f.code,
              'code',
              TeamEligibilityErrorCode.duplicateTeamNameInTournament,
            ),
          ),
        );

        // Same name in a DIFFERENT tournament is allowed
        final otherTournament = openTournament.copyWith(id: 'tour-other');
        final teamInOtherTournament = TournamentTeam(
          id: 'team-3',
          tournamentId: otherTournament.id,
          name: 'Real Sabana Club',
          shortCode: 'RSC',
        );

        final savedOther = await useCase.registerOrUpdateTeam(
          team: teamInOtherTournament,
          tournament: otherTournament,
          actorRole: UserRole.organizer,
        );

        expect(savedOther.tournamentId, equals('tour-other'));
      },
    );
  });

  group('ManageTeamsEligibilityUseCase - Player Enrollment & Uniqueness', () {
    late TournamentTeam testTeam;

    setUp(() async {
      testTeam = await useCase.registerOrUpdateTeam(
        team: TournamentTeam(
          id: 'team-test',
          tournamentId: openTournament.id,
          name: 'Deportivo ViFutbol',
          shortCode: 'DVF',
        ),
        tournament: openTournament,
        actorRole: UserRole.organizer,
      );
    });

    test('validates player name, documentId, and shirtNumber range', () async {
      const invalidNamePlayer = RegisteredPlayer(
        id: 'p1',
        fullName: 'Al',
        documentId: '10203040',
        shirtNumber: 10,
        position: PlayerPosition.forward,
      );

      expect(
        () => useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: invalidNamePlayer,
          tournament: openTournament,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.invalidPlayerName,
          ),
        ),
      );

      const invalidDocPlayer = RegisteredPlayer(
        id: 'p2',
        fullName: 'Carlos Gómez',
        documentId: '123',
        shirtNumber: 10,
        position: PlayerPosition.forward,
      );

      expect(
        () => useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: invalidDocPlayer,
          tournament: openTournament,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.invalidDocumentId,
          ),
        ),
      );

      const invalidShirtPlayer = RegisteredPlayer(
        id: 'p3',
        fullName: 'Carlos Gómez',
        documentId: '10203040',
        shirtNumber: 100,
        position: PlayerPosition.forward,
      );

      expect(
        () => useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: invalidShirtPlayer,
          tournament: openTournament,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.invalidShirtNumber,
          ),
        ),
      );
    });

    test(
      'enforces duplicate shirt number rejection with exact Gherkin message',
      () async {
        const player1 = RegisteredPlayer(
          id: 'p1',
          fullName: 'Carlos Gómez',
          documentId: '10203040',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
        );

        await useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: player1,
          tournament: openTournament,
          actorRole: UserRole.coach,
        );

        const player2 = RegisteredPlayer(
          id: 'p2',
          fullName: 'Juan Pérez',
          documentId: '50607080',
          shirtNumber: 10,
          position: PlayerPosition.forward,
        );

        expect(
          () => useCase.enrollOrUpdatePlayer(
            teamId: testTeam.id,
            player: player2,
            tournament: openTournament,
            actorRole: UserRole.coach,
          ),
          throwsA(
            isA<TeamEligibilityValidationFailure>()
                .having(
                  (f) => f.code,
                  'code',
                  TeamEligibilityErrorCode.duplicateShirtNumberInTeam,
                )
                .having(
                  (f) => f.message,
                  'message',
                  'El número de camiseta 10 ya está en uso en este equipo.',
                ),
          ),
        );
      },
    );

    test(
      'enforces player document exclusivity per tournament with exact Gherkin message',
      () async {
        final teamB = await useCase.registerOrUpdateTeam(
          team: TournamentTeam(
            id: 'team-b',
            tournamentId: openTournament.id,
            name: 'Atlético Norte FC',
            shortCode: 'ATN',
          ),
          tournament: openTournament,
          actorRole: UserRole.organizer,
        );

        const playerTeamA = RegisteredPlayer(
          id: 'p1',
          fullName: 'Carlos Gómez',
          documentId: '10203040',
          shirtNumber: 7,
          position: PlayerPosition.forward,
        );

        await useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: playerTeamA,
          tournament: openTournament,
          actorRole: UserRole.coach,
        );

        const playerTeamB = RegisteredPlayer(
          id: 'p2',
          fullName: 'Carlos Andrés Gómez',
          documentId: '  10203040  ',
          shirtNumber: 9,
          position: PlayerPosition.forward,
        );

        expect(
          () => useCase.enrollOrUpdatePlayer(
            teamId: teamB.id,
            player: playerTeamB,
            tournament: openTournament,
            actorRole: UserRole.coach,
          ),
          throwsA(
            isA<TeamEligibilityValidationFailure>()
                .having(
                  (f) => f.code,
                  'code',
                  TeamEligibilityErrorCode.playerAlreadyRegisteredInTournament,
                )
                .having(
                  (f) => f.message,
                  'message',
                  'Este jugador ya se encuentra inscrito en otro equipo de este campeonato.',
                ),
          ),
        );
      },
    );

    test(
      'allows the same player document in a DIFFERENT championship',
      () async {
        const playerTeamA = RegisteredPlayer(
          id: 'p1',
          fullName: 'Carlos Gómez',
          documentId: '10203040',
          shirtNumber: 7,
          position: PlayerPosition.forward,
        );

        await useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: playerTeamA,
          tournament: openTournament,
          actorRole: UserRole.coach,
        );

        final otherTournament = openTournament.copyWith(id: 'tour-other');
        final teamInOtherTournament = await useCase.registerOrUpdateTeam(
          team: TournamentTeam(
            id: 'team-other',
            tournamentId: otherTournament.id,
            name: 'Deportivo ViFutbol 2',
            shortCode: 'DV2',
          ),
          tournament: otherTournament,
          actorRole: UserRole.organizer,
        );

        const playerInOtherTournament = RegisteredPlayer(
          id: 'p2',
          fullName: 'Carlos Gómez',
          documentId: '10203040',
          shirtNumber: 7,
          position: PlayerPosition.forward,
        );

        final updatedOther = await useCase.enrollOrUpdatePlayer(
          teamId: teamInOtherTournament.id,
          player: playerInOtherTournament,
          tournament: otherTournament,
          actorRole: UserRole.coach,
        );

        expect(updatedOther.players.length, equals(1));
      },
    );

    test('rejects adding player beyond maxPlayersPerTeam', () async {
      final smallSquadTournament = openTournament.copyWith(
        rules: const TournamentRulesConfig(
          minPlayersPerTeam: 2,
          maxPlayersPerTeam: 2,
        ),
      );

      await useCase.enrollOrUpdatePlayer(
        teamId: testTeam.id,
        player: const RegisteredPlayer(
          id: 'p1',
          fullName: 'Player 1',
          documentId: '10000001',
          shirtNumber: 1,
          position: PlayerPosition.goalkeeper,
        ),
        tournament: smallSquadTournament,
        actorRole: UserRole.coach,
      );

      await useCase.enrollOrUpdatePlayer(
        teamId: testTeam.id,
        player: const RegisteredPlayer(
          id: 'p2',
          fullName: 'Player 2',
          documentId: '10000002',
          shirtNumber: 2,
          position: PlayerPosition.defender,
        ),
        tournament: smallSquadTournament,
        actorRole: UserRole.coach,
      );

      expect(
        () => useCase.enrollOrUpdatePlayer(
          teamId: testTeam.id,
          player: const RegisteredPlayer(
            id: 'p3',
            fullName: 'Player 3',
            documentId: '10000003',
            shirtNumber: 3,
            position: PlayerPosition.midfielder,
          ),
          tournament: smallSquadTournament,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.maxPlayersQuotaReached,
          ),
        ),
      );
    });
  });

  group(
    'ManageTeamsEligibilityUseCase - Quota Evaluation & Eligibility Approval',
    () {
      late TournamentTeam smallTeam;

      setUp(() async {
        smallTeam = await useCase.registerOrUpdateTeam(
          team: TournamentTeam(
            id: 'team-quota',
            tournamentId: openTournament.id,
            name: 'Real Sabana Club',
            shortCode: 'RSC',
          ),
          tournament: openTournament,
          actorRole: UserRole.organizer,
        );
      });

      test(
        'transitions from pendingQuota to readyForApproval when reaching minPlayersPerTeam',
        () async {
          expect(
            smallTeam.eligibilityStatus,
            equals(TeamEligibilityStatus.pendingQuota),
          );

          TournamentTeam current = smallTeam;
          for (int i = 1; i <= 6; i++) {
            current = await useCase.enrollOrUpdatePlayer(
              teamId: current.id,
              player: RegisteredPlayer(
                id: 'p-$i',
                fullName: 'Player $i',
                documentId: '1000000$i',
                shirtNumber: i,
                position: PlayerPosition.defender,
              ),
              tournament: openTournament,
              actorRole: UserRole.coach,
            );
            expect(
              current.eligibilityStatus,
              equals(TeamEligibilityStatus.pendingQuota),
            );
          }

          // 7th player satisfies minPlayersPerTeam (7)
          current = await useCase.enrollOrUpdatePlayer(
            teamId: current.id,
            player: const RegisteredPlayer(
              id: 'p-7',
              fullName: 'Player 7',
              documentId: '10000007',
              shirtNumber: 7,
              position: PlayerPosition.forward,
            ),
            tournament: openTournament,
            actorRole: UserRole.coach,
          );

          expect(
            current.eligibilityStatus,
            equals(TeamEligibilityStatus.readyForApproval),
          );
        },
      );

      test(
        'coach cannot approve team eligibility (UnauthorizedRoleFailure)',
        () async {
          expect(
            () => useCase.approveTeamEligibility(
              teamId: smallTeam.id,
              tournament: openTournament,
              actorRole: UserRole.coach,
            ),
            throwsA(isA<UnauthorizedRoleFailure>()),
          );
        },
      );

      test(
        'organizer cannot approve team when below minPlayersPerTeam',
        () async {
          expect(
            () => useCase.approveTeamEligibility(
              teamId: smallTeam.id,
              tournament: openTournament,
              actorRole: UserRole.organizer,
            ),
            throwsA(
              isA<TeamEligibilityValidationFailure>().having(
                (f) => f.code,
                'code',
                TeamEligibilityErrorCode.insufficientPlayersForApproval,
              ),
            ),
          );
        },
      );

      test(
        'organizer approval marks team eligible and all players isEligible = true',
        () async {
          TournamentTeam current = smallTeam;
          for (int i = 1; i <= 7; i++) {
            current = await useCase.enrollOrUpdatePlayer(
              teamId: current.id,
              player: RegisteredPlayer(
                id: 'p-$i',
                fullName: 'Player $i',
                documentId: '1000000$i',
                shirtNumber: i,
                position: PlayerPosition.defender,
              ),
              tournament: openTournament,
              actorRole: UserRole.coach,
            );
          }

          final approved = await useCase.approveTeamEligibility(
            teamId: current.id,
            tournament: openTournament,
            actorRole: UserRole.organizer,
          );

          expect(
            approved.eligibilityStatus,
            equals(TeamEligibilityStatus.eligible),
          );
          expect(approved.players.every((p) => p.isEligible), isTrue);
        },
      );

      test(
        'removing player below minimum quota reverts team to pendingQuota and isEligible = false',
        () async {
          TournamentTeam current = smallTeam;
          for (int i = 1; i <= 7; i++) {
            current = await useCase.enrollOrUpdatePlayer(
              teamId: current.id,
              player: RegisteredPlayer(
                id: 'p-$i',
                fullName: 'Player $i',
                documentId: '1000000$i',
                shirtNumber: i,
                position: PlayerPosition.defender,
              ),
              tournament: openTournament,
              actorRole: UserRole.coach,
            );
          }

          final approved = await useCase.approveTeamEligibility(
            teamId: current.id,
            tournament: openTournament,
            actorRole: UserRole.organizer,
          );
          expect(
            approved.eligibilityStatus,
            equals(TeamEligibilityStatus.eligible),
          );

          final reverted = await useCase.removePlayer(
            teamId: approved.id,
            playerId: 'p-7',
            tournament: openTournament,
            actorRole: UserRole.coach,
          );

          expect(reverted.players.length, equals(6));
          expect(
            reverted.eligibilityStatus,
            equals(TeamEligibilityStatus.pendingQuota),
          );
          expect(reverted.players.every((p) => !p.isEligible), isTrue);
        },
      );
    },
  );
}
