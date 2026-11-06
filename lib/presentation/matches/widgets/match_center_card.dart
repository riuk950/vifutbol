import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Tarjeta de partido con disposición simétrica estilo Match Center (Stitch).
class MatchCenterCard extends StatelessWidget {
  final ChampionshipMatch match;
  final TournamentTeam? homeTeam;
  final TournamentTeam? awayTeam;
  final VoidCallback? onTap;

  const MatchCenterCard({
    super.key,
    required this.match,
    this.homeTeam,
    this.awayTeam,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeName = homeTeam?.name ?? match.homeTeamId;
    final awayName = awayTeam?.name ?? match.awayTeamId;

    return Semantics(
      container: true,
      button: onTap != null,
      label: 'Partido: $homeName contra $awayName',
      child: Material(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceMd,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Columna 1: Equipo Local (Flex, alineado a la derecha)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          homeName,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: KickPulseColors.textPrimary,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      KickPulseTeamCrest(
                        shortCode: homeTeam?.shortCode ??
                            (homeName.length >= 3
                                ? homeName.substring(0, 3)
                                : homeName),
                        crestShape:
                            homeTeam?.crestShape ?? TeamCrestShape.shield,
                        primaryColorHex:
                            homeTeam?.primaryColorHex ?? 0xFF00E676,
                        secondaryColorHex:
                            homeTeam?.secondaryColorHex ?? 0xFF0A0E17,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

                // Columna 2: Bloque Central Hub (Ancho simétrico para marcadores y badges)
                Container(
                  width: 94,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: match.status == MatchStatus.inProgress
                          ? KickPulseColors.accentLive.withValues(alpha: 0.5)
                          : KickPulseColors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCenterContent(context, l10n),
                    ],
                  ),
                ),

                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

                // Columna 3: Equipo Visitante (Flex, alineado a la izquierda)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      KickPulseTeamCrest(
                        shortCode: awayTeam?.shortCode ??
                            (awayName.length >= 3
                                ? awayName.substring(0, 3)
                                : awayName),
                        crestShape:
                            awayTeam?.crestShape ?? TeamCrestShape.shield,
                        primaryColorHex:
                            awayTeam?.primaryColorHex ?? 0xFF38BDF8,
                        secondaryColorHex:
                            awayTeam?.secondaryColorHex ?? 0xFF0A0E17,
                        size: 32,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Flexible(
                        child: Text(
                          awayName,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: KickPulseColors.textPrimary,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, AppLocalizations l10n) {
    if (match.status == MatchStatus.inProgress) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
            style: KickPulseTypography.cardTitle.copyWith(
              color: KickPulseColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: KickPulseColors.accentLive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.liveMatchBadge,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.accentLive,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (match.status == MatchStatus.completed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
            style: KickPulseTypography.cardTitle.copyWith(
              color: KickPulseColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.finalMatchBadge,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textTertiary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      );
    } else if (match.status == MatchStatus.cancelled) {
      return Text(
        l10n.cancelledMatchBadge,
        style: KickPulseTypography.captionMeta.copyWith(
          color: KickPulseColors.accentLive,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    } else {
      // Programado (scheduled)
      final timeStr = match.scheduledStartTime != null
          ? DateFormat('HH:mm').format(match.scheduledStartTime!)
          : '--:--';

      return Text(
        timeStr,
        style: KickPulseTypography.cardTitle.copyWith(
          color: KickPulseColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }
  }
}
