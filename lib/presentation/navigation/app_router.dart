import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/presentation/auth/auth_gate.dart';
import 'package:vifutbol/presentation/auth/role_onboarding_screen.dart';
import 'package:vifutbol/presentation/auth/welcome_auth_screen.dart';
import 'package:vifutbol/presentation/directories/competitions_directory_screen.dart';
import 'package:vifutbol/presentation/tournaments/competition_detail_screen.dart';
import 'package:vifutbol/presentation/directories/players_directory_screen.dart';
import 'package:vifutbol/presentation/directories/teams_directory_screen.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/venues_tab_view.dart';
import 'package:vifutbol/presentation/teams/coach_lineup_tracking_screen.dart';
import 'package:vifutbol/presentation/teams/team_roster_detail_screen.dart';
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

    final matchesHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.matches);
      },
    );

    final exploreHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        // Safe redirect: Explore is temporarily hidden, fallback to Matches per HU 12.1
        return const AppShellScreen(initialSection: AppShellSection.matches);
      },
    );

    final panelHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const PanelScreen();
      },
    );

    final newsHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const AppShellScreen(initialSection: AppShellSection.news);
      },
    );

    final competitionsHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const CompetitionsDirectoryScreen();
      },
    );

    final competitionDetailHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        final id = params['id']?.first ?? '';
        return CompetitionDetailScreen(tournamentId: id);
      },
    );

    final teamsHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const TeamsDirectoryScreen();
      },
    );

    final playersHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const PlayersDirectoryScreen();
      },
    );

    final venuesHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return Scaffold(
          appBar: AppBar(title: const Text('Sedes Deportivas')),
          body: const VenuesTabView(),
        );
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

    final teamRosterDetailHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const TeamRosterDetailScreen();
      },
    );

    final teamLineupTrackingHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        return const CoachLineupTrackingScreen();
      },
    );

    final matchReportHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
        final args = context?.settings?.arguments;
        final match = args is ChampionshipMatch ? args : null;
        return DigitalMatchReportScreen(initialMatch: match);
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
      '/matches',
      handler: matchesHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/matchday',
      handler: matchesHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/explore',
      handler: exploreHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/standings',
      handler: exploreHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/news',
      handler: newsHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/panel',
      handler: panelHandler,
      transitionType: TransitionType.native,
    );
    router.define(
      '/competitions',
      handler: competitionsHandler,
      transitionType: TransitionType.native,
    );
    router.define(
      '/competitions/:id',
      handler: competitionDetailHandler,
      transitionType: TransitionType.native,
    );
    router.define(
      '/teams',
      handler: teamsHandler,
      transitionType: TransitionType.native,
    );
    router.define(
      '/players',
      handler: playersHandler,
      transitionType: TransitionType.native,
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
    router.define(
      '/tournaments/teams/detail',
      handler: teamRosterDetailHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/tournaments/teams/lineup',
      handler: teamLineupTrackingHandler,
      transitionType: TransitionType.fadeIn,
    );
    router.define(
      '/matches/report',
      handler: matchReportHandler,
      transitionType: TransitionType.fadeIn,
    );
  }
}
