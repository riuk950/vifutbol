import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Localization helpers for tournament domain enumerations.
extension TournamentEnumLocalizationX on AppLocalizations {
  String formatLabel(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.league:
        return tournamentFormatLeague;
      case TournamentFormat.knockoutCup:
        return tournamentFormatKnockout;
      case TournamentFormat.mixedGroupsAndKnockout:
        return tournamentFormatMixed;
    }
  }

  String statusLabel(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return tournamentStatusOpenRegistration;
      case TournamentStatus.inProgress:
        return tournamentStatusInProgress;
      case TournamentStatus.finished:
        return tournamentStatusFinished;
    }
  }

  String tiebreakerLabel(TiebreakerCriterion criterion) {
    switch (criterion) {
      case TiebreakerCriterion.goalDifference:
        return tiebreakerGoalDifference;
      case TiebreakerCriterion.goalsFor:
        return tiebreakerGoalsFor;
      case TiebreakerCriterion.headToHead:
        return tiebreakerHeadToHead;
      case TiebreakerCriterion.fairPlay:
        return tiebreakerFairPlay;
    }
  }

  String knockoutRoundLabel(KnockoutRound round) {
    switch (round) {
      case KnockoutRound.roundOf16:
        return knockoutRoundOf16;
      case KnockoutRound.quarterFinals:
        return knockoutQuarterFinals;
      case KnockoutRound.semiFinals:
        return knockoutSemiFinals;
      case KnockoutRound.finalMatch:
        return knockoutFinalMatch;
    }
  }
}

/// Visual summary card displaying the official rules, scoring system,
/// tiebreakers, knockout bracket structure, and audit trail of a [ChampionshipTournament].
class TournamentRulesSummaryCard extends StatelessWidget {
  const TournamentRulesSummaryCard({
    super.key,
    required this.tournament,
    required this.isOrganizer,
    this.onEditPressed,
    this.onTransitionStatusPressed,
  });

