import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vifutbol/app_bootstrap.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('vifutbol_bootstrap_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    try {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Supabase Bootstrap Resilience & Offline Continuity (US3)', () {
    test(
      'unconfigured dev environment boots in <500ms with pure local Hive continuity',
      () async {
        final stopwatch = Stopwatch()..start();

        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig.empty(),
        );

        final container = await bootstrapApp(devConfig, appRunner: (_) {});
        addTearDown(container.dispose);

        stopwatch.stop();

        // Must boot well under 500ms constraint
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: 'Bootstrap took too long: ${stopwatch.elapsedMilliseconds}ms',
        );

        // Supabase client should be null (offline/local fallback)
        expect(container.read(supabaseClientProvider), isNull);

        // Local storage should be functional
        final storage = container.read(localStorageRepositoryProvider);
        expect(storage, isNotNull);

        // Verify storage operations succeed locally
        await storage.writeString('resilience_key', 'resilience_value');
        final value = await storage.readString('resilience_key');
        expect(value, 'resilience_value');
      },
    );

    test(
      'configured environment with unreachable host boots in <500ms without blocking on network',
      () async {
        final stopwatch = Stopwatch()..start();

        final unreachableConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url:
                'https://192.0.2.1:54321', // Unreachable dummy RFC 5737 TEST-NET IP
            anonKey: 'dummy-anon-key',
          ),
        );

        final container = await bootstrapApp(
          unreachableConfig,
          appRunner: (_) {},
        );
        addTearDown(container.dispose);

        stopwatch.stop();

        // Health check runs in background; initial bootstrap must not block
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason:
              'Bootstrap blocked on network: ${stopwatch.elapsedMilliseconds}ms',
        );

        // Local storage remains functional despite unreachable backend host
        final storage = container.read(localStorageRepositoryProvider);
        await storage.writeString('offline_check', 'saved_locally');
        expect(await storage.readString('offline_check'), 'saved_locally');
      },
    );
  });
}
