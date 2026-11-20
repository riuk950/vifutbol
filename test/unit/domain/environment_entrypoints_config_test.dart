import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

void main() {
  group('DEV and PROD EnvironmentConfig isolation (HU 23.1)', () {
    test(
      'development entrypoint config shows DEV banner and uses isolated dev prefix',
      () {
        final config = EnvironmentConfig.development();
        expect(config.environment, AppEnvironment.development);
        expect(config.showEnvironmentBanner, isTrue);
        expect(config.localStoragePrefix, 'vifutbol_dev');
        expect(config.appName, 'vifutbol DEV');
      },
    );

    test(
      'production entrypoint config hides DEV banner and uses isolated prod prefix',
      () {
        final config = EnvironmentConfig.production();
        expect(config.environment, AppEnvironment.production);
        expect(config.showEnvironmentBanner, isFalse);
        expect(config.localStoragePrefix, 'vifutbol_prod');
        expect(config.appName, 'vifutbol');
      },
    );
  });
}
