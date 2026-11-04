import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/digital_match_report_state.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../infrastructure/repositories/local_match_reports_repository.dart';
import '../controllers/digital_match_report_controller.dart';
import '../use_cases/manage_digital_match_report_use_case.dart';
import 'foundation_providers.dart';
import 'lineups_tracking_providers.dart';
import 'matches_catalog_providers.dart';
import 'teams_providers.dart';
import 'tournaments_providers.dart';

/// Provider exposing [MatchReportsRepository].
final matchReportsRepositoryProvider = Provider<MatchReportsRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  return LocalMatchReportsRepository(storage: storage, config: config);
});

/// Provider exposing [ManageDigitalMatchReportUseCase].
final manageDigitalMatchReportUseCaseProvider =
    Provider<ManageDigitalMatchReportUseCase>((ref) {
      final reportsRepo = ref.watch(matchReportsRepositoryProvider);
      final matchesRepo = ref.watch(tournamentMatchesRepositoryProvider);
      final lineupsRepo = ref.watch(lineupsTrackingRepositoryProvider);
      final tournamentsRepo = ref.watch(tournamentsRepositoryProvider);

      return ManageDigitalMatchReportUseCase(
        matchReportsRepository: reportsRepo,
        tournamentMatchesRepository: matchesRepo,
        lineupsTrackingRepository: lineupsRepo,
        tournamentsRepository: tournamentsRepo,
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
