import 'package:uuid/uuid.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/services/standings_calculator_service.dart';

/// Structured result returned after enrolling an existing catalog club into a tournament.
class EnrollExistingTeamResult {
  final TournamentTeam enrolledTeam;
  final int copiedPlayersCount;
  final int skippedConflictingPlayersCount;
  final String? assignedGroupName;

  const EnrollExistingTeamResult({
    required this.enrolledTeam,
    required this.copiedPlayersCount,
    required this.skippedConflictingPlayersCount,
    this.assignedGroupName,
  });
}

/// Use case that orchestrates team registration, player roster enrollment,
/// sports integrity uniqueness checks (team name, shirt number, player document),
/// quota threshold evaluations, and official eligibility approvals.
class ManageTeamsEligibilityUseCase {
  const ManageTeamsEligibilityUseCase(
    this._repository, [
    this._matchesRepository,
  ]);

  final TeamsRepository _repository;
  final TournamentMatchesRepository? _matchesRepository;

  /// Registers or updates a [TournamentTeam] in a championship or as an autonomous club.
  ///
  /// Throws [UnauthorizedRoleFailure] if [actorRole] lacks roster management permissions.
  /// Throws [TeamEligibilityValidationFailure] if tournament is not in open registration,
  /// fields are invalid, or team name collides.
  Future<TournamentTeam> registerOrUpdateTeam({
    required TournamentTeam team,
    ChampionshipTournament? tournament,
    required UserRole actorRole,
    bool isEdit = false,
    String? actorUserId,
  }) async {
    _ensureRosterManagementPermission(actorRole);
    if (isEdit &&
        actorRole == UserRole.coach &&
        actorUserId != null &&
        actorUserId.trim().isNotEmpty &&
        team.coachId != actorUserId) {
      throw const UnauthorizedRoleFailure(
        'Solo el entrenador propietario puede editar este equipo',
      );
    }
    if (tournament != null && !isEdit) {
      _ensureOpenRegistration(tournament);
    }

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

    if (team.primaryColorHex == team.secondaryColorHex) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateTeamColors,
        'El color primario y el color secundario deben ser distintos',
      );
    }

    final foundedDate = team.foundedDate;
    if (foundedDate != null) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final normalizedFounded = DateTime(
        foundedDate.year,
        foundedDate.month,
        foundedDate.day,
      );
      if (normalizedFounded.isAfter(todayDate)) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.invalidFoundedDate,
          'La fecha de creación no puede ser posterior a hoy',
        );
      }
    }

    final candidateNormalizedName = _normalizeTeamKey(trimmedName);

    if (tournament != null) {
      final tournamentTeams = await _repository.loadTeamsForTournament(
        tournament.id,
      );

      final isDuplicateName = tournamentTeams.any(
        (t) =>
            t.id != team.id &&
            _normalizeTeamKey(t.name) == candidateNormalizedName,
      );
      if (isDuplicateName) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.duplicateTeamNameInTournament,
          'Ya existe un equipo con este nombre en este campeonato',
        );
      }
    } else {
      final allTeams = await _repository.loadTeams();
      final isDuplicateName = allTeams.any(
        (t) =>
            t.id != team.id &&
            _normalizeTeamKey(t.name) == candidateNormalizedName,
      );
      if (isDuplicateName) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.duplicateTeamNameInTournament,
          'Ya existe un equipo con este nombre',
        );
      }
    }

    final trimmedDelegate = team.delegateName?.trim();
    final sanitizedTeam = team.copyWith(
      name: trimmedName,
      shortCode: trimmedShortCode.toUpperCase(),
      tournamentId: tournament?.id ?? team.tournamentId,
      delegateName:
          (trimmedDelegate != null && trimmedDelegate.isNotEmpty)
              ? trimmedDelegate
              : null,
      clearDelegateName: trimmedDelegate == null || trimmedDelegate.isEmpty,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(sanitizedTeam);
  }

  /// Moves an enrolled team to a target group in a tournament.
  ///
  /// Enforces Organizer role and editable tournament status.
  Future<TournamentTeam> moveTeamToGroup({
    required String teamId,
    required String groupName,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureTournamentManagementPermission(actorRole);
    _ensureEditableTournament(tournament);

    final teams = await _repository.loadTeamsForTournament(tournament.id);
    final index = teams.indexWhere((t) => t.id == teamId);
    if (index < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamNotFound,
        'Equipo no encontrado en la competición',
      );
    }

    final team = teams[index];
    final updatedTeam = team.copyWith(
      groupName: groupName.trim(),
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(updatedTeam);
  }

  /// Removes an enrolled team from a tournament.
  ///
  /// Enforces Organizer role and editable tournament status.
  /// Blocks removal if the team has matches that are inProgress or completed.
  /// Cleans up any scheduled/pending matches belonging to this team.
  Future<void> removeTeamFromCompetition({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureTournamentManagementPermission(actorRole);
    _ensureEditableTournament(tournament);

    if (_matchesRepository != null) {
      final tournamentMatches = await _matchesRepository
          .loadMatchesForTournament(tournament.id);
      final hasPlayedMatches = tournamentMatches.any(
        (m) =>
            (m.homeTeamId == teamId || m.awayTeamId == teamId) &&
            (m.status == MatchStatus.inProgress ||
                m.status == MatchStatus.completed),
      );

      if (hasPlayedMatches) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.teamHasPlayedMatches,
          'No se puede retirar un equipo que ya tiene partidos en curso o finalizados',
        );
      }

      final remainingMatches = tournamentMatches
          .where((m) => m.homeTeamId != teamId && m.awayTeamId != teamId)
          .toList();
      await _matchesRepository.replaceMatchesForTournament(
        tournament.id,
        remainingMatches,
      );
    }

    await _repository.deleteTeam(teamId);
  }

  /// Safely deletes a coach-owned [team] from local and remote storage.
  ///
  /// Enforces owner permission, blocks deletion when [tournament] is in progress
  /// or finished, and blocks deletion when any match references [team.id].
  Future<void> deleteCoachTeam({
    required TournamentTeam team,
    ChampionshipTournament? tournament,
    required String actorUserId,
    required UserRole actorRole,
  }) async {
    _ensureRosterManagementPermission(actorRole);
    if (actorRole == UserRole.coach &&
        (team.coachId == null || team.coachId != actorUserId)) {
      throw const UnauthorizedRoleFailure(
        'Solo el entrenador propietario puede eliminar este equipo',
      );
    }
    if (tournament != null &&
        tournament.status != TournamentStatus.openRegistration) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamInActiveOrFinishedTournament,
        'No puedes eliminar un equipo inscrito en un campeonato en curso o finalizado',
      );
    }
    if (_matchesRepository != null) {
      final matchesToCheck = team.tournamentId.trim().isNotEmpty
          ? await _matchesRepository.loadMatchesForTournament(team.tournamentId)
          : await _matchesRepository.loadAllMatches();
      final hasAssociatedMatches = matchesToCheck.any(
        (m) => m.homeTeamId == team.id || m.awayTeamId == team.id,
      );
      if (hasAssociatedMatches) {
        throw const TeamEligibilityValidationFailure(
          TeamEligibilityErrorCode.teamHasPlayedMatches,
          'No puedes eliminar un equipo que ya tiene partidos registrados',
        );
      }
    }
    await _repository.deleteTeam(team.id);
  }

  /// Enrolls a team into a championship competition from the Organizer's perspective.
  ///
  /// Throws [UnauthorizedRoleFailure] if [actorRole] does not have [RoleCapability.manageTournaments].
  /// Throws [TeamEligibilityValidationFailure] if tournament is not editable, fields are invalid,
  /// or team name collides within the tournament.
  Future<TournamentTeam> enrollTeamInCompetition({
    required TournamentTeam team,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureTournamentManagementPermission(actorRole);
    _ensureEditableTournament(tournament);

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
      tournamentId: tournament.id,
      name: trimmedName,
      shortCode: trimmedShortCode.toUpperCase(),
      groupName: team.groupName?.trim().isNotEmpty == true
          ? team.groupName!.trim()
          : null,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(sanitizedTeam);
  }

  /// Enrolls an existing catalog club into a championship competition with
  /// [TeamEligibilityStatus.pendingVerification], copying its identity and
  /// non-conflicting base roster players (marked pending validation).
  Future<EnrollExistingTeamResult> enrollExistingTeamFromCatalog({
    required TournamentTeam sourceTeam,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    String? generatedTeamId,
  }) async {
    _ensureTournamentManagementPermission(actorRole);
    _ensureEditableTournament(tournament);

    final trimmedName = sourceTeam.name.trim();
    if (trimmedName.length < 3) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidTeamName,
        'El nombre del equipo debe tener al menos 3 caracteres',
      );
    }

    final trimmedShortCode = sourceTeam.shortCode.trim();
    if (trimmedShortCode.length < 2 || trimmedShortCode.length > 4) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidShortCode,
        'La sigla debe tener entre 2 y 4 caracteres',
      );
    }

    final tournamentTeams = await _repository.loadTeamsForTournament(
      tournament.id,
    );

    final targetNormalizedQueryName = normalizeSearchText(trimmedName);
    final isDuplicate = tournamentTeams.any(
      (t) =>
          t.id == sourceTeam.id ||
          t.normalizedName == sourceTeam.normalizedName ||
          normalizeSearchText(t.name) == targetNormalizedQueryName,
    );
    if (isDuplicate) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateTeamNameInTournament,
        'Ya existe un equipo con este nombre en este campeonato',
      );
    }

    final assignedGroupName =
        tournament.format == TournamentFormat.mixedGroupsAndKnockout
        ? StandingsCalculatorService.resolveLeastPopulatedGroupName(
            groupCount: tournament.rules.groupStageConfig.groupCount,
            tournamentTeams: tournamentTeams,
          )
        : null;

    const uuid = Uuid();
    final newTeamId = generatedTeamId ?? uuid.v4();
    final existingDocs = tournamentTeams
        .expand((t) => t.players.map((p) => p.normalizedDocumentId))
        .toSet();

    final copiedPlayers = <RegisteredPlayer>[];
    var skippedConflictingCount = 0;
    for (final player in sourceTeam.players) {
      final normalizedDoc = player.normalizedDocumentId;
      if (existingDocs.contains(normalizedDoc) ||
          copiedPlayers.length >= tournament.rules.maxPlayersPerTeam) {
        skippedConflictingCount++;
        continue;
      }
      existingDocs.add(normalizedDoc);
      copiedPlayers.add(player.copyWith(id: uuid.v4(), isEligible: false));
    }

    final enrolledTeam = TournamentTeam(
      id: newTeamId,
      tournamentId: tournament.id,
      name: trimmedName,
      shortCode: trimmedShortCode.toUpperCase(),
      crestShape: sourceTeam.crestShape,
      primaryColorHex: sourceTeam.primaryColorHex,
      secondaryColorHex: sourceTeam.secondaryColorHex,
      eligibilityStatus: TeamEligibilityStatus.pendingVerification,
      players: copiedPlayers,
      groupName: assignedGroupName,
      coachId: sourceTeam.coachId,
      coachName: sourceTeam.coachName,
      categoryLabel: tournament.category,
      delegateName: sourceTeam.delegateName,
      foundedDate: sourceTeam.foundedDate,
      crestUrl: sourceTeam.crestUrl,
      updatedAt: DateTime.now(),
    );

    final savedTeam = await _repository.saveTeam(enrolledTeam);
    return EnrollExistingTeamResult(
      enrolledTeam: savedTeam,
      copiedPlayersCount: copiedPlayers.length,
      skippedConflictingPlayersCount: skippedConflictingCount,
      assignedGroupName: assignedGroupName,
    );
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
      newStatus = TeamEligibilityStatus.pendingVerification;
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

    final minRequired = tournament.rules.minPlayersPerTeam;

    if (updatedPlayers.length < minRequired) {
      newStatus = TeamEligibilityStatus.pendingVerification;
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
  /// Authorized for [UserRole.coach] (via [RoleCapability.manageTeamRoster])
  /// and [UserRole.organizer] (via [RoleCapability.approveRegistrations]).
  /// Requires player count within [max(11, minPlayersPerTeam), maxPlayersPerTeam].
  Future<TournamentTeam> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    final canApprove =
        actorRole == UserRole.coach ||
        RolePermissionMatrix.hasCapability(
          actorRole,
          RoleCapability.manageTeamRoster,
        ) ||
        RolePermissionMatrix.hasCapability(
          actorRole,
          RoleCapability.approveRegistrations,
        );
    if (!canApprove) {
      throw const UnauthorizedRoleFailure(
        'Solo el Entrenador o el Organizador pueden habilitar a un equipo',
      );
    }

    if (tournament.id.isNotEmpty &&
        tournament.status == TournamentStatus.finished) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
      );
    }

    final candidateTeams = tournament.id.isNotEmpty
        ? await _repository.loadTeamsForTournament(tournament.id)
        : await _repository.loadTeams();

    final teamIndex = candidateTeams.indexWhere((t) => t.id == teamId);
    if (teamIndex < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.teamNotFound,
        'Equipo no encontrado',
      );
    }

    final targetTeam = candidateTeams[teamIndex];
    final playerCount = targetTeam.players.length;
    final minRequired = tournament.rules.minPlayersPerTeam > 11
        ? tournament.rules.minPlayersPerTeam
        : 11;

    if (playerCount < minRequired) {
      throw TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.insufficientPlayersForApproval,
        'El equipo no cumple la cuota reglamentaria mínima (mínimo $minRequired jugadores requeridos, actual: $playerCount)',
      );
    }

    if (playerCount > tournament.rules.maxPlayersPerTeam) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.insufficientPlayersForApproval,
        'El equipo excede el cupo máximo de jugadores permitido por el campeonato',
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

  /// Officially revokes a team's eligibility, reverting it to [TeamEligibilityStatus.pendingVerification].
  ///
  /// Restricted to roles with [RoleCapability.approveRegistrations] (Organizer).
  Future<TournamentTeam> revokeTeamEligibility({
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
        'Solo el Organizador puede inhabilitar oficialmente a un equipo',
      );
    }

    if (tournament.status == TournamentStatus.finished) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
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
    final unapprovedPlayers = targetTeam.players
        .map((p) => p.copyWith(isEligible: false))
        .toList();

    final revokedTeam = targetTeam.copyWith(
      eligibilityStatus: TeamEligibilityStatus.pendingVerification,
      players: unapprovedPlayers,
      updatedAt: DateTime.now(),
    );

    return _repository.saveTeam(revokedTeam);
  }

  void _ensureTournamentManagementPermission(UserRole role) {
    if (!RolePermissionMatrix.hasCapability(
      role,
      RoleCapability.manageTournaments,
    )) {
      throw const UnauthorizedRoleFailure(
        'Solo el Organizador puede gestionar la inscripción de equipos en la competición',
      );
    }
  }

  void _ensureEditableTournament(ChampionshipTournament tournament) {
    if (!tournament.status.isEditable) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
      );
    }
  }

  String _normalizeTeamKey(String name) =>
      normalizeSearchText(name).replaceAll(RegExp(r'\s+'), ' ');

  void _ensureRosterManagementPermission(UserRole role) {
    if (!RolePermissionMatrix.hasCapability(
      role,
      RoleCapability.manageTeamRoster,
    )) {
      throw const UnauthorizedRoleFailure(
        'Solo los entrenadores pueden registrar equipos o futbolistas',
      );
    }
  }

  void _ensureOpenRegistration(ChampionshipTournament tournament) {
    if (tournament.status == TournamentStatus.finished) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'El campeonato ha finalizado y se encuentra en modo de solo lectura histórica.',
      );
    }
    if (tournament.status != TournamentStatus.openRegistration) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.tournamentRegistrationsClosed,
        'Las inscripciones de este campeonato están cerradas',
      );
    }
  }
}
