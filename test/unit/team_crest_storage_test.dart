import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/infrastructure/storage/supabase_document_storage_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  group('HU 27.3 crestUrl entity serialization', () {
    test('TournamentTeam and TeamDirectoryItem preserve crestUrl in JSON', () {
      final team = TournamentTeam(
        id: 'team-crest-1',
        name: 'Real Madrid FC',
        shortCode: 'RM',
        crestUrl: 'https://example.com/crest.png',
      );
      expect(TournamentTeam.fromJson(team.toJson()).crestUrl, team.crestUrl);

      final item = TeamDirectoryItem(
        id: 'team-crest-1',
        name: 'Real Madrid FC',
        shortCode: 'RM',
        crestUrl: 'https://example.com/crest.png',
        updatedAt: DateTime(2026, 11, 26),
      );
      expect(TeamDirectoryItem.fromJson(item.toJson()), equals(item));
    });
  });

  group('uploadTeamCrest validation (format and max size 5 MB)', () {
    late Directory tempDir;
    late SupabaseDocumentStorageRepository repository;
    late _MockConnectivityRepository connectivity;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('crest_storage_test_');
      connectivity = _MockConnectivityRepository();
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => NetworkConnectionStatus.connected);
      repository = SupabaseDocumentStorageRepository(
        client: _MockSupabaseClient(),
        connectivity: connectivity,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('rejects unsupported file extension with DocumentUploadFailure', () async {
      final gifFile = File('${tempDir.path}/crest.gif')
        ..writeAsBytesSync([1, 2, 3]);

      await expectLater(
        repository.uploadTeamCrest(
          userId: 'u1',
          teamId: 't1',
          localPath: gifFile.path,
        ),
        throwsA(isA<DocumentUploadFailure>()),
      );
    });

    test('rejects image exceeding 5 MB with DocumentUploadFailure', () async {
      final largePng = File('${tempDir.path}/huge.png')
        ..writeAsBytesSync(
          List<int>.filled(
            SupabaseDocumentStorageRepository.maxTeamCrestBytes + 1,
            0,
          ),
        );

      await expectLater(
        repository.uploadTeamCrest(
          userId: 'u1',
          teamId: 't1',
          localPath: largePng.path,
        ),
        throwsA(isA<DocumentUploadFailure>()),
      );
    });

    test('throws OfflineAuthOperationFailure when disconnected on valid file', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => NetworkConnectionStatus.disconnected);
      final validJpg = File('${tempDir.path}/crest.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

      await expectLater(
        repository.uploadTeamCrest(
          userId: 'u1',
          teamId: 't1',
          localPath: validJpg.path,
        ),
        throwsA(isA<OfflineAuthOperationFailure>()),
      );
    });
  });
}
