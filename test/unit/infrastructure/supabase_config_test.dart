import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';

void main() {
  group('SupabaseConfig Value Object', () {
    test('empty constructor creates unconfigured instance', () {
      const config = SupabaseConfig.empty();

      expect(config.url, isEmpty);
      expect(config.anonKey, isEmpty);
      expect(config.isConfigured, isFalse);
    });

    test(
      'isConfigured is true only when both url and anonKey are non-empty',
      () {
        const valid = SupabaseConfig(
          url: 'https://supabase.artbusinesstechnology.com',
          anonKey: 'sample-anon-key',
        );
        expect(valid.isConfigured, isTrue);

        const missingKey = SupabaseConfig(
          url: 'https://supabase.artbusinesstechnology.com',
          anonKey: '',
        );
        expect(missingKey.isConfigured, isFalse);

        const missingUrl = SupabaseConfig(url: '', anonKey: 'sample-anon-key');
        expect(missingUrl.isConfigured, isFalse);
      },
    );

    test('redacts anonKey in toSafeDiagnosticMap and toString', () {
      const config = SupabaseConfig(
        url: 'https://supabase.artbusinesstechnology.com',
        anonKey: 'ultra-secret-anon-key',
      );

      final diagnostic = config.toSafeDiagnosticMap();
      expect(diagnostic['url'], 'https://supabase.artbusinesstechnology.com');
      expect(diagnostic['anonKey'], '[REDACTED]');
      expect(diagnostic['isConfigured'], isTrue);

      final str = config.toString();
      expect(str.contains('ultra-secret-anon-key'), isFalse);
      expect(str.contains('[REDACTED]'), isTrue);
    });

    test('shows [EMPTY] for anonKey in toSafeDiagnosticMap when empty', () {
      const config = SupabaseConfig.empty();
      final diagnostic = config.toSafeDiagnosticMap();

      expect(diagnostic['anonKey'], '[EMPTY]');
      expect(diagnostic['isConfigured'], isFalse);
    });
  });

  group('EnvironmentConfig Supabase Integration & Isolation', () {
    test('development environment defaults to self-hosted dev URL', () {
      final devConfig = EnvironmentConfig.development();

      expect(
        devConfig.supabase.url,
        'https://supabase.artbusinesstechnology.com',
      );
      // In local testing without --dart-define, anonKey is empty
      expect(devConfig.supabase.isConfigured, isFalse);
    });

    test(
      'development environment accepts explicit configured SupabaseConfig',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'valid-dev-key',
          ),
        );

        expect(devConfig.supabase.isConfigured, isTrue);
        expect(devConfig.supabase.anonKey, 'valid-dev-key');
      },
    );

    test('production environment rejects development Supabase URLs', () {
      expect(
        () => EnvironmentConfig.production(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'prod-key',
          ),
        ),
        throwsA(isA<EnvironmentValidationFailure>()),
      );

      expect(
        () => EnvironmentConfig.production(
          supabase: const SupabaseConfig(
            url: 'https://dev-supabase.example.com',
            anonKey: 'prod-key',
          ),
        ),
        throwsA(isA<EnvironmentValidationFailure>()),
      );
    });

    test('production environment accepts valid Supabase Cloud URL', () {
      final prodConfig = EnvironmentConfig.production(
        supabase: const SupabaseConfig(
          url: 'https://xyzproject.supabase.co',
          anonKey: 'valid-prod-key',
        ),
      );

      expect(prodConfig.supabase.isConfigured, isTrue);
      expect(prodConfig.supabase.url, 'https://xyzproject.supabase.co');
      expect(prodConfig.supabase.anonKey, 'valid-prod-key');
    });

    test('rejects malformed Supabase URLs', () {
      expect(
        () => EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'not-a-valid-url',
            anonKey: 'key',
          ),
        ),
        throwsA(isA<EnvironmentValidationFailure>()),
      );
    });

    test('toSafeDiagnosticMap includes redacted Supabase information', () {
      final devConfig = EnvironmentConfig.development(
        supabase: const SupabaseConfig(
          url: 'https://supabase.artbusinesstechnology.com',
          anonKey: 'sensitive-anon-key',
        ),
      );

      final safeMap = devConfig.toSafeDiagnosticMap();
      expect(safeMap.containsKey('supabase'), isTrue);

      final supabaseMap = safeMap['supabase'] as Map<String, dynamic>;
      expect(supabaseMap['url'], 'https://supabase.artbusinesstechnology.com');
      expect(supabaseMap['anonKey'], '[REDACTED]');
      expect(supabaseMap['isConfigured'], isTrue);
    });
  });

  group('dotenv resolution in EnvironmentConfig', () {
    tearDown(() {
      dotenv.clean();
    });

    test('resolves Supabase DEV credentials from dotenv', () {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://supabase.artbusinesstechnology.com\nSUPABASE_ANON_KEY=test-oracle-anon-key\n',
      );

      final devConfig = EnvironmentConfig.development();
      expect(
        devConfig.supabase.url,
        'https://supabase.artbusinesstechnology.com',
      );
      expect(devConfig.supabase.anonKey, 'test-oracle-anon-key');
      expect(devConfig.supabase.isConfigured, isTrue);
    });

    test('resolves Supabase PROD credentials from dotenv', () {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://prod-project.supabase.co\nSUPABASE_ANON_KEY=test-prod-cloud-key\n',
      );

      final prodConfig = EnvironmentConfig.production();
      expect(prodConfig.supabase.url, 'https://prod-project.supabase.co');
      expect(prodConfig.supabase.anonKey, 'test-prod-cloud-key');
      expect(prodConfig.supabase.isConfigured, isTrue);
    });
  });
}
