import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/team_join_requests_repository.dart';

/// Local offline-first implementation of [TeamJoinRequestsRepository] backed by [LocalStorageRepository].
class LocalTeamJoinRequestsRepository implements TeamJoinRequestsRepository {
  LocalTeamJoinRequestsRepository({
    required this.storage,
    this.config,
    this.uuid = const Uuid(),
  });

  final LocalStorageRepository storage;
  final EnvironmentConfig? config;
  final Uuid uuid;

  static const String storageKey = 'vifutbol.team_join_requests.v1';
  static const String accountsStorageKey = 'auth_accounts';
  static const String sessionStorageKey = 'auth_session';

  Future<List<TeamJoinRequest>> _loadAll() async {
    final raw = await storage.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <TeamJoinRequest>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TeamJoinRequest.fromJson)
          .toList();
    } catch (_) {
      return <TeamJoinRequest>[];
    }
  }

  Future<void> _persist(List<TeamJoinRequest> requests) async {
    final encoded = jsonEncode(requests.map((r) => r.toJson()).toList());
    await storage.writeString(storageKey, encoded);
  }

  Future<UserAccount?> _getCurrentUser() async {
    final raw = await storage.readString(sessionStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final sessionMap = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromJson(sessionMap);
      return session.user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
  }) async {
    final raw = await storage.readString(accountsStorageKey);
    final candidates = <AvailablePlayerCandidate>[];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          final account = UserAccount.fromJson(item);
          final hasPlayerRole = account.authorizedRoles.contains(UserRole.player) ||
              account.activeRole == UserRole.player;
          if (hasPlayerRole) {
            candidates.add(
              AvailablePlayerCandidate(
                userAccountId: account.id,
                fullName: account.fullName,
                documentId: account.documentId ?? '',
              ),
            );
          }
        }
      } catch (_) {
        // Fallback or ignore corrupted local accounts
      }
    }

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return candidates;
    }

    return candidates.where((candidate) {
      final matchName = candidate.fullName.toLowerCase().contains(cleanQuery);
      final matchDoc = candidate.documentId.toLowerCase().contains(cleanQuery);
      return matchName || matchDoc;
    }).toList();
  }

  @override
  Future<List<TeamJoinRequest>> loadRequestsForTeam(String teamId) async {
    final all = await _loadAll();
    return all.where((r) => r.teamId == teamId).toList();
  }

  @override
  Future<List<TeamJoinRequest>> loadRequestsForCurrentPlayer() async {
    final user = await _getCurrentUser();
    if (user == null) {
      return <TeamJoinRequest>[];
    }
    final all = await _loadAll();
    return all
        .where(
          (r) =>
              r.playerAccountId == user.id &&
              r.status == TeamJoinRequestStatus.pending,
        )
        .toList();
  }

  @override
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
  }) async {
    if (shirtNumber < 1 || shirtNumber > 99) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidShirtNumber,
        'El dorsal propuesto debe estar entre 1 y 99.',
      );
    }

    // Check if shirt number already exists in roster
    final shirtInRoster = team.players.any((p) => p.shirtNumber == shirtNumber);
    if (shirtInRoster) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateShirtNumberInTeam,
        'El dorsal propuesto ya se encuentra asignado a un jugador en el equipo.',
      );
    }

    final all = await _loadAll();

    // Check if shirt is reserved in a pending request for this team
    final shirtReserved = all.any(
      (r) =>
          r.teamId == team.id &&
          r.shirtNumber == shirtNumber &&
          r.status == TeamJoinRequestStatus.pending,
    );
    if (shirtReserved) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.shirtNumberAlreadyReserved,
        'El dorsal ya tiene una solicitud pendiente en este equipo.',
      );
    }

    // Check if candidate already has a pending request in this team
    final pendingCandidate = all.any(
      (r) =>
          r.teamId == team.id &&
          r.playerAccountId == candidate.userAccountId &&
          r.status == TeamJoinRequestStatus.pending,
    );
    if (pendingCandidate) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.playerAlreadyHasPendingRequest,
        'El jugador ya tiene una solicitud pendiente de confirmación en este equipo.',
      );
    }

    // Check if candidate is already in team roster
    final candidateInRoster = team.players.any(
      (p) =>
          p.normalizedDocumentId == candidate.normalizedDocumentId ||
          p.id == candidate.userAccountId,
    );
    if (candidateInRoster) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.playerAlreadyRegisteredInTournament,
        'El jugador ya forma parte de la plantilla del equipo.',
      );
    }

    final currentUser = await _getCurrentUser();
    final now = DateTime.now();

    final request = TeamJoinRequest(
      id: uuid.v4(),
      teamId: team.id,
      tournamentTeamId: team.tournamentId.isNotEmpty ? team.id : null,
      tournamentId: team.tournamentId.isNotEmpty ? team.tournamentId : null,
      teamName: team.name,
      teamShortCode: team.shortCode,
      coachAccountId: currentUser?.id ?? '',
      coachName: currentUser?.fullName ?? team.coachName ?? '',
      playerAccountId: candidate.userAccountId,
      playerName: candidate.fullName,
      playerDocumentId: candidate.documentId,
      shirtNumber: shirtNumber,
      position: position,
      status: TeamJoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    all.add(request);
    await _persist(all);
    return request;
  }

  @override
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    final all = await _loadAll();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index < 0) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.joinRequestNotFound,
        'No se encontró la solicitud de unión especificada.',
      );
    }

    final current = all[index];
    final updated = current.copyWith(
      status:
          accept ? TeamJoinRequestStatus.accepted : TeamJoinRequestStatus.rejected,
      updatedAt: DateTime.now(),
    );

    all[index] = updated;
    await _persist(all);
    return updated;
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    final all = await _loadAll();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index < 0) {
      return;
    }

    all[index] = all[index].copyWith(
      status: TeamJoinRequestStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _persist(all);
  }
}
