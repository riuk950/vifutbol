import 'package:flutter/material.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class GenerateFixtureConfirmationDialog extends StatelessWidget {
  const GenerateFixtureConfirmationDialog({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => GenerateFixtureConfirmationDialog(
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      title: Text(
        l10n.matchdayGenerateFixtureDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: Text(
        l10n.matchdayGenerateFixtureDialogMessage,
        style: KickPulseTypography.bodyPrimary.copyWith(
          color: KickPulseColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_generate_fixture_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.matchdayGenerateFixtureCancelButton,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('confirm_generate_fixture_button'),
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
            ),
          ),
          child: Text(
            l10n.matchdayGenerateFixtureConfirmButton,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.surfaceBase,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