  final ChampionshipTournament tournament;
  final bool isOrganizer;
  final VoidCallback? onEditPressed;
  final ValueChanged<TournamentStatus>? onTransitionStatusPressed;

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return KickPulseColors.accentPrimary;
      case TournamentStatus.inProgress:
        return KickPulseColors.accentElectric;
      case TournamentStatus.finished:
        return KickPulseColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = tournament.rules;
    final statusColor = _statusColor(tournament.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KickPulseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: KickPulseRadiiSpacing.spaceSm,
                runSpacing: KickPulseRadiiSpacing.spaceXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceSm,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.badgeRadius,
                      ),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      l10n.statusLabel(tournament.status),
                      style: KickPulseTypography.microBadge.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceSm,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.badgeRadius,
                      ),
                    ),
                    child: Text(
                      l10n.formatLabel(tournament.format),
                      style: KickPulseTypography.microBadge,
                    ),
                  ),
                  Text(
                    tournament.category,
                    style: KickPulseTypography.captionMeta,
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Text(tournament.name, style: KickPulseTypography.screenTitle),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                '${_formatDate(tournament.startDate)} — ${_formatDate(tournament.endDate)}',
                style: KickPulseTypography.captionMeta,
              ),
              if (isOrganizer && tournament.status.isEditable) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Wrap(
                  spacing: KickPulseRadiiSpacing.spaceSm,
                  runSpacing: KickPulseRadiiSpacing.spaceSm,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('edit_tournament_rules_button'),
                      onPressed: onEditPressed,
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(l10n.tournamentsEditAction),
                    ),
                    if (tournament.status == TournamentStatus.openRegistration)
                      ElevatedButton.icon(
                        key: const Key('start_tournament_status_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KickPulseColors.accentPrimary,
                          foregroundColor: KickPulseColors.canvasBackground,
                        ),
                        onPressed: onTransitionStatusPressed == null
                            ? null
                            : () => onTransitionStatusPressed!(
                                TournamentStatus.inProgress,
                              ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(l10n.tournamentStartAction),
                      ),
                    if (tournament.status == TournamentStatus.inProgress)
                      OutlinedButton.icon(
                        key: const Key('finish_tournament_status_button'),
                        onPressed: onTransitionStatusPressed == null
                            ? null
                            : () => onTransitionStatusPressed!(
                                TournamentStatus.finished,
                              ),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: Text(l10n.tournamentFinishAction),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        KickPulseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tournamentScoringTitle,
                style: KickPulseTypography.cardTitle,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _ScoreMetricBox(
                      label: l10n.tournamentPointsWin,
                      value: l10n.tournamentPointsValue(rules.pointsForWin),
                      accent: KickPulseColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: _ScoreMetricBox(
                      label: l10n.tournamentPointsDraw,
                      value: l10n.tournamentPointsValue(rules.pointsForDraw),
                      accent: KickPulseColors.accentElectric,
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: _ScoreMetricBox(
                      label: l10n.tournamentPointsLoss,
                      value: l10n.tournamentPointsValue(rules.pointsForLoss),
                      accent: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (tournament.format.hasStandingsTable) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Text(
                  l10n.tournamentTiebreakersTitle,
                  style: KickPulseTypography.sectionHeader,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                ...List<Widget>.generate(rules.tiebreakerOrder.length, (index) {
                  final criterion = rules.tiebreakerOrder[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: KickPulseColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: KickPulseTypography.microBadge,
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            l10n.tiebreakerLabel(criterion),
                            style: KickPulseTypography.bodyPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        KickPulseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tournamentDisciplinaryAndSquadTitle,
                style: KickPulseTypography.cardTitle,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              _RuleRow(
                icon: Icons.style_outlined,
                label: l10n.tournamentYellowCardLimitLabel,
                value: l10n.tournamentYellowCardLimitValue(
                  rules.yellowCardSuspensionLimit,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              _RuleRow(
                icon: Icons.groups_outlined,
                label: l10n.tournamentSquadRangeLabel,
                value: l10n.tournamentSquadRangeValue(
                  rules.minPlayersPerTeam,
                  rules.maxPlayersPerTeam,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              _RuleRow(
                icon: Icons.timer_outlined,
                label: l10n.tournamentHalfDurationLabel,
                value: l10n.tournamentHalfDurationValue(
                  rules.halfDurationMinutes,
                ),
              ),
              if (tournament.format == TournamentFormat.league) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                _RuleRow(
                  icon: Icons.repeat_rounded,
                  label: l10n.tournamentLeagueRoundsLabel,
                  value: rules.leagueRounds == 2
                      ? l10n.tournamentLeagueDoubleRound
                      : l10n.tournamentLeagueSingleRound,
                ),
              ],
            ],
          ),
        ),
        if (tournament.format.hasGroupStage) ...[
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tournamentGroupStageTitle,
                  style: KickPulseTypography.cardTitle,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  l10n.tournamentGroupSummaryValue(
                    rules.groupStageConfig.groupCount,
                    rules.groupStageConfig.advancingPerGroup,
                  ),
                  style: KickPulseTypography.bodyPrimary,
                ),
              ],
            ),
          ),
        ],
        if (tournament.format.hasKnockoutBracket) ...[
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tournamentKnockoutStructureTitle,
                  style: KickPulseTypography.cardTitle,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Wrap(
                  spacing: KickPulseRadiiSpacing.spaceSm,
                  runSpacing: KickPulseRadiiSpacing.spaceSm,
                  children: rules.knockoutConfig.activeRoundsSequence
                      .map(
                        (round) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KickPulseRadiiSpacing.spaceSm,
                            vertical: KickPulseRadiiSpacing.spaceXs,
                          ),
                          decoration: BoxDecoration(
                            color: KickPulseColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(
                              KickPulseRadiiSpacing.chipRadius,
                            ),
                            border: Border.all(
                              color: KickPulseColors.borderStrong,
                            ),
                          ),
                          child: Text(
                            '${l10n.knockoutRoundLabel(round)} (${round.tieCount})',
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Text(
                  rules.knockoutConfig.twoLeggedTies
                      ? l10n.tournamentTwoLeggedTiesLabel
                      : l10n.tournamentSingleLegTieValue,
                  style: KickPulseTypography.captionMeta,
                ),
                if (rules.knockoutConfig.directPenaltyShootoutOnDraw) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        size: 16,
                        color: KickPulseColors.accentPrimary,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      Expanded(
                        child: Text(
                          l10n.tournamentDirectPenaltiesLabel,
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (tournament.auditTrail.isNotEmpty) ...[
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tournamentAuditTrailTitle,
                  style: KickPulseTypography.cardTitle,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                ...tournament.auditTrail.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: KickPulseRadiiSpacing.spaceSm,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(
                        KickPulseRadiiSpacing.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: KickPulseColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(
                          KickPulseRadiiSpacing.chipRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.summary,
                            style: KickPulseTypography.bodyPrimary.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.reason,
                            style: KickPulseTypography.captionMeta,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreMetricBox extends StatelessWidget {
  const _ScoreMetricBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KickPulseTypography.captionMeta),
          const SizedBox(height: 4),
          Text(
            value,
            style: KickPulseTypography.cardTitle.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: KickPulseColors.accentElectric),
        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
        Expanded(child: Text(label, style: KickPulseTypography.captionMeta)),
        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
        Text(
          value,
          style: KickPulseTypography.bodyPrimary.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
