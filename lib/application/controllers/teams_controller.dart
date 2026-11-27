import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// State notifier managing the teams catalog, player rosters, and team eligibility.
class TeamsController extends StateNotifier<TeamsCatalogState> {
  TeamsController({
    required this.teamsRepository,
    required this.manageTeamsEligibilityUseCase,
  }) : super(const TeamsCatalogState()) {
    loadTeams();
  }

  final TeamsRepository teamsRepository;
  final ManageTeamsEligibilityUseCase manageTeamsEligibilityUseCase;

  /// Loads all persisted teams across championships.
  Future<void> loadTeams() async {
    try {
      final teams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: teams, clearLastFailure: true);
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(lastFailure: failure);
    }
  }

  /// Sets the currently selected team ID for roster inspection and management.
  void selectTeam(String? teamId) {
    if (teamId == null) {
      state = state.copyWith(clearSelectedTeamId: true);
    } else {
      state = state.copyWith(selectedTeamId: teamId);
    }
  }

  /// Registers a new team or updates an existing team with single-flight protection.
  Future<bool> registerOrUpdateTeam({
    required TournamentTeam team,
    ChampionshipTournament? tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final saved = await manageTeamsEligibilityUseCase.registerOrUpdateTeam(
        team: team,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: saved.id,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidTeamName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Creates a new autonomous or tournament-enrolled team for a coach or organizer.
  Future<bool> createTeam({
    required String name,
    required String shortCode,
    String? delegateName,
    DateTime? foundedDate,
    int primaryColorHex = 0xFF00E676,
    int secondaryColorHex = 0xFF0A0E17,
    String? crestUrl,
    ChampionshipTournament? tournament,
    String coachId = 'coach-seed-1',
    UserRole actorRole = UserRole.coach,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final team = TournamentTeam(
        id: const Uuid().v4(),
        tournamentId: tournament?.id ?? '',
        name: name,
        shortCode: shortCode,
        crestShape: TeamCrestShape.circle,
        primaryColorHex: primaryColorHex,
        secondaryColorHex: secondaryColorHex,
        delegateName: delegateName,
        foundedDate: foundedDate,
        crestUrl: crestUrl,
        coachId: coachId,
      );

      final saved = await manageTeamsEligibilityUseCase.registerOrUpdateTeam(
        team: team,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: saved.id,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidTeamName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Updates an existing team owned by a coach or organizer with single-flight protection.
  Future<bool> updateTeam({
    required TournamentTeam existingTeam,
    required String name,
    required String shortCode,
    String? delegateName,
    DateTime? foundedDate,
    int primaryColorHex = 0xFF00E676,
    int secondaryColorHex = 0xFF0A0E17,
    String? crestUrl,
    bool clearCrestUrl = false,
    ChampionshipTournament? tournament,
    String? actorUserId,
    UserRole actorRole = UserRole.coach,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final updatedCandidate = existingTeam.copyWith(
        name: name,
        shortCode: shortCode,
        delegateName: delegateName,
        clearDelegateName: delegateName == null || delegateName.trim().isEmpty,
        foundedDate: foundedDate,
        clearFoundedDate: foundedDate == null,
        primaryColorHex: primaryColorHex,
        secondaryColorHex: secondaryColorHex,
        crestUrl: crestUrl,
        clearCrestUrl: clearCrestUrl,
        tournamentId: tournament?.id ?? '',
      );

      final saved = await manageTeamsEligibilityUseCase.registerOrUpdateTeam(
        team: updatedCandidate,
        tournament: tournament,
        actorRole: actorRole,
        isEdit: true,
        actorUserId: actorUserId,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: saved.id,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidTeamName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Safely deletes a coach-owned team with single-flight protection and selection fallback.
  Future<bool> deleteCoachTeam({
    required TournamentTeam team,
    ChampionshipTournament? tournament,
    required String actorUserId,
    UserRole actorRole = UserRole.coach,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.deleteCoachTeam(
        team: team,
        tournament: tournament,
        actorUserId: actorUserId,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      final nextCoachTeam = updatedTeams
          .where((t) => t.coachId == team.coachId)
          .firstOrNull;
      final nextSelectedId = state.selectedTeamId == team.id
          ? nextCoachTeam?.id
          : state.selectedTeamId;

      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: nextSelectedId,
        clearSelectedTeamId: nextSelectedId == null,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.teamNotFound,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Enrolls a team into a competition from the Organizer's workflow with single-flight protection.
  Future<bool> enrollTeamInCompetition({
    required TournamentTeam team,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final saved = await manageTeamsEligibilityUseCase.enrollTeamInCompetition(
        team: team,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: saved.id,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidTeamName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Enrolls an existing catalog club into a competition with single-flight protection,
  /// returning structured enrollment counts (copied & skipped players).
  Future<EnrollExistingTeamResult?> enrollExistingTeamFromCatalog({
    required TournamentTeam sourceTeam,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return null;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final result = await manageTeamsEligibilityUseCase
          .enrollExistingTeamFromCatalog(
            sourceTeam: sourceTeam,
            tournament: tournament,
            actorRole: actorRole,
          );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        selectedTeamId: result.enrolledTeam.id,
        isSaving: false,
      );
      return result;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidTeamName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return null;
    }
  }

  /// Moves an enrolled team to a target group in the competition.
  Future<bool> moveTeamToGroup({
    required String teamId,
    required String groupName,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.moveTeamToGroup(
        teamId: teamId,
        groupName: groupName,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: updatedTeams, isSaving: false);
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.teamNotFound,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Removes an enrolled team from a competition.
  Future<bool> removeTeamFromCompetition({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.removeTeamFromCompetition(
        teamId: teamId,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(
        teams: updatedTeams,
        clearSelectedTeamId: state.selectedTeamId == teamId,
        isSaving: false,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.teamNotFound,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Enrolls or updates a player in a team roster.
  Future<bool> enrollOrUpdatePlayer({
    required String teamId,
    required RegisteredPlayer player,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.enrollOrUpdatePlayer(
        teamId: teamId,
        player: player,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: updatedTeams, isSaving: false);
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.invalidPlayerName,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Removes a player from a team roster.
  Future<bool> removePlayer({
    required String teamId,
    required String playerId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.removePlayer(
        teamId: teamId,
        playerId: playerId,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: updatedTeams, isSaving: false);
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Approves the official eligibility of a team (Organizer only).
  Future<bool> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.approveTeamEligibility(
        teamId: teamId,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: updatedTeams, isSaving: false);
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : const TeamEligibilityValidationFailure(
              TeamEligibilityErrorCode.insufficientPlayersForApproval,
            );
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Revokes the official eligibility of a team (Organizer only).
  Future<bool> revokeTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageTeamsEligibilityUseCase.revokeTeamEligibility(
        teamId: teamId,
        tournament: tournament,
        actorRole: actorRole,
      );

      final updatedTeams = await teamsRepository.loadTeams();
      state = state.copyWith(teams: updatedTeams, isSaving: false);
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }
}
