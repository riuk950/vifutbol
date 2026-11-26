import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/standings_calculator_service.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/team_detail_screen.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Tab view presenting the enrolled teams in a competition.
///
/// Supports group segmentation for [TournamentFormat.mixedGroupsAndKnockout],
/// alphabetical list for leagues/cups, empty state, team navigation,
/// and Organizer group relocation and team removal.
class CompetitionTeamsTabView extends ConsumerWidget {
  final String tournamentId;
  final Future<void> Function()? onRefresh;

  const CompetitionTeamsTabView({
    super.key,
    required this.tournamentId,
    this.onRefresh,
  });

  void _onTeamTapped(BuildContext context, WidgetRef ref, TournamentTeam team) {
    ref.read(teamsControllerProvider.notifier).selectTeam(team.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(teamId: team.id),
        settings: RouteSettings(name: '/teams/${team.id}'),
      ),
    );
  }

  Future<void> _showMoveGroupDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    AppLocalizations l10n,
  ) async {
    final groupCount = tournament.rules.groupStageConfig.groupCount;
    final groups = StandingsCalculatorService.buildValidGroupNames(groupCount);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('competition_move_group_dialog'),
          backgroundColor: KickPulseColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.cardRadius,
            ),
          ),
          title: Text(
            l10n.competitionMoveGroupDialogTitle,
            style: KickPulseTypography.cardTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: groups.map((g) {
                final isCurrentGroup = team.groupName == g;
                return ListTile(
                  key: Key('competition_move_group_option_$g'),
                  title: Text(
                    g,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: isCurrentGroup
                          ? KickPulseColors.accentPrimary
                          : KickPulseColors.textPrimary,
                      fontWeight: isCurrentGroup
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrentGroup
                      ? const Icon(
                          Icons.check,
                          color: KickPulseColors.accentPrimary,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    final userRole = ref.read(activeUserRoleProvider);
                    final success = await ref
                        .read(teamsControllerProvider.notifier)
                        .moveTeamToGroup(
                          teamId: team.id,
                          groupName: g,
                          tournament: tournament,
                          actorRole: userRole,
                        );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.competitionMoveGroupSuccess(team.name, g),
                          ),
                          backgroundColor: KickPulseColors.accentPrimary,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRemoveTeamDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    AppLocalizations l10n,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('competition_remove_team_confirm_dialog'),
          backgroundColor: KickPulseColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.cardRadius,
            ),
          ),
          title: Text(
            l10n.competitionRemoveTeamConfirmTitle,
            style: KickPulseTypography.cardTitle,
          ),
          content: Text(
            l10n.competitionRemoveTeamConfirmMessage(team.name),
            style: KickPulseTypography.bodyPrimary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.actionCancel,
                style: const TextStyle(color: KickPulseColors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('competition_remove_team_confirm_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KickPulseColors.accentWarning,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final userRole = ref.read(activeUserRoleProvider);
                final success = await ref
                    .read(teamsControllerProvider.notifier)
                    .removeTeamFromCompetition(
                      teamId: team.id,
                      tournament: tournament,
                      actorRole: userRole,
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.competitionRemoveTeamSuccess),
                      backgroundColor: KickPulseColors.accentPrimary,
                    ),
                  );
                } else if (context.mounted) {
                  final failure = ref.read(teamsControllerProvider).lastFailure;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        failure?.message ??
                            l10n.competitionRemoveTeamHasPlayedMatchesError,
                      ),
                      backgroundColor: KickPulseColors.accentWarning,
                    ),
                  );
                }
              },
              child: Text(l10n.competitionRemoveTeamConfirmAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tournamentsCatalog = ref.watch(tournamentsControllerProvider);
    final ChampionshipTournament? tournament = tournamentsCatalog.tournaments
        .where((t) => t.id == tournamentId)
        .firstOrNull;

    final teamsState = ref.watch(teamsControllerProvider);
    final teams = teamsState.teams
        .where((t) => t.tournamentId == tournamentId)
        .toList();

    final userRole = ref.watch(activeUserRoleProvider);
    final canManage =
        RolePermissionMatrix.hasCapability(
          userRole,
          RoleCapability.manageTournaments,
        ) &&
        (tournament?.status.isEditable ?? false);

    Future<void> handleRefresh() async {
      if (onRefresh != null) {
        await onRefresh!();
      } else {
        await ref.read(teamsControllerProvider.notifier).loadTeams();
      }
    }

    if (teams.isEmpty) {
      return RefreshIndicator(
        onRefresh: handleRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                key: const Key('competition_teams_empty_state'),
                child: Padding(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 56,
                        color: KickPulseColors.textMuted,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      Text(
                        l10n.competitionTeamsEmptyTitle,
                        style: KickPulseTypography.cardTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Text(
                        l10n.competitionTeamsEmptyDescription,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isMixedGroups =
        tournament?.format == TournamentFormat.mixedGroupsAndKnockout;

    return RefreshIndicator(
      onRefresh: handleRefresh,
      child: SingleChildScrollView(
        key: const Key('competition_teams_tab_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.competitionTeamsHeaderCount(teams.length),
            key: const Key('competition_teams_header_count'),
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (isMixedGroups)
            ..._buildGroupSections(
              context,
              ref,
              tournament!,
              teams,
              canManage,
              l10n,
            )
          else
            ..._buildSimpleTeamList(
              context,
              ref,
              tournament,
              teams,
              canManage,
              l10n,
            ),
        ],
      ),
    ),
    );
  }

  List<Widget> _buildGroupSections(
    BuildContext context,
    WidgetRef ref,
    ChampionshipTournament tournament,
    List<TournamentTeam> teams,
    bool canManage,
    AppLocalizations l10n,
  ) {
    final groupCount = tournament.rules.groupStageConfig.groupCount;
    final distinctGroupNames = StandingsCalculatorService.buildValidGroupNames(
      groupCount,
    );

    final Map<String, List<TournamentTeam>> teamsByGroup = {
      for (final g in distinctGroupNames) g: <TournamentTeam>[],
    };

    for (final team in teams) {
      final effectiveGroup =
          StandingsCalculatorService.resolveEffectiveGroupName(
            team: team,
            allTournamentTeams: teams,
            groupCount: groupCount,
          );
      teamsByGroup
          .putIfAbsent(effectiveGroup, () => <TournamentTeam>[])
          .add(team);
    }

    final sortedGroupKeys = teamsByGroup.keys.toList()..sort();

    final widgets = <Widget>[];
    for (final groupName in sortedGroupKeys) {
      final groupTeams = teamsByGroup[groupName] ?? [];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: KickPulseRadiiSpacing.spaceSm,
            bottom: KickPulseRadiiSpacing.spaceSm,
          ),
          child: Row(
            children: [
              Text(
                groupName,
                key: Key('competition_team_group_header_$groupName'),
                style: KickPulseTypography.cardTitle.copyWith(
                  color: KickPulseColors.accentPrimary,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Text(
                '(${groupTeams.length})',
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

      for (final team in groupTeams) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              bottom: KickPulseRadiiSpacing.spaceSm,
            ),
            child: _buildTeamCard(
              context,
              ref,
              team,
              tournament,
              groupName,
              canManage,
              l10n,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildSimpleTeamList(
    BuildContext context,
    WidgetRef ref,
    ChampionshipTournament? tournament,
    List<TournamentTeam> teams,
    bool canManage,
    AppLocalizations l10n,
  ) {
    final sortedTeams = [...teams]..sort((a, b) => a.name.compareTo(b.name));
    return sortedTeams.map((team) {
      return Padding(
        padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
        child: _buildTeamCard(
          context,
          ref,
          team,
          tournament,
          null,
          canManage,
          l10n,
        ),
      );
    }).toList();
  }

  Widget _buildTeamCard(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament? tournament,
    String? groupName,
    bool canManage,
    AppLocalizations l10n,
  ) {
    final (statusLabel, badgeVariant) = switch (team.eligibilityStatus) {
      TeamEligibilityStatus.pendingVerification => (
        l10n.teamEligibilityPendingVerification,
        KickPulseBadgeVariant.warning,
      ),
      TeamEligibilityStatus.eligible => (
        l10n.teamEligibilityEligible,
        KickPulseBadgeVariant.dev,
      ),
    };

    final rosterCountText = team.players.length < 11
        ? l10n.competitionTeamPlayersIncomplete(team.players.length)
        : l10n.competitionTeamPlayersComplete(team.players.length);

    return KickPulseCard(
      key: Key('competition_team_card_${team.id}'),
      onTap: () => _onTeamTapped(context, ref, team),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KickPulseTeamCrest(
                shortCode: team.shortCode,
                crestShape: team.crestShape,
                primaryColorHex: team.primaryColorHex,
                secondaryColorHex: team.secondaryColorHex,
                crestUrl: team.crestUrl,
                size: 44.0,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: KickPulseTypography.bodyPrimary.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        Text(
                          team.shortCode,
                          style: KickPulseTypography.captionMeta.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KickPulseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                    Text(
                      rosterCountText,
                      key: Key('competition_team_players_count_${team.id}'),
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: team.players.length < 11
                            ? KickPulseColors.accentWarning
                            : KickPulseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                    Wrap(
                      spacing: KickPulseRadiiSpacing.spaceXs,
                      runSpacing: KickPulseRadiiSpacing.spaceXs,
                      children: [
                        KickPulseBadge(
                          key: Key('competition_team_status_badge_${team.id}'),
                          label: statusLabel,
                          variant: badgeVariant,
                        ),
                        if (groupName != null)
                          KickPulseBadge(
                            key: Key('competition_team_group_badge_${team.id}'),
                            label: groupName,
                            variant: KickPulseBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage && tournament != null) ...[
                if (groupName != null)
                  IconButton(
                    key: Key('competition_team_move_group_${team.id}'),
                    tooltip: l10n.competitionTeamMoveGroupTooltip,
                    icon: const Icon(
                      Icons.swap_horiz,
                      size: 20,
                      color: KickPulseColors.accentPrimary,
                    ),
                    onPressed: ref.watch(teamsControllerProvider).isSaving
                        ? null
                        : () => _showMoveGroupDialog(
                              context,
                              ref,
                              team,
                              tournament,
                              l10n,
                            ),
                  ),
                IconButton(
                  key: Key('competition_team_remove_${team.id}'),
                  tooltip: l10n.competitionTeamRemoveTooltip,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: KickPulseColors.accentWarning,
                  ),
                  onPressed: ref.watch(teamsControllerProvider).isSaving
                      ? null
                      : () => _showRemoveTeamDialog(
                            context,
                            ref,
                            team,
                            tournament,
                            l10n,
                          ),
                ),
              ],
            ],
          ),
          if (canManage && tournament != null)
            Padding(
              padding: const EdgeInsets.only(
                top: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Wrap(
                spacing: KickPulseRadiiSpacing.spaceXs,
                runSpacing: KickPulseRadiiSpacing.spaceXs,
                children: [
                  if (!team.isEligible)
                    KickPulseButton(
                      key: Key('competition_team_action_approve_${team.id}'),
                      label: l10n.teamEligibilityActionApprove,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      variant: KickPulseButtonVariant.outline,
                      onPressed: ref.watch(teamsControllerProvider).isSaving
                          ? null
                          : () => _handleApproveTeam(
                                context,
                                ref,
                                team,
                                tournament,
                                l10n,
                              ),
                    ),
                  if (team.isEligible)
                    KickPulseButton(
                      key: Key('competition_team_action_revoke_${team.id}'),
                      label: l10n.teamEligibilityActionRevoke,
                      icon: const Icon(Icons.block, size: 18),
                      variant: KickPulseButtonVariant.secondary,
                      onPressed: ref.watch(teamsControllerProvider).isSaving
                          ? null
                          : () => _handleRevokeTeam(
                                context,
                                ref,
                                team,
                                tournament,
                                l10n,
                              ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleApproveTeam(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    AppLocalizations l10n,
  ) async {
    if (ref.read(teamsControllerProvider).isSaving) return;
    if (team.players.length < 11) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('competition_team_insufficient_quota_dialog'),
          backgroundColor: KickPulseColors.surfaceBase,
          title: Text(
            l10n.teamEligibilityQuotaInsufficientTitle,
            style: KickPulseTypography.screenTitle.copyWith(fontSize: 18),
          ),
          content: Text(
            l10n.teamEligibilityQuotaInsufficientMessage(team.players.length),
            style: KickPulseTypography.bodyPrimary,
          ),
          actions: [
            TextButton(
              key: const Key('competition_team_dialog_confirm_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.teamEligibilityActionUnderstood,
                style: KickPulseTypography.bodyPrimary.copyWith(
                  color: KickPulseColors.accentPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final userRole = ref.read(activeUserRoleProvider);
    final success = await ref
        .read(teamsControllerProvider.notifier)
        .approveTeamEligibility(
          teamId: team.id,
          tournament: tournament,
          actorRole: userRole,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamEligibilityApprovedSuccess),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
    } else {
      final state = ref.read(teamsControllerProvider);
      final msg = state.lastFailure?.message ?? 'Error al habilitar el equipo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: KickPulseColors.accentWarning,
        ),
      );
    }
  }

  Future<void> _handleRevokeTeam(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    AppLocalizations l10n,
  ) async {
    if (ref.read(teamsControllerProvider).isSaving) return;
    final userRole = ref.read(activeUserRoleProvider);
    final success = await ref
        .read(teamsControllerProvider.notifier)
        .revokeTeamEligibility(
          teamId: team.id,
          tournament: tournament,
          actorRole: userRole,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamEligibilityRevokedSuccess),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
    } else {
      final state = ref.read(teamsControllerProvider);
      final msg =
          state.lastFailure?.message ?? 'Error al inhabilitar el equipo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: KickPulseColors.accentWarning,
        ),
      );
    }
  }
}
