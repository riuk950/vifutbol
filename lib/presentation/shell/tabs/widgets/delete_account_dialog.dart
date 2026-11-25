import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design_system/kick_pulse_colors.dart';
import '../../../design_system/kick_pulse_radii_spacing.dart';
import '../../../design_system/kick_pulse_typography.dart';

/// Irreversible confirmation dialog for permanent cascade account deletion
/// with single-flight loading lock.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.onConfirmDelete});

  /// Executes account deletion and returns `true` if deletion succeeded.
  final Future<bool> Function() onConfirmDelete;

  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function() onConfirmDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(onConfirmDelete: onConfirmDelete),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isDeleting = false;

  Future<void> _handleConfirm() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
    });

    final deleted = await widget.onConfirmDelete();
    if (!mounted) return;
    Navigator.of(context).pop(deleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        key: const ValueKey('delete_account_dialog'),
        backgroundColor: KickPulseColors.surfaceBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          side: const BorderSide(color: KickPulseColors.borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: KickPulseColors.accentLive,
            ),
            const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
            Expanded(
              child: Text(
                l10n.deleteAccountDialogTitle,
                style: KickPulseTypography.cardTitle,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteAccountDialogMessage,
          style: const TextStyle(
            color: KickPulseColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('delete_account_cancel_button'),
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text(
              l10n.actionCancel,
              style: TextStyle(
                color: _isDeleting
                    ? KickPulseColors.textMuted
                    : KickPulseColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            key: const ValueKey('delete_account_confirm_button'),
            onPressed: _isDeleting ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: KickPulseColors.accentLive,
              foregroundColor: KickPulseColors.textPrimary,
              disabledBackgroundColor: KickPulseColors.accentLive.withAlpha(140),
              disabledForegroundColor: KickPulseColors.textPrimary,
              minimumSize: const Size(0, 44),
            ),
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KickPulseColors.textPrimary,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined, size: 18),
            label: Text(
              _isDeleting
                  ? l10n.deleteAccountDeletingLabel
                  : l10n.deleteAccountConfirmAction,
            ),
          ),
        ],
      ),
    );
  }
}
