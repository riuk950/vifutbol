import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Modal dialog for transitioning a tournament's lifecycle status.
class CompetitionLifecycleDialog extends ConsumerStatefulWidget {
  const CompetitionLifecycleDialog({
    super.key,
    required this.tournament,
    this.enrolledTeamsCount = 0,
    this.hasGeneratedFixture = false,
    this.onEnrollTeamsRequested,
    this.onGenerateFixtureRequested,
  });

  final ChampionshipTournament tournament;
  final int enrolledTeamsCount;
  final bool hasGeneratedFixture;
  final VoidCallback? onEnrollTeamsRequested;
  final VoidCallback? onGenerateFixtureRequested;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
    int enrolledTeamsCount = 0,
    bool hasGeneratedFixture = false,
    VoidCallback? onEnrollTeamsRequested,
    VoidCallback? onGenerateFixtureRequested,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompetitionLifecycleDialog(
        tournament: tournament,
        enrolledTeamsCount: enrolledTeamsCount,
        hasGeneratedFixture: hasGeneratedFixture,
        onEnrollTeamsRequested: onEnrollTeamsRequested,
        onGenerateFixtureRequested: onGenerateFixtureRequested,
      ),
    );
  }

  @override
  ConsumerState<CompetitionLifecycleDialog> createState() =>
      _CompetitionLifecycleDialogState();
}

class _CompetitionLifecycleDialogState
    extends ConsumerState<CompetitionLifecycleDialog> {
  late TournamentStatus _targetStatus;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournament.status == TournamentStatus.openRegistration) {
      _targetStatus = TournamentStatus.inProgress;
    } else if (widget.tournament.status == TournamentStatus.inProgress) {
      _targetStatus = TournamentStatus.finished;
    } else {
      _targetStatus = TournamentStatus.finished;
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

  Future<void> _handleConfirm() async {
    if (_isExecuting) return;

    setState(() => _isExecuting = true);

    try {
      final actorRole = ref.read(activeUserRoleProvider);
      final success = await ref
          .read(tournamentsControllerProvider.notifier)
          .transitionTournamentStatus(
            tournament: widget.tournament,
            targetStatus: _targetStatus,
            actorRole: actorRole,
            enrolledTeamsCount: widget.enrolledTeamsCount,
            hasGeneratedFixture: widget.hasGeneratedFixture,
          );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.competitionLifecycleSuccess(_statusLabel(_targetStatus, l10n)),
            ),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGoingToProgress = _targetStatus == TournamentStatus.inProgress;
    final missingTeams = isGoingToProgress && widget.enrolledTeamsCount < 2;
    final missingFixture = isGoingToProgress && !widget.hasGeneratedFixture;
    final hasBlocker = missingTeams || missingFixture;

    return Dialog(
      backgroundColor: KickPulseColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.competitionLifecycleDialogTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: KickPulseColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Container(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                ),
                child: Text(
                  l10n.competitionLifecycleCurrentStatus(
                    _statusLabel(widget.tournament.status, l10n),
                  ),
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              DropdownButtonFormField<TournamentStatus>(
                key: const Key('competition_lifecycle_target_select'),
                initialValue: _targetStatus,
                isExpanded: true,
                dropdownColor: KickPulseColors.surfaceElevated,
                style: KickPulseTypography.bodyPrimary,
                decoration: InputDecoration(
                  labelText: l10n.competitionLifecycleTargetStatus,
                  labelStyle: KickPulseTypography.captionMeta,
                  filled: true,
                  fillColor: KickPulseColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    borderSide: const BorderSide(
                      color: KickPulseColors.borderSubtle,
                    ),
                  ),
                ),
                items: [
                  if (widget.tournament.status == TournamentStatus.openRegistration)
                    DropdownMenuItem(
                      value: TournamentStatus.inProgress,
                      child: Text(_statusLabel(TournamentStatus.inProgress, l10n)),
                    ),
                  if (widget.tournament.status == TournamentStatus.inProgress)
                    DropdownMenuItem(
                      value: TournamentStatus.finished,
                      child: Text(_statusLabel(TournamentStatus.finished, l10n)),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetStatus = val);
                },
              ),
              if (missingTeams) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentWarning.withAlpha(30),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(
                      color: KickPulseColors.accentWarning.withAlpha(100),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.competitionLifecycleValidationMinTeams(
                          widget.enrolledTeamsCount,
                        ),
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentWarning,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      KickPulseButton(
                        key: const Key(
                          'competition_lifecycle_action_enroll_teams',
                        ),
                        label: l10n.competitionLifecycleActionEnrollTeams,
                        icon: const Icon(Icons.group_add, size: 16),
                        variant: KickPulseButtonVariant.secondary,
                        onPressed: () async {
                          Navigator.of(context).pop(false);
                          widget.onEnrollTeamsRequested?.call();
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (missingFixture) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentWarning.withAlpha(30),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(
                      color: KickPulseColors.accentWarning.withAlpha(100),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.competitionLifecycleValidationNoFixture,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentWarning,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      KickPulseButton(
                        key: const Key(
                          'competition_lifecycle_action_generate_fixture',
                        ),
                        label: l10n.competitionLifecycleActionGenerateFixture,
                        icon: const Icon(Icons.alt_route, size: 16),
                        variant: KickPulseButtonVariant.secondary,
                        onPressed: () async {
                          Navigator.of(context).pop(false);
                          widget.onGenerateFixtureRequested?.call();
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: KickPulseRadiiSpacing.spaceSm,
                runSpacing: KickPulseRadiiSpacing.spaceSm,
                children: [
                  KickPulseButton(
                    key: const Key('competition_lifecycle_cancel_button'),
                    label: l10n.competitionDeleteCancelButton,
                    variant: KickPulseButtonVariant.outline,
                    onPressed: () async {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  KickPulseButton(
                    key: const Key('competition_lifecycle_confirm_button'),
                    label: l10n.competitionLifecycleConfirmButton,
                    variant: KickPulseButtonVariant.primary,
                    isLoading: _isExecuting,
                    onPressed: hasBlocker
                        ? null
                        : () async {
                            await _handleConfirm();
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
