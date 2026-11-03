import 'package:vifutbol/app_bootstrap.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';

/// Default entrypoint delegating to development configuration.
void main() async {
  final config = EnvironmentConfig.development();
  await bootstrapApp(config);
}
