import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
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
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Section embedded within tournament details / standings tab displaying registered
/// teams, quota progress, and entrypoint for team registration dialog.
class TournamentTeamsSection extends ConsumerWidget {
  const TournamentTeamsSection({
    super.key,
    required this.tournament,
    required this.actorRole,
  });

  final ChampionshipTournament tournament;
  final UserRole actorRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(teamsControllerProvider);
    final teams = state.teamsForTournament(tournament.id);

    final canRegisterTeams =
        RolePermissionMatrix.hasCapability(
          actorRole,
          RoleCapability.manageTeamRoster,
        ) &&
        tournament.status == TournamentStatus.openRegistration;

    final eligibleCount = teams
        .where((t) => t.eligibilityStatus == TeamEligibilityStatus.eligible)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teamsSectionTitle,
                    style: KickPulseTypography.screenTitle.copyWith(
                      color: KickPulseColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    l10n.teamsCountSummary(eligibleCount, teams.length),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentElectric,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (canRegisterTeams)
              KickPulseButton(
                key: const Key('register_team_action_button'),
                label: l10n.teamsRegisterAction,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () async {
                  _showRegisterTeamDialog(context, ref, l10n);
                },
              ),
          ],
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        if (teams.isEmpty)
          KickPulseCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceMd,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: KickPulseColors.textTertiary,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    l10n.teamsEmptyTitle,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    l10n.teamsEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < teams.length; index++) ...[
                if (index > 0)
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                _TeamCard(
                  team: teams[index],
                  tournament: tournament,
                  l10n: l10n,
                  onTap: () {
                    ref
                        .read(teamsControllerProvider.notifier)
                        .selectTeam(teams[index].id);
                    AppRouter.router.navigateTo(
                      context,
                      '/tournaments/teams/detail',
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }

  void _showRegisterTeamDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _RegisterTeamDialog(
          tournament: tournament,
          actorRole: actorRole,
          l10n: l10n,
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.tournament,
    required this.l10n,
    required this.onTap,
  });

  final TournamentTeam team;
  final ChampionshipTournament tournament;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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

    return KickPulseCard(
      onTap: onTap,
      child: Row(
        children: [
          KickPulseTeamCrest(
            shortCode: team.shortCode,
            crestShape: team.crestShape,
            primaryColorHex: team.primaryColorHex,
            secondaryColorHex: team.secondaryColorHex,
            size: 46.0,
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
                          color: KickPulseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                    Flexible(
                      child: KickPulseBadge(
                        label: statusLabel,
                        variant: badgeVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
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
              ],
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
          const Icon(
            Icons.chevron_right,
            color: KickPulseColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RegisterTeamDialog extends ConsumerStatefulWidget {
  const _RegisterTeamDialog({
    required this.tournament,
    required this.actorRole,
    required this.l10n,
  });

  final ChampionshipTournament tournament;
  final UserRole actorRole;
  final AppLocalizations l10n;

  @override
  ConsumerState<_RegisterTeamDialog> createState() =>
      _RegisterTeamDialogState();
}

class _RegisterTeamDialogState extends ConsumerState<_RegisterTeamDialog> {
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  TeamCrestShape _crestShape = TeamCrestShape.shield;
  int _primaryColorHex = 0xFF00E676;
  int _secondaryColorHex = 0xFF0A0E17;
  String? _errorMessage;

  static const List<int> _curatedPrimaryColors = [
    0xFF00E676,
    0xFF2979FF,
    0xFFFF1744,
    0xFFFFD600,
    0xFFFF6D00,
    0xFFAA00FF,
    0xFF00E5FF,
    0xFFFFFFFF,
  ];

  static const List<int> _curatedSecondaryColors = [
    0xFF0A0E17,
    0xFF1A237E,
    0xFF212121,
    0xFF37474F,
    0xFF004D40,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamsControllerProvider);

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceBase,
      title: Text(
        widget.l10n.teamsRegisterAction,
        style: KickPulseTypography.cardTitle.copyWith(
          color: KickPulseColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: KickPulseTeamCrest(
                shortCode: _shortCodeController.text.isEmpty
                    ? 'ATN'
                    : _shortCodeController.text,
                crestShape: _crestShape,
                primaryColorHex: _primaryColorHex,
                secondaryColorHex: _secondaryColorHex,
                size: 56.0,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.teamFormNameLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            TextField(
              key: const Key('team_name_input'),
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.l10n.teamFormNameHint,
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
              widget.l10n.teamFormShortCodeLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            TextField(
              key: const Key('team_short_code_input'),
              controller: _shortCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.l10n.teamFormShortCodeHint,
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
              widget.l10n.teamFormCrestShapeLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Wrap(
              spacing: 8,
              children: TeamCrestShape.values.map((shape) {
                final isSelected = _crestShape == shape;
                final label = switch (shape) {
                  TeamCrestShape.shield => widget.l10n.crestShapeShield,
                  TeamCrestShape.circle => widget.l10n.crestShapeCircle,
                  TeamCrestShape.diamond => widget.l10n.crestShapeDiamond,
                  TeamCrestShape.hexagon => widget.l10n.crestShapeHexagon,
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: KickPulseColors.accentPrimary.withAlpha(50),
                  onSelected: (selected) {
                    if (selected) setState(() => _crestShape = shape);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.teamFormPrimaryColorLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Wrap(
              spacing: 8,
              children: _curatedPrimaryColors.map((colorHex) {
                final isSelected = _primaryColorHex == colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _primaryColorHex = colorHex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              widget.l10n.teamFormSecondaryColorLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Wrap(
              spacing: 8,
              children: _curatedSecondaryColors.map((colorHex) {
                final isSelected = _secondaryColorHex == colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _secondaryColorHex = colorHex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                _errorMessage!,
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
          child: Text(
            'Cancelar',
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
        ),
        ElevatedButton(
          key: const Key('team_submit_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: Colors.black,
          ),
          onPressed: state.isSaving ? null : _submit,
          child: Text(widget.l10n.teamFormSubmitCreate),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final teamId = const Uuid().v4();
    final team = TournamentTeam(
      id: teamId,
      tournamentId: widget.tournament.id,
      name: _nameController.text,
      shortCode: _shortCodeController.text.isEmpty
          ? 'TEAM'
          : _shortCodeController.text,
      crestShape: _crestShape,
      primaryColorHex: _primaryColorHex,
      secondaryColorHex: _secondaryColorHex,
    );

    final success = await ref
        .read(teamsControllerProvider.notifier)
        .registerOrUpdateTeam(
          team: team,
          tournament: widget.tournament,
          actorRole: widget.actorRole,
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final failure = ref.read(teamsControllerProvider).lastFailure;
      setState(() {
        _errorMessage = failure?.message ?? 'Error al registrar el equipo';
      });
    }
  }
}
