import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

class TournamentBackupSheet extends ConsumerStatefulWidget {
  const TournamentBackupSheet({super.key, required this.tournament});

  final ChampionshipTournament tournament;

  static Future<void> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (_) => TournamentBackupSheet(tournament: tournament),
    );
  }

  @override
  ConsumerState<TournamentBackupSheet> createState() =>
      _TournamentBackupSheetState();
}

class _TournamentBackupSheetState extends ConsumerState<TournamentBackupSheet> {
  int _activeTab = 0; // 0 = Export, 1 = Import
  final TextEditingController _importTextController = TextEditingController();
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(activeUserRoleProvider);
      ref
          .read(backupAndSeasonClosureControllerProvider.notifier)
          .exportBackup(widget.tournament.id, role);
    });
  }

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(backupAndSeasonClosureControllerProvider);
    final controller = ref.read(
      backupAndSeasonClosureControllerProvider.notifier,
    );
    final role = ref.watch(activeUserRoleProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.backupModalTitle,
                      style: KickPulseTypography.cardTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: const Key('close_backup_sheet_button'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Segmented selector
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(l10n.backupExportTab),
                    icon: const Icon(Icons.download_rounded, size: 16),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(l10n.backupImportTab),
                    icon: const Icon(Icons.upload_rounded, size: 16),
                  ),
                ],
                selected: {_activeTab},
                onSelectionChanged: (set) {
                  setState(() {
                    _activeTab = set.first;
                    controller.clearMessages();
                  });
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Body content
              Flexible(
                child: SingleChildScrollView(
                  child: _activeTab == 0
                      ? _buildExportTab(context, l10n, state)
                      : _buildImportTab(context, l10n, state, controller, role),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportTab(
    BuildContext context,
    AppLocalizations l10n,
    dynamic state,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(KickPulseRadiiSpacing.spaceXl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final package = state.exportedPackage;
    if (package == null) {
      return Padding(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Text(
          state.errorMessage ?? l10n.backupInvalidMessage,
          style: KickPulseTypography.bodyPrimary.copyWith(
            color: KickPulseColors.accentLive,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KickPulseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.tournament.name,
                style: KickPulseTypography.sectionHeader,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                'Archivo sugerido: ${package.suggestedFileName}',
                style: KickPulseTypography.captionMeta,
              ),
              const Divider(height: KickPulseRadiiSpacing.spaceLg),
              _buildSummaryItem(
                Icons.shield_outlined,
                l10n.backupSummaryTeams(package.teams.length),
              ),
              _buildSummaryItem(
                Icons.people_outline,
                l10n.backupSummaryPlayers(package.totalPlayersCount),
              ),
              _buildSummaryItem(
                Icons.sports_soccer_outlined,
                l10n.backupSummaryMatches(package.matches.length),
              ),
              _buildSummaryItem(
                Icons.assignment_outlined,
                l10n.backupSummaryReports(package.matchReports.length),
              ),
              _buildSummaryItem(
                Icons.newspaper_outlined,
                l10n.backupSummaryNews(package.newsItems.length),
              ),
            ],
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        ElevatedButton.icon(
          key: const Key('copy_backup_json_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.canvasBackground,
            padding: const EdgeInsets.symmetric(
              vertical: KickPulseRadiiSpacing.spaceSm,
            ),
          ),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(l10n.backupCopyJsonAction),
          onPressed: () async {
            final jsonStr = const JsonEncoder.withIndent(
              '  ',
            ).convert(package.toJson());
            await Clipboard.setData(ClipboardData(text: jsonStr));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.backupCopySuccess),
                  backgroundColor: KickPulseColors.accentPrimary,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildImportTab(
    BuildContext context,
    AppLocalizations l10n,
    dynamic state,
    dynamic controller,
    dynamic role,
  ) {
    final validation = state.validationResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('backup_import_text_field'),
          controller: _importTextController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.backupImportInputLabel,
            hintText: l10n.backupImportInputHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        OutlinedButton.icon(
          key: const Key('validate_backup_button'),
          onPressed: () {
            controller.validateBackup(_importTextController.text);
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(l10n.backupValidateAction),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

        if (state.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
            decoration: BoxDecoration(
              color: KickPulseColors.accentLive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
              border: Border.all(color: KickPulseColors.accentLive),
            ),
            child: Text(
              state.errorMessage!,
              key: const Key('backup_error_message_text'),
              style: KickPulseTypography.bodyPrimary.copyWith(
                color: KickPulseColors.accentLive,
              ),
            ),
          ),

        if (validation != null) ...[
          if (!validation.isValid)
            Container(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.accentLive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                border: Border.all(color: KickPulseColors.accentLive),
              ),
              child: Text(
                validation.errorMessage ?? l10n.backupInvalidMessage,
                key: const Key('backup_validation_error_text'),
                style: KickPulseTypography.bodyPrimary.copyWith(
                  color: KickPulseColors.accentLive,
                ),
              ),
            )
          else if (validation.package != null) ...[
            KickPulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respaldo Válido: ${validation.package!.tournament.name}',
                    style: KickPulseTypography.sectionHeader.copyWith(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    '${validation.package!.teams.length} equipos · ${validation.package!.matches.length} partidos',
                    style: KickPulseTypography.captionMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            CheckboxListTile(
              key: const Key('backup_two_step_checkbox'),
              value: _isConfirmed,
              activeColor: KickPulseColors.accentPrimary,
              onChanged: (val) {
                setState(() {
                  _isConfirmed = val ?? false;
                });
              },
              title: Text(
                l10n.backupTwoStepCheckbox,
                style: KickPulseTypography.captionMeta,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            ElevatedButton(
              key: const Key('restore_backup_confirmed_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KickPulseColors.accentPrimary,
                foregroundColor: KickPulseColors.canvasBackground,
              ),
              onPressed: _isConfirmed && !state.isLoading
                  ? () async {
                      final success = await controller.restoreBackup(
                        rawJson: _importTextController.text,
                        role: role,
                        isConfirmed: _isConfirmed,
                      );
                      if (success && context.mounted) {
                        ref
                            .read(tournamentsControllerProvider.notifier)
                            .loadCatalog();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.backupRestoreSuccess),
                            backgroundColor: KickPulseColors.accentPrimary,
                          ),
                        );
                      }
                    }
                  : null,
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.backupRestoreAction),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KickPulseColors.textSecondary),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(child: Text(text, style: KickPulseTypography.bodyPrimary)),
        ],
      ),
    );
  }
}
