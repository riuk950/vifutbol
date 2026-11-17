import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/dialogs/create_team_dialog.dart';

/// Dynamic panel content for [UserRole.coach].
class CoachPanelContent extends ConsumerWidget {
  const CoachPanelContent({super.key});

  Widget _buildMetricCard({
    required Key key,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: KickPulseCard(
        key: key,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KickPulseRadiiSpacing.spaceSm,
            horizontal: KickPulseRadiiSpacing.spaceXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                value,
                style: KickPulseTypography.screenTitle.copyWith(
                  fontSize: 20,
                  color: KickPulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: KickPulseTypography.captionMeta.copyWith(
                  fontSize: 10,
                  color: KickPulseColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLineupAction(
    BuildContext context,
    TournamentTeam? team,
    AppLocalizations l10n,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            team != null
                ? '${l10n.coachActionMatchLineup}: ${team.name}'
                : l10n.coachActionMatchLineup,
          ),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
  }

  void _onManageRosterAction(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam? team,
    AppLocalizations l10n,
  ) {
    if (team != null) {
      ref.read(teamsControllerProvider.notifier).selectTeam(team.id);
      Navigator.of(context).pushNamed('/tournaments/teams/detail');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final coachTeams = ref.watch(coachTeamsProvider);
    final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

    if (coachTeams.isEmpty) {
      return SingleChildScrollView(
        key: const Key('coach_panel_content'),
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KickPulseCard(
              key: const Key('coach_no_team_card'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KickPulseRadiiSpacing.spaceXl,
                  horizontal: KickPulseRadiiSpacing.spaceLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: KickPulseColors.accentPrimary,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                    Text(
                      l10n.coachNoTeamTitle,
                      style: KickPulseTypography.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      l10n.coachNoTeamDescription,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    KickPulseButton(
                      key: const Key('coach_action_register_team_empty'),
                      label: l10n.coachActionRegisterTeamEmpty,
                      icon: const Icon(Icons.add, size: 20),
                      variant: KickPulseButtonVariant.primary,
                      onPressed: () => CreateTeamDialog.show(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final team = coachTeams.first;

    final players = team.players;
    final totalPlayers = players.length;
    final eligiblePlayersCount = players.where((p) => p.isEligible).length;
    final suspendedPlayersCount = players.where((p) => !p.isEligible).length;

    // Next match for this team
    final teamMatches = matchesCatalogState.matches
        .where((m) => m.homeTeamId == team.id || m.awayTeamId == team.id)
        .toList();

    final nextMatch = teamMatches.isNotEmpty ? teamMatches.first : null;

    return SingleChildScrollView(
      key: const Key('coach_panel_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team Header / Summary
          Row(
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: KickPulseTypography.sectionHeader,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              KickPulseBadge(
                label: team.shortCode,
                variant: KickPulseBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Squad Metrics Cards
          Row(
            children: [
              _buildMetricCard(
                key: const Key('coach_metric_total_players'),
                label: l10n.coachMetricTotalPlayers,
                value: '$totalPlayers',
                icon: Icons.groups_outlined,
                iconColor: KickPulseColors.textPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('coach_metric_eligible_players'),
                label: l10n.coachMetricEligiblePlayers,
                value: '$eligiblePlayersCount',
                icon: Icons.check_circle_outline,
                iconColor: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('coach_metric_suspended_players'),
                label: l10n.coachMetricSuspendedPlayers,
                value: '$suspendedPlayersCount',
                icon: Icons.warning_amber_outlined,
                iconColor: KickPulseColors.accentWarning,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Next Match Card
          Text(
            l10n.coachNextMatchTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            key: const Key('coach_next_match_card'),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  color: KickPulseColors.accentPrimary,
                  size: 24,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextMatch != null
                            ? nextMatch.roundName
                            : l10n.coachNoUpcomingMatch,
                        style: KickPulseTypography.bodyPrimary.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (nextMatch != null)
                        Text(
                          '${nextMatch.homeTeamId.toUpperCase()} vs ${nextMatch.awayTeamId.toUpperCase()}',
                          style: KickPulseTypography.captionMeta,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Quick Actions Section
          Text(
            l10n.coachQuickActionsTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KickPulseButton(
                  key: const Key('coach_action_match_lineup'),
                  label: l10n.coachActionMatchLineup,
                  icon: const Icon(Icons.format_list_numbered, size: 20),
                  variant: KickPulseButtonVariant.primary,
                  onPressed: () async {
                    _onLineupAction(context, team, l10n);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                KickPulseButton(
                  key: const Key('coach_action_manage_roster'),
                  label: l10n.coachActionManageRoster,
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  variant: KickPulseButtonVariant.secondary,
                  onPressed: () async {
                    _onManageRosterAction(context, ref, team, l10n);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
