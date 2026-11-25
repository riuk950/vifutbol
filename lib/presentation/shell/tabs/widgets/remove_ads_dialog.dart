import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design_system/kick_pulse_colors.dart';
import '../../../design_system/kick_pulse_radii_spacing.dart';
import '../../../design_system/kick_pulse_typography.dart';
import '../../../design_system/widgets/kick_pulse_badge.dart';
import '../../../design_system/widgets/kick_pulse_button.dart';

/// Informative modal dialog explaining the upcoming ad-free experience.
class RemoveAdsDialog extends StatelessWidget {
  const RemoveAdsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const RemoveAdsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      key: const ValueKey('remove_ads_dialog'),
      backgroundColor: KickPulseColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: KickPulseColors.accentWarning,
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Text(
              l10n.removeAdsDialogTitle,
              style: KickPulseTypography.cardTitle,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickPulseBadge(
            label: l10n.removeAdsComingSoonBadge,
            variant: KickPulseBadgeVariant.warning,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          Text(
            l10n.removeAdsDialogDescription,
            style: const TextStyle(
              color: KickPulseColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          Text(
            l10n.removeAdsDialogNotice,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        KickPulseButton(
          key: const ValueKey('remove_ads_dialog_close_button'),
          label: l10n.removeAdsDialogCloseAction,
          variant: KickPulseButtonVariant.primary,
          isFullWidth: true,
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
