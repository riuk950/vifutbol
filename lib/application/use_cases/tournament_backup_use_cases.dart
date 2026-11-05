import 'dart:convert';
import 'package:vifutbol/domain/entities/backup_validation_result.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_backup_package.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_news_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Validates the format, schema version, and cross-referential integrity of a backup payload.
class ValidateTournamentBackupUseCase {
  const ValidateTournamentBackupUseCase();

  static const String invalidBackupMessage =
      'El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.';

  BackupValidationResult execute(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const BackupValidationResult.invalid(invalidBackupMessage);
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult.invalid(invalidBackupMessage);
      }

      final signature = decoded['formatSignature'] as String?;
      final version = decoded['schemaVersion'] as num?;
      if (signature != TournamentBackupPackage.currentSignature ||
          version != TournamentBackupPackage.currentSchemaVersion) {
        return const BackupValidationResult.invalid(invalidBackupMessage);
      }

      final rawTournament = decoded['tournament'];
      if (rawTournament is! Map<String, dynamic>) {
        return const BackupValidationResult.invalid(invalidBackupMessage);
      }

      final package = TournamentBackupPackage.fromJson(decoded);
      final tournament = package.tournament;
      if (tournament.id.trim().isEmpty || tournament.name.trim().length < 3) {
        return const BackupValidationResult.invalid(invalidBackupMessage);
      }

      final teamIds = <String>{};
      for (final team in package.teams) {
        if (team.tournamentId != tournament.id || team.id.trim().isEmpty) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
        if (!teamIds.add(team.id)) {
          // Duplicate team ID in package
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
      }

      final matchIds = <String>{};
      for (final match in package.matches) {
        if (match.tournamentId != tournament.id || match.id.trim().isEmpty) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
        if (!matchIds.add(match.id)) {
          // Duplicate match ID in package
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }

        // Validate referential integrity for non-placeholder teams
        if (match.homeTeamId.isNotEmpty &&
            !match.homeTeamId.startsWith('TBD') &&
            !teamIds.contains(match.homeTeamId)) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
        if (match.awayTeamId.isNotEmpty &&
            !match.awayTeamId.startsWith('TBD') &&
            !teamIds.contains(match.awayTeamId)) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
      }

      for (final report in package.matchReports) {
        if (report.tournamentId != tournament.id) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
        if (!matchIds.contains(report.matchId)) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
      }

      for (final news in package.newsItems) {
        if (news.tournamentId != tournament.id) {
          return const BackupValidationResult.invalid(invalidBackupMessage);
        }
      }

      if (package.honorRoll != null &&
          package.honorRoll!.tournamentId != tournament.id) {
        return const BackupValidationResult.invalid(invalidBackupMessage);
      }

      return BackupValidationResult.valid(package);
    } catch (_) {
      return const BackupValidationResult.invalid(invalidBackupMessage);
    }
  }
}

/// Use case that exports a complete, self-contained tournament backup package.
class ExportTournamentBackupUseCase {
  const ExportTournamentBackupUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.matchesRepository,
    required this.reportsRepository,
    required this.newsRepository,
    required this.honorRollRepository,
  });

  final TournamentsRepository tournamentsRepository;
  final TeamsRepository teamsRepository;
  final TournamentMatchesRepository matchesRepository;
  final MatchReportsRepository reportsRepository;
  final TournamentNewsRepository newsRepository;
  final SeasonHonorRollRepository honorRollRepository;

  Future<TournamentBackupPackage> execute({
    required String tournamentId,
    required UserRole actorRole,
  }) async {
    _ensureOrganizer(actorRole);

    final tournaments = await tournamentsRepository.loadTournaments();
    final tournament = tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidName,
        'Campeonato no encontrado',
      ),
    );

    final teams = await teamsRepository.loadTeamsForTournament(tournamentId);
    final matches = await matchesRepository.loadMatchesForTournament(
      tournamentId,
    );
    final reports = await reportsRepository.loadReportsForTournament(
      tournamentId,
    );
    final news = await newsRepository.loadNewsForTournament(tournamentId);
    final honorRoll = await honorRollRepository.loadHonorRollForTournament(
      tournamentId,
    );

    return TournamentBackupPackage(
      exportedAt: DateTime.now().toUtc(),
      tournament: tournament,
      teams: teams,
      matches: matches,
      matchReports: reports,
      newsItems: news,
      honorRoll: honorRoll,
    );
  }

  void _ensureOrganizer(UserRole actorRole) {
    if (!RolePermissionMatrix.hasCapability(
      actorRole,
      RoleCapability.manageTournaments,
    )) {
      throw const UnauthorizedRoleFailure();
    }
  }
}

/// Use case that atomically restores a tournament backup package into local storage.
class ImportTournamentBackupUseCase {
  const ImportTournamentBackupUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.matchesRepository,
    required this.reportsRepository,
    required this.newsRepository,
    required this.honorRollRepository,
    this.validationUseCase = const ValidateTournamentBackupUseCase(),
  });

  final TournamentsRepository tournamentsRepository;
  final TeamsRepository teamsRepository;
  final TournamentMatchesRepository matchesRepository;
  final MatchReportsRepository reportsRepository;
  final TournamentNewsRepository newsRepository;
  final SeasonHonorRollRepository honorRollRepository;
  final ValidateTournamentBackupUseCase validationUseCase;

  Future<ChampionshipTournament> execute({
    required String rawJson,
    required UserRole actorRole,
    required bool isTwoStepConfirmed,
  }) async {
    _ensureOrganizer(actorRole);

    if (!isTwoStepConfirmed) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.missingTwoStepConfirmation,
        'Se requiere confirmación de seguridad para restaurar el respaldo',
      );
    }

    final validationResult = validationUseCase.execute(rawJson);
    if (!validationResult.isValid || validationResult.package == null) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.invalidBackupPackage,
        ValidateTournamentBackupUseCase.invalidBackupMessage,
      );
    }

    final package = validationResult.package!;
    final tournamentId = package.tournament.id;

    // Atomic per-tournament replacement
    await tournamentsRepository.saveTournament(package.tournament);
    await teamsRepository.replaceTeamsForTournament(
      tournamentId,
      package.teams,
    );
    await matchesRepository.replaceMatchesForTournament(
      tournamentId,
      package.matches,
    );
    await reportsRepository.replaceReportsForTournament(
      tournamentId,
      package.matchReports,
    );
    await newsRepository.replaceNewsForTournament(
      tournamentId,
      package.newsItems,
    );

    if (package.honorRoll != null) {
      await honorRollRepository.saveHonorRoll(package.honorRoll!);
    } else {
      await honorRollRepository.deleteHonorRollForTournament(tournamentId);
    }

    return package.tournament;
  }

  void _ensureOrganizer(UserRole actorRole) {
    if (!RolePermissionMatrix.hasCapability(
      actorRole,
      RoleCapability.manageTournaments,
    )) {
      throw const UnauthorizedRoleFailure();
    }
  }
}
