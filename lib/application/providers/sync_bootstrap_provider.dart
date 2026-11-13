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

/// Eagerly instantiates all 10 hybrid repositories when cloud sync is enabled so
/// every [SyncOutboxEntityType] replay handler is registered at cold startup before
/// any lazy UI tab is opened.
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
});
