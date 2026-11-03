import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/initialize_app_foundation_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/infrastructure/connectivity/platform_connectivity_repository.dart';
import 'package:vifutbol/infrastructure/storage/hive_local_storage_repository.dart';
import 'package:vifutbol/presentation/app.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';

/// Bootstraps the application runtime with environment isolation and orientation lock.
Future<void> bootstrapApp(EnvironmentConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final connectivityRepository = PlatformConnectivityRepository();

  AppRouter.setupRouter();

  runApp(
    ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(config),
        localStorageRepositoryProvider.overrideWithValue(
          localStorageRepository,
        ),
        connectivityRepositoryProvider.overrideWithValue(
          connectivityRepository,
        ),
      ],
      child: const App(),
    ),
  );
}
