import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';

/// Fluro router configuration for App Shell navigation.
class AppRouter {
  static final FluroRouter router = FluroRouter();

  static void setupRouter() {
    final rootHandler = Handler(
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

    router.define(
      '/',
      handler: rootHandler,
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
  }
}
