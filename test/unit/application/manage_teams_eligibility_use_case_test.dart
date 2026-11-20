import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';

class _FakeMatchesRepository implements TournamentMatchesRepository {
  List<ChampionshipMatch> matches = [];

  @override
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  ) async {
    return matches.where((m) => m.tournamentId == tournamentId).toList();
  }

  @override
  Future<void> replaceMatchesForTournament(
    String tournamentId,
    List<ChampionshipMatch> updatedMatches,
  ) async {
    matches.removeWhere((m) => m.tournamentId == tournamentId);
    matches.addAll(updatedMatches);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) async {
    _teams.removeWhere((t) => t.tournamentId == tournamentId);
    _teams.addAll(teams);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    _teams.removeWhere((t) => t.id == teamId);
  }

  @override
  Future<List<PlayerDirectoryItem>> loadAllPlayers() async {
    final List<PlayerDirectoryItem> items = [];
    for (final team in _teams) {
      for (final p in team.players) {
        items.add(
          PlayerDirectoryItem(
            player: p,
            teamId: team.id,
            teamName: team.name,
            teamShortCode: team.shortCode,
            tournamentId: team.tournamentId,
            tournamentName: '',
          ),
        );
      }
    }
    items.sort(
      (a, b) => a.player.fullName.toLowerCase().compareTo(
        b.player.fullName.toLowerCase(),
      ),
    );
    return items;
  }

  @override
  Future<List<TeamDirectoryItem>> loadAllTeams() async => [];
}

