import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/daily_matches_tab_bar.dart';
import 'package:vifutbol/presentation/matches/widgets/organizer_pending_matches_banner.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/tournament_matches_group_card.dart';

class MatchdayTabView extends ConsumerStatefulWidget {
  const MatchdayTabView({super.key});

  @override
  ConsumerState<MatchdayTabView> createState() => _MatchdayTabViewState();
}

class _MatchdayTabViewState extends ConsumerState<MatchdayTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    ref.read(tournamentsControllerProvider.notifier).loadCatalog();
    ref.read(teamsControllerProvider.notifier).loadTeams();
    ref.read(dailyMatchesFeedControllerProvider.notifier).refresh();
  }

  Future<void> _onGenerateFixture(
    ChampionshipTournament tournament,
    List<TournamentTeam> teams,
  ) async {
    final confirmed = await GenerateFixtureConfirmationDialog.show(context);
    if (confirmed == true && mounted) {
      final userRole = ref.read(activeUserRoleProvider);
      final controller = ref.read(matchesCatalogControllerProvider.notifier);
      final success = await controller.generateFixture(
        tournament: tournament,
        teams: teams,
        userRole: userRole,
      );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        final matches = ref.read(matchesCatalogControllerProvider).matches;
        ref.read(dailyMatchesFeedControllerProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchdayFixtureGeneratedSuccess(matches.length)),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      }
    }
  }

  void _onOpenScheduleDialogForPending(BuildContext context) {
    final matches = ref.read(matchesCatalogControllerProvider).matches;
    final tournaments = ref.read(tournamentsControllerProvider).tournaments;
    final pendingMatches =
        matches.where((m) => m.scheduledStartTime == null).toList();

    if (pendingMatches.isEmpty) return;

    final firstPending = pendingMatches.first;
    final tournament = tournaments.firstWhere(
      (t) => t.id == firstPending.tournamentId,
      orElse: () => tournaments.first,
    );

    ScheduleMatchDialog.show(
      context: context,
      match: firstPending,
      tournament: tournament,
    );
  }

  void _onOpenMatchReport(ChampionshipMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigitalMatchReportScreen(initialMatch: match),
      ),
    );
  }

  void _onOpenCompetitionDetail(String tournamentId) {
    Navigator.of(context).pushNamed('/competitions/$tournamentId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feedState = ref.watch(dailyMatchesFeedControllerProvider);
    final userRole = ref.watch(activeUserRoleProvider);
    final isOrganizer = userRole == UserRole.organizer;

    return Scaffold(
      backgroundColor: KickPulseColors.surfaceBase,
      body: Column(
        children: [
          // Barra de navegación temporal rápida fija (Ayer, Hoy, Mañana)
          DailyMatchesTabBar(
            key: const Key('daily_matches_tab_bar'),
            dateState: feedState.dateState,
            onTabSelected: (tab) {
              ref
                  .read(dailyMatchesFeedControllerProvider.notifier)
                  .selectQuickTab(tab);
            },
          ),

          // Banner de aviso exclusivo para el Organizador si hay pendientes
          if (isOrganizer && feedState.hasOrganizerAlerts)
            OrganizerPendingMatchesBanner(
              key: const Key('organizer_pending_matches_banner'),
              pendingMatchesCount: feedState.pendingScheduleMatchesCount,
              unseededTournamentsCount: feedState.unseededTournamentsCount,
              onScheduleTap: () => _onOpenScheduleDialogForPending(context),
              onGenerateFixtureTap: () {
                final tournaments =
                    ref.read(tournamentsControllerProvider).tournaments;
                final matches =
                    ref.read(matchesCatalogControllerProvider).matches;
                final teams = ref.read(teamsControllerProvider).teams;
                final unseeded = tournaments.firstWhere(
                  (t) =>
                      t.status.isEditable &&
                      !matches.any((m) => m.tournamentId == t.id),
                );
                _onGenerateFixture(unseeded, teams);
              },
            ),

          Expanded(
            child: RefreshIndicator(
              color: KickPulseColors.accentPrimary,
              backgroundColor: KickPulseColors.surfaceElevated,
              onRefresh: () async {
                ref.read(dailyMatchesFeedControllerProvider.notifier).refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (feedState.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: KickPulseColors.accentPrimary,
                        ),
                      ),
                    )
                  else if (feedState.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            KickPulseRadiiSpacing.spaceLg,
                          ),
                          child: KickPulseStateView<void>(
                            state: UiEmptyState<void>(
                              message: l10n.emptyMatchesForDate,
                              description: l10n.emptyMatchesSuggestion,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = feedState.tournamentGroups[index];
                            return TournamentMatchesGroupCard(
                              key: Key('tournament_group_${group.tournament.id}'),
                              group: group,
                              onMatchTap: _onOpenMatchReport,
                              onTournamentTap: () =>
                                  _onOpenCompetitionDetail(group.tournament.id),
                            );
                          },
                          childCount: feedState.tournamentGroups.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
