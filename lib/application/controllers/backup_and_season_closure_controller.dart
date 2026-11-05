import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/close_tournament_season_use_case.dart';
import 'package:vifutbol/application/use_cases/tournament_backup_use_cases.dart';
import 'package:vifutbol/domain/entities/backup_validation_result.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/tournament_backup_package.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';

class BackupAndSeasonClosureState {
  const BackupAndSeasonClosureState({
    this.isLoading = false,
    this.exportedPackage,
    this.validationResult,
    this.successMessage,
    this.errorMessage,
    this.honorRoll,
    this.previewHonorRoll,
  });

  final bool isLoading;
  final TournamentBackupPackage? exportedPackage;
  final BackupValidationResult? validationResult;
  final String? successMessage;
  final String? errorMessage;
  final SeasonHonorRoll? honorRoll;
  final SeasonHonorRoll? previewHonorRoll;

  BackupAndSeasonClosureState copyWith({
    bool? isLoading,
    TournamentBackupPackage? exportedPackage,
    BackupValidationResult? validationResult,
    String? successMessage,
    String? errorMessage,
    SeasonHonorRoll? honorRoll,
    SeasonHonorRoll? previewHonorRoll,
    bool clearExported = false,
    bool clearValidation = false,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearPreview = false,
  }) {
    return BackupAndSeasonClosureState(
      isLoading: isLoading ?? this.isLoading,
      exportedPackage: clearExported
          ? null
          : (exportedPackage ?? this.exportedPackage),
      validationResult: clearValidation
          ? null
          : (validationResult ?? this.validationResult),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      honorRoll: honorRoll ?? this.honorRoll,
      previewHonorRoll: clearPreview
          ? null
          : (previewHonorRoll ?? this.previewHonorRoll),
    );
  }
}

class BackupAndSeasonClosureController
    extends StateNotifier<BackupAndSeasonClosureState> {
  BackupAndSeasonClosureController({
    required this.exportBackupUseCase,
    required this.validateBackupUseCase,
    required this.importBackupUseCase,
    required this.honorRollRepository,
    this.closeSeasonUseCase,
  }) : super(const BackupAndSeasonClosureState());

  final ExportTournamentBackupUseCase exportBackupUseCase;
  final ValidateTournamentBackupUseCase validateBackupUseCase;
  final ImportTournamentBackupUseCase importBackupUseCase;
  final SeasonHonorRollRepository honorRollRepository;
  final CloseTournamentSeasonUseCase? closeSeasonUseCase;

  void clearMessages() {
    state = state.copyWith(clearSuccess: true, clearError: true);
  }

  Future<TournamentBackupPackage?> exportBackup(
    String tournamentId,
    UserRole role,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final package = await exportBackupUseCase.execute(
        tournamentId: tournamentId,
        actorRole: role,
      );
      state = state.copyWith(isLoading: false, exportedPackage: package);
      return package;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return null;
    }
  }

  void validateBackup(String rawJson) {
    final result = validateBackupUseCase.execute(rawJson);
    state = state.copyWith(validationResult: result);
  }

  Future<bool> restoreBackup({
    required String rawJson,
    required UserRole role,
    required bool isConfirmed,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await importBackupUseCase.execute(
        rawJson: rawJson,
        actorRole: role,
        isTwoStepConfirmed: isConfirmed,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage:
            'El campeonato fue restaurado con éxito desde el respaldo.',
        clearValidation: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<SeasonHonorRoll?> loadHonorRoll(String tournamentId) async {
    try {
      final honorRoll = await honorRollRepository.loadHonorRollForTournament(
        tournamentId,
      );
      state = state.copyWith(honorRoll: honorRoll);
      return honorRoll;
    } catch (_) {
      return null;
    }
  }

  Future<SeasonHonorRoll?> previewSeasonClosure(
    ChampionshipTournament tournament,
    UserRole role,
  ) async {
    if (closeSeasonUseCase == null) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final preview = await closeSeasonUseCase!.previewHonorRoll(
        tournament: tournament,
        actorRole: role,
      );
      state = state.copyWith(isLoading: false, previewHonorRoll: preview);
      return preview;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return null;
    }
  }

  Future<bool> closeSeason({
    required ChampionshipTournament tournament,
    required UserRole role,
    required bool isConfirmed,
  }) async {
    if (closeSeasonUseCase == null) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final honorRoll = await closeSeasonUseCase!.closeSeason(
        tournament: tournament,
        actorRole: role,
        isTwoStepConfirmed: isConfirmed,
      );
      state = state.copyWith(
        isLoading: false,
        honorRoll: honorRoll,
        clearPreview: true,
        successMessage:
            '¡Temporada finalizada! El Cuadro de Honor oficial ha sido publicado.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }
}
