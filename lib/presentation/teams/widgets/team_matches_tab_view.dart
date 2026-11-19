import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/matches/widgets/match_center_card.dart';
import 'package:vifutbol/presentation/teams/models/team_matches_schedule.dart';

/// Tab view presenting the complete match schedule for a specific team,
/// organized into "Próximos Partidos" and "Resultados Anteriores".
class TeamMatchesTabView extends ConsumerWidget {
  final String teamId;

  const TeamMatchesTabView({super.key, required this.teamId});

  void _openMatchDetailModal(
    BuildContext context,
    TeamScheduledMatchItem item,
    AppLocalizations l10n,
  ) {
    final match = item.match;
    final homeName = item.homeTeam?.name ?? match.homeTeamId;
    final awayName = item.awayTeam?.name ?? match.awayTeamId;

    final dateStr = match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(
            match.scheduledStartTime!,
            separator: ' - ',
          )
        : l10n.teamMatchDetailModalPendingSchedule;

    final venueStr = (match.pitchName != null && match.pitchName!.isNotEmpty)
        ? match.pitchName!
        : l10n.teamMatchDetailModalUnassignedVenue;

    final refereeStr =
        (match.refereeName != null && match.refereeName!.isNotEmpty)
        ? match.refereeName!
        : l10n.teamMatchDetailModalUnassignedReferee;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            key: const Key('team_match_detail_modal'),
            decoration: const BoxDecoration(
              color: KickPulseColors.surfaceBase,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
              ),
            ),
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: KickPulseColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Text(
                  match.roundName,
                  style: KickPulseTypography.sectionHeader.copyWith(
                    color: KickPulseColors.accentElectric,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Text(
                  '$homeName vs $awayName',
                  style: KickPulseTypography.screenTitle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                if (item.outcome != null) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Center(
                    child: _buildOutcomeBadge(item.outcome!, match.id, l10n),
                  ),
                ],
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KickPulseCard(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceMd,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: KickPulseColors.accentPrimary,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: KickPulseTypography.bodyPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Row(
                          children: [
                            const Icon(
                              Icons.stadium_outlined,
                              size: 18,
                              color: KickPulseColors.accentElectric,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Text(
                                venueStr,
                                style: KickPulseTypography.bodyPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Row(
                          children: [
                            const Icon(
                              Icons.sports_rounded,
                              size: 18,
                              color: KickPulseColors.accentWarning,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Text(
                                '${l10n.teamMatchDetailModalRefereeLabel}: $refereeStr',
                                style: KickPulseTypography.captionMeta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutcomeBadge(
    TeamMatchOutcome outcome,
    String matchId,
    AppLocalizations l10n,
  ) {
    final (label, variant) = switch (outcome) {
      TeamMatchOutcome.win => (
        l10n.teamMatchOutcomeWin,
        KickPulseBadgeVariant.success,
      ),
      TeamMatchOutcome.draw => (
        l10n.teamMatchOutcomeDraw,
        KickPulseBadgeVariant.warning,
      ),
      TeamMatchOutcome.loss => (
        l10n.teamMatchOutcomeLoss,
        KickPulseBadgeVariant.live,
      ),
    };

    return KickPulseBadge(
      key: Key('team_match_outcome_badge_$matchId'),
      label: label,
      variant: variant,
    );
  }

  Widget _buildSectionHeader({
    required Key key,
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(
        top: KickPulseRadiiSpacing.spaceMd,
        bottom: KickPulseRadiiSpacing.spaceSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Text(
              title,
              style: KickPulseTypography.sectionHeader.copyWith(
                color: KickPulseColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Text(
              '$count',
              style: KickPulseTypography.captionMeta.copyWith(
                fontWeight: FontWeight.bold,
                color: KickPulseColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchItem(
    BuildContext context,
    TeamScheduledMatchItem item,
    AppLocalizations l10n,
  ) {
    final dateStr = item.match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(
            item.match.scheduledStartTime!,
            separator: ' ',
            includeYear: false,
          )
        : l10n.teamMatchDetailModalPendingSchedule;

    final conditionBadge = item.match.status == MatchStatus.inProgress
        ? const KickPulseBadge(
            label: 'EN VIVO',
            variant: KickPulseBadgeVariant.live,
          )
        : KickPulseBadge(
            label: item.isHome
                ? l10n.teamDetailHomeConditionBadge
                : l10n.teamDetailAwayConditionBadge,
            variant: KickPulseBadgeVariant.info,
          );

    final venueStr =
        item.match.pitchName != null && item.match.pitchName!.isNotEmpty
        ? item.match.pitchName!
        : l10n.teamMatchDetailModalUnassignedVenue;

    return Padding(
      padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
      child: KickPulseCard(
        key: Key('team_upcoming_match_item_${item.match.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: KickPulseRadiiSpacing.spaceXs,
              children: [
                Text(
                  item.match.roundName,
                  style: KickPulseTypography.captionMeta.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KickPulseColors.accentElectric,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                conditionBadge,
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            MatchCenterCard(
              match: item.match,
              homeTeam: item.homeTeam,
              awayTeam: item.awayTeam,
              onTap: () => _openMatchDetailModal(context, item, l10n),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 13,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venueStr,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedMatchItem(
    BuildContext context,
    TeamScheduledMatchItem item,
    AppLocalizations l10n,
  ) {
    final dateStr = item.match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDate(item.match.scheduledStartTime!)
        : '';

    final outcomeBadge = item.outcome != null
        ? _buildOutcomeBadge(item.outcome!, item.match.id, l10n)
        : const SizedBox.shrink();

    final venueStr =
        item.match.pitchName != null && item.match.pitchName!.isNotEmpty
        ? item.match.pitchName!
        : l10n.teamMatchDetailModalUnassignedVenue;

    return Padding(
      padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
      child: KickPulseCard(
        key: Key('team_completed_match_item_${item.match.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: KickPulseRadiiSpacing.spaceXs,
              children: [
                Text(
                  item.match.roundName,
                  style: KickPulseTypography.captionMeta.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KickPulseColors.textPrimary,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                outcomeBadge,
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            MatchCenterCard(
              match: item.match,
              homeTeam: item.homeTeam,
              awayTeam: item.awayTeam,
              onTap: () => _openMatchDetailModal(context, item, l10n),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 13,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venueStr,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedule = ref.watch(teamMatchesScheduleProvider(teamId));

    if (!schedule.hasAnyMatches) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: KickPulseStateView<void>(
            key: const Key('team_matches_empty_state'),
            state: UiEmptyState<void>(
              message: l10n.teamMatchesEmptyGlobalTitle,
              description: l10n.teamMatchesEmptyGlobalMessage,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      children: [
        // 1. Sección: Próximos Partidos
        _buildSectionHeader(
          key: const Key('team_upcoming_matches_header'),
          title: l10n.teamMatchesUpcomingSectionTitle,
          icon: Icons.event_outlined,
          iconColor: KickPulseColors.accentPrimary,
          count: schedule.upcomingMatches.length,
        ),
        if (schedule.upcomingMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: KickPulseRadiiSpacing.spaceMd,
            ),
            child: Center(
              child: Text(
                l10n.teamMatchesUpcomingEmpty,
                key: const Key('team_upcoming_matches_empty_state'),
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...schedule.upcomingMatches.map(
            (item) => _buildUpcomingMatchItem(context, item, l10n),
          ),

        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

        // 2. Sección: Resultados Anteriores
        _buildSectionHeader(
          key: const Key('team_completed_matches_header'),
          title: l10n.teamMatchesCompletedSectionTitle,
          icon: Icons.history,
          iconColor: KickPulseColors.accentElectric,
          count: schedule.completedMatches.length,
        ),
        if (schedule.completedMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: KickPulseRadiiSpacing.spaceMd,
            ),
            child: Center(
              child: Text(
                l10n.teamMatchesCompletedEmpty,
                key: const Key('team_completed_matches_empty_state'),
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...schedule.completedMatches.map(
            (item) => _buildCompletedMatchItem(context, item, l10n),
          ),
      ],
    );
  }
}
