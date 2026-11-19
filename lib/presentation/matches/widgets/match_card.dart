import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.homeTeam,
    this.awayTeam,
    this.canSchedule = false,
    this.onScheduleTap,
    this.onOpenReportTap,
  });

  final ChampionshipMatch match;
  final TournamentTeam? homeTeam;
  final TournamentTeam? awayTeam;
  final bool canSchedule;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onOpenReportTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeName = homeTeam?.name ?? match.homeTeamId;
    final awayName = awayTeam?.name ?? match.awayTeamId;

    return Semantics(
      container: true,
      label: 'Tarjeta de partido: $homeName contra $awayName',
      child: KickPulseCard(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Round name and Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.roundName,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentElectric,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                _buildStatusBadge(l10n, match.status),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

            // Teams Row with Crests
            Row(
              children: [
                // Home Team
                Expanded(
                  child: Row(
                    children: [
                      KickPulseTeamCrest(
                        shortCode:
                            homeTeam?.shortCode ??
                            (homeName.length >= 3
                                ? homeName.substring(0, 3)
                                : homeName),
                        crestShape:
                            homeTeam?.crestShape ?? TeamCrestShape.shield,
                        primaryColorHex:
                            homeTeam?.primaryColorHex ?? 0xFF00E676,
                        secondaryColorHex:
                            homeTeam?.secondaryColorHex ?? 0xFF0A0E17,
                        size: 36,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          homeName,
                          style: KickPulseTypography.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // VS Badge or Live/Final Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: match.homeScore != null && match.awayScore != null
                        ? KickPulseColors.surfaceBase
                        : KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(
                      color: match.status == MatchStatus.inProgress
                          ? KickPulseColors.accentLive
                          : KickPulseColors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    match.homeScore != null && match.awayScore != null
                        ? '${match.homeScore} - ${match.awayScore}'
                        : 'VS',
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: match.status == MatchStatus.inProgress
                          ? KickPulseColors.accentLive
                          : (match.homeScore != null
                                ? Colors.white
                                : KickPulseColors.textSecondary),
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                // Away Team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          awayName,
                          style: KickPulseTypography.cardTitle,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      KickPulseTeamCrest(
                        shortCode:
                            awayTeam?.shortCode ??
                            (awayName.length >= 3
                                ? awayName.substring(0, 3)
                                : awayName),
                        crestShape:
                            awayTeam?.crestShape ?? TeamCrestShape.shield,
                        primaryColorHex:
                            awayTeam?.primaryColorHex ?? 0xFF2979FF,
                        secondaryColorHex:
                            awayTeam?.secondaryColorHex ?? 0xFF0A0E17,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Schedule info (if scheduled)
            if (match.isScheduled) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(color: KickPulseColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and Date
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: KickPulseColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatMatchDateTime(
                              match.scheduledStartTime!,
                              match.scheduledEndTime,
                            ),
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Pitch (with "Por definir" fallback when optional logistics are unassigned)
                    Row(
                      children: [
                        const Icon(
                          Icons.stadium_outlined,
                          size: 14,
                          color: KickPulseColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (match.pitchName != null &&
                                    match.pitchName!.trim().isNotEmpty)
                                ? match.pitchName!
                                : l10n.matchLogisticsTbdLabel,
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Referee (with "Por definir" fallback when unassigned)
                    Row(
                      children: [
                        const Icon(
                          Icons.sports,
                          size: 14,
                          color: KickPulseColors.accentElectric,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Árbitro: ${(match.refereeName != null && match.refereeName!.trim().isNotEmpty) ? match.refereeName! : l10n.matchLogisticsTbdLabel}',
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.accentElectric,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons row
            if (canSchedule ||
                match.status == MatchStatus.scheduled ||
                match.status == MatchStatus.inProgress ||
                match.status == MatchStatus.completed) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: KickPulseRadiiSpacing.spaceSm,
                runSpacing: KickPulseRadiiSpacing.spaceXs,
                children: [
                  if (match.status != MatchStatus.pendingSchedule)
                    OutlinedButton.icon(
                      key: Key('open_match_report_button_${match.id}'),
                      onPressed:
                          onOpenReportTap ??
                          () {
                            Navigator.of(
                              context,
                            ).pushNamed('/matches/report', arguments: match);
                          },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KickPulseColors.accentPrimary,
                        side: const BorderSide(
                          color: KickPulseColors.accentPrimary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: KickPulseRadiiSpacing.spaceMd,
                          vertical: KickPulseRadiiSpacing.spaceXs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.chipRadius,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.assignment, size: 16),
                      label: Text(
                        match.status == MatchStatus.completed
                            ? 'Ver Acta'
                            : 'Acta Arbitral',
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (canSchedule)
                    ElevatedButton.icon(
                      key: Key('schedule_match_button_${match.id}'),
                      onPressed: onScheduleTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KickPulseColors.surfaceElevated,
                        foregroundColor: KickPulseColors.accentElectric,
                        side: const BorderSide(
                          color: KickPulseColors.accentElectric,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: KickPulseRadiiSpacing.spaceMd,
                          vertical: KickPulseRadiiSpacing.spaceXs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.chipRadius,
                          ),
                        ),
                      ),
                      icon: Icon(
                        match.isScheduled
                            ? Icons.edit_calendar
                            : Icons.add_alarm,
                        size: 16,
                      ),
                      label: Text(
                        match.isScheduled
                            ? 'Reprogramar'
                            : l10n.scheduleMatchAction,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentElectric,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n, MatchStatus status) {
    return switch (status) {
      MatchStatus.pendingSchedule => KickPulseBadge(
        label: l10n.matchStatusPending,
        variant: KickPulseBadgeVariant.neutral,
      ),
      MatchStatus.scheduled => KickPulseBadge(
        label: l10n.matchStatusScheduled,
        variant: KickPulseBadgeVariant.info,
      ),
      MatchStatus.inProgress => KickPulseBadge(
        label: l10n.matchLiveBadge,
        variant: KickPulseBadgeVariant.live,
      ),
      MatchStatus.completed => KickPulseBadge(
        label: l10n.matchStatusCompleted,
        variant: KickPulseBadgeVariant.neutral,
      ),
      MatchStatus.cancelled => KickPulseBadge(
        label: l10n.matchStatusCancelled,
        variant: KickPulseBadgeVariant.warning,
      ),
    };
  }

  String _formatMatchDateTime(DateTime start, DateTime? end) {
    final dateFormatter = DateFormat('EEE d MMM', 'es');
    final colombiaStart = ColombiaTimeUtils.toColombiaWallClock(start);
    final dateStr = dateFormatter.format(colombiaStart);
    final startTimeStr = ColombiaTimeUtils.formatTime12h(start);

    if (end != null) {
      final endTimeStr = ColombiaTimeUtils.formatTime12h(end);
      return '$dateStr · $startTimeStr - $endTimeStr';
    }
    return '$dateStr · $startTimeStr';
  }
}
