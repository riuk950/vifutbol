import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Screen displaying the official squad roster of a team, player registration,
/// quota progress, and organizer-only eligibility approval.
class TeamRosterDetailScreen extends ConsumerWidget {
  const TeamRosterDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeRole = ref.watch(activeUserRoleProvider);
    final teamsState = ref.watch(teamsControllerProvider);
    final team = teamsState.selectedTeam;
    final tournamentsState = ref.watch(tournamentsControllerProvider);

    if (team == null) {
      return Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          title: Text(l10n.teamRosterTitle),
        ),
        body: Center(
          child: Text(
            l10n.teamsEmptyTitle,
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
        ),
      );
    }

    final tournament = tournamentsState.tournaments.firstWhere(
      (t) => t.id == team.tournamentId,
      orElse: () =>
          tournamentsState.selectedTournament ??
          ChampionshipTournament(
            id: team.tournamentId,
            name: 'Campeonato',
            category: 'Libre',
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 90)),
            format: TournamentFormat.league,
            updatedAt: DateTime.now(),
          ),
    );

    final canManageRoster =
        (RolePermissionMatrix.hasCapability(
              activeRole,
              RoleCapability.manageTeamRoster,
            ) ||
            RolePermissionMatrix.hasCapability(
              activeRole,
              RoleCapability.manageTournaments,
            ) ||
            RolePermissionMatrix.hasCapability(
              activeRole,
              RoleCapability.approveRegistrations,
            )) &&
        tournament.status == TournamentStatus.openRegistration;

    final canApproveEligibility =
        RolePermissionMatrix.hasCapability(
          activeRole,
          RoleCapability.approveRegistrations,
        ) &&
        tournament.status == TournamentStatus.openRegistration;

    final meetsMinQuota =
        team.players.length >= tournament.rules.minPlayersPerTeam;
    final withinMaxQuota =
        team.players.length <= tournament.rules.maxPlayersPerTeam;
    final isReadyOrEligible =
        team.eligibilityStatus == TeamEligibilityStatus.eligible;

    final (statusLabel, badgeVariant) = switch (team.eligibilityStatus) {
      TeamEligibilityStatus.pendingQuota => (
        l10n.teamEligibilityPendingQuota,
        KickPulseBadgeVariant.warning,
      ),
      TeamEligibilityStatus.readyForApproval => (
        l10n.teamEligibilityReadyForApproval,
        KickPulseBadgeVariant.info,
      ),
      TeamEligibilityStatus.eligible => (
        l10n.teamEligibilityEligible,
        KickPulseBadgeVariant.dev,
      ),
    };

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          l10n.teamRosterTitle,
          style: KickPulseTypography.screenTitle.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header Card
            KickPulseCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      KickPulseTeamCrest(
                        shortCode: team.shortCode,
                        crestShape: team.crestShape,
                        primaryColorHex: team.primaryColorHex,
                        secondaryColorHex: team.secondaryColorHex,
                        size: 60.0,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: KickPulseTypography.cardTitle.copyWith(
                                color: KickPulseColors.textPrimary,
                              ),
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceXs,
                            ),
                            KickPulseBadge(
                              label: statusLabel,
                              variant: badgeVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  // Quota Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value:
                          (team.players.length /
                                  (tournament.rules.maxPlayersPerTeam > 0
                                      ? tournament.rules.maxPlayersPerTeam
                                      : 1))
                              .clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: KickPulseColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        meetsMinQuota
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.accentWarning,
                      ),
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.teamsQuotaProgress(
                          team.players.length,
                          tournament.rules.minPlayersPerTeam,
                          tournament.rules.maxPlayersPerTeam,
                        ),
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                      ),
                      if (team.players.length >=
                          tournament.rules.maxPlayersPerTeam)
                        Text(
                          l10n.teamErrorMaxPlayersQuotaReached,
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentWarning,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

            // Actions for Organizer and Coach
            Padding(
              padding: const EdgeInsets.only(
                bottom: KickPulseRadiiSpacing.spaceMd,
              ),
              child: Column(
                children: [
                  // Open Lineup & Internal Tracking Button
                  KickPulseButton(
                    key: const Key('open_team_lineup_tracking_button'),
                    label: l10n.lineupOpenAction,
                    icon: const Icon(Icons.sports_soccer, size: 18),
                    variant: KickPulseButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () async {
                      Navigator.pushNamed(context, '/tournaments/teams/lineup');
                    },
                  ),
                  if (canManageRoster ||
                      (canApproveEligibility && !isReadyOrEligible)) ...[
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Row(
                      children: [
                        if (canManageRoster)
                          Expanded(
                            child: KickPulseButton(
                              key: const Key('enroll_player_button'),
                              label: l10n.teamEnrollPlayerAction,
                              icon: const Icon(Icons.person_add, size: 18),
                              onPressed: () async {
                                _showPlayerFormDialog(
                                  context,
                                  ref,
                                  team,
                                  tournament,
                                  activeRole,
                                  l10n,
                                );
                              },
                            ),
                          ),
                        if (canManageRoster &&
                            canApproveEligibility &&
                            !isReadyOrEligible)
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        if (canApproveEligibility && !isReadyOrEligible)
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('approve_team_eligibility_button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: meetsMinQuota && withinMaxQuota
                                    ? KickPulseColors.accentPrimary
                                    : KickPulseColors.surfaceSubtle,
                                foregroundColor: meetsMinQuota && withinMaxQuota
                                    ? Colors.black
                                    : KickPulseColors.textMuted,
                                padding: const EdgeInsets.symmetric(
                                  vertical: KickPulseRadiiSpacing.spaceSm,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      KickPulseRadiiSpacing.chipBorderRadius,
                                ),
                              ),
                              icon: const Icon(Icons.verified),
                              label: Text(l10n.teamApproveEligibilityAction),
                              onPressed:
                                  (meetsMinQuota &&
                                      withinMaxQuota &&
                                      !teamsState.isSaving)
                                  ? () async {
                                      final success = await ref
                                          .read(
                                            teamsControllerProvider.notifier,
                                          )
                                          .approveTeamEligibility(
                                            teamId: team.id,
                                            tournament: tournament,
                                            actorRole: activeRole,
                                          );
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.teamEligibilityApprovedSuccess,
                                            ),
                                            backgroundColor:
                                                KickPulseColors.accentPrimary,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Roster Header
            Text(
              l10n.teamRosterSubtitle,
              style: KickPulseTypography.sectionHeader.copyWith(
                color: KickPulseColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

            if (team.players.isEmpty)
              KickPulseCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: KickPulseRadiiSpacing.spaceLg,
                  ),
                  child: Center(
                    child: Text(
                      l10n.teamRosterEmpty,
                      textAlign: TextAlign.center,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: team.players.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                itemBuilder: (context, index) {
                  final player = team.players[index];
                  return _PlayerRowCard(
                    key: Key('player_card_${player.shirtNumber}'),
                    player: player,
                    canManageRoster: canManageRoster,
                    l10n: l10n,
                    onEdit: () {
                      _showPlayerFormDialog(
                        context,
                        ref,
                        team,
                        tournament,
                        activeRole,
                        l10n,
                        existingPlayer: player,
                      );
                    },
                    onDelete: () {
                      _confirmRemovePlayer(
                        context,
                        ref,
                        team,
                        tournament,
                        player,
                        activeRole,
                        l10n,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerFormDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    UserRole activeRole,
    AppLocalizations l10n, {
    RegisteredPlayer? existingPlayer,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _PlayerEnrollmentDialog(
          team: team,
          tournament: tournament,
          activeRole: activeRole,
          l10n: l10n,
          existingPlayer: existingPlayer,
        );
      },
    );
  }

  void _confirmRemovePlayer(
    BuildContext context,
    WidgetRef ref,
    TournamentTeam team,
    ChampionshipTournament tournament,
    RegisteredPlayer player,
    UserRole activeRole,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: KickPulseColors.surfaceBase,
          title: Text(
            l10n.playerRemoveConfirmTitle,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            l10n.playerRemoveConfirmMessage(player.fullName),
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: Key('confirm_delete_player_${player.shirtNumber}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KickPulseColors.accentLive,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(teamsControllerProvider.notifier)
                    .removePlayer(
                      teamId: team.id,
                      playerId: player.id,
                      tournament: tournament,
                      actorRole: activeRole,
                    );
              },
              child: Text(l10n.playerRemoveAction),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerRowCard extends StatelessWidget {
  const _PlayerRowCard({
    super.key,
    required this.player,
    required this.canManageRoster,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  final RegisteredPlayer player;
  final bool canManageRoster;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final positionLabel = switch (player.position) {
      PlayerPosition.goalkeeper => l10n.playerPositionShortGoalkeeper,
      PlayerPosition.defender => l10n.playerPositionShortDefender,
      PlayerPosition.midfielder => l10n.playerPositionShortMidfielder,
      PlayerPosition.forward => l10n.playerPositionShortForward,
    };

    return KickPulseCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: KickPulseColors.surfaceElevated,
            child: Text(
              '#${player.shirtNumber}',
              style: const TextStyle(
                color: KickPulseColors.accentElectric,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  'Doc: ${player.documentId}',
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceSubtle,
              borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
            ),
            child: Text(
              positionLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.accentPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (canManageRoster) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: KickPulseColors.textSecondary,
              onPressed: onEdit,
            ),
            IconButton(
              key: Key('delete_player_${player.shirtNumber}'),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: KickPulseColors.accentLive,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerEnrollmentDialog extends ConsumerStatefulWidget {
  const _PlayerEnrollmentDialog({
    required this.team,
    required this.tournament,
    required this.activeRole,
    required this.l10n,
    this.existingPlayer,
  });

  final TournamentTeam team;
  final ChampionshipTournament tournament;
  final UserRole activeRole;
  final AppLocalizations l10n;
  final RegisteredPlayer? existingPlayer;

  @override
  ConsumerState<_PlayerEnrollmentDialog> createState() =>
      _PlayerEnrollmentDialogState();
}

class _PlayerEnrollmentDialogState
    extends ConsumerState<_PlayerEnrollmentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _documentController;
  late final TextEditingController _shirtNumberController;
  late PlayerPosition _position;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPlayer?.fullName ?? '',
    );
    _documentController = TextEditingController(
      text: widget.existingPlayer?.documentId ?? '',
    );
    _shirtNumberController = TextEditingController(
      text: widget.existingPlayer != null
          ? widget.existingPlayer!.shirtNumber.toString()
          : '',
    );
    _position = widget.existingPlayer?.position ?? PlayerPosition.forward;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _shirtNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamsControllerProvider);
    final isEditing = widget.existingPlayer != null;

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceBase,
      title: Text(
        isEditing
            ? widget.l10n.playerFormSubmitEdit
            : widget.l10n.teamEnrollPlayerAction,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.l10n.playerFormFullNameLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            TextField(
              key: const Key('player_full_name_input'),
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.l10n.playerFormFullNameHint,
                hintStyle: const TextStyle(color: KickPulseColors.textMuted),
                filled: true,
                fillColor: KickPulseColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                  borderSide: const BorderSide(
                    color: KickPulseColors.borderSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.playerFormDocumentLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            TextField(
              key: const Key('player_document_input'),
              controller: _documentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.l10n.playerFormDocumentHint,
                hintStyle: const TextStyle(color: KickPulseColors.textMuted),
                filled: true,
                fillColor: KickPulseColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                  borderSide: const BorderSide(
                    color: KickPulseColors.borderSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.playerFormShirtNumberLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            TextField(
              key: const Key('player_shirt_number_input'),
              controller: _shirtNumberController,
              keyboardType: TextInputType.number,
              maxLength: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.l10n.playerFormShirtNumberHint,
                hintStyle: const TextStyle(color: KickPulseColors.textMuted),
                counterText: '',
                filled: true,
                fillColor: KickPulseColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                  borderSide: const BorderSide(
                    color: KickPulseColors.borderSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.playerFormPositionLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Wrap(
              spacing: 8,
              children: PlayerPosition.values.map((pos) {
                final isSelected = _position == pos;
                final label = switch (pos) {
                  PlayerPosition.goalkeeper =>
                    widget.l10n.playerPositionGoalkeeper,
                  PlayerPosition.defender => widget.l10n.playerPositionDefender,
                  PlayerPosition.midfielder =>
                    widget.l10n.playerPositionMidfielder,
                  PlayerPosition.forward => widget.l10n.playerPositionForward,
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: KickPulseColors.accentPrimary.withAlpha(50),
                  onSelected: (selected) {
                    if (selected) setState(() => _position = pos);
                  },
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                _errorMessage!,
                key: const Key('player_form_error_text'),
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.accentLive,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('player_submit_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: Colors.black,
          ),
          onPressed: state.isSaving ? null : _submit,
          child: Text(
            isEditing
                ? widget.l10n.playerFormSubmitEdit
                : widget.l10n.playerFormSubmitEnroll,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final parsedShirt = int.tryParse(_shirtNumberController.text.trim()) ?? 0;
    final playerId =
        widget.existingPlayer?.id ??
        'p-${DateTime.now().millisecondsSinceEpoch}';

    final player = RegisteredPlayer(
      id: playerId,
      fullName: _nameController.text,
      documentId: _documentController.text,
      shirtNumber: parsedShirt,
      position: _position,
      isEligible: widget.existingPlayer?.isEligible ?? false,
    );

    final success = await ref
        .read(teamsControllerProvider.notifier)
        .enrollOrUpdatePlayer(
          teamId: widget.team.id,
          player: player,
          tournament: widget.tournament,
          actorRole: widget.activeRole,
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final failure = ref.read(teamsControllerProvider).lastFailure;
      setState(() {
        _errorMessage = failure?.message ?? 'Error al guardar jugador';
      });
    }
  }
}
