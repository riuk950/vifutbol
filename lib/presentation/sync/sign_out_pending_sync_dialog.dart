import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';

/// User resolution chosen when signing out with pending local outbox items (Q3).
enum SignOutGuardDecision { syncedAndExit, keepPendingAndExit, cancel }

/// 3-option confirmation dialog preventing accidental loss of queued offline items on sign-out (`Q3`).
class SignOutPendingSyncDialog extends ConsumerStatefulWidget {
  const SignOutPendingSyncDialog({super.key, required this.pendingCount});

  final int pendingCount;

  /// Presents [SignOutPendingSyncDialog] modally and returns the chosen [SignOutGuardDecision].
  static Future<SignOutGuardDecision> show(
    BuildContext context, {
    required int pendingCount,
  }) async {
    final result = await showDialog<SignOutGuardDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignOutPendingSyncDialog(pendingCount: pendingCount),
    );
    return result ?? SignOutGuardDecision.cancel;
  }

  @override
  ConsumerState<SignOutPendingSyncDialog> createState() =>
      _SignOutPendingSyncDialogState();
}

class _SignOutPendingSyncDialogState
    extends ConsumerState<SignOutPendingSyncDialog> {
  bool _isSyncing = false;
  bool _syncFailed = false;

  Future<void> _onSyncAndExit() async {
    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });
    final result = await ref
        .read(syncStatusControllerProvider.notifier)
        .syncNow();
    if (!mounted) return;
    if (result != null && result.isFullySynced) {
      Navigator.of(context).pop(SignOutGuardDecision.syncedAndExit);
    } else {
      setState(() {
        _isSyncing = false;
        _syncFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final syncState = ref.watch(syncStatusControllerProvider);

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceBase,
      title: Text(
        l10n.syncLogoutGuardTitle,
        style: const TextStyle(color: KickPulseColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.syncLogoutGuardMessage(widget.pendingCount),
            style: const TextStyle(color: KickPulseColors.textMuted),
          ),
          if (_syncFailed) ...[
            const SizedBox(height: 12),
            Text(
              l10n.syncLogoutSyncFailedNotice,
              style: const TextStyle(color: KickPulseColors.accentLive),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          key: const Key('logout_cancel_button'),
          onPressed: _isSyncing
              ? null
              : () => Navigator.of(context).pop(SignOutGuardDecision.cancel),
          child: Text(
            l10n.actionCancel,
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
        ),
        TextButton(
          key: const Key('logout_keep_pending_button'),
          onPressed: _isSyncing
              ? null
              : () => Navigator.of(
                  context,
                ).pop(SignOutGuardDecision.keepPendingAndExit),
          child: Text(
            l10n.syncLogoutActionKeepPending,
            style: const TextStyle(color: KickPulseColors.accentLive),
          ),
        ),
        ElevatedButton(
          key: const Key('logout_sync_and_exit_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
          ),
          onPressed: (!_isSyncing && syncState.isConnected)
              ? _onSyncAndExit
              : null,
          child: _isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.syncLogoutActionSyncAndExit),
        ),
      ],
    );
  }
}
