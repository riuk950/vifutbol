import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Modal dialog allowing authenticated coaches to create an autonomous or tournament-enrolled team.
class CreateTeamDialog extends ConsumerStatefulWidget {
  const CreateTeamDialog({super.key});

  /// Static helper to display the [CreateTeamDialog].
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const CreateTeamDialog(),
    );
  }

  @override
  ConsumerState<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends ConsumerState<CreateTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortCodeController;
  String? _selectedTournamentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.read(tournamentsControllerProvider);
    final authState = ref.read(authControllerProvider);

    final selectedTournament = _selectedTournamentId != null
        ? tournamentsState.tournaments
              .where((t) => t.id == _selectedTournamentId)
              .firstOrNull
        : null;

    final coachId = authState.session?.user.id ?? 'coach-seed-1';
    final actorRole = authState.session?.user.activeRole ?? UserRole.coach;
    final teamName = _nameController.text.trim();
    final shortCode = _shortCodeController.text.trim().toUpperCase();

    final success = await ref
        .read(teamsControllerProvider.notifier)
        .createTeam(
          name: teamName,
          shortCode: shortCode,
          tournament: selectedTournament,
          coachId: coachId,
          actorRole: actorRole,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.createTeamSuccessMessage(teamName)),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
    } else {
      final teamsState = ref.read(teamsControllerProvider);
      final failureMessage =
          teamsState.lastFailure?.message ??
          l10n.unauthorizedTeamCreationMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage),
          backgroundColor: KickPulseColors.accentWarning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final openTournaments = tournamentsState.tournaments
        .where((t) => t.status == TournamentStatus.openRegistration)
        .toList();

    return AlertDialog(
      key: const Key('create_team_dialog'),
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
      ),
      title: Text(
        l10n.createTeamDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Name input
              TextFormField(
                key: const Key('create_team_name_input'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.createTeamNameLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 3) {
                    return 'El nombre del equipo debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Short code input
              TextFormField(
                key: const Key('create_team_short_code_input'),
                controller: _shortCodeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.createTeamShortCodeLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 2 || trimmed.length > 4) {
                    return 'La sigla debe tener entre 2 y 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Optional tournament dropdown
              DropdownButtonFormField<String?>(
                key: const Key('create_team_tournament_dropdown'),
                isExpanded: true,
                initialValue: _selectedTournamentId,
                decoration: InputDecoration(
                  labelText: l10n.createTeamTournamentLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.emoji_events_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.createTeamNoTournamentOption),
                  ),
                  ...openTournaments.map(
                    (tourn) => DropdownMenuItem<String?>(
                      value: tourn.id,
                      child: Text(tourn.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedTournamentId = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceMd,
        vertical: KickPulseRadiiSpacing.spaceSm,
      ),
      actionsOverflowButtonSpacing: KickPulseRadiiSpacing.spaceSm,
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: KickPulseRadiiSpacing.spaceSm,
          runSpacing: KickPulseRadiiSpacing.spaceSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              key: const Key('create_team_cancel_button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.actionCancel,
                style: const TextStyle(color: KickPulseColors.textSecondary),
              ),
            ),
            KickPulseButton(
              key: const Key('create_team_submit_button'),
              label: l10n.createTeamSubmitAction,
              icon: const Icon(Icons.check, size: 18),
              variant: KickPulseButtonVariant.primary,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ],
    );
  }
}
