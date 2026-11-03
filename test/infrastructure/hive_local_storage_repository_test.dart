import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/infrastructure/storage/hive_local_storage_repository.dart';

void main() {
  group('HiveLocalStorageRepository Isolation & Fallback Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vifutbol_hive_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'maintains strict isolation between dev and prod storage namespaces',
      () async {
        final devRepo = HiveLocalStorageRepository(basePath: tempDir.path);
        final prodRepo = HiveLocalStorageRepository(basePath: tempDir.path);

        await devRepo.initialize('vifutbol_dev');
        await prodRepo.initialize('vifutbol_prod');

        await devRepo.writeString('user_token', 'dev_session_token_123');
        await prodRepo.writeString('user_token', 'prod_official_token_789');

        expect(await devRepo.readString('user_token'), 'dev_session_token_123');
        expect(
          await prodRepo.readString('user_token'),
          'prod_official_token_789',
        );

        await devRepo.clearNamespace();
        expect(await devRepo.readString('user_token'), isNull);
        expect(
          await prodRepo.readString('user_token'),
          'prod_official_token_789',
        );
      },
    );

    test(
      'falls back gracefully to in-memory store if directory cannot be opened',
      () async {
        // Pass an invalid path that cannot be created or accessed
        final brokenPath = Platform.isWindows
            ? 'Z:\\invalid\\path'
            : '/dev/null/forbidden';
        final fallbackRepo = HiveLocalStorageRepository(basePath: brokenPath);

        final status = await fallbackRepo.initialize('vifutbol_dev');
        expect(status.isPersistent, isFalse);
        expect(fallbackRepo.isUsingFallbackMemory, isTrue);

        await fallbackRepo.writeString('session_key', 'fallback_data');
        expect(await fallbackRepo.readString('session_key'), 'fallback_data');
      },
    );
  });
}
