import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vifutbol/app_bootstrap.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

/// Default entrypoint delegating to development configuration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env.dev', isOptional: true);
  } catch (_) {
    // Falls back gracefully if .env.dev asset is not bundled
  }

  final config = EnvironmentConfig.development();
  await bootstrapApp(config);
}
