import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Modal dialog for confirming or blocking tournament deletion.
class CompetitionDeleteDialog extends ConsumerStatefulWidget {
  const CompetitionDeleteDialog({
    super.key,
    required this.tournament,
    required this.canDelete,
    this.blockReason,
    this.onConfirmed,
  });

  final ChampionshipTournament tournament;
  final bool canDelete;
  final String? blockReason;
  final Future<void> Function()? onConfirmed;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
    required bool canDelete,
    String? blockReason,
    Future<void> Function()? onConfirmed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompetitionDeleteDialog(
        tournament: tournament,
        canDelete: canDelete,
        blockReason: blockReason,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  ConsumerState<CompetitionDeleteDialog> createState() =>
      _CompetitionDeleteDialogState();
}

class _CompetitionDeleteDialogState
    extends ConsumerState<CompetitionDeleteDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      if (widget.onConfirmed != null) {
        await widget.onConfirmed!();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      final success = await ref
          .read(tournamentsControllerProvider.notifier)
          .deleteTournament(
            tournamentId: widget.tournament.id,
            hasStartedOrCompletedMatches: false,
            onCascadeDeleteMatches: () async {
              final matchesRepo = ref.read(tournamentMatchesRepositoryProvider);
              await matchesRepo.replaceMatchesForTournament(
                widget.tournament.id,
                [],
              );
              await ref
                  .read(matchesCatalogControllerProvider.notifier)
                  .loadTournamentMatches(widget.tournament.id);
            },
          );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.competitionDeleteSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: KickPulseColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
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
                      l10n.competitionDeleteDialogTitle,
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
              if (!widget.canDelete) ...[
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: KickPulseColors.accentWarning,
                        size: 24,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      Expanded(
                        child: Text(
                          widget.blockReason ??
                              l10n.competitionDeleteBlockedInProgress,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            color: KickPulseColors.accentWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Align(
                  alignment: Alignment.centerRight,
                  child: KickPulseButton(
                    key: const Key('competition_delete_cancel_button'),
                    label: l10n.competitionDeleteCancelButton,
                    variant: KickPulseButtonVariant.outline,
                    onPressed: () async {
                      Navigator.of(context).pop(false);
                    },
                  ),
                ),
              ] else ...[
                Text(
                  l10n.competitionDeleteDialogMessage(widget.tournament.name),
                  style: KickPulseTypography.bodyPrimary,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: KickPulseRadiiSpacing.spaceSm,
                  runSpacing: KickPulseRadiiSpacing.spaceSm,
                  children: [
                    KickPulseButton(
                      key: const Key('competition_delete_cancel_button'),
                      label: l10n.competitionDeleteCancelButton,
                      variant: KickPulseButtonVariant.outline,
                      onPressed: () async {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    KickPulseButton(
                      key: const Key('competition_delete_confirm_button'),
                      label: l10n.competitionDeleteConfirmButton,
                      variant: KickPulseButtonVariant.primary,
                      isLoading: _isDeleting,
                      onPressed: () async {
                        await _handleDelete();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
