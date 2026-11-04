import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/schedule_collision_result.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/services/round_robin_generator.dart';

class FixtureSchedulingUseCase {
  const FixtureSchedulingUseCase({required this.matchesRepository});

  final TournamentMatchesRepository matchesRepository;

  /// Generates a complete official fixture for the tournament.
  Future<List<ChampionshipMatch>> generateRoundRobinFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  }) async {
    // 1. Validate authorization
    if (!RolePermissionMatrix.hasCapability(
      userRole,
      RoleCapability.manageTournaments,
    )) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.unauthorizedRole,
        'No tienes permisos de organizador para generar el fixture.',
      );
    }

    // 2. Validate tournament is open
    if (tournament.status == TournamentStatus.finished) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.tournamentClosed,
        'El torneo ya se encuentra finalizado.',
      );
    }

    // 3. Filter eligible teams
    final eligibleTeams = teams.where((t) => t.isEligible).toList();
    if (eligibleTeams.length < 2) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.insufficientTeams,
        'Se requieren al menos 2 equipos habilitados para generar el fixture.',
      );
    }

    // 4. Block regeneration if any match is inProgress or completed
    final existingMatches = await matchesRepository.loadMatchesForTournament(
      tournament.id,
    );
    final hasActiveOrCompletedMatches = existingMatches.any(
      (m) =>
          m.status == MatchStatus.inProgress ||
          m.status == MatchStatus.completed,
    );

    if (hasActiveOrCompletedMatches) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.regenerationBlocked,
        'No se puede regenerar el fixture porque ya existen partidos en juego o finalizados.',
      );
    }

    final teamIds = eligibleTeams.map((t) => t.id).toList();

    // 5. Generate matches based on tournament format
    final List<ChampionshipMatch> generatedMatches;
    if (tournament.format == TournamentFormat.knockoutCup) {
      generatedMatches = RoundRobinGenerator.generateKnockoutFixture(
        tournamentId: tournament.id,
        teamIds: teamIds,
      );
    } else {
      generatedMatches = RoundRobinGenerator.generateLeagueFixture(
        tournamentId: tournament.id,
        teamIds: teamIds,
        leagueRounds: tournament.rules.leagueRounds,
      );
    }

    // 6. Persist matches
    await matchesRepository.saveMatchesBatch(generatedMatches);
    return generatedMatches;
  }

  /// Schedules or reschedules a single match, computing its duration and checking collisions.
  Future<ChampionshipMatch> scheduleMatch({
    required String matchId,
    required ChampionshipTournament tournament,
    required DateTime scheduledStartTime,
    required SportsVenue venue,
    required VenuePitch pitch,
    required MatchReferee referee,
    required UserRole userRole,
  }) async {
    // 1. Validate authorization
    if (!RolePermissionMatrix.hasCapability(
      userRole,
      RoleCapability.manageTournaments,
    )) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.unauthorizedRole,
        'No tienes permisos de organizador para programar partidos.',
      );
    }

    // 2. Load existing matches
    final existingMatches = await matchesRepository.loadMatchesForTournament(
      tournament.id,
    );
    final matchIndex = existingMatches.indexWhere((m) => m.id == matchId);
    if (matchIndex < 0) {
      throw const FixtureScheduleValidationFailure(
        FixtureScheduleErrorCode.invalidScheduleTimes,
        'El partido no existe en este torneo.',
      );
    }

    final currentMatch = existingMatches[matchIndex];

    // 3. Compute duration and end time: (halfDurationMinutes * 2) + 15 min break
    final durationMinutes = (tournament.rules.halfDurationMinutes * 2) + 15;
    final scheduledEndTime = scheduledStartTime.add(
      Duration(minutes: durationMinutes),
    );

    // 4. Validate collisions
    final collision = detectCollisions(
      candidateMatchId: matchId,
      tournamentId: tournament.id,
      startTime: scheduledStartTime,
      endTime: scheduledEndTime,
      pitchId: pitch.id,
      refereeId: referee.id,
      homeTeamId: currentMatch.homeTeamId,
      awayTeamId: currentMatch.awayTeamId,
      existingMatches: existingMatches,
    );

    if (collision.hasCollision) {
      final code = switch (collision.collisionType!) {
        ScheduleCollisionType.pitchConflict =>
          FixtureScheduleErrorCode.pitchScheduleCollision,
        ScheduleCollisionType.refereeConflict =>
          FixtureScheduleErrorCode.refereeScheduleCollision,
        ScheduleCollisionType.teamConflict =>
          FixtureScheduleErrorCode.teamScheduleCollision,
      };

      throw FixtureScheduleValidationFailure(
        code,
        collision.message ?? 'Conflicto de horario detectado.',
        collision.conflictingMatchId,
        collision.conflictingEntityName,
      );
    }

    // 5. Update match
    final updatedMatch = currentMatch.copyWith(
      status: MatchStatus.scheduled,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      venueId: venue.id,
      pitchId: pitch.id,
      pitchName: pitch.name,
      refereeId: referee.id,
      refereeName: referee.fullName,
    );

    return matchesRepository.saveMatch(updatedMatch);
  }

  /// Evaluates whether candidate scheduling window collides with existing matches.
  ScheduleCollisionResult detectCollisions({
    required String candidateMatchId,
    required String tournamentId,
    required DateTime startTime,
    required DateTime endTime,
    required String pitchId,
    required String refereeId,
    required String homeTeamId,
    required String awayTeamId,
    required List<ChampionshipMatch> existingMatches,
  }) {
    for (final match in existingMatches) {
      if (match.id == candidateMatchId) continue;
      if (!match.isScheduled) continue;
      if (!match.overlapsWith(startTime, endTime)) continue;

      // Pitch collision
      if (match.pitchId == pitchId) {
        return ScheduleCollisionResult.collision(
          collisionType: ScheduleCollisionType.pitchConflict,
          conflictingMatchId: match.id,
          conflictingEntityName: match.pitchName ?? pitchId,
          message:
              'La cancha ya se encuentra ocupada en ese intervalo de horario.',
        );
      }

      // Referee collision
      if (match.refereeId == refereeId) {
        return ScheduleCollisionResult.collision(
          collisionType: ScheduleCollisionType.refereeConflict,
          conflictingMatchId: match.id,
          conflictingEntityName: match.refereeName ?? refereeId,
          message: 'El árbitro ya tiene otro partido designado en ese horario.',
        );
      }

      // Team collision
      if (match.homeTeamId == homeTeamId ||
          match.awayTeamId == homeTeamId ||
          match.homeTeamId == awayTeamId ||
          match.awayTeamId == awayTeamId) {
        return ScheduleCollisionResult.collision(
          collisionType: ScheduleCollisionType.teamConflict,
          conflictingMatchId: match.id,
          conflictingEntityName: match.homeTeamId,
          message:
              'Uno de los equipos ya tiene otro partido programado en ese horario.',
        );
      }
    }

    return ScheduleCollisionResult.none();
  }
}
