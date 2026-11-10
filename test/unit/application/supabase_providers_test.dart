import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('supabase_providers', () {
    test(
      'supabaseConfigProvider derives config from environmentConfigProvider',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'sample-anon-key',
          ),
        );

        final container = ProviderContainer(
          overrides: [environmentConfigProvider.overrideWithValue(devConfig)],
        );
        addTearDown(container.dispose);

        final supabaseConfig = container.read(supabaseConfigProvider);
        expect(
          supabaseConfig.url,
          'https://supabase.artbusinesstechnology.com',
        );
        expect(supabaseConfig.anonKey, 'sample-anon-key');
        expect(supabaseConfig.isConfigured, isTrue);
      },
    );

    test(
      'supabaseClientProvider returns null when Supabase is not configured',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig.empty(),
        );

        final container = ProviderContainer(
          overrides: [environmentConfigProvider.overrideWithValue(devConfig)],
        );
        addTearDown(container.dispose);

        final client = container.read(supabaseClientProvider);
        expect(client, isNull);
      },
    );

    test(
      'supabaseClientProvider returns null safely when configured but SDK is not initialized',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'sample-anon-key',
          ),
        );

        final container = ProviderContainer(
          overrides: [environmentConfigProvider.overrideWithValue(devConfig)],
        );
        addTearDown(container.dispose);

        // Should not throw unhandled exception even if Supabase.initialize has not been invoked
        final client = container.read(supabaseClientProvider);
        expect(client, isNull);
      },
    );

    test(
      'supabaseClientProvider can be overridden for testing and consumers',
      () {
        final mockClient = MockSupabaseClient();
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'sample-anon-key',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(devConfig),
            supabaseClientProvider.overrideWithValue(mockClient),
          ],
        );
        addTearDown(container.dispose);

        final client = container.read(supabaseClientProvider);
        expect(client, equals(mockClient));
      },
    );
  });
}
