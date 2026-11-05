import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/backup_and_season_closure_controller.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/close_tournament_season_use_case.dart';
import 'package:vifutbol/application/use_cases/tournament_backup_use_cases.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_season_honor_roll_repository.dart';

final seasonHonorRollRepositoryProvider = Provider<SeasonHonorRollRepository>((
  ref,
) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final env = ref.watch(environmentConfigProvider);
  return LocalSeasonHonorRollRepository(storage: storage, config: env);
});

final validateTournamentBackupUseCaseProvider =
    Provider<ValidateTournamentBackupUseCase>((ref) {
      return const ValidateTournamentBackupUseCase();
    });

final exportTournamentBackupUseCaseProvider =
    Provider<ExportTournamentBackupUseCase>((ref) {
      return ExportTournamentBackupUseCase(
        tournamentsRepository: ref.watch(tournamentsRepositoryProvider),
        teamsRepository: ref.watch(teamsRepositoryProvider),
        matchesRepository: ref.watch(tournamentMatchesRepositoryProvider),
        reportsRepository: ref.watch(matchReportsRepositoryProvider),
        newsRepository: ref.watch(tournamentNewsRepositoryProvider),
        honorRollRepository: ref.watch(seasonHonorRollRepositoryProvider),
      );
    });

final importTournamentBackupUseCaseProvider =
    Provider<ImportTournamentBackupUseCase>((ref) {
      return ImportTournamentBackupUseCase(
        tournamentsRepository: ref.watch(tournamentsRepositoryProvider),
        teamsRepository: ref.watch(teamsRepositoryProvider),
        matchesRepository: ref.watch(tournamentMatchesRepositoryProvider),
        reportsRepository: ref.watch(matchReportsRepositoryProvider),
        newsRepository: ref.watch(tournamentNewsRepositoryProvider),
        honorRollRepository: ref.watch(seasonHonorRollRepositoryProvider),
        validationUseCase: ref.watch(validateTournamentBackupUseCaseProvider),
      );
    });

final closeTournamentSeasonUseCaseProvider =
    Provider<CloseTournamentSeasonUseCase>((ref) {
      return CloseTournamentSeasonUseCase(
        tournamentsRepository: ref.watch(tournamentsRepositoryProvider),
        teamsRepository: ref.watch(teamsRepositoryProvider),
        matchesRepository: ref.watch(tournamentMatchesRepositoryProvider),
        reportsRepository: ref.watch(matchReportsRepositoryProvider),
        honorRollRepository: ref.watch(seasonHonorRollRepositoryProvider),
        calculateStandingsUseCase: ref.watch(
          calculateTournamentStandingsAndRankingsUseCaseProvider,
        ),
      );
    });

final backupAndSeasonClosureControllerProvider =
    StateNotifierProvider.autoDispose<
      BackupAndSeasonClosureController,
      BackupAndSeasonClosureState
    >((ref) {
      return BackupAndSeasonClosureController(
        exportBackupUseCase: ref.watch(exportTournamentBackupUseCaseProvider),
        validateBackupUseCase: ref.watch(
          validateTournamentBackupUseCaseProvider,
        ),
        importBackupUseCase: ref.watch(importTournamentBackupUseCaseProvider),
        honorRollRepository: ref.watch(seasonHonorRollRepositoryProvider),
        closeSeasonUseCase: ref.watch(closeTournamentSeasonUseCaseProvider),
      );
    });

final tournamentHonorRollProvider =
    FutureProvider.family<SeasonHonorRoll?, String>((ref, tournamentId) async {
      final repo = ref.watch(seasonHonorRollRepositoryProvider);
      return repo.loadHonorRollForTournament(tournamentId);
    });
