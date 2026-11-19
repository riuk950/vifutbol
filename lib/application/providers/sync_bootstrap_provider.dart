import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/sync_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';

/// Refreshes reactive controllers after a background outbox sync item completes.
Future<void> refreshControllerForSyncedEntity(
  Ref ref,
  SyncOutboxEntityType entityType,
) async {
  try {
    switch (entityType) {
      case SyncOutboxEntityType.tournament:
        await ref.read(tournamentsControllerProvider.notifier).loadCatalog();
      case SyncOutboxEntityType.team:
        await ref.read(teamsControllerProvider.notifier).loadTeams();
      case SyncOutboxEntityType.match:
        await ref
            .read(matchesCatalogControllerProvider.notifier)
            .loadAllMatches(silent: true);
      case SyncOutboxEntityType.venue:
      case SyncOutboxEntityType.lineupTracking:
      case SyncOutboxEntityType.matchReport:
      case SyncOutboxEntityType.matchAlert:
      case SyncOutboxEntityType.tournamentNews:
      case SyncOutboxEntityType.seasonHonorRoll:
      case SyncOutboxEntityType.fanFavorite:
        break;
    }
  } catch (_) {
    // Non-destructive: keep existing cached state if post-sync refresh fails.
  }
}

/// Eagerly instantiates all 10 hybrid repositories when cloud sync is enabled so
/// every [SyncOutboxEntityType] replay handler is registered at cold startup before
/// any lazy UI tab is opened, and wires post-sync reactive controller refreshes.
final cloudSyncBootstrapProvider = Provider<void>((ref) {
  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  if (!useRemote) return;

  ref.watch(tournamentsRepositoryProvider);
  ref.watch(venuesRepositoryProvider);
  ref.watch(teamsRepositoryProvider);
  ref.watch(tournamentMatchesRepositoryProvider);
  ref.watch(lineupsTrackingRepositoryProvider);
  ref.watch(matchReportsRepositoryProvider);
  ref.watch(matchAlertsRepositoryProvider);
  ref.watch(tournamentNewsRepositoryProvider);
  ref.watch(seasonHonorRollRepositoryProvider);
  ref.watch(fanFavoritesRepositoryProvider);

  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerAfterSyncCallback(
        (item) => refreshControllerForSyncedEntity(ref, item.entityType),
      );
});
