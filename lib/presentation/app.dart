import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/auth/auth_gate.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/splash/lottie_splash_screen.dart';

/// Root Application Widget configured with KickPulse Mobile theme and Spanish l10n.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vifutbol',
      debugShowCheckedModeBanner: false,
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      onGenerateRoute: AppRouter.router.generator,
      home: const LottieSplashScreen(child: AuthGate()),
    );
  }
}
