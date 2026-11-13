import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/digital_match_report_state.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../infrastructure/repositories/hybrid_match_reports_repository.dart';
import '../../infrastructure/repositories/local_match_reports_repository.dart';
import '../controllers/digital_match_report_controller.dart';
import '../use_cases/manage_digital_match_report_use_case.dart';
import 'foundation_providers.dart';
import 'lineups_tracking_providers.dart';
import 'matches_catalog_providers.dart';
import 'supabase_providers.dart';
import 'sync_providers.dart';
import 'teams_providers.dart';
import 'tournaments_providers.dart';

/// Provider exposing [MatchReportsRepository].
final matchReportsRepositoryProvider = Provider<MatchReportsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final local = LocalMatchReportsRepository(storage: storage, config: config);

  final useRemote = ref.watch(isRemoteCloudSyncEnabledProvider);
  final client = ref.watch(supabaseClientProvider);
  if (!useRemote || client == null) {
    return local;
  }

  final support = ref.watch(hybridRepositorySupportProvider);
  final remote = PostgrestMatchReportsRemoteDataSource(
    client: client,
    schema: config.supabase.schema,
    support: support,
  );
  final hybrid = HybridMatchReportsRepository(
    local: local,
    remote: remote,
    support: support,
  );
  ref
      .read(supabaseCloudSyncServiceProvider)
      .registerHandler(
        SyncOutboxEntityType.matchReport,
        hybrid.replayOutboxItem,
      );
  return hybrid;
});

/// Provider exposing [ManageDigitalMatchReportUseCase].
final manageDigitalMatchReportUseCaseProvider =
    Provider<ManageDigitalMatchReportUseCase>((ref) {
      final reportsRepo = ref.watch(matchReportsRepositoryProvider);
      final matchesRepo = ref.watch(tournamentMatchesRepositoryProvider);
      final lineupsRepo = ref.watch(lineupsTrackingRepositoryProvider);
      final tournamentsRepo = ref.watch(tournamentsRepositoryProvider);
      final teamsRepo = ref.watch(teamsRepositoryProvider);

      return ManageDigitalMatchReportUseCase(
        matchReportsRepository: reportsRepo,
        tournamentMatchesRepository: matchesRepo,
        lineupsTrackingRepository: lineupsRepo,
        tournamentsRepository: tournamentsRepo,
        teamsRepository: teamsRepo,
      );
    });

/// StateNotifierProvider for [DigitalMatchReportController].
final digitalMatchReportControllerProvider =
    StateNotifierProvider.autoDispose<
      DigitalMatchReportController,
      DigitalMatchReportState
    >((ref) {
      final useCase = ref.watch(manageDigitalMatchReportUseCaseProvider);
      final teamsRepo = ref.watch(teamsRepositoryProvider);
      final lineupsRepo = ref.watch(lineupsTrackingRepositoryProvider);
      final reportsRepo = ref.watch(matchReportsRepositoryProvider);
      final matchesRepo = ref.watch(tournamentMatchesRepositoryProvider);

      return DigitalMatchReportController(
        useCase: useCase,
        teamsRepository: teamsRepo,
        lineupsTrackingRepository: lineupsRepo,
        matchReportsRepository: reportsRepo,
        matchesRepository: matchesRepo,
      );
    });
