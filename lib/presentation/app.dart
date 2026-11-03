import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      onGenerateRoute: AppRouter.router.generator,
      home: const AppShellScreen(),
    );
  }
}
