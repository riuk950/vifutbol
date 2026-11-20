import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vifutbol/app_bootstrap.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

/// Development entrypoint loading `.env.dev` and [EnvironmentConfig.development].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env.dev', isOptional: true);
  } catch (_) {
    // Falls back gracefully if .env.dev asset is empty or not bundled.
  }

  final config = EnvironmentConfig.development();
  await bootstrapApp(config);
}
