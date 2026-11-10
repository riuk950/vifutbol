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

/// Modal dialog allowing tournament organizers to edit metadata.
class CompetitionEditDialog extends ConsumerStatefulWidget {
  const CompetitionEditDialog({
    super.key,
    required this.tournament,
  });

  final ChampionshipTournament tournament;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompetitionEditDialog(tournament: tournament),
    );
  }

  @override
  ConsumerState<CompetitionEditDialog> createState() =>
      _CompetitionEditDialogState();
}

class _CompetitionEditDialogState extends ConsumerState<CompetitionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _pointsForWinController;
  late TextEditingController _pointsForDrawController;
  late TournamentFormat _format;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tournament.name);
    _categoryController = TextEditingController(
      text: widget.tournament.category,
    );
    _format = widget.tournament.format;
    _pointsForWinController = TextEditingController(
      text: '${widget.tournament.rules.pointsForWin}',
    );
    _pointsForDrawController = TextEditingController(
      text: '${widget.tournament.rules.pointsForDraw}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _pointsForWinController.dispose();
    _pointsForDrawController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final actorRole = ref.read(activeUserRoleProvider);
      final winPoints =
          int.tryParse(_pointsForWinController.text.trim()) ??
          widget.tournament.rules.pointsForWin;
      final drawPoints =
          int.tryParse(_pointsForDrawController.text.trim()) ??
          widget.tournament.rules.pointsForDraw;

      final updatedRules = widget.tournament.rules.copyWith(
        pointsForWin: winPoints,
        pointsForDraw: drawPoints,
      );

      final success = await ref
          .read(tournamentsControllerProvider.notifier)
          .updateTournamentMetadata(
            tournamentId: widget.tournament.id,
            name: _nameController.text.trim(),
            category: _categoryController.text.trim(),
            format: _format,
            rules: updatedRules,
            actorRole: actorRole,
          );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.competitionEditSavedSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.competitionEditDialogTitle,
                        style: KickPulseTypography.cardTitle,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: KickPulseColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                TextFormField(
                  key: const Key('competition_edit_name_input'),
                  controller: _nameController,
                  style: KickPulseTypography.bodyPrimary,
                  decoration: InputDecoration(
                    labelText: l10n.competitionEditNameLabel,
                    labelStyle: KickPulseTypography.captionMeta,
                    filled: true,
                    fillColor: KickPulseColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                      borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                TextFormField(
                  key: const Key('competition_edit_category_input'),
                  controller: _categoryController,
                  style: KickPulseTypography.bodyPrimary,
                  decoration: InputDecoration(
                    labelText: l10n.competitionEditCategoryLabel,
                    labelStyle: KickPulseTypography.captionMeta,
                    filled: true,
                    fillColor: KickPulseColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                      borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Debes ingresar una categoría válida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                DropdownButtonFormField<TournamentFormat>(
                  key: const Key('competition_edit_format_select'),
                  initialValue: _format,
                  isExpanded: true,
                  dropdownColor: KickPulseColors.surfaceElevated,
                  style: KickPulseTypography.bodyPrimary,
                  decoration: InputDecoration(
                    labelText: l10n.competitionEditFormatLabel,
                    labelStyle: KickPulseTypography.captionMeta,
                    filled: true,
                    fillColor: KickPulseColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                      borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
                    ),
                  ),
                  items: TournamentFormat.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(_formatLabel(f, l10n)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _format = val);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsForWinController,
                        style: KickPulseTypography.bodyPrimary,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Puntos Victoria',
                          labelStyle: KickPulseTypography.captionMeta,
                          filled: true,
                          fillColor: KickPulseColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                            borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Expanded(
                      child: TextFormField(
                        controller: _pointsForDrawController,
                        style: KickPulseTypography.bodyPrimary,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Puntos Empate',
                          labelStyle: KickPulseTypography.captionMeta,
                          filled: true,
                          fillColor: KickPulseColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                            borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: KickPulseRadiiSpacing.spaceSm,
                  runSpacing: KickPulseRadiiSpacing.spaceSm,
                  children: [
                    KickPulseButton(
                      key: const Key('competition_edit_cancel_button'),
                      label: l10n.competitionDeleteCancelButton,
                      variant: KickPulseButtonVariant.outline,
                      onPressed: () async {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    KickPulseButton(
                      key: const Key('competition_edit_save_button'),
                      label: l10n.competitionEditSaveButton,
                      variant: KickPulseButtonVariant.primary,
                      isLoading: _isSaving,
                      onPressed: () async {
                        await _handleSave();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
