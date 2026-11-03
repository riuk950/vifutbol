import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';

void main() {
  group('EnvironmentConfig Isolation & Invariants', () {
    test(
      'creates valid development config with isolated prefix and dev banner visible',
      () {
        final config = EnvironmentConfig.development();

        expect(config.environment, AppEnvironment.development);
        expect(config.localStoragePrefix, 'vifutbol_dev');
        expect(config.showEnvironmentBanner, isTrue);
        expect(config.appName, 'vifutbol DEV');
      },
    );

    test(
      'creates valid production config with isolated prefix and dev banner hidden',
      () {
        final config = EnvironmentConfig.production();

        expect(config.environment, AppEnvironment.production);
        expect(config.localStoragePrefix, 'vifutbol_prod');
        expect(config.showEnvironmentBanner, isFalse);
        expect(config.appName, 'vifutbol');
      },
    );

    test('rejects cross-environment namespace mixing', () {
      expect(
        () =>
            EnvironmentConfig.development(localStoragePrefix: 'vifutbol_prod'),
        throwsA(isA<EnvironmentValidationFailure>()),
      );

      expect(
        () => EnvironmentConfig.production(localStoragePrefix: 'vifutbol_dev'),
        throwsA(isA<EnvironmentValidationFailure>()),
      );

      expect(
        () => EnvironmentConfig.development(localStoragePrefix: '   '),
        throwsA(isA<EnvironmentValidationFailure>()),
      );
    });

    test(
      'redacts credentials and sensitive tokens in toSafeDiagnosticMap and toString (FR-010)',
      () {
        final config = EnvironmentConfig.development(
          apiAnonKey: 'super-sensitive-secret-key-12345',
        );

        final safeMap = config.toSafeDiagnosticMap();
        expect(safeMap['apiAnonKey'], '[REDACTED]');

        final stringRep = config.toString();
        expect(stringRep.contains('super-sensitive-secret-key-12345'), isFalse);
        expect(stringRep.contains('[REDACTED]'), isTrue);
      },
    );
  });
}
