import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_team_join_requests_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_team_join_requests_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';

class InMemoryLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _storage = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<void> clearNamespace() async => _storage.clear();

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      const LocalStorageStatus(isPersistent: false, storageNamespace: 'test');

  @override
  Future<String?> readString(String key) async => _storage[key];

  @override
  Future<void> writeString(String key, String value) async {
    _storage[key] = value;
  }
}

void main() {
  group('ManageTeamJoinRequestsUseCase & Coach Roster Eligibility Tests (HU 20.1)', () {
    late InMemoryLocalStorageRepository storage;
    late LocalTeamJoinRequestsRepository requestsRepo;
    late LocalTeamsRepository teamsRepo;
    late ManageTeamJoinRequestsUseCase useCase;

    late TournamentTeam testTeam;
    const candidate1 = AvailablePlayerCandidate(
      userAccountId: 'acc-player-1',
      fullName: 'Carlos Bacca',
      documentId: 'CC-100200',
    );
    const candidate2 = AvailablePlayerCandidate(
      userAccountId: 'acc-player-2',
      fullName: 'Luis Díaz',
      documentId: 'CC-300400',
    );

    setUp(() async {
      storage = InMemoryLocalStorageRepository();
      final config = EnvironmentConfig.development();
      requestsRepo = LocalTeamJoinRequestsRepository(storage: storage, config: config);
      teamsRepo = LocalTeamsRepository(storage: storage, config: config);
      useCase = ManageTeamJoinRequestsUseCase(
        repository: requestsRepo,
        teamsRepository: teamsRepo,
      );

      testTeam = TournamentTeam(
        id: 'team-1',
        tournamentId: 'tour-1',
        name: 'Barranquilla FC',
        shortCode: 'BFC',
        coachId: 'coach-1',
        coachName: 'Julio Comesaña',
        players: const [
          RegisteredPlayer(
            id: 'existing-p-1',
            fullName: 'Sebastián Viera',
            documentId: 'CC-999999',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: true,
          ),
        ],
      );

      await teamsRepo.saveTeam(testTeam);

      // Save coach session in local storage for coach identification
      final coachAccount = UserAccount(
        id: 'coach-1',
        email: 'coach@vifutbol.com',
        fullName: 'Julio Comesaña',
        authorizedRoles: const {UserRole.coach},
        activeRole: UserRole.coach,
      );
      final coachSession = AuthSession(
        sessionId: 'sess-coach-1',
        user: coachAccount,
        sessionToken: 'token-coach',
        authenticatedAt: DateTime.now(),
      );
      await storage.writeString('auth_session', jsonEncode(coachSession.toJson()));
    });

    test('Coach sends join request successfully to an available player candidate', () async {
      final request = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate1,
        shirtNumber: 9,
        position: PlayerPosition.forward,
        actorRole: UserRole.coach,
      );

      expect(request.id, isNotEmpty);
      expect(request.teamId, equals('team-1'));
      expect(request.playerAccountId, equals(candidate1.userAccountId));
      expect(request.playerName, equals(candidate1.fullName));
      expect(request.shirtNumber, equals(9));
      expect(request.position, equals(PlayerPosition.forward));
      expect(request.status, equals(TeamJoinRequestStatus.pending));

      // Verify that team roster count has NOT increased yet (request is pending)
      final teams = await teamsRepo.loadTeams();
      expect(teams.first.players.length, equals(1));
    });

    test('Prevents unauthorized roles from sending join requests', () async {
      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate1,
          shirtNumber: 9,
          position: PlayerPosition.forward,
          actorRole: UserRole.player,
        ),
        throwsA(isA<UnauthorizedRoleFailure>()),
      );
    });

    test('Prevents sending request with invalid shirt number (outside 1..99)', () async {
      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate1,
          shirtNumber: 0,
          position: PlayerPosition.forward,
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

      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate1,
          shirtNumber: 100,
          position: PlayerPosition.forward,
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

    test('Prevents sending request with a shirt number already taken in roster', () async {
      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate1,
          shirtNumber: 1, // Taken by Sebastián Viera
          position: PlayerPosition.forward,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.duplicateShirtNumberInTeam,
          ),
        ),
      );
    });

    test('Prevents duplicate pending requests for the same player or same reserved shirt', () async {
      await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate1,
        shirtNumber: 9,
        position: PlayerPosition.forward,
        actorRole: UserRole.coach,
      );

      // Attempt sending another request for candidate1
      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate1,
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.playerAlreadyHasPendingRequest,
          ),
        ),
      );

      // Attempt sending request for candidate2 with already reserved shirt 9
      expect(
        () => useCase.sendJoinRequest(
          team: testTeam,
          candidate: candidate2,
          shirtNumber: 9, // Reserved by candidate1
          position: PlayerPosition.forward,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.shirtNumberAlreadyReserved,
          ),
        ),
      );
    });

    test('Player accepting request adds player to roster and updates count', () async {
      final req = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate1,
        shirtNumber: 9,
        position: PlayerPosition.forward,
        actorRole: UserRole.coach,
      );

      final accepted = await useCase.respondToJoinRequest(
        requestId: req.id,
        accept: true,
        actorRole: UserRole.player,
      );

      expect(accepted.status, equals(TeamJoinRequestStatus.accepted));

      // Team roster in repository must now contain 2 players
      final teams = await teamsRepo.loadTeams();
      final updatedTeam = teams.first;
      expect(updatedTeam.players.length, equals(2));
      expect(updatedTeam.players.any((p) => p.shirtNumber == 9), isTrue);
      expect(updatedTeam.players.any((p) => p.fullName == 'Carlos Bacca'), isTrue);
    });

    test('Player rejecting request frees up shirt number and does not alter roster', () async {
      final req = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate1,
        shirtNumber: 9,
        position: PlayerPosition.forward,
        actorRole: UserRole.coach,
      );

      final rejected = await useCase.respondToJoinRequest(
        requestId: req.id,
        accept: false,
        actorRole: UserRole.player,
      );

      expect(rejected.status, equals(TeamJoinRequestStatus.rejected));

      // Roster count is still 1
      final teams = await teamsRepo.loadTeams();
      expect(teams.first.players.length, equals(1));

      // Shirt 9 is now free to be assigned to candidate 2
      final req2 = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate2,
        shirtNumber: 9,
        position: PlayerPosition.forward,
        actorRole: UserRole.coach,
      );
      expect(req2.status, equals(TeamJoinRequestStatus.pending));
    });

    test('Coach canceling request marks it cancelled and frees up shirt number', () async {
      final req = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate1,
        shirtNumber: 7,
        position: PlayerPosition.midfielder,
        actorRole: UserRole.coach,
      );

      await useCase.cancelJoinRequest(
        requestId: req.id,
        actorRole: UserRole.coach,
      );

      final teamRequests = await useCase.loadRequestsForTeam('team-1');
      final cancelledReq = teamRequests.firstWhere((r) => r.id == req.id);
      expect(cancelledReq.status, equals(TeamJoinRequestStatus.cancelled));

      // Shirt 7 is now free
      final req2 = await useCase.sendJoinRequest(
        team: testTeam,
        candidate: candidate2,
        shirtNumber: 7,
        position: PlayerPosition.midfielder,
        actorRole: UserRole.coach,
      );
      expect(req2.status, equals(TeamJoinRequestStatus.pending));
    });

    test('approveTeamEligibility fails when squad has fewer than 11 players', () async {
      final eligibilityUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

      final tournament = ChampionshipTournament(
        id: 'tour-1',
        name: 'Liga Apertura',
        category: 'Libre',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        format: TournamentFormat.league,
        updatedAt: DateTime.now(),
      );

      // testTeam initially has only 1 player (< 11)
      expect(
        () => eligibilityUseCase.approveTeamEligibility(
          teamId: testTeam.id,
          tournament: tournament,
          actorRole: UserRole.coach,
        ),
        throwsA(
          isA<TeamEligibilityValidationFailure>().having(
            (f) => f.code,
            'code',
            TeamEligibilityErrorCode.insufficientPlayersForApproval,
          ),
        ),
      );
    });

    test('approveTeamEligibility succeeds for UserRole.coach when squad has 11 or more players', () async {
      final eligibilityUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

      final tournament = ChampionshipTournament(
        id: 'tour-1',
        name: 'Liga Apertura',
        category: 'Libre',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        format: TournamentFormat.league,
        updatedAt: DateTime.now(),
      );

      // Create 11 players
      final elevenPlayers = List.generate(
        11,
        (i) => RegisteredPlayer(
          id: 'player-${i + 1}',
          fullName: 'Jugador ${i + 1}',
          documentId: 'CC-00000${i + 1}',
          shirtNumber: i + 1,
          position: PlayerPosition.forward,
          isEligible: false,
        ),
      );

      final readyTeam = testTeam.copyWith(players: elevenPlayers);
      await teamsRepo.saveTeam(readyTeam);

      final approved = await eligibilityUseCase.approveTeamEligibility(
        teamId: readyTeam.id,
        tournament: tournament,
        actorRole: UserRole.coach,
      );

      expect(approved.eligibilityStatus, equals(TeamEligibilityStatus.eligible));
      expect(approved.players.every((p) => p.isEligible), isTrue);
    });

    test('approveTeamEligibility works for standalone club (tournamentId == "") with 11 players', () async {
      final eligibilityUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

      final dummyTournament = ChampionshipTournament(
        id: '',
        name: 'Club Base',
        category: 'Libre',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        format: TournamentFormat.league,
        updatedAt: DateTime.now(),
      );

      final elevenPlayers = List.generate(
        11,
        (i) => RegisteredPlayer(
          id: 'standalone-p-${i + 1}',
          fullName: 'Standalone ${i + 1}',
          documentId: 'CC-99000${i + 1}',
          shirtNumber: i + 1,
          position: PlayerPosition.defender,
          isEligible: false,
        ),
      );

      final standaloneTeam = TournamentTeam(
        id: 'standalone-team-1',
        tournamentId: '',
        name: 'Club Social y Deportivo',
        shortCode: 'CSD',
        coachId: 'coach-1',
        players: elevenPlayers,
      );

      await teamsRepo.saveTeam(standaloneTeam);

      final approved = await eligibilityUseCase.approveTeamEligibility(
        teamId: standaloneTeam.id,
        tournament: dummyTournament,
        actorRole: UserRole.coach,
      );

      expect(approved.eligibilityStatus, equals(TeamEligibilityStatus.eligible));
    });
  });
}
