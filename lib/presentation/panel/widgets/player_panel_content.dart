import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/panel/models/panel_presentation_models.dart';

/// Dynamic panel content for [UserRole.player].
class PlayerPanelContent extends ConsumerWidget {
  const PlayerPanelContent({super.key, this.data});

  final PlayerPanelData? data;

  Widget _buildStatCard({
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
              Icon(icon, size: 22, color: iconColor),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Resolve PlayerPanelData from override or reactive providers
    final PlayerPanelData panelData;
    if (data != null) {
      panelData = data!;
    } else {
      final authState = ref.watch(authControllerProvider);
      final currentUserId = authState.session?.user.id;
      final teamsState = ref.watch(teamsControllerProvider);
      final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

      TournamentTeam? resolvedTeam;
      RegisteredPlayer? resolvedPlayer;

      // 1. Search player matching current user id
      if (currentUserId != null && currentUserId.isNotEmpty) {
        for (final team in teamsState.teams) {
          for (final p in team.players) {
            if (p.id == currentUserId) {
              resolvedPlayer = p;
              resolvedTeam = team;
              break;
            }
          }
          if (resolvedPlayer != null) break;
        }
      }

      // 2. Fallback in guest/demo mode to first available team & player
      if (resolvedPlayer == null && teamsState.teams.isNotEmpty) {
        for (final team in teamsState.teams) {
          if (team.players.isNotEmpty) {
            resolvedTeam = team;
            resolvedPlayer = team.players.first;
            break;
          }
        }
      }

      // 3. Resolve next match for this team
      final currentTeam = resolvedTeam;
      final teamMatches = currentTeam != null
          ? matchesCatalogState.matches
                .where(
                  (m) =>
                      m.homeTeamId == currentTeam.id ||
                      m.awayTeamId == currentTeam.id,
                )
                .toList()
          : <ChampionshipMatch>[];

      final nextMatch = teamMatches.isNotEmpty ? teamMatches.first : null;

      panelData = PlayerPanelData(
        player: resolvedPlayer,
        team: resolvedTeam,
        isEligible: resolvedPlayer?.isEligible ?? true,
        goals: 0,
        assists: 0,
        yellowCards: 0,
        redCards: 0,
        matchesPlayed: 0,
        nextMatch: nextMatch,
      );
    }

    final player = panelData.player;
    final team = panelData.team;
    final isEligible = panelData.isEligible;
    final nextMatch = panelData.nextMatch;

    return SingleChildScrollView(
      key: const Key('player_panel_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Identity & Eligibility Header
          KickPulseCard(
            key: const Key('player_identity_card'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: KickPulseColors.accentPrimary.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    player != null && player.shirtNumber > 0
                        ? '#${player.shirtNumber}'
                        : '#',
                    style: KickPulseTypography.sectionHeader.copyWith(
                      color: KickPulseColors.accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player?.fullName ?? 'Jugador',
                        style: KickPulseTypography.screenTitle.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team?.name ?? 'Sin club asignado',
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      KickPulseBadge(
                        key: const Key('player_eligibility_badge'),
                        label: isEligible
                            ? l10n.playerStatusEligible
                            : l10n.playerStatusSuspended,
                        variant: isEligible
                            ? KickPulseBadgeVariant.info
                            : KickPulseBadgeVariant.live,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Season Performance Section Title
          Text(l10n.playerStatsTitle, style: KickPulseTypography.sectionHeader),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Row 1: Matches Played, Goals, Assists
          Row(
            children: [
              _buildStatCard(
                key: const Key('player_stat_matches_played'),
                label: l10n.playerStatMatchesPlayed,
                value: '${panelData.matchesPlayed}',
                icon: Icons.sports_soccer,
                iconColor: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildStatCard(
                key: const Key('player_stat_goals'),
                label: l10n.playerStatGoals,
                value: '${panelData.goals}',
                icon: Icons.emoji_events_outlined,
                iconColor: KickPulseColors.accentWarning,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildStatCard(
                key: const Key('player_stat_assists'),
                label: l10n.playerStatAssists,
                value: '${panelData.assists}',
                icon: Icons.handshake_outlined,
                iconColor: KickPulseColors.accentElectric,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),

          // Row 2: Yellow Cards, Red Cards
          Row(
            children: [
              _buildStatCard(
                key: const Key('player_stat_yellow_cards'),
                label: l10n.playerStatYellowCards,
                value: '${panelData.yellowCards}',
                icon: Icons.style,
                iconColor: KickPulseColors.accentWarning,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildStatCard(
                key: const Key('player_stat_red_cards'),
                label: l10n.playerStatRedCards,
                value: '${panelData.redCards}',
                icon: Icons.style,
                iconColor: KickPulseColors.accentLive,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Next Club Match Card
          Text(
            l10n.playerNextMatchTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            key: const Key('player_next_match_card'),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
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
                            : l10n.playerNoUpcomingMatch,
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
        ],
      ),
    );
  }
}
