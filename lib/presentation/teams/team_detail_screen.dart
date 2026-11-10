import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';
import 'package:vifutbol/presentation/teams/widgets/team_info_tab_view.dart';
import 'package:vifutbol/presentation/teams/widgets/team_matches_tab_view.dart';
import 'package:vifutbol/presentation/teams/widgets/team_squad_tab_view.dart';

/// Dedicated Team Detail screen (`/teams/:id`) with 3 horizontal fixed tabs:
/// "Información", "Partidos", and "Plantilla".
class TeamDetailScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  (String, KickPulseBadgeVariant) _eligibilityBadgeInfo(
    TeamEligibilityStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case TeamEligibilityStatus.pendingVerification:
        return (
          l10n.teamEligibilityPendingVerification,
          KickPulseBadgeVariant.warning,
        );
      case TeamEligibilityStatus.eligible:
        return (l10n.teamEligibilityEligible, KickPulseBadgeVariant.dev);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(teamMatchSummaryProvider(teamId));
    final team = summary.team;
    final tournament = summary.tournament;

    if (team == null) {
      return Scaffold(
        key: const Key('team_detail_screen'),
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          leading: IconButton(
            key: const Key('team_detail_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: KickPulseColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.teamDetailNotFoundTitle,
            style: KickPulseTypography.screenTitle.copyWith(fontSize: 18),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
            child: KickPulseStateView<void>(
              key: const Key('team_detail_not_found_state'),
              state: UiEmptyState<void>(
                message: l10n.teamDetailNotFoundTitle,
                description: l10n.teamDetailNotFoundMessage,
              ),
            ),
          ),
        ),
      );
    }

    final (badgeLabel, badgeVariant) = _eligibilityBadgeInfo(
      team.eligibilityStatus,
      l10n,
    );

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        key: const Key('team_detail_screen'),
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          elevation: 0,
          leading: IconButton(
            key: const Key('team_detail_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: KickPulseColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              KickPulseTeamCrest(
                key: const Key('team_detail_app_bar_crest'),
                shortCode: team.shortCode,
                crestShape: team.crestShape,
                primaryColorHex: team.primaryColorHex,
                secondaryColorHex: team.secondaryColorHex,
                size: 36,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            team.name,
                            key: const Key('team_detail_title'),
                            style: KickPulseTypography.screenTitle.copyWith(
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        Text(
                          team.shortCode,
                          key: const Key('team_detail_short_code'),
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (tournament != null)
                      Text(
                        tournament.name,
                        key: const Key('team_detail_competition_name'),
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: KickPulseRadiiSpacing.spaceMd,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: KickPulseBadge(
                    key: const Key('team_detail_eligibility_badge'),
                    label: badgeLabel,
                    variant: badgeVariant,
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            key: const Key('team_detail_tab_bar'),
            indicatorColor: KickPulseColors.accentPrimary,
            indicatorWeight: 3,
            labelColor: KickPulseColors.accentPrimary,
            unselectedLabelColor: KickPulseColors.textSecondary,
            labelStyle: KickPulseTypography.bodyPrimary.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                key: const Key('team_detail_tab_info'),
                text: l10n.teamDetailTabInfo,
              ),
              Tab(
                key: const Key('team_detail_tab_matches'),
                text: l10n.teamDetailTabMatches,
              ),
              Tab(
                key: const Key('team_detail_tab_squad'),
                text: l10n.teamDetailTabSquad,
              ),
            ],
          ),
        ),
        body: TabBarView(
          key: const Key('team_detail_tab_bar_view'),
          children: [
            // Pestaña 1: Información
            TeamInfoTabView(
              key: const PageStorageKey('team_info_tab_view'),
              teamId: teamId,
            ),
            // Pestaña 2: Partidos (HU 14.2)
            TeamMatchesTabView(
              key: const PageStorageKey('team_matches_tab_view'),
              teamId: teamId,
            ),
            // Pestaña 3: Plantilla (HU 14.3)
            TeamSquadTabView(
              key: const PageStorageKey('team_squad_tab_view'),
              teamId: teamId,
            ),
          ],
        ),
      ),
    );
  }
}
