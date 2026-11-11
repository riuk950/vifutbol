import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/use_cases/check_supabase_backend_health_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/backend_health_status.dart';
import 'package:vifutbol/infrastructure/network/supabase_health_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  late MockHttpClient mockHttpClient;
  late SupabaseHealthClient healthClient;

  const testConfig = SupabaseConfig(
    url: 'https://supabase.artbusinesstechnology.com',
    anonKey: 'valid-test-anon-key',
  );

  setUp(() {
    mockHttpClient = MockHttpClient();
    healthClient = SupabaseHealthClient(client: mockHttpClient);
  });

  group('SupabaseHealthClient', () {
    test('returns unconfigured result when config is not configured', () async {
      final result = await healthClient.checkHealth(
        const SupabaseConfig.empty(),
      );

      expect(result.status, BackendHealthStatus.unconfigured);
      expect(result.isHealthy, isFalse);
      verifyZeroInteractions(mockHttpClient);
    });

    test(
      'returns healthy status on HTTP 200 OK with correct headers and endpoint',
      () async {
        when(
          () => mockHttpClient.get(
            Uri.parse('https://supabase.artbusinesstechnology.com/rest/v1/'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => http.Response('{"swagger":"2.0"}', 200));

        final result = await healthClient.checkHealth(testConfig);

        expect(result.status, BackendHealthStatus.healthy);
        expect(result.isHealthy, isTrue);
        expect(result.httpStatusCode, 200);

        verify(
          () => mockHttpClient.get(
            Uri.parse('https://supabase.artbusinesstechnology.com/rest/v1/'),
            headers: {
              'apikey': 'valid-test-anon-key',
              'Accept': 'application/openapi+json, application/json',
            },
          ),
        ).called(1);
      },
    );

    test(
      'probes /rest/v1/tournaments with Accept-Profile and Bearer headers when schema is vifutboldev',
      () async {
        const devSchemaConfig = SupabaseConfig(
          url: 'https://supabase.artbusinesstechnology.com',
          anonKey: 'valid-dev-anon-key',
          schema: 'vifutboldev',
        );

        when(
          () => mockHttpClient.get(
            Uri.parse(
              'https://supabase.artbusinesstechnology.com/rest/v1/tournaments?select=id&limit=1',
            ),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => http.Response('[]', 200));

        final result = await healthClient.checkHealth(devSchemaConfig);

        expect(result.status, BackendHealthStatus.healthy);
        expect(result.isHealthy, isTrue);
        expect(result.httpStatusCode, 200);

        verify(
          () => mockHttpClient.get(
            Uri.parse(
              'https://supabase.artbusinesstechnology.com/rest/v1/tournaments?select=id&limit=1',
            ),
            headers: {
              'apikey': 'valid-dev-anon-key',
              'Authorization': 'Bearer valid-dev-anon-key',
              'Accept-Profile': 'vifutboldev',
              'Accept': 'application/json',
            },
          ),
        ).called(1);
      },
    );

    test('returns unreachable status on HTTP 401 Unauthorized', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('{"message":"Invalid API key"}', 401),
      );

      final result = await healthClient.checkHealth(testConfig);

      expect(result.status, BackendHealthStatus.unreachable);
      expect(result.isHealthy, isFalse);
      expect(result.httpStatusCode, 401);
      expect(result.errorMessage, contains('401'));
    });

    test('returns unreachable status on HTTP 500 error', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      final result = await healthClient.checkHealth(testConfig);

      expect(result.status, BackendHealthStatus.unreachable);
      expect(result.isHealthy, isFalse);
      expect(result.httpStatusCode, 500);
      expect(result.errorMessage, contains('500'));
    });

    test(
      'returns unreachable status on SocketException (network failure)',
      () async {
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(const SocketException('Failed host lookup'));

        final result = await healthClient.checkHealth(testConfig);

        expect(result.status, BackendHealthStatus.unreachable);
        expect(result.isHealthy, isFalse);
        expect(result.errorMessage, contains('Failed host lookup'));
      },
    );

    test('returns unreachable status on TimeoutException', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 50),
          () => http.Response('OK', 200),
        ),
      );

      final result = await healthClient.checkHealth(
        testConfig,
        timeout: const Duration(milliseconds: 10),
      );

      expect(result.status, BackendHealthStatus.unreachable);
      expect(result.isHealthy, isFalse);
      expect(result.errorMessage, contains('timed out'));
    });
  });

  group('CheckSupabaseBackendHealthUseCase & BackendHealthNotifier', () {
    test('executes handshake and returns healthy result', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{"swagger":"2.0"}', 200));

      final useCase = CheckSupabaseBackendHealthUseCaseImpl(
        healthClient: healthClient,
        config: testConfig,
      );

      final result = await useCase();
      expect(result.status, BackendHealthStatus.healthy);
      expect(result.isHealthy, isTrue);
    });

    test(
      'BackendHealthNotifier transitions through checking to result',
      () async {
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('{"swagger":"2.0"}', 200));

        final useCase = CheckSupabaseBackendHealthUseCaseImpl(
          healthClient: healthClient,
          config: testConfig,
        );

        final notifier = BackendHealthNotifier(useCase);
        expect(notifier.state.status, BackendHealthStatus.unconfigured);

        final checkFuture = notifier.checkHealth();
        expect(notifier.state.status, BackendHealthStatus.checking);

        final result = await checkFuture;
        expect(result.status, BackendHealthStatus.healthy);
        expect(notifier.state.status, BackendHealthStatus.healthy);
      },
    );
  });
}
