import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vifutbol/app_bootstrap.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env.prod', isOptional: true);
  } catch (_) {
    // Falls back gracefully if .env.prod asset is not bundled
  }

  final config = EnvironmentConfig.production();
  await bootstrapApp(config);
}
