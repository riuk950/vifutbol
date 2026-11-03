import 'package:vifutbol/domain/failures/app_failure.dart';

/// Runtime execution environment.
enum AppEnvironment { development, production }

/// Immutable configuration and isolation contract for application environments.
class EnvironmentConfig {
  final AppEnvironment environment;
  final String appName;
  final String localStoragePrefix;
  final String apiBaseUrl;
  final String apiAnonKey;
  final bool showEnvironmentBanner;

  const EnvironmentConfig._({
    required this.environment,
    required this.appName,
    required this.localStoragePrefix,
    required this.apiBaseUrl,
    required this.apiAnonKey,
    required this.showEnvironmentBanner,
  });

  /// Factory for development environment.
  factory EnvironmentConfig.development({
    String appName = 'vifutbol DEV',
    String localStoragePrefix = 'vifutbol_dev',
    String apiBaseUrl = 'https://dev-api.vifutbol.com',
    String apiAnonKey = 'dev-anon-key-vifutbol',
  }) {
    _validatePrefix(AppEnvironment.development, localStoragePrefix);
    return EnvironmentConfig._(
      environment: AppEnvironment.development,
      appName: appName,
      localStoragePrefix: localStoragePrefix,
      apiBaseUrl: apiBaseUrl,
      apiAnonKey: apiAnonKey,
      showEnvironmentBanner: true,
    );
  }

  /// Factory for production environment.
  factory EnvironmentConfig.production({
    String appName = 'vifutbol',
    String localStoragePrefix = 'vifutbol_prod',
    String apiBaseUrl = 'https://api.vifutbol.com',
    String apiAnonKey = 'prod-anon-key-vifutbol',
  }) {
    _validatePrefix(AppEnvironment.production, localStoragePrefix);
    return EnvironmentConfig._(
      environment: AppEnvironment.production,
      appName: appName,
      localStoragePrefix: localStoragePrefix,
      apiBaseUrl: apiBaseUrl,
      apiAnonKey: apiAnonKey,
      showEnvironmentBanner: false,
    );
  }

  static void _validatePrefix(AppEnvironment env, String prefix) {
    if (prefix.trim().isEmpty) {
      throw const EnvironmentValidationFailure(
        'localStoragePrefix cannot be empty.',
      );
    }
    if (env == AppEnvironment.development && prefix.contains('prod')) {
      throw const EnvironmentValidationFailure(
        'Development configuration cannot use a production storage namespace.',
      );
    }
    if (env == AppEnvironment.production && prefix.contains('dev')) {
      throw const EnvironmentValidationFailure(
        'Production configuration cannot use a development storage namespace.',
      );
    }
  }

  /// Safe diagnostic representation with credentials redacted (FR-010).
  Map<String, dynamic> toSafeDiagnosticMap() {
    return {
      'environment': environment.name,
      'appName': appName,
      'localStoragePrefix': localStoragePrefix,
      'apiBaseUrl': apiBaseUrl,
      'apiAnonKey': '[REDACTED]',
      'showEnvironmentBanner': showEnvironmentBanner,
    };
  }

  @override
  String toString() {
    return 'EnvironmentConfig(environment: ${environment.name}, appName: $appName, '
        'localStoragePrefix: $localStoragePrefix, apiBaseUrl: $apiBaseUrl, '
        'apiAnonKey: [REDACTED], showEnvironmentBanner: $showEnvironmentBanner)';
  }
}
