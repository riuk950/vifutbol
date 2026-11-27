import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_positional_roster_section.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Dynamic panel content for [UserRole.coach].
class CoachPanelContent extends ConsumerWidget {
  const CoachPanelContent({super.key});

  Widget _buildMetricCard({
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
              Icon(icon, size: 24, color: iconColor),
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

  void _onLineupAction(
    BuildContext context,
    TournamentTeam? team,
    AppLocalizations l10n,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            team != null
                ? '${l10n.coachActionMatchLineup}: ${team.name}'
                : l10n.coachActionMatchLineup,
          ),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
  }

  void _onManageRosterAction(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam? team,
    AppLocalizations l10n,
  ) {
    if (team != null) {
      ref.read(teamsControllerProvider.notifier).selectTeam(team.id);
      Navigator.of(context).pushNamed('/tournaments/teams/detail');
    }
  }

  Future<void> _confirmDeleteTeam(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceElevated,
        title: Text(
          l10n.coachPanelDeleteTeamTitle,
          style: KickPulseTypography.cardTitle,
        ),
        content: Text(
          l10n.coachPanelDeleteTeamMessage(team.name),
          style: KickPulseTypography.bodyPrimary.copyWith(
            color: KickPulseColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('coach_delete_team_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            key: const Key('coach_delete_team_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.coachPanelDeleteTeamConfirm,
              style: const TextStyle(color: KickPulseColors.accentLive),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authState = ref.read(authControllerProvider);
    final tournamentsState = ref.read(tournamentsControllerProvider);
    final tournament = team.tournamentId.trim().isNotEmpty
        ? tournamentsState.tournaments
              .where((t) => t.id == team.tournamentId)
              .firstOrNull
        : null;
    final actorUserId = authState.session?.user.id ?? 'coach-seed-1';
    final actorRole = authState.session?.user.activeRole ?? UserRole.coach;

    final success = await ref
        .read(teamsControllerProvider.notifier)
        .deleteCoachTeam(
          team: team,
          tournament: tournament,
          actorUserId: actorUserId,
          actorRole: actorRole,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.coachPanelDeleteTeamSuccess(team.name)),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
    } else {
      final failure = ref.read(teamsControllerProvider).lastFailure;
      final errorMessage = switch (failure) {
        TeamEligibilityValidationFailure(
          code: TeamEligibilityErrorCode.teamInActiveOrFinishedTournament,
        ) =>
          l10n.coachPanelDeleteTeamBlockedTournament,
        TeamEligibilityValidationFailure(
          code: TeamEligibilityErrorCode.teamHasPlayedMatches,
        ) =>
          l10n.coachPanelDeleteTeamBlockedMatches,
        _ => failure?.message ?? l10n.coachPanelDeleteTeamBlockedTournament,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
    }
  }

  Widget _buildCoachTeamCard(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam item,
    bool isSelected,
    bool isSaving,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
      decoration: BoxDecoration(
        borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
        border: Border.all(
          color: isSelected
              ? KickPulseColors.accentPrimary
              : KickPulseColors.borderSubtle,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: Key('coach_team_card_${item.id}'),
        borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
        onTap: () =>
            ref.read(teamsControllerProvider.notifier).selectTeam(item.id),
        child: KickPulseCard(
          child: Row(
            children: [
              KickPulseTeamCrest(
                shortCode: item.shortCode,
                primaryColorHex: item.primaryColorHex,
                secondaryColorHex: item.secondaryColorHex,
                crestUrl: item.crestUrl,
                size: 48,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: KickPulseTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(item.primaryColorHex),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(item.secondaryColorHex),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          item.shortCode,
                          style: KickPulseTypography.captionMeta.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.delegateName != null &&
                            item.delegateName!.trim().isNotEmpty)
                          Text(
                            '· ${item.delegateName!.trim()}',
                            style: KickPulseTypography.captionMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.players.length} ${l10n.coachMetricTotalPlayers.toLowerCase()}',
                      style: KickPulseTypography.captionMeta,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('coach_team_edit_${item.id}'),
                tooltip: l10n.coachPanelEditTeamAction,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: KickPulseColors.accentElectric,
                ),
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pushNamed('/teams/edit', arguments: item),
              ),
              IconButton(
                key: Key('coach_team_delete_${item.id}'),
                tooltip: l10n.coachPanelDeleteTeamAction,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(
                  Icons.delete_outline,
                  color: KickPulseColors.accentLive,
                ),
                onPressed: isSaving
                    ? null
                    : () => _confirmDeleteTeam(context, ref, item, l10n),
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
    final coachTeams = ref.watch(coachTeamsProvider);
    final teamsState = ref.watch(teamsControllerProvider);
    final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

    if (coachTeams.isEmpty) {
      return SingleChildScrollView(
        key: const Key('coach_panel_content'),
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KickPulseCard(
              key: const Key('coach_no_team_card'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KickPulseRadiiSpacing.spaceXl,
                  horizontal: KickPulseRadiiSpacing.spaceLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: KickPulseColors.accentPrimary,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                    Text(
                      l10n.coachNoTeamTitle,
                      style: KickPulseTypography.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      l10n.coachNoTeamDescription,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    KickPulseButton(
                      key: const Key('coach_action_register_team_empty'),
                      label: l10n.coachActionRegisterTeamEmpty,
                      icon: const Icon(Icons.add, size: 20),
                      variant: KickPulseButtonVariant.primary,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/teams/create'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final team =
        coachTeams
            .where((t) => t.id == teamsState.selectedTeamId)
            .firstOrNull ??
        coachTeams.first;

    final players = team.players;
    final totalPlayers = players.length;
    final eligiblePlayersCount = players.where((p) => p.isEligible).length;
    final suspendedPlayersCount = players.where((p) => !p.isEligible).length;

    // Next match for this team
    final teamMatches = matchesCatalogState.matches
        .where((m) => m.homeTeamId == team.id || m.awayTeamId == team.id)
        .toList();

    final nextMatch = teamMatches.isNotEmpty ? teamMatches.first : null;

    return RepaintBoundary(
      child: SingleChildScrollView(
        key: const Key('coach_panel_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coach Created Teams List
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: [
              Text(
                l10n.coachPanelTeamsListTitle,
                style: KickPulseTypography.sectionHeader,
              ),
              TextButton.icon(
                key: const Key('coach_action_add_another_team'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/teams/create'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.coachPanelAddAnotherTeamAction),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
          Column(
            key: const Key('coach_panel_teams_list'),
            children: coachTeams
                .map(
                  (item) => _buildCoachTeamCard(
                    context,
                    ref,
                    item,
                    item.id == team.id,
                    teamsState.isSaving,
                    l10n,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Squad Metrics Cards
          Row(
            children: [
              _buildMetricCard(
                key: const Key('coach_metric_total_players'),
                label: l10n.coachMetricTotalPlayers,
                value: '$totalPlayers',
                icon: Icons.groups_outlined,
                iconColor: KickPulseColors.textPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('coach_metric_eligible_players'),
                label: l10n.coachMetricEligiblePlayers,
                value: '$eligiblePlayersCount',
                icon: Icons.check_circle_outline,
                iconColor: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('coach_metric_suspended_players'),
                label: l10n.coachMetricSuspendedPlayers,
                value: '$suspendedPlayersCount',
                icon: Icons.warning_amber_outlined,
                iconColor: KickPulseColors.accentWarning,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Next Match Card
          Text(
            l10n.coachNextMatchTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            key: const Key('coach_next_match_card'),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
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
                            : l10n.coachNoUpcomingMatch,
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
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Quick Actions Section
          Text(
            l10n.coachQuickActionsTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KickPulseButton(
                  key: const Key('coach_action_match_lineup'),
                  label: l10n.coachActionMatchLineup,
                  icon: const Icon(Icons.format_list_numbered, size: 20),
                  variant: KickPulseButtonVariant.primary,
                  onPressed: () async {
                    _onLineupAction(context, team, l10n);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                KickPulseButton(
                  key: const Key('coach_action_manage_roster'),
                  label: l10n.coachActionManageRoster,
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  variant: KickPulseButtonVariant.secondary,
                  onPressed: () async {
                    _onManageRosterAction(context, ref, team, l10n);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Positional Roster Section (HU 20.2)
          CoachPositionalRosterSection(teamId: team.id),
        ],
      ),
    ),
    );
  }
}
