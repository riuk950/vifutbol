import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/matches/widgets/daily_matches_tab_bar.dart';
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
    ref
        .read(dailyMatchesFeedControllerProvider.notifier)
        .refreshFromCloud(showLoading: true);
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
    ref.listen(appShellControllerProvider, (previous, next) {
      if (next.activeSection == AppShellSection.matchday &&
          previous?.activeSection != AppShellSection.matchday) {
        ref
            .read(dailyMatchesFeedControllerProvider.notifier)
            .refreshFromCloud();
      }
    });

    final l10n = AppLocalizations.of(context);
    final feedState = ref.watch(dailyMatchesFeedControllerProvider);

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

          Expanded(
            child: RefreshIndicator(
              color: KickPulseColors.accentPrimary,
              backgroundColor: KickPulseColors.surfaceElevated,
              onRefresh: () async {
                await ref
                    .read(dailyMatchesFeedControllerProvider.notifier)
                    .refreshFromCloud();
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
                      padding: const EdgeInsets.all(
                        KickPulseRadiiSpacing.spaceMd,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final group = feedState.tournamentGroups[index];
                          return TournamentMatchesGroupCard(
                            key: Key('tournament_group_${group.tournament.id}'),
                            group: group,
                            onMatchTap: _onOpenMatchReport,
                            onTournamentTap: () =>
                                _onOpenCompetitionDetail(group.tournament.id),
                          );
                        }, childCount: feedState.tournamentGroups.length),
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
