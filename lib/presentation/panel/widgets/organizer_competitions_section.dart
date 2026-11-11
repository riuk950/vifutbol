import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Section in Organizer Panel listing the tournaments managed by the active organizer.
class OrganizerCompetitionsSection extends ConsumerStatefulWidget {
  const OrganizerCompetitionsSection({
    super.key,
    this.onCreateTournament,
    this.onEditTournament,
    this.onChangeStatus,
    this.onDeleteTournament,
    this.onTapTournament,
  });

  final VoidCallback? onCreateTournament;
  final ValueChanged<ChampionshipTournament>? onEditTournament;
  final ValueChanged<ChampionshipTournament>? onChangeStatus;
  final ValueChanged<ChampionshipTournament>? onDeleteTournament;
  final ValueChanged<ChampionshipTournament>? onTapTournament;

  @override
  ConsumerState<OrganizerCompetitionsSection> createState() =>
      _OrganizerCompetitionsSectionState();
}

class _OrganizerCompetitionsSectionState
    extends ConsumerState<OrganizerCompetitionsSection> {
  DateTime? _lastNavigationTap;

  void _handleCreate(BuildContext context) {
    if (widget.onCreateTournament != null) {
      widget.onCreateTournament!();
    } else {
      Navigator.of(context).pushNamed('/tournaments/form');
    }
  }

  void _handleTournamentTap(
    BuildContext context,
    ChampionshipTournament tournament,
  ) {
    final now = DateTime.now();
    if (_lastNavigationTap != null &&
        now.difference(_lastNavigationTap!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _lastNavigationTap = now;

    try {
      ref
          .read(tournamentsControllerProvider.notifier)
          .selectTournament(tournament.id);
    } catch (_) {
      // Fallback in isolated test environments where controller is not mounted
    }

    if (widget.onTapTournament != null) {
      widget.onTapTournament!(tournament);
    } else {
      Navigator.of(context).pushNamed('/competitions/${tournament.id}');
    }
  }

  KickPulseBadgeVariant _statusBadgeVariant(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return KickPulseBadgeVariant.info;
      case TournamentStatus.inProgress:
        return KickPulseBadgeVariant.live;
      case TournamentStatus.finished:
        return KickPulseBadgeVariant.neutral;
    }
  }

  String _statusLabel(TournamentStatus status, AppLocalizations l10n) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return l10n.tournamentStatusOpenRegistration;
      case TournamentStatus.inProgress:
        return l10n.tournamentStatusInProgress;
      case TournamentStatus.finished:
        return l10n.tournamentStatusFinished;
    }
  }

  String _formatLabel(TournamentFormat format, AppLocalizations l10n) {
    switch (format) {
      case TournamentFormat.league:
        return l10n.tournamentFormatLeague;
      case TournamentFormat.knockoutCup:
        return l10n.tournamentFormatKnockout;
      case TournamentFormat.mixedGroupsAndKnockout:
        return l10n.tournamentFormatMixed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tournaments = ref.watch(organizerTournamentsProvider);

    return Column(
      key: const Key('organizer_competitions_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.organizerCompetitionsSectionTitle,
                style: KickPulseTypography.sectionHeader,
              ),
            ),
            const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tournaments.length}',
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
        KickPulseButton(
          key: const Key('organizer_action_create_competition'),
          label: l10n.organizerCompetitionsCreateAction,
          icon: const Icon(Icons.add, size: 18),
          variant: KickPulseButtonVariant.primary,
          onPressed: () async {
            _handleCreate(context);
          },
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        if (tournaments.isEmpty)
          KickPulseCard(
            key: const Key('organizer_competitions_empty_state'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceLg,
                horizontal: KickPulseRadiiSpacing.spaceMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: KickPulseColors.textSecondary,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    l10n.organizerCompetitionsEmptyTitle,
                    style: KickPulseTypography.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    l10n.organizerCompetitionsEmptySubtitle,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  KickPulseButton(
                    key: const Key('organizer_action_empty_create_competition'),
                    label: l10n.organizerCompetitionsEmptyCreateButton,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    variant: KickPulseButtonVariant.primary,
                    onPressed: () async {
                      _handleCreate(context);
                    },
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tournaments.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return _buildTournamentCard(context, tournament, l10n);
            },
          ),
      ],
    );
  }

  Widget _buildTournamentCard(
    BuildContext context,
    ChampionshipTournament tournament,
    AppLocalizations l10n,
  ) {
    return KickPulseCard(
      key: Key('organizer_competition_card_${tournament.id}'),
      onTap: () => _handleTournamentTap(context, tournament),
      child: Padding(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tournament.name,
                    style: KickPulseTypography.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key(
                    'organizer_competition_menu_button_${tournament.id}',
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    color: KickPulseColors.textSecondary,
                  ),
                  color: KickPulseColors.surfaceElevated,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEditTournament?.call(tournament);
                        break;
                      case 'status':
                        widget.onChangeStatus?.call(tournament);
                        break;
                      case 'delete':
                        widget.onDeleteTournament?.call(tournament);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      key: Key(
                        'organizer_competition_menu_edit_${tournament.id}',
                      ),
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: KickPulseColors.textPrimary,
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                          Expanded(
                            child: Text(
                              l10n.organizerCompetitionsMenuEdit,
                              style: KickPulseTypography.bodyPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      key: Key(
                        'organizer_competition_menu_status_${tournament.id}',
                      ),
                      value: 'status',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sync_alt,
                            size: 18,
                            color: KickPulseColors.accentPrimary,
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                          Expanded(
                            child: Text(
                              l10n.organizerCompetitionsMenuStatus,
                              style: KickPulseTypography.bodyPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      key: Key(
                        'organizer_competition_menu_delete_${tournament.id}',
                      ),
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: KickPulseColors.accentLive,
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                          Expanded(
                            child: Text(
                              l10n.organizerCompetitionsMenuDelete,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                color: KickPulseColors.accentLive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Wrap(
              spacing: KickPulseRadiiSpacing.spaceXs,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KickPulseBadge(
                  key: Key(
                    'organizer_competition_status_badge_${tournament.id}',
                  ),
                  label: _statusLabel(tournament.status, l10n),
                  variant: _statusBadgeVariant(tournament.status),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tournament.category,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatLabel(tournament.format, l10n),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
