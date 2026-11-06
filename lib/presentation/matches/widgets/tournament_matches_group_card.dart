import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/matches/widgets/match_center_card.dart';

/// Tarjeta que agrupa una competición y sus partidos programados o disputados en la fecha.
class TournamentMatchesGroupCard extends ConsumerWidget {
  final TournamentMatchesGroup group;
  final ValueChanged<ChampionshipMatch>? onMatchTap;
  final VoidCallback? onTournamentTap;

  const TournamentMatchesGroupCard({
    super.key,
    required this.group,
    this.onMatchTap,
    this.onTournamentTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = group.tournament;
    final teamsState = ref.watch(teamsControllerProvider);
    final teamsMap = {for (final team in teamsState.teams) team.id: team};

    return Semantics(
      container: true,
      label: 'Competición: ${tournament.name}, ${tournament.category}',
      child: Container(
        margin: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceMd),
        decoration: BoxDecoration(
          color: KickPulseColors.surfaceBase,
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          border: Border.all(color: KickPulseColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header de la competición
            Material(
              color: KickPulseColors.surfaceElevated,
              child: InkWell(
                onTap: onTournamentTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceMd,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: KickPulseColors.surfaceBase,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: KickPulseColors.accentWarning,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: KickPulseTypography.cardTitle.copyWith(
                                color: KickPulseColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tournament.category,
                              style: KickPulseTypography.captionMeta.copyWith(
                                color: KickPulseColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: KickPulseColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Lista de partidos con diseño simétrico MatchCenterCard
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              itemCount: group.matches.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              itemBuilder: (context, index) {
                final match = group.matches[index];
                return MatchCenterCard(
                  key: Key('match_center_card_${match.id}'),
                  match: match,
                  homeTeam: teamsMap[match.homeTeamId],
                  awayTeam: teamsMap[match.awayTeamId],
                  onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
