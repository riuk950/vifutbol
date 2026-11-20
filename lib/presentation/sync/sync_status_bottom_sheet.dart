import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Modal bottom sheet displaying current cloud sync health, last successful sync timestamp,
/// itemized pending/errored outbox items, per-item recovery controls, and manual sync trigger.
class SyncStatusBottomSheet extends ConsumerWidget {
  const SyncStatusBottomSheet({super.key});

  /// Opens the [SyncStatusBottomSheet] modally above the active screen.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SyncStatusBottomSheet(),
    );
  }

  String _entityLabel(AppLocalizations l10n, SyncOutboxEntityType type) =>
      switch (type) {
        SyncOutboxEntityType.tournament => l10n.syncEntityTournament,
        SyncOutboxEntityType.venue => l10n.syncEntityVenue,
        SyncOutboxEntityType.team => l10n.syncEntityTeam,
        SyncOutboxEntityType.match => l10n.syncEntityMatch,
        SyncOutboxEntityType.lineupTracking => l10n.syncEntityLineup,
        SyncOutboxEntityType.matchReport => l10n.syncEntityMatchReport,
        SyncOutboxEntityType.matchAlert => l10n.syncEntityMatchAlert,
        SyncOutboxEntityType.tournamentNews => l10n.syncEntityNews,
        SyncOutboxEntityType.seasonHonorRoll => l10n.syncEntityHonorRoll,
        SyncOutboxEntityType.fanFavorite => l10n.syncEntityFavorite,
      };

  String _errorLabel(AppLocalizations l10n, SyncErrorCode? code) =>
      switch (code) {
        SyncErrorCode.permissionDenied => l10n.syncErrorPermissionDenied,
        SyncErrorCode.constraintViolation => l10n.syncErrorConstraintViolation,
        SyncErrorCode.validationFailed => l10n.syncErrorValidationFailed,
        SyncErrorCode.notFound => l10n.syncErrorNotFound,
        SyncErrorCode.unknown || null => l10n.syncErrorUnknown,
      };

  String _headline(AppLocalizations l10n, SyncSummaryState state) {
    if (state.isSyncing) return l10n.syncStateSyncingTitle;
    if (state.errorCount > 0) return l10n.syncStateErrorTitle(state.errorCount);
    if (state.pendingCount > 0) {
      return l10n.syncStatePendingTitle(state.pendingCount);
    }
    return l10n.syncStateSyncedTitle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(syncStatusControllerProvider);
    final controller = ref.read(syncStatusControllerProvider.notifier);

    final lastSyncedText = state.lastSyncedAt == null
        ? l10n.syncLastSyncedNever
        : l10n.syncLastSyncedAt(
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(state.lastSyncedAt!.toLocal()),
          );

    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KickPulseRadiiSpacing.spaceMd,
          KickPulseRadiiSpacing.spaceMd,
          KickPulseRadiiSpacing.spaceMd,
          KickPulseRadiiSpacing.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.syncSheetTitle,
                    style: KickPulseTypography.sectionHeader,
                  ),
                ),
                _ConnectionChip(
                  isConnected: state.isConnected,
                  onlineLabel: l10n.syncConnectionOnline,
                  offlineLabel: l10n.syncConnectionOffline,
                ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Container(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KickPulseColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(l10n, state),
                    style: KickPulseTypography.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastSyncedText,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.syncQueueEmptyMessage,
                  textAlign: TextAlign.center,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _OutboxItemTile(
                      item: item,
                      entityLabel: _entityLabel(l10n, item.entityType),
                      statusLabel: switch (item.status) {
                        SyncOutboxItemStatus.queued =>
                          l10n.syncItemStatusQueued,
                        SyncOutboxItemStatus.retrying =>
                          l10n.syncItemStatusRetrying,
                        SyncOutboxItemStatus.error => l10n.syncItemStatusError,
                      },
                      localizedError: item.status == SyncOutboxItemStatus.error
                          ? _errorLabel(l10n, item.errorCode)
                          : null,
                      retryLabel: l10n.syncActionRetry,
                      discardLabel: l10n.syncActionDiscard,
                      onRetry: state.isConnected && !state.isSyncing
                          ? () => controller.retryItem(item.id)
                          : null,
                      onDiscard: !state.isSyncing
                          ? () => controller.discardItem(item.id)
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('sync_now_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KickPulseColors.accentPrimary,
                  foregroundColor: KickPulseColors.surfaceBase,
                ),
                onPressed: state.isConnected && !state.isSyncing
                    ? () => controller.syncNow()
                    : null,
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(l10n.syncActionNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({
    required this.isConnected,
    required this.onlineLabel,
    required this.offlineLabel,
  });

  final bool isConnected;
  final String onlineLabel;
  final String offlineLabel;

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? KickPulseColors.accentPrimary
        : KickPulseColors.accentLive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? onlineLabel : offlineLabel,
            style: KickPulseTypography.captionMeta.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _OutboxItemTile extends StatelessWidget {
  const _OutboxItemTile({
    required this.item,
    required this.entityLabel,
    required this.statusLabel,
    required this.localizedError,
    required this.retryLabel,
    required this.discardLabel,
    required this.onRetry,
    required this.onDiscard,
  });

  final SyncOutboxItem item;
  final String entityLabel;
  final String statusLabel;
  final String? localizedError;
  final String retryLabel;
  final String discardLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final isError = item.status == SyncOutboxItemStatus.error;
    final badgeColor = isError
        ? KickPulseColors.accentLive
        : KickPulseColors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? KickPulseColors.accentLive.withValues(alpha: 0.6)
              : KickPulseColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$entityLabel · ${item.displayTitle}',
                  style: KickPulseTypography.cardTitle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (localizedError != null) ...[
            const SizedBox(height: 6),
            Text(
              localizedError!,
              style: KickPulseTypography.bodyPrimary.copyWith(
                color: KickPulseColors.accentLive,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    key: Key('sync_retry_item_${item.id}'),
                    onPressed: onRetry,
                    child: Text(retryLabel),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: TextButton(
                    key: Key('sync_discard_item_${item.id}'),
                    onPressed: onDiscard,
                    child: Text(
                      discardLabel,
                      style: const TextStyle(color: KickPulseColors.accentLive),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
