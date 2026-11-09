import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/standings/widgets/player_performance_profile_card.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

/// Tab view displaying the complete official squad roster of a team (`HU 14.3`),
/// organized vertically into 4 fixed tactical blocks:
/// - Porteros (`goalkeeper`)
/// - Defensas (`defender`)
/// - Centrocampistas (`midfielder`)
/// - Delanteros (`forward`)
class TeamSquadTabView extends ConsumerWidget {
  final String teamId;

  const TeamSquadTabView({super.key, required this.teamId});

  String _positionLabel(AppLocalizations l10n, PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return l10n.teamSquadPositionGoalkeeper;
      case PlayerPosition.defender:
        return l10n.teamSquadPositionDefender;
      case PlayerPosition.midfielder:
        return l10n.teamSquadPositionMidfielder;
      case PlayerPosition.forward:
        return l10n.teamSquadPositionForward;
    }
  }

  String _sectionTitle(AppLocalizations l10n, PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return l10n.teamSquadGoalkeepersSectionTitle;
      case PlayerPosition.defender:
        return l10n.teamSquadDefendersSectionTitle;
      case PlayerPosition.midfielder:
        return l10n.teamSquadMidfieldersSectionTitle;
      case PlayerPosition.forward:
        return l10n.teamSquadForwardsSectionTitle;
    }
  }

  void _openPlayerProfileSheet(
    BuildContext context,
    TeamSquadPlayerItem item,
    List<PlayerPerformanceProfile> allProfiles,
  ) {
    var currentProfile = item.performanceProfile;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: PlayerPerformanceProfileCard(
                    profile: currentProfile,
                    allTournamentPlayers: allProfiles,
                    onPlayerSelected: (selectedId) {
                      final found = allProfiles.firstWhere(
                        (p) => p.playerId == selectedId,
                        orElse: () => currentProfile,
                      );
                      setModalState(() {
                        currentProfile = found;
                      });
                    },
                    onClose: () => Navigator.of(modalContext).pop(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTacticalBlock({
    required BuildContext context,
    required AppLocalizations l10n,
    required PlayerPosition position,
    required List<TeamSquadPlayerItem> players,
    required List<PlayerPerformanceProfile> allProfiles,
  }) {
    final title = _sectionTitle(l10n, position);
    final headerKey = Key('team_squad_header_${position.name}');
    final emptyKey = Key('team_squad_empty_${position.name}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KickPulseRadiiSpacing.spaceSm,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: [
              Text(
                title,
                key: headerKey,
                style: KickPulseTypography.sectionHeader.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KickPulseColors.textPrimary,
                ),
              ),
              KickPulseBadge(
                label: '${players.length}',
                variant: KickPulseBadgeVariant.neutral,
              ),
            ],
          ),
        ),

        // Content: Empty state or Player List
        if (players.isEmpty)
          Container(
            key: emptyKey,
            width: double.infinity,
            margin: const EdgeInsets.only(
              bottom: KickPulseRadiiSpacing.spaceMd,
            ),
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceElevated,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: KickPulseColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Expanded(
                  child: Text(
                    l10n.teamSquadEmptyPositionMessage,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...players.map((item) {
            final p = item.player;
            final posLabel = _positionLabel(l10n, p.position);
            final eligibilityLabel = item.isEligible
                ? l10n.teamSquadPlayerStatusEligible
                : l10n.teamSquadPlayerStatusSuspended;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Semantics(
                button: true,
                label:
                    'Dorsal ${p.shirtNumber}, ${p.fullName}, $posLabel, $eligibilityLabel',
                child: KickPulseCard(
                  key: Key('team_squad_player_item_${p.id}'),
                  onTap: () =>
                      _openPlayerProfileSheet(context, item, allProfiles),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tabular shirt number badge
                        Container(
                          key: Key('team_squad_player_shirt_${p.id}'),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: KickPulseColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              KickPulseRadiiSpacing.chipRadius,
                            ),
                            border: Border.all(
                              color: KickPulseColors.borderSubtle,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${p.shirtNumber}',
                            style:
                                KickPulseTypography.statMetric(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: KickPulseColors.accentElectric,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

                        // Player info: Full name + Badges Wrap
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.fullName,
                                style: KickPulseTypography.bodyPrimary.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KickPulseColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: KickPulseRadiiSpacing.spaceXs,
                                runSpacing: KickPulseRadiiSpacing.spaceXs,
                                children: [
                                  KickPulseBadge(
                                    key: Key(
                                      'team_squad_player_position_badge_${p.id}',
                                    ),
                                    label: posLabel,
                                    variant: KickPulseBadgeVariant.neutral,
                                  ),
                                  KickPulseBadge(
                                    key: Key(
                                      'team_squad_player_eligibility_badge_${p.id}',
                                    ),
                                    label: eligibilityLabel,
                                    variant: item.isEligible
                                        ? KickPulseBadgeVariant.success
                                        : KickPulseBadgeVariant.live,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),

                        // Navigation chevron
                        const Icon(
                          Icons.chevron_right,
                          color: KickPulseColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(teamSquadRosterProvider(teamId));

    if (!roster.hasPlayers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: KickPulseStateView<void>(
            key: const Key('team_squad_empty_state'),
            state: UiEmptyState<void>(
              message: l10n.teamSquadEmptyGlobalTitle,
              description: l10n.teamSquadEmptyGlobalMessage,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      children: [
        _buildTacticalBlock(
          context: context,
          l10n: l10n,
          position: PlayerPosition.goalkeeper,
          players: roster.goalkeepers,
          allProfiles: roster.allProfiles,
        ),
        _buildTacticalBlock(
          context: context,
          l10n: l10n,
          position: PlayerPosition.defender,
          players: roster.defenders,
          allProfiles: roster.allProfiles,
        ),
        _buildTacticalBlock(
          context: context,
          l10n: l10n,
          position: PlayerPosition.midfielder,
          players: roster.midfielders,
          allProfiles: roster.allProfiles,
        ),
        _buildTacticalBlock(
          context: context,
          l10n: l10n,
          position: PlayerPosition.forward,
          players: roster.forwards,
          allProfiles: roster.allProfiles,
        ),
      ],
    );
  }
}
