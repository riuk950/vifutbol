import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';

/// Modal bottom sheet allowing the Organizer to select an active/editable tournament
/// before initiating fixture generation.
class SelectTournamentForFixtureSheet extends ConsumerWidget {
  final List<ChampionshipTournament> tournaments;
  final ValueChanged<ChampionshipTournament> onTournamentSelected;

  const SelectTournamentForFixtureSheet({
    super.key,
    required this.tournaments,
    required this.onTournamentSelected,
  });

  static Future<ChampionshipTournament?> show({
    required BuildContext context,
    required List<ChampionshipTournament> tournaments,
  }) {
    return showModalBottomSheet<ChampionshipTournament>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectTournamentForFixtureSheet(
        tournaments: tournaments,
        onTournamentSelected: (selected) {
          Navigator.of(ctx).pop(selected);
        },
      ),
    );
  }

  (String, KickPulseBadgeVariant) _statusBadgeInfo(
    TournamentStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return (
          l10n.tournamentStatusOpenRegistration,
          KickPulseBadgeVariant.dev,
        );
      case TournamentStatus.inProgress:
        return (l10n.tournamentStatusInProgress, KickPulseBadgeVariant.live);
      case TournamentStatus.finished:
        return (l10n.tournamentStatusFinished, KickPulseBadgeVariant.neutral);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teamsState = ref.watch(teamsControllerProvider);
    final allTeams = teamsState.teams;

    return Container(
      key: const Key('select_tournament_for_fixture_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceMd,
        vertical: KickPulseRadiiSpacing.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KickPulseColors.accentPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alt_route,
                  color: KickPulseColors.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectTournamentForFixtureTitle,
                      style: KickPulseTypography.sectionHeader.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.selectTournamentForFixtureSubtitle,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Tournament List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tournaments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                final (statusLabel, statusVariant) = _statusBadgeInfo(
                  tournament.status,
                  l10n,
                );

                final eligibleTeamsCount = allTeams
                    .where(
                      (t) => t.tournamentId == tournament.id && t.isEligible,
                    )
                    .length;

                return InkWell(
                  key: Key('select_tournament_fixture_item_${tournament.id}'),
                  onTap: () => onTournamentSelected(tournament),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.cardRadius,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceMd,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.cardRadius,
                      ),
                      border: Border.all(color: KickPulseColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.name,
                                style: KickPulseTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: KickPulseRadiiSpacing.spaceSm,
                                children: [
                                  Text(
                                    tournament.category,
                                    style: KickPulseTypography.captionMeta
                                        .copyWith(
                                          color: KickPulseColors.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    '• ${l10n.selectTournamentEligibleTeamsCount(eligibleTeamsCount)}',
                                    style: KickPulseTypography.captionMeta
                                        .copyWith(
                                          color: eligibleTeamsCount >= 2
                                              ? KickPulseColors.accentElectric
                                              : KickPulseColors.accentWarning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        KickPulseBadge(
                          label: statusLabel,
                          variant: statusVariant,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: KickPulseColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
