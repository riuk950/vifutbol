import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Tab view presenting the club profile (ficha del club), last played match,
/// and next scheduled match for a specific team.
class TeamInfoTabView extends ConsumerWidget {
  final String teamId;

  const TeamInfoTabView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(teamMatchSummaryProvider(teamId));
    final team = summary.team;
    final tournament = summary.tournament;

    if (team == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: KickPulseStateView<void>(
            state: UiEmptyState<void>(
              message: l10n.teamDetailNotFoundTitle,
              description: l10n.teamDetailNotFoundMessage,
            ),
          ),
        ),
      );
    }

    return ListView(
      key: const Key('team_info_tab_scroll_view'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      children: [
        _buildClubProfileCard(context, team, tournament, l10n),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        _buildLastMatchCard(context, summary, l10n),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        _buildNextMatchCard(context, summary, l10n),
      ],
    );
  }

  Widget _buildClubProfileCard(
    BuildContext context,
    TournamentTeam team,
    ChampionshipTournament? tournament,
    AppLocalizations l10n,
  ) {
    final primaryColor = Color(team.primaryColorHex);
    final secondaryColor = Color(team.secondaryColorHex);

    return KickPulseCard(
      key: const Key('team_club_profile_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.teamDetailClubProfileTitle,
                  style: KickPulseTypography.sectionHeader.copyWith(
                    color: KickPulseColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          _buildInfoRow(
            label: l10n.teamDetailOfficialNameLabel,
            value: team.name,
          ),
          const Divider(color: KickPulseColors.borderSubtle, height: 16),
          _buildInfoRow(
            label: l10n.teamDetailShortCodeLabel,
            value: team.shortCode,
          ),
          const Divider(color: KickPulseColors.borderSubtle, height: 16),
          _buildInfoRow(
            label: l10n.teamDetailCompetitionLabel,
            value: tournament?.name ?? 'Competición oficial',
          ),
          const Divider(color: KickPulseColors.borderSubtle, height: 16),
          KeyedSubtree(
            key: const Key('team_info_delegate_row'),
            child: _buildInfoRow(
              label: l10n.teamInfoDelegateLabel,
              value: (team.delegateName != null &&
                      team.delegateName!.trim().isNotEmpty)
                  ? team.delegateName!
                  : l10n.teamInfoNotRegistered,
            ),
          ),
          const Divider(color: KickPulseColors.borderSubtle, height: 16),
          KeyedSubtree(
            key: const Key('team_info_founded_date_row'),
            child: _buildInfoRow(
              label: l10n.teamInfoFoundedDateLabel,
              value: team.foundedDate != null
                  ? '${team.foundedDate!.day.toString().padLeft(2, '0')}/${team.foundedDate!.month.toString().padLeft(2, '0')}/${team.foundedDate!.year}'
                  : l10n.teamInfoDateNotRegistered,
            ),
          ),
          const Divider(color: KickPulseColors.borderSubtle, height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: [
              Text(
                l10n.teamDetailClubColorsLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              _buildColorChip(
                key: const Key('team_primary_color_swatch'),
                label: l10n.teamDetailPrimaryColorLabel,
                color: primaryColor,
              ),
              _buildColorChip(
                key: const Key('team_secondary_color_swatch'),
                label: l10n.teamDetailSecondaryColorLabel,
                color: secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip({
    required Key key,
    required String label,
    required Color color,
  }) {
    return Row(
      key: key,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: KickPulseColors.borderStrong, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: KickPulseTypography.captionMeta.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
        Flexible(
          child: Text(
            value,
            style: KickPulseTypography.bodyPrimary.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLastMatchCard(
    BuildContext context,
    TeamMatchSummary summary,
    AppLocalizations l10n,
  ) {
    final match = summary.lastPlayedMatch;
    final opponent = summary.lastMatchOpponent;

    return KickPulseCard(
      key: const Key('team_last_match_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 18,
                color: KickPulseColors.accentElectric,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.teamDetailLastMatchTitle,
                  style: KickPulseTypography.sectionHeader.copyWith(
                    color: KickPulseColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (match != null) ...[
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                const KickPulseBadge(
                  label: 'FT',
                  variant: KickPulseBadgeVariant.neutral,
                ),
              ],
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (match == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Center(
                child: Text(
                  l10n.teamDetailLastMatchEmpty,
                  key: const Key('team_last_match_empty_state'),
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            _buildMatchSummaryContent(
              context: context,
              contentKey: const Key('team_last_match_content'),
              match: match,
              team: summary.team!,
              opponent: opponent,
              isHome: summary.isLastMatchHome,
              isFinished: true,
              l10n: l10n,
            ),
        ],
      ),
    );
  }

  Widget _buildNextMatchCard(
    BuildContext context,
    TeamMatchSummary summary,
    AppLocalizations l10n,
  ) {
    final match = summary.nextScheduledMatch;
    final opponent = summary.nextMatchOpponent;

    return KickPulseCard(
      key: const Key('team_next_match_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 18,
                color: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.teamDetailNextMatchTitle,
                  style: KickPulseTypography.sectionHeader.copyWith(
                    color: KickPulseColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (match != null) ...[
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                KickPulseBadge(
                  label: match.status == MatchStatus.inProgress
                      ? 'EN VIVO'
                      : (summary.isNextMatchHome
                            ? l10n.teamDetailHomeConditionBadge
                            : l10n.teamDetailAwayConditionBadge),
                  variant: match.status == MatchStatus.inProgress
                      ? KickPulseBadgeVariant.live
                      : KickPulseBadgeVariant.info,
                ),
              ],
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (match == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Center(
                child: Text(
                  l10n.teamDetailNextMatchEmpty,
                  key: const Key('team_next_match_empty_state'),
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            _buildMatchSummaryContent(
              context: context,
              contentKey: const Key('team_next_match_content'),
              match: match,
              team: summary.team!,
              opponent: opponent,
              isHome: summary.isNextMatchHome,
              isFinished: false,
              l10n: l10n,
            ),
        ],
      ),
    );
  }

  Widget _buildMatchSummaryContent({
    required BuildContext context,
    required Key contentKey,
    required ChampionshipMatch match,
    required TournamentTeam team,
    required TournamentTeam? opponent,
    required bool isHome,
    required bool isFinished,
    required AppLocalizations l10n,
  }) {
    final opponentName =
        opponent?.name ?? (isHome ? match.awayTeamId : match.homeTeamId);
    final opponentCode =
        opponent?.shortCode ??
        (opponentName.length >= 3
            ? opponentName.substring(0, 3)
            : opponentName);

    final scoreStr = isFinished
        ? (isHome
              ? '${match.homeScore ?? 0} - ${match.awayScore ?? 0}'
              : '${match.awayScore ?? 0} - ${match.homeScore ?? 0}')
        : null;

    final dateStr = match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(
            match.scheduledStartTime!,
            separator: ' ',
          )
        : 'Horario pendiente';

    final venueStr = (match.pitchName != null && match.pitchName!.isNotEmpty)
        ? match.pitchName!
        : 'Cancha por asignar';

    return Column(
      key: contentKey,
      children: [
        Row(
          children: [
            KickPulseTeamCrest(
              shortCode: opponentCode,
              crestShape: opponent?.crestShape ?? TeamCrestShape.shield,
              primaryColorHex: opponent?.primaryColorHex ?? 0xFF38BDF8,
              secondaryColorHex: opponent?.secondaryColorHex ?? 0xFF0A0E17,
              size: 38,
            ),
            const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHome ? 'vs $opponentName' : '@ $opponentName',
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    match.roundName,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (scoreStr != null) ...[
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: KickPulseColors.borderSubtle),
                ),
                child: Text(
                  scoreStr,
                  style: KickPulseTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        Wrap(
          spacing: KickPulseRadiiSpacing.spaceMd,
          runSpacing: KickPulseRadiiSpacing.spaceXs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
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
      ],
    );
  }
}
