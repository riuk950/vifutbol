import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/presentation/auth/auth_gate.dart';
import 'package:vifutbol/presentation/auth/role_onboarding_screen.dart';
import 'package:vifutbol/presentation/auth/welcome_auth_screen.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';
import 'package:vifutbol/presentation/venues/venue_form_screen.dart';

/// Fluro router configuration for App Shell navigation.
class AppRouter {
  static final FluroRouter router = FluroRouter();

  static void setupRouter() {
    final rootHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AuthGate();
      },
    );

    final authHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const WelcomeAuthScreen();
      },
    );

    final onboardingHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const RoleOnboardingScreen();
      },
    );

    final shellHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen();
      },
    );

    final matchdayHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.matchday);
      },
    );

    final standingsHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.standings);
      },
    );

    final venuesHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.venues);
      },
    );

    final profileHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.profile);
      },
    );

    final venueFormHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const VenueFormScreen();
      },
    );

    final tournamentFormHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        final args = context?.settings?.arguments;
        final initialTournament = args is ChampionshipTournament ? args : null;
        return TournamentFormScreen(initialTournament: initialTournament);
      },
    );

    router.define(
      '/',
      handler: rootHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/auth',
      handler: authHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/onboarding',
      handler: onboardingHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/shell',
      handler: shellHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/matchday',
      handler: matchdayHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/standings',
      handler: standingsHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/venues',
      handler: venuesHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/profile',
      handler: profileHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/venues/form',
      handler: venueFormHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/tournaments/form',
      handler: tournamentFormHandler,
      transitionType: TransitionType.fadeIn,
    );
  }
}
