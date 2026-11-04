import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/lineups_tracking_controller.dart';
import 'package:vifutbol/application/use_cases/manage_lineups_tracking_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';

class _InMemoryStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _data.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  late LocalLineupsTrackingRepository repository;
  late ManageLineupsTrackingUseCase useCase;
  late LineupsTrackingController controller;

  final tournament = ChampionshipTournament(
    id: 'tour-1',
    name: 'Torneo Apertura',
    category: 'Libre',
    format: TournamentFormat.league,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 90)),
    rules: const TournamentRulesConfig(
      minPlayersPerTeam: 7,
      yellowCardSuspensionLimit: 3,
    ),
    updatedAt: DateTime.now(),
  );

  final playerList = List.generate(
    10,
    (index) => RegisteredPlayer(
      id: 'p-$index',
      fullName: 'Jugador $index',
      documentId: '1000$index',
      shirtNumber: index + 1,
      position: PlayerPosition.midfielder,
      isEligible: true,
    ),
  );

  final team = TournamentTeam(
    id: 'team-1',
    tournamentId: tournament.id,
    name: 'Atlético Norte FC',
    shortCode: 'ATN',
    eligibilityStatus: TeamEligibilityStatus.eligible,
    players: playerList,
  );

  setUp(() {
    final storage = _InMemoryStorage();
    repository = LocalLineupsTrackingRepository(
      storage: storage,
      config: EnvironmentConfig.development(),
    );
    useCase = ManageLineupsTrackingUseCase(repository);
    controller = LineupsTrackingController(
      repository: repository,
      manageLineupsTrackingUseCase: useCase,
    );
  });

  group('ManageLineupsTrackingUseCase & Controller Tests', () {
    test(
      'confirms convocation when required starters and captain are valid',
      () async {
        await controller.loadForTeam(tournamentId: tournament.id, team: team);

        final starterIds = ['p-0', 'p-1', 'p-2', 'p-3', 'p-4', 'p-5', 'p-6'];
        final substituteIds = ['p-7', 'p-8'];

        for (final id in starterIds) {
          await controller.setPlayerRole(
            activeRole: UserRole.coach,
            tournament: tournament,
            team: team,
            playerId: id,
            isStarter: true,
            isSubstitute: false,
          );
        }

        for (final id in substituteIds) {
          await controller.setPlayerRole(
            activeRole: UserRole.coach,
            tournament: tournament,
            team: team,
            playerId: id,
            isStarter: false,
            isSubstitute: true,
          );
        }

        await controller.setCaptain(
          activeRole: UserRole.coach,
          tournament: tournament,
          team: team,
          playerId: 'p-0',
        );

        final confirmed = await controller.confirmConvocation(
          activeRole: UserRole.coach,
          tournament: tournament,
          team: team,
        );

        expect(confirmed.status, equals(ConvocationStatus.confirmed));
        expect(confirmed.confirmedStarterPlayerIds.length, equals(7));
        expect(confirmed.confirmedSubstitutePlayerIds.length, equals(2));
        expect(confirmed.confirmedCaptainPlayerId, equals('p-0'));
        expect(confirmed.isSyncedWithRefereeReport, isTrue);
      },
    );

    test(
      'rejects convocation if starters count does not match requiredStarters',
      () async {
        await controller.loadForTeam(tournamentId: tournament.id, team: team);

        await controller.setPlayerRole(
          activeRole: UserRole.coach,
          tournament: tournament,
          team: team,
          playerId: 'p-0',
          isStarter: true,
          isSubstitute: false,
        );
        await controller.setCaptain(
          activeRole: UserRole.coach,
          tournament: tournament,
          team: team,
          playerId: 'p-0',
        );

        expect(
          () => controller.confirmConvocation(
            activeRole: UserRole.coach,
            tournament: tournament,
            team: team,
          ),
          throwsA(
            isA<LineupConvocationValidationFailure>().having(
              (f) => f.code,
              'code',
              equals(LineupConvocationErrorCode.invalidStartersCount),
            ),
          ),
        );
      },
    );

    test('blocks drafting suspended player', () async {
      await controller.loadForTeam(tournamentId: tournament.id, team: team);

      // Make p-9 suspended
      final suspendedTracking = PlayerInternalTracking(
        playerId: 'p-9',
        teamId: team.id,
        tournamentId: tournament.id,
        pendingSuspensionMatches: 1,
      );
      await controller.updatePlayerMetrics(
        activeRole: UserRole.coach,
        tournament: tournament,
        team: team,
        updatedTracking: suspendedTracking,
      );

      expect(
        () => controller.setPlayerRole(
          activeRole: UserRole.coach,
          tournament: tournament,
          team: team,
          playerId: 'p-9',
          isStarter: true,
          isSubstitute: false,
        ),
        throwsA(
          isA<LineupConvocationValidationFailure>().having(
            (f) => f.code,
            'code',
            equals(LineupConvocationErrorCode.suspendedPlayerSelected),
          ),
        ),
      );
    });
  });
}
