import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/auth/local_auth_repository.dart';
import 'package:vifutbol/infrastructure/auth/supabase_auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  late MockLocalStorageRepository mockStorage;
  late MockConnectivityRepository mockConnectivity;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockStorage = MockLocalStorageRepository();
    mockConnectivity = MockConnectivityRepository();
    mockSupabaseClient = MockSupabaseClient();
  });

  group('authRepositoryProvider DI selection (FR-002)', () {
    test(
      'returns SupabaseAuthRepository when DEV environment is configured and client is initialized',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'dev-anon-key',
            schema: 'vifutboldev',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(devConfig),
            localStorageRepositoryProvider.overrideWithValue(mockStorage),
            connectivityRepositoryProvider.overrideWithValue(mockConnectivity),
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(authRepositoryProvider);
        expect(repo, isA<SupabaseAuthRepository>());
        expect((repo as SupabaseAuthRepository).schema, 'vifutboldev');
      },
    );

    test(
      'falls back to LocalAuthRepository when supabaseClientProvider is null',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig(
            url: 'https://supabase.artbusinesstechnology.com',
            anonKey: 'dev-anon-key',
            schema: 'vifutboldev',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(devConfig),
            localStorageRepositoryProvider.overrideWithValue(mockStorage),
            connectivityRepositoryProvider.overrideWithValue(mockConnectivity),
            supabaseClientProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(authRepositoryProvider);
        expect(repo, isA<LocalAuthRepository>());
      },
    );

    test(
      'falls back to LocalAuthRepository when DEV SupabaseConfig is empty',
      () {
        final devConfig = EnvironmentConfig.development(
          supabase: const SupabaseConfig.empty(),
        );

        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(devConfig),
            localStorageRepositoryProvider.overrideWithValue(mockStorage),
            connectivityRepositoryProvider.overrideWithValue(mockConnectivity),
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(authRepositoryProvider);
        expect(repo, isA<LocalAuthRepository>());
      },
    );

    test(
      'uses LocalAuthRepository in production environment regardless of client',
      () {
        final prodConfig = EnvironmentConfig.production(
          supabase: const SupabaseConfig(
            url: 'https://prod-project.supabase.co',
            anonKey: 'prod-anon-key',
            schema: 'public',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(prodConfig),
            localStorageRepositoryProvider.overrideWithValue(mockStorage),
            connectivityRepositoryProvider.overrideWithValue(mockConnectivity),
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(authRepositoryProvider);
        expect(repo, isA<LocalAuthRepository>());
      },
    );
  });
}
