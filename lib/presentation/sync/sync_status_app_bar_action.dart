import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/sync/sync_status_bottom_sheet.dart';

/// AppBar sync indicator button visible strictly to operational roles
/// (`organizer`, `coach`, `referee`) and hidden for `player`, `fan`, and `guestFan` (`FR-008`, `FR-009`).
class SyncStatusAppBarAction extends ConsumerStatefulWidget {
  const SyncStatusAppBarAction({super.key});

  @override
  ConsumerState<SyncStatusAppBarAction> createState() =>
      _SyncStatusAppBarActionState();
}

class _SyncStatusAppBarActionState extends ConsumerState<SyncStatusAppBarAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = ref.watch(activeSyncUserContextProvider);
    if (userContext.isGuest) {
      return const SizedBox.shrink();
    }

    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    if (!capabilities.contains(RoleCapability.viewCloudSyncIndicator)) {
      return const SizedBox.shrink();
    }

    final syncState = ref.watch(syncStatusControllerProvider);
    final l10n = AppLocalizations.of(context);

    if (syncState.status == SyncStatus.syncing) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else if (_spinController.isAnimating) {
      _spinController.stop();
    }

    final totalBadge = syncState.totalAttentionCount;
    final tooltip = switch (syncState.status) {
      SyncStatus.synced => l10n.syncStatusSyncedTooltip,
      SyncStatus.pending => l10n.syncStatusPendingTooltip(
        syncState.pendingCount,
      ),
      SyncStatus.syncing => l10n.syncStatusSyncingTooltip,
      SyncStatus.offlineOrError => l10n.syncStatusOfflineOrErrorTooltip,
    };

    final Widget iconWidget = switch (syncState.status) {
      SyncStatus.synced => const Icon(
        Icons.cloud_done_outlined,
        color: KickPulseColors.accentPrimary,
        size: 24,
      ),
      SyncStatus.pending => const Icon(
        Icons.cloud_upload_outlined,
        color: KickPulseColors.accentWarning,
        size: 24,
      ),
      SyncStatus.syncing => RotationTransition(
        turns: _spinController,
        child: const Icon(
          Icons.sync,
          color: KickPulseColors.accentPrimary,
          size: 24,
        ),
      ),
      SyncStatus.offlineOrError => Icon(
        syncState.errorCount > 0
            ? Icons.error_outline
            : Icons.cloud_off_outlined,
        color: KickPulseColors.accentLive,
        size: 24,
      ),
    };

    return Semantics(
      button: true,
      label: tooltip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: IconButton(
          key: const Key('app_bar_sync_status_action'),
          tooltip: tooltip,
          onPressed: () => SyncStatusBottomSheet.show(context),
          icon: Badge(
            key: const Key('app_bar_sync_status_badge'),
            isLabelVisible: totalBadge > 0,
            backgroundColor: syncState.errorCount > 0
                ? KickPulseColors.accentLive
                : KickPulseColors.accentWarning,
            label: Text(
              '$totalBadge',
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.surfaceBase,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: iconWidget,
          ),
        ),
      ),
    );
  }
}
