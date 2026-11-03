import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// Use case that orchestrates team registration, player roster enrollment,
/// sports integrity uniqueness checks (team name, shirt number, player document),
/// quota threshold evaluations, and official eligibility approvals.
class ManageTeamsEligibilityUseCase {
  const ManageTeamsEligibilityUseCase(this._repository);

  final TeamsRepository _repository;

  /// Registers or updates a [TournamentTeam] in a championship.
  ///
  /// Throws [UnauthorizedRoleFailure] if [actorRole] lacks roster/tournament management permissions.
  /// Throws [TeamEligibilityValidationFailure] if tournament is not in open registration,
  /// fields are invalid, or team name collides within the tournament.
  Future<TournamentTeam> registerOrUpdateTeam({
    required TournamentTeam team,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureRosterManagementPermission(actorRole);
    _ensureOpenRegistration(tournament);

    final trimmedName = team.name.trim();
    if (trimmedName.length < 3) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidTeamName,
        'El nombre del equipo debe tener al menos 3 caracteres',
      );
    }

    final trimmedShortCode = team.shortCode.trim();
    if (trimmedShortCode.length < 2 || trimmedShortCode.length > 4) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidShortCode,
        'La sigla debe tener entre 2 y 4 caracteres',
      );
    }

    final tournamentTeams = await _repository.loadTeamsForTournament(
      tournament.id,
    );

    final isDuplicateName = tournamentTeams.any(
      (t) => t.id != team.id && t.normalizedName == team.normalizedName,
    );
    if (isDuplicateName) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateTeamNameInTournament,
        'Ya existe un equipo con este nombre en este campeonato',
      );
    }

    final sanitizedTeam = team.copyWith(
      name: trimmedName,
      shortCode: trimmedShortCode.toUpperCase(),
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(sanitizedTeam);
  }

  /// Enrolls or updates a player in the roster of a team.
  ///
  /// Enforces tournament open status, input constraints, squad max limit,
  /// shirt number uniqueness per team, and document uniqueness across the tournament.
  Future<TournamentTeam> enrollOrUpdatePlayer({
    required String teamId,
    required RegisteredPlayer player,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureRosterManagementPermission(actorRole);
    _ensureOpenRegistration(tournament);

    final trimmedName = player.fullName.trim();
    if (trimmedName.length < 3) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidPlayerName,
        'El nombre del jugador debe tener al menos 3 caracteres',
      );
    }

    final trimmedDoc = player.documentId.trim();
    if (trimmedDoc.length < 5) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidDocumentId,
        'El documento de identidad debe tener al menos 5 caracteres',
      );
    }

    if (player.shirtNumber < 1 || player.shirtNumber > 99) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidShirtNumber,
        'El número de camiseta debe estar entre 1 y 99',
      );
    }

    final tournamentTeams = await _repository.loadTeamsForTournament(
      tournament.id,
    );

    final teamIndex = tournamentTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamNotFound,
        'Equipo no encontrado en el campeonato',
      );
    }

    final targetTeam = tournamentTeams[teamIndex];
    final isNewPlayer = !targetTeam.players.any((p) => p.id == player.id);

    if (isNewPlayer &&
        targetTeam.players.length >= tournament.rules.maxPlayersPerTeam) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.maxPlayersQuotaReached,
        'El equipo ya alcanzó el cupo máximo de jugadores permitido',
      );
    }

    // Uniqueness of shirt number within this team
    final hasDuplicateShirt = targetTeam.players.any(
      (p) => p.id != player.id && p.shirtNumber == player.shirtNumber,
    );
    if (hasDuplicateShirt) {
      throw TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateShirtNumberInTeam,
        'El número de camiseta ${player.shirtNumber} ya está en uso en este equipo.',
      );
    }

    // Uniqueness of documentId across all teams in this tournament
    final normalizedDoc = trimmedDoc.toUpperCase();
    for (final otherTeam in tournamentTeams) {
      final duplicatePlayerInTournament = otherTeam.players.any(
        (p) => p.id != player.id && p.normalizedDocumentId == normalizedDoc,
      );
      if (duplicatePlayerInTournament) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.playerAlreadyRegisteredInTournament,
          'Este jugador ya se encuentra inscrito en otro equipo de este campeonato.',
        );
      }
    }

    final sanitizedPlayer = player.copyWith(
      fullName: trimmedName,
      documentId: trimmedDoc,
      isEligible:
          targetTeam.eligibilityStatus == TeamEligibilityStatus.eligible,
    );

    final updatedPlayers = List<RegisteredPlayer>.from(targetTeam.players);
    final existingPlayerIndex = updatedPlayers.indexWhere(
      (p) => p.id == player.id,
    );
    if (existingPlayerIndex >= 0) {
      updatedPlayers[existingPlayerIndex] = sanitizedPlayer;
    } else {
      updatedPlayers.add(sanitizedPlayer);
    }

    // Re-evaluate eligibility status based on minimum quota
    TeamEligibilityStatus newStatus = targetTeam.eligibilityStatus;
    if (updatedPlayers.length < tournament.rules.minPlayersPerTeam) {
      newStatus = TeamEligibilityStatus.pendingQuota;
    } else if (newStatus == TeamEligibilityStatus.pendingQuota) {
      newStatus = TeamEligibilityStatus.readyForApproval;
    }

    final updatedTeam = targetTeam.copyWith(
      players: updatedPlayers,
      eligibilityStatus: newStatus,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(updatedTeam);
  }

  /// Removes a player from a team roster and reverts eligibility if below minimum quota.
  Future<TournamentTeam> removePlayer({
    required String teamId,
    required String playerId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureRosterManagementPermission(actorRole);
    _ensureOpenRegistration(tournament);

    final tournamentTeams = await _repository.loadTeamsForTournament(
      tournament.id,
    );

    final teamIndex = tournamentTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamNotFound,
        'Equipo no encontrado en el campeonato',
      );
    }

    final targetTeam = tournamentTeams[teamIndex];
    final updatedPlayers = targetTeam.players
        .where((p) => p.id != playerId)
        .toList();

    TeamEligibilityStatus newStatus = targetTeam.eligibilityStatus;
    List<RegisteredPlayer> finalPlayers = updatedPlayers;

    if (updatedPlayers.length < tournament.rules.minPlayersPerTeam) {
      newStatus = TeamEligibilityStatus.pendingQuota;
      finalPlayers = updatedPlayers
          .map((p) => p.copyWith(isEligible: false))
          .toList();
    }

    final updatedTeam = targetTeam.copyWith(
      players: finalPlayers,
      eligibilityStatus: newStatus,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(updatedTeam);
  }

  /// Officially marks a team as [TeamEligibilityStatus.eligible].
  ///
  /// Restricted to roles with [RoleCapability.approveRegistrations] (Organizer).
  /// Requires player count within [minPlayersPerTeam, maxPlayersPerTeam].
  Future<TournamentTeam> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    final canApprove = RolePermissionMatrix.hasCapability(
      actorRole,
      RoleCapability.approveRegistrations,
    );
    if (!canApprove) {
      throw const UnauthorizedRoleFailure(
        'Solo el Organizador puede habilitar oficialmente a un equipo',
      );
    }

    final tournamentTeams = await _repository.loadTeamsForTournament(
      tournament.id,
    );

    final teamIndex = tournamentTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamNotFound,
        'Equipo no encontrado en el campeonato',
      );
    }

    final targetTeam = tournamentTeams[teamIndex];
    final playerCount = targetTeam.players.length;

    if (playerCount < tournament.rules.minPlayersPerTeam ||
        playerCount > tournament.rules.maxPlayersPerTeam) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.insufficientPlayersForApproval,
        'El equipo aún no alcanza el mínimo reglamentario de jugadores requerido por el campeonato',
      );
    }

    final eligiblePlayers = targetTeam.players
        .map((p) => p.copyWith(isEligible: true))
        .toList();

    final approvedTeam = targetTeam.copyWith(
      eligibilityStatus: TeamEligibilityStatus.eligible,
      players: eligiblePlayers,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(approvedTeam);
  }

  void _ensureRosterManagementPermission(UserRole role) {
    final hasPermission =
        RolePermissionMatrix.hasCapability(
          role,
          RoleCapability.manageTeamRoster,
        ) ||
        RolePermissionMatrix.hasCapability(
          role,
          RoleCapability.manageTournaments,
        ) ||
        RolePermissionMatrix.hasCapability(
          role,
          RoleCapability.approveRegistrations,
        );

    if (!hasPermission) {
      throw const UnauthorizedRoleFailure(
        'Tu rol no tiene permisos para gestionar equipos o plantillas',
      );
    }
  }

  void _ensureOpenRegistration(ChampionshipTournament tournament) {
    if (tournament.status != TournamentStatus.openRegistration) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'Las inscripciones de este campeonato están cerradas',
      );
    }
  }
}