void main() {
  late _FakeTeamsRepository repository;
  late _FakeMatchesRepository matchesRepository;
  late ManageTeamsEligibilityUseCase useCase;
  late ChampionshipTournament openTournament;
  late ChampionshipTournament closedTournament;

  setUp(() {
    repository = _FakeTeamsRepository();
    matchesRepository = _FakeMatchesRepository();
    useCase = ManageTeamsEligibilityUseCase(repository, matchesRepository);

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
    test('coach can register a valid team', () async {
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

        expect(
          () => useCase.registerOrUpdateTeam(
            team: team,
            tournament: openTournament,
            actorRole: UserRole.organizer,
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
            actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
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
            actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
        );

        expect(savedOther.tournamentId, equals('tour-other'));
      },
    );

    test(
      'HU 15.4: enrollTeamInCompetition enforces Organizer role and editable tournament',
      () async {
        final team = TournamentTeam(
          id: 'team-fab-1',
          tournamentId: openTournament.id,
          name: 'Club Atlético Fab',
          shortCode: 'CAF',
          groupName: 'Grupo A',
        );

        // Non-organizer (fan) rejected
        expect(
          () => useCase.enrollTeamInCompetition(
            team: team,
            tournament: openTournament,
            actorRole: UserRole.fan,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );

        // Finished tournament rejected
        final finishedTournament = openTournament.copyWith(
          status: TournamentStatus.finished,
        );
        expect(
          () => useCase.enrollTeamInCompetition(
            team: team,
            tournament: finishedTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(isA<TeamEligibilityValidationFailure>()),
        );

        // Organizer succeeds on inProgress tournament
        final inProgressTournament = openTournament.copyWith(
          status: TournamentStatus.inProgress,
        );
        final enrolled = await useCase.enrollTeamInCompetition(
          team: team,
          tournament: inProgressTournament,
          actorRole: UserRole.organizer,
        );
        expect(enrolled.name, 'Club Atlético Fab');
        expect(enrolled.shortCode, 'CAF');
        expect(enrolled.groupName, 'Grupo A');

        // Duplicate name rejected in same tournament
        expect(
          () => useCase.enrollTeamInCompetition(
            team: team.copyWith(id: 'team-fab-2'),
            tournament: inProgressTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(isA<TeamEligibilityValidationFailure>()),
        );
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
        actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
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
          actorRole: UserRole.coach,
        );
      });

      test(
        'keeps pendingVerification when enrolling players before organizer approval',
        () async {
          expect(
            smallTeam.eligibilityStatus,
            equals(TeamEligibilityStatus.pendingVerification),
          );

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
            expect(
              current.eligibilityStatus,
              equals(TeamEligibilityStatus.pendingVerification),
            );
          }
        },
      );

      test(
        'fan cannot approve team eligibility (UnauthorizedRoleFailure)',
        () async {
          expect(
            () => useCase.approveTeamEligibility(
              teamId: smallTeam.id,
              tournament: openTournament,
              actorRole: UserRole.fan,
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
          for (int i = 1; i <= 11; i++) {
            current = await useCase.enrollOrUpdatePlayer(
              teamId: current.id,
              player: RegisteredPlayer(
                id: 'p-$i',
                fullName: 'Player $i',
                documentId: '100000${i.toString().padLeft(2, '0')}',
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
        'removing player below minimum quota reverts team to pendingVerification and isEligible = false',
        () async {
          final strictTournament = openTournament.copyWith(
            rules: const TournamentRulesConfig(minPlayersPerTeam: 11),
          );
          TournamentTeam current = smallTeam;
          for (int i = 1; i <= 11; i++) {
            current = await useCase.enrollOrUpdatePlayer(
              teamId: current.id,
              player: RegisteredPlayer(
                id: 'p-$i',
                fullName: 'Player $i',
                documentId: '100000${i.toString().padLeft(2, '0')}',
                shirtNumber: i,
                position: PlayerPosition.defender,
              ),
              tournament: strictTournament,
              actorRole: UserRole.coach,
            );
          }

          final approved = await useCase.approveTeamEligibility(
            teamId: current.id,
            tournament: strictTournament,
            actorRole: UserRole.organizer,
          );
          expect(
            approved.eligibilityStatus,
            equals(TeamEligibilityStatus.eligible),
          );

          final reverted = await useCase.removePlayer(
            teamId: approved.id,
            playerId: 'p-11',
            tournament: strictTournament,
            actorRole: UserRole.coach,
          );

          expect(reverted.players.length, equals(10));
          expect(
            reverted.eligibilityStatus,
            equals(TeamEligibilityStatus.pendingVerification),
          );
          expect(reverted.players.every((p) => !p.isEligible), isTrue);
        },
      );
    },
  );

  group('US3: Team Group Relocation and Competition Removal', () {
    test(
      'moveTeamToGroup moves team to another group when Organizer',
      () async {
        final team = await repository.saveTeam(
          TournamentTeam(
            id: 'team-mv',
            tournamentId: openTournament.id,
            name: 'Deportivo Relocalizado',
            shortCode: 'DREL',
            groupName: 'Grupo A',
          ),
        );

        final updated = await useCase.moveTeamToGroup(
          teamId: team.id,
          groupName: 'Grupo B',
          tournament: openTournament,
          actorRole: UserRole.organizer,
        );

        expect(updated.groupName, equals('Grupo B'));
        final inRepo = (await repository.loadTeams()).firstWhere(
          (t) => t.id == team.id,
        );
        expect(inRepo.groupName, equals('Grupo B'));
      },
    );

    test('moveTeamToGroup rejects non-organizer roles', () async {
      expect(
        () => useCase.moveTeamToGroup(
          teamId: 'team-x',
          groupName: 'Grupo B',
          tournament: openTournament,
          actorRole: UserRole.coach,
        ),
        throwsA(isA<UnauthorizedRoleFailure>()),
      );
    });

    test('moveTeamToGroup rejects finished tournament', () async {
      expect(
        () => useCase.moveTeamToGroup(
          teamId: 'team-x',
          groupName: 'Grupo B',
          tournament: closedTournament,
          actorRole: UserRole.organizer,
        ),
        throwsA(isA<TeamEligibilityValidationFailure>()),
      );
    });

    test(
      'removeTeamFromCompetition deletes team and cleans pending matches',
      () async {
        final team = await repository.saveTeam(
          TournamentTeam(
            id: 'team-rem',
            tournamentId: openTournament.id,
            name: 'Equipo Por Borrar',
            shortCode: 'EPB',
          ),
        );

        matchesRepository.matches = [
          ChampionshipMatch(
            id: 'm-pending',
            tournamentId: openTournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: team.id,
            awayTeamId: 'team-other',
            status: MatchStatus.scheduled,
          ),
          ChampionshipMatch(
            id: 'm-other',
            tournamentId: openTournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
            status: MatchStatus.scheduled,
          ),
        ];

        await useCase.removeTeamFromCompetition(
          teamId: team.id,
          tournament: openTournament,
          actorRole: UserRole.organizer,
        );

        final teams = await repository.loadTeams();
        expect(teams.any((t) => t.id == team.id), isFalse);
        expect(matchesRepository.matches.length, equals(1));
        expect(matchesRepository.matches.first.id, equals('m-other'));
      },
    );

    test(
      'removeTeamFromCompetition blocks removal if team has completed/inProgress matches',
      () async {
        final team = await repository.saveTeam(
          TournamentTeam(
            id: 'team-played',
            tournamentId: openTournament.id,
            name: 'Equipo Con Partidos',
            shortCode: 'ECP',
          ),
        );

        matchesRepository.matches = [
          ChampionshipMatch(
            id: 'm-comp',
            tournamentId: openTournament.id,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: team.id,
            awayTeamId: 'team-other',
            status: MatchStatus.completed,
            homeScore: 2,
            awayScore: 1,
          ),
        ];

        expect(
          () => useCase.removeTeamFromCompetition(
            teamId: team.id,
            tournament: openTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            predicate<TeamEligibilityValidationFailure>(
              (f) => f.code == TeamEligibilityErrorCode.teamHasPlayedMatches,
            ),
          ),
        );
      },
    );
  });
}
