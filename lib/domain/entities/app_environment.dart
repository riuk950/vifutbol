import 'package:vifutbol/domain/failures/app_failure.dart';

/// Runtime execution environment.
enum AppEnvironment { development, production }

/// Immutable configuration value object for Supabase backend connection.
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({required this.url, required this.anonKey});

  /// Unconfigured / local-only empty configuration.
  const SupabaseConfig.empty() : url = '', anonKey = '';

  /// Whether both the URL and anonKey are provided.
  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Safe diagnostic representation with credentials redacted.
  Map<String, dynamic> toSafeDiagnosticMap() {
    return {
      'url': url,
      'anonKey': anonKey.isEmpty ? '[EMPTY]' : '[REDACTED]',
      'isConfigured': isConfigured,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupabaseConfig &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          anonKey == other.anonKey;

  @override
  int get hashCode => url.hashCode ^ anonKey.hashCode;

  @override
  String toString() {
    return 'SupabaseConfig(url: $url, anonKey: ${anonKey.isEmpty ? "[EMPTY]" : "[REDACTED]"}, isConfigured: $isConfigured)';
  }
}

/// Immutable configuration and isolation contract for application environments.
class EnvironmentConfig {
  final AppEnvironment environment;
  final String appName;
  final String localStoragePrefix;
  final String apiBaseUrl;
  final String apiAnonKey;
  final bool showEnvironmentBanner;
  final SupabaseConfig supabase;

  const EnvironmentConfig._({
    required this.environment,
    required this.appName,
    required this.localStoragePrefix,
    required this.apiBaseUrl,
    required this.apiAnonKey,
    required this.showEnvironmentBanner,
    required this.supabase,
  });

  /// Factory for development environment.
  factory EnvironmentConfig.development({
    String appName = 'vifutbol DEV',
    String localStoragePrefix = 'vifutbol_dev',
    String apiBaseUrl = 'https://dev-api.vifutbol.com',
    String apiAnonKey = 'dev-anon-key-vifutbol',
    SupabaseConfig? supabase,
  }) {
    _validatePrefix(AppEnvironment.development, localStoragePrefix);
    final resolvedSupabase =
        supabase ??
        const SupabaseConfig(
          url: String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://supabase.artbusinesstechnology.com',
          ),
          anonKey: String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: '',
          ),
        );
    _validateSupabase(AppEnvironment.development, resolvedSupabase);

    return EnvironmentConfig._(
      environment: AppEnvironment.development,
      appName: appName,
      localStoragePrefix: localStoragePrefix,
      apiBaseUrl: apiBaseUrl,
      apiAnonKey: apiAnonKey,
      showEnvironmentBanner: true,
      supabase: resolvedSupabase,
    );
  }

  /// Factory for production environment.
  factory EnvironmentConfig.production({
    String appName = 'vifutbol',
    String localStoragePrefix = 'vifutbol_prod',
    String apiBaseUrl = 'https://api.vifutbol.com',
    String apiAnonKey = 'prod-anon-key-vifutbol',
    SupabaseConfig? supabase,
  }) {
    _validatePrefix(AppEnvironment.production, localStoragePrefix);
    final resolvedSupabase =
        supabase ??
        const SupabaseConfig(
          url: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
          anonKey: String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: '',
          ),
        );
    _validateSupabase(AppEnvironment.production, resolvedSupabase);

    return EnvironmentConfig._(
      environment: AppEnvironment.production,
      appName: appName,
      localStoragePrefix: localStoragePrefix,
      apiBaseUrl: apiBaseUrl,
      apiAnonKey: apiAnonKey,
      showEnvironmentBanner: false,
      supabase: resolvedSupabase,
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

  static void _validateSupabase(AppEnvironment env, SupabaseConfig config) {
    if (config.url.isNotEmpty) {
      final uri = Uri.tryParse(config.url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw EnvironmentValidationFailure(
          'Invalid Supabase URL: ${config.url}. Must be a valid absolute URI.',
        );
      }
    }

    if (env == AppEnvironment.production && config.isConfigured) {
      final normalizedUrl = config.url.toLowerCase();
      if (normalizedUrl.contains('supabase.artbusinesstechnology.com') ||
          normalizedUrl.contains('dev')) {
        throw EnvironmentValidationFailure(
          'Production configuration cannot use a development Supabase URL: ${config.url}.',
        );
      }
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
      'supabase': supabase.toSafeDiagnosticMap(),
    };
  }

  @override
  String toString() {
    return 'EnvironmentConfig(environment: ${environment.name}, appName: $appName, '
        'localStoragePrefix: $localStoragePrefix, apiBaseUrl: $apiBaseUrl, '
        'apiAnonKey: [REDACTED], showEnvironmentBanner: $showEnvironmentBanner, '
        'supabase: $supabase)';
  }
}
