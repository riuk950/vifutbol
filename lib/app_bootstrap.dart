import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/supabase_providers.dart';
import 'package:vifutbol/application/use_cases/initialize_app_foundation_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/infrastructure/connectivity/platform_connectivity_repository.dart';
import 'package:vifutbol/infrastructure/storage/hive_local_storage_repository.dart';
import 'package:vifutbol/presentation/app.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';

/// Bootstraps the application runtime with environment isolation,
/// conditional Supabase backend initialization, and orientation lock.
Future<ProviderContainer> bootstrapApp(
  EnvironmentConfig config, {
  void Function(Widget app)? appRunner,
}) async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (appRunner == null) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // FR-008: Strict Portrait orientation lock for mobile smartphones
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize local persistence
  try {
    await Hive.initFlutter();
  } catch (_) {
    // Falls back to in-memory mode if disk initialization is prohibited
  }

  final localStorageRepository = HiveLocalStorageRepository();
  final initializeFoundation = InitializeAppFoundationUseCase(
    localStorageRepository,
  );
  await initializeFoundation(config);

  // Initialize Supabase conditionally (FR-005)
  if (config.supabase.isConfigured) {
    try {
      await Supabase.initialize(
        url: config.supabase.url,
        // ignore: deprecated_member_use
        anonKey: config.supabase.anonKey,
        postgrestOptions: PostgrestClientOptions(
          schema: config.supabase.schema,
        ),
      );
    } catch (e) {
      debugPrint(
        '[Supabase] Falló la inicialización remota; operando en modo local (Hive): $e',
      );
    }
  } else {
    debugPrint(
      '[Supabase] No se suministraron credenciales; operando en modo local (Hive).',
    );
  }

  final connectivityRepository = PlatformConnectivityRepository();

  AppRouter.setupRouter();

  final container = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(config),
      localStorageRepositoryProvider.overrideWithValue(localStorageRepository),
      connectivityRepositoryProvider.overrideWithValue(connectivityRepository),
    ],
  );

  final runner = appRunner ?? runApp;
  runner(UncontrolledProviderScope(container: container, child: const App()));

  // FR-008 / US3: Trigger health check asynchronously in background after runApp
  if (config.supabase.isConfigured) {
    unawaited(
      container.read(backendHealthStatusProvider.notifier).checkHealth(),
    );
  }

  return container;
}
