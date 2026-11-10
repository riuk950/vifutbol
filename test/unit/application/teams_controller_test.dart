import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
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
}

void main() {
  late _FakeTeamsRepository repository;
  late ManageTeamsEligibilityUseCase useCase;
  late TeamsController controller;
  late ChampionshipTournament tournament;

  setUp(() {
    repository = _FakeTeamsRepository();
    useCase = ManageTeamsEligibilityUseCase(repository);
    controller = TeamsController(
      teamsRepository: repository,
      manageTeamsEligibilityUseCase: useCase,
    );

    tournament = ChampionshipTournament(
      id: 'tour-1',
      name: 'Liga de Apertura 2026',
      category: 'Libre',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 12, 1),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(
        minPlayersPerTeam: 2,
        maxPlayersPerTeam: 10,
      ),
      updatedAt: DateTime(2026, 4, 1),
    );
  });

  group('TeamsController', () {
    test('registers a team, updates selection, and loads teams', () async {
      final team = TournamentTeam(
        id: 'team-1',
        tournamentId: tournament.id,
        name: 'Atlético Norte FC',
        shortCode: 'ATN',
      );

      final success = await controller.registerOrUpdateTeam(
        team: team,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(success, isTrue);
      expect(controller.state.teams.length, equals(1));
      expect(controller.state.selectedTeamId, equals('team-1'));
      expect(controller.state.selectedTeam?.name, equals('Atlético Norte FC'));
    });

    test('captures lastFailure when team registration fails', () async {
      final invalidTeam = TournamentTeam(
        id: 'team-invalid',
        tournamentId: tournament.id,
        name: 'A',
        shortCode: 'A',
      );

      final success = await controller.registerOrUpdateTeam(
        team: invalidTeam,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(success, isFalse);
      expect(
        controller.state.lastFailure,
        isA<TeamEligibilityValidationFailure>(),
      );
    });

    test(
      'HU 15.4: enrollTeamInCompetition adds team to state and respects single-flight',
      () async {
        final team = TournamentTeam(
          id: 'team-enroll-1',
          tournamentId: tournament.id,
          name: 'Deportivo Enroll',
          shortCode: 'DEN',
          groupName: 'Grupo B',
        );

        final success = await controller.enrollTeamInCompetition(
          team: team,
          tournament: tournament,
          actorRole: UserRole.organizer,
        );

        expect(success, isTrue);
        expect(
          controller.state.teams.any((t) => t.id == 'team-enroll-1'),
          isTrue,
        );
        expect(
          controller.state.teams
              .firstWhere((t) => t.id == 'team-enroll-1')
              .groupName,
          'Grupo B',
        );
      },
    );

    test('enrolls and removes player in team', () async {
      final team = TournamentTeam(
        id: 'team-1',
        tournamentId: tournament.id,
        name: 'Atlético Norte FC',
        shortCode: 'ATN',
      );

      await controller.registerOrUpdateTeam(
        team: team,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      const player = RegisteredPlayer(
        id: 'p1',
        fullName: 'Carlos Gómez',
        documentId: '10203040',
        shirtNumber: 10,
        position: PlayerPosition.midfielder,
      );

      final enrolled = await controller.enrollOrUpdatePlayer(
        teamId: 'team-1',
        player: player,
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      expect(enrolled, isTrue);
      expect(controller.state.selectedTeam?.players.length, equals(1));

      final removed = await controller.removePlayer(
        teamId: 'team-1',
        playerId: 'p1',
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      expect(removed, isTrue);
      expect(controller.state.selectedTeam?.players, isEmpty);
    });

    test('approves team eligibility when minimum quota is satisfied', () async {
      final team = TournamentTeam(
        id: 'team-1',
        tournamentId: tournament.id,
        name: 'Atlético Norte FC',
        shortCode: 'ATN',
      );

      await controller.registerOrUpdateTeam(
        team: team,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      // minPlayersPerTeam is 2
      await controller.enrollOrUpdatePlayer(
        teamId: 'team-1',
        player: const RegisteredPlayer(
          id: 'p1',
          fullName: 'Player 1',
          documentId: '10000001',
          shirtNumber: 1,
          position: PlayerPosition.goalkeeper,
        ),
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      await controller.enrollOrUpdatePlayer(
        teamId: 'team-1',
        player: const RegisteredPlayer(
          id: 'p2',
          fullName: 'Player 2',
          documentId: '10000002',
          shirtNumber: 2,
          position: PlayerPosition.defender,
        ),
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      final approved = await controller.approveTeamEligibility(
        teamId: 'team-1',
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(approved, isTrue);
      expect(
        controller.state.selectedTeam?.eligibilityStatus,
        equals(TeamEligibilityStatus.eligible),
      );
      expect(
        controller.state.selectedTeam?.players.every((p) => p.isEligible),
        isTrue,
      );
    });

    test('selectTeam clears or sets selected ID', () {
      controller.selectTeam('team-custom');
      expect(controller.state.selectedTeamId, equals('team-custom'));

      controller.selectTeam(null);
      expect(controller.state.selectedTeamId, isNull);
    });

    test('moveTeamToGroup updates team group and reloads teams', () async {
      final team = TournamentTeam(
        id: 'team-ctrl-mv',
        tournamentId: tournament.id,
        name: 'Club Movible',
        shortCode: 'CMV',
        groupName: 'Grupo A',
      );
      await repository.saveTeam(team);
      await controller.loadTeams();

      final success = await controller.moveTeamToGroup(
        teamId: team.id,
        groupName: 'Grupo B',
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(success, isTrue);
      final updated = controller.state.teams.firstWhere((t) => t.id == team.id);
      expect(updated.groupName, equals('Grupo B'));
    });

    test('removeTeamFromCompetition deletes team and updates state', () async {
      final team = TournamentTeam(
        id: 'team-ctrl-del',
        tournamentId: tournament.id,
        name: 'Club Eliminable',
        shortCode: 'CEL',
      );
      await repository.saveTeam(team);
      await controller.loadTeams();
      controller.selectTeam(team.id);

      final success = await controller.removeTeamFromCompetition(
        teamId: team.id,
        tournament: tournament,
        actorRole: UserRole.organizer,
      );

      expect(success, isTrue);
      expect(controller.state.teams.any((t) => t.id == team.id), isFalse);
      expect(controller.state.selectedTeamId, isNull);
    });
  });
}
