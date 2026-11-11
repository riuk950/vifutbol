import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';

class _InMemoryStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

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
  group('LocalLineupsTrackingRepository', () {
    test(
      'returns default zeroed metrics when tracking storage is empty',
      () async {
        final storage = _InMemoryStorage();
        final repo = LocalLineupsTrackingRepository(
          storage: storage,
          config: EnvironmentConfig.development(),
        );

        final roster = [
          const RegisteredPlayer(
            id: 'p-1',
            fullName: 'Wilmar Barrios',
            documentId: '10100008',
            shirtNumber: 6,
            position: PlayerPosition.midfielder,
          ),
          const RegisteredPlayer(
            id: 'p-2',
            fullName: 'Yerry Mina',
            documentId: '10100002',
            shirtNumber: 4,
            position: PlayerPosition.defender,
          ),
        ];

        final trackingList = await repo.loadTrackingForTeam(
          'tournament-1',
          'team-1',
          roster,
        );

        expect(trackingList.length, equals(2));
        expect(
          trackingList.every((t) => t.pendingSuspensionMatches == 0),
          isTrue,
        );
        expect(trackingList.every((t) => t.yellowCards == 0), isTrue);
      },
    );

    test('saves and retrieves convocation', () async {
      final storage = _InMemoryStorage();
      final repo = LocalLineupsTrackingRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );

      final conv = MatchLineupConvocation(
        id: 'conv-test-1',
        tournamentId: 'tour-1',
        teamId: 'team-1',
        starterPlayerIds: const ['p-1'],
        captainPlayerId: 'p-1',
        status: ConvocationStatus.draft,
      );

      await repo.saveConvocation(conv);

      final loaded = await repo.loadConvocationForTeam('tour-1', 'team-1');
      expect(loaded.id, equals('conv-test-1'));
      expect(loaded.starterPlayerIds, equals(['p-1']));
      expect(loaded.captainPlayerId, equals('p-1'));
    });
  });
}
