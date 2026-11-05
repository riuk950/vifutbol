import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Modal dialog providing a 2-step security confirmation and preview
/// of the official Honor Roll before closing a tournament season.
class SeasonClosureConfirmationDialog extends ConsumerStatefulWidget {
  const SeasonClosureConfirmationDialog({
    super.key,
    required this.tournament,
    required this.actorRole,
    this.onSeasonClosed,
  });

  final ChampionshipTournament tournament;
  final UserRole actorRole;
  final VoidCallback? onSeasonClosed;

  static Future<bool?> show(
    BuildContext context, {
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    VoidCallback? onSeasonClosed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SeasonClosureConfirmationDialog(
        tournament: tournament,
        actorRole: actorRole,
        onSeasonClosed: onSeasonClosed,
      ),
    );
  }

  @override
  ConsumerState<SeasonClosureConfirmationDialog> createState() =>
      _SeasonClosureConfirmationDialogState();
}

class _SeasonClosureConfirmationDialogState
    extends ConsumerState<SeasonClosureConfirmationDialog> {
  bool _isConfirmed = false;
  SeasonHonorRoll? _preview;
  String? _errorMessage;
  bool _isLoadingPreview = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreview();
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(
        backupAndSeasonClosureControllerProvider.notifier,
      );
      final preview = await controller.previewSeasonClosure(
        widget.tournament,
        widget.actorRole,
      );

      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
          final state = ref.read(backupAndSeasonClosureControllerProvider);
          _errorMessage = state.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleConfirmClosure() async {
    if (!_isConfirmed || _preview == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(
      backupAndSeasonClosureControllerProvider.notifier,
    );
    final success = await controller.closeSeason(
      tournament: widget.tournament,
      role: widget.actorRole,
      isConfirmed: _isConfirmed,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      widget.onSeasonClosed?.call();
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(backupAndSeasonClosureControllerProvider);
      setState(() {
        _errorMessage = state.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPendingMatches =
        _errorMessage?.contains('obligatorios') == true ||
        _errorMessage?.contains('pendingMandatoryMatchesForSeasonClosure') ==
            true;

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: KickPulseColors.accentPrimary,
            size: 24,
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Text(
              l10n.seasonClosureDialogTitle,
              style: KickPulseTypography.cardTitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingPreview) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                ),
              ] else if (_errorMessage != null && _preview == null) ...[
                Container(
                  key: const Key('season_closure_error_notice'),
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentLive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                    border: Border.all(color: KickPulseColors.accentLive),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: KickPulseColors.accentLive,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasPendingMatches
                              ? l10n.seasonClosurePendingMatchesError
                              : _errorMessage!,
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentLive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_preview != null) ...[
                Container(
                  key: const Key('season_closure_honor_roll_preview'),
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                    border: Border.all(color: KickPulseColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.honorRollTitle,
                        style: KickPulseTypography.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        label: l10n.honorRollChampion,
                        value:
                            '${_preview!.championTeamName} (${_preview!.championShortCode})',
                      ),
                      const SizedBox(height: 4),
                      _PreviewRow(
                        label: l10n.honorRollRunnerUp,
                        value:
                            '${_preview!.runnerUpTeamName} (${_preview!.runnerUpShortCode})',
                      ),
                      const SizedBox(height: 4),
                      _PreviewRow(
                        label: l10n.honorRollTopScorer,
                        value: _preview!.topScorerGoals > 0
                            ? '${_preview!.topScorerPlayerName ?? "-"} (${_preview!.topScorerTeamName ?? "-"}) · ${l10n.honorRollGoalsCount(_preview!.topScorerGoals)}'
                            : l10n.honorRollNoGoals,
                      ),
                      const SizedBox(height: 4),
                      _PreviewRow(
                        label: l10n.honorRollBestDefense,
                        value:
                            '${_preview!.bestDefenseTeamName} (${_preview!.bestDefenseShortCode}) · ${l10n.honorRollGoalsAgainstCount(_preview!.bestDefenseGoalsAgainst)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                    border: Border.all(
                      color: KickPulseColors.accentWarning.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: KickPulseColors.accentWarning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta acción es definitiva e irreversible. El torneo pasará a modo solo lectura histórica.',
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                InkWell(
                  key: const Key('season_closure_checkbox_tap_area'),
                  onTap: () {
                    setState(() {
                      _isConfirmed = !_isConfirmed;
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        key: const Key('season_closure_confirm_checkbox'),
                        value: _isConfirmed,
                        onChanged: (val) {
                          setState(() {
                            _isConfirmed = val ?? false;
                          });
                        },
                        activeColor: KickPulseColors.accentPrimary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            l10n.seasonClosureTwoStepCheckbox,
                            style: KickPulseTypography.captionMeta.copyWith(
                              color: KickPulseColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('season_closure_cancel_button'),
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('season_closure_confirm_button'),
          onPressed:
              (!_isConfirmed ||
                  _preview == null ||
                  _isSubmitting ||
                  _isLoadingPreview)
              ? null
              : _handleConfirmClosure,
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KickPulseColors.surfaceBase,
                  ),
                )
              : Text(l10n.seasonClosureConfirmAction),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
