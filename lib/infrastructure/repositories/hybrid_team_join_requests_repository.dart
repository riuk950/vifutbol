import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/team_join_requests_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_team_join_requests_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for team join requests and registered player searches.
abstract interface class TeamJoinRequestsRemoteDataSource {
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
  });
  Future<List<TeamJoinRequest>> fetchRequestsForTeam(String teamId);
  Future<List<TeamJoinRequest>> fetchRequestsForCurrentPlayer();
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
  });
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
  });
  Future<void> cancelJoinRequest(String requestId);
}

/// PostgREST implementation of [TeamJoinRequestsRemoteDataSource] targeting `vifutboldev`.
class PostgrestTeamJoinRequestsRemoteDataSource
    implements TeamJoinRequestsRemoteDataSource {
  PostgrestTeamJoinRequestsRemoteDataSource({
    required this.client,
    required this.schema,
  });

  final SupabaseClient client;
  final String schema;

  static TeamJoinRequest _fromRow(Map<String, dynamic> row) {
    final teamMap =
        row['teams'] is Map ? row['teams'] as Map<String, dynamic> : null;
    final coachMap =
        row['coach'] is Map ? row['coach'] as Map<String, dynamic> : null;
    final playerMap =
        row['player'] is Map ? row['player'] as Map<String, dynamic> : null;

    final teamName =
        teamMap?['name'] as String? ?? (row['team_name'] as String? ?? '');
    final teamShortCode =
        teamMap?['short_code'] as String? ??
        (row['team_short_code'] as String? ?? '');
    final coachName =
        coachMap?['full_name'] as String? ??
        (row['coach_name'] as String? ?? '');
    final playerName =
        playerMap?['full_name'] as String? ??
        (row['player_name'] as String? ?? '');
    final playerDocumentId =
        playerMap?['document_id'] as String? ??
        (row['player_document_id'] as String? ?? '');

    return TeamJoinRequest(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      tournamentTeamId: row['tournament_team_id'] as String?,
      tournamentId: row['tournament_id'] as String?,
      teamName: teamName,
      teamShortCode: teamShortCode,
      coachAccountId: row['coach_account_id'] as String? ?? '',
      coachName: coachName,
      playerAccountId: row['player_account_id'] as String? ?? '',
      playerName: playerName,
      playerDocumentId: playerDocumentId,
      shirtNumber: (row['shirt_number'] as num).toInt(),
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == row['position'],
        orElse: () => PlayerPosition.forward,
      ),
      status: TeamJoinRequestStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => TeamJoinRequestStatus.pending,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
  }) async {
    final res = await client
        .schema(schema)
        .rpc('search_registered_players', params: {'p_query': query});

    if (res is! List) {
      return <AvailablePlayerCandidate>[];
    }

    return res
        .whereType<Map<String, dynamic>>()
        .map(AvailablePlayerCandidate.fromJson)
        .toList();
  }

  @override
  Future<List<TeamJoinRequest>> fetchRequestsForTeam(String teamId) async {
    final cleanTeamId = HybridRepositorySupport.ensureUuid(teamId, 'team');
    final res = await client
        .schema(schema)
        .from('team_join_requests')
        .select(
          '*, teams(name, short_code), coach:user_accounts!team_join_requests_coach_account_id_fkey(full_name), player:user_accounts!team_join_requests_player_account_id_fkey(full_name, document_id)',
        )
        .eq('team_id', cleanTeamId)
        .order('created_at', ascending: false);

    return (res as List)
        .whereType<Map<String, dynamic>>()
        .map(_fromRow)
        .toList();
  }

  @override
  Future<List<TeamJoinRequest>> fetchRequestsForCurrentPlayer() async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      return <TeamJoinRequest>[];
    }

    // Lookup user_account id from auth user id
    final accountRes = await client
        .schema(schema)
        .from('user_accounts')
        .select('id')
        .eq('auth_user_id', currentUserId)
        .maybeSingle();

    final accountId = accountRes?['id'] as String?;
    if (accountId == null) {
      return <TeamJoinRequest>[];
    }

    final res = await client
        .schema(schema)
        .from('team_join_requests')
        .select(
          '*, teams(name, short_code), coach:user_accounts!team_join_requests_coach_account_id_fkey(full_name), player:user_accounts!team_join_requests_player_account_id_fkey(full_name, document_id)',
        )
        .eq('player_account_id', accountId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (res as List)
        .whereType<Map<String, dynamic>>()
        .map(_fromRow)
        .toList();
  }

  @override
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
  }) async {
    final currentUserId = client.auth.currentUser?.id;
    String? coachAccountId;
    if (currentUserId != null) {
      final accountRes = await client
          .schema(schema)
          .from('user_accounts')
          .select('id')
          .eq('auth_user_id', currentUserId)
          .maybeSingle();
      coachAccountId = accountRes?['id'] as String?;
    }

    final cleanTeamId = HybridRepositorySupport.ensureUuid(team.id, 'team');
    final cleanTournamentTeamId =
        team.tournamentId.isNotEmpty
            ? HybridRepositorySupport.ensureUuid(team.id, 'tournament_team')
            : null;
    final cleanCandidateId = HybridRepositorySupport.ensureUuid(
      candidate.userAccountId,
      'user_account',
    );

    final payload = <String, dynamic>{
      'team_id': cleanTeamId,
      'tournament_team_id': ?cleanTournamentTeamId,
      'coach_account_id': coachAccountId ?? cleanCandidateId,
      'player_account_id': cleanCandidateId,
      'shirt_number': shirtNumber,
      'position': position.name,
      'status': 'pending',
    };

    final res = await client
        .schema(schema)
        .from('team_join_requests')
        .insert(payload)
        .select(
          '*, teams(name, short_code), coach:user_accounts!team_join_requests_coach_account_id_fkey(full_name), player:user_accounts!team_join_requests_player_account_id_fkey(full_name, document_id)',
        )
        .single();

    return _fromRow(Map<String, dynamic>.from(res));
  }

  @override
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    final cleanId = HybridRepositorySupport.ensureUuid(requestId, 'join_request');
    final res = await client
        .schema(schema)
        .rpc(
          'respond_team_join_request',
          params: {'p_request_id': cleanId, 'p_accept': accept},
        );

    if (res is Map) {
      // Re-fetch request with joins for complete metadata
      try {
        final fullRow = await client
            .schema(schema)
            .from('team_join_requests')
            .select(
              '*, teams(name, short_code), coach:user_accounts!team_join_requests_coach_account_id_fkey(full_name), player:user_accounts!team_join_requests_player_account_id_fkey(full_name, document_id)',
            )
            .eq('id', cleanId)
            .single();
        return _fromRow(Map<String, dynamic>.from(fullRow));
      } catch (_) {
        return _fromRow(Map<String, dynamic>.from(res));
      }
    }

    throw const TeamEligibilityValidationFailure(
      TeamEligibilityErrorCode.joinRequestNotFound,
      'Error al procesar la respuesta a la solicitud.',
    );
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    final cleanId = HybridRepositorySupport.ensureUuid(requestId, 'join_request');
    await client
        .schema(schema)
        .from('team_join_requests')
        .update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', cleanId);
  }
}

/// Hybrid implementation combining [LocalTeamJoinRequestsRepository] and
/// [TeamJoinRequestsRemoteDataSource] with offline fallback.
class HybridTeamJoinRequestsRepository implements TeamJoinRequestsRepository {
  HybridTeamJoinRequestsRepository({
    required this.local,
    this.remote,
    required this.connectivity,
  });

  final LocalTeamJoinRequestsRepository local;
  final TeamJoinRequestsRemoteDataSource? remote;
  final ConnectivityRepository connectivity;

  Future<bool> _isOnline() async {
    if (remote == null) return false;
    final status = await connectivity.checkConnectivity();
    return status.isConnected;
  }

  @override
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
  }) async {
    if (await _isOnline()) {
      try {
        final remoteCandidates =
            await remote!.searchRegisteredPlayers(query: query);
        if (remoteCandidates.isNotEmpty) {
          return remoteCandidates;
        }
      } catch (_) {
        // Fallback to local
      }
    }
    return local.searchRegisteredPlayers(query: query);
  }

  @override
  Future<List<TeamJoinRequest>> loadRequestsForTeam(String teamId) async {
    if (await _isOnline()) {
      try {
        final remoteRequests = await remote!.fetchRequestsForTeam(teamId);
        for (final r in remoteRequests) {
          // Sync to local
          final localAll = await local.loadRequestsForTeam(teamId);
          if (!localAll.any((l) => l.id == r.id)) {
            // Save newly fetched request locally
            // We can also let local repository mirror it
          }
        }
        return remoteRequests;
      } catch (_) {
        // Fallback to local
      }
    }
    return local.loadRequestsForTeam(teamId);
  }

  @override
  Future<List<TeamJoinRequest>> loadRequestsForCurrentPlayer() async {
    if (await _isOnline()) {
      try {
        final remoteRequests = await remote!.fetchRequestsForCurrentPlayer();
        return remoteRequests;
      } catch (_) {
        // Fallback to local
      }
    }
    return local.loadRequestsForCurrentPlayer();
  }

  @override
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
  }) async {
    if (await _isOnline()) {
      try {
        final result = await remote!.sendJoinRequest(
          team: team,
          candidate: candidate,
          shirtNumber: shirtNumber,
          position: position,
        );
        // Also persist locally for offline cache
        await local.sendJoinRequest(
          team: team,
          candidate: candidate,
          shirtNumber: shirtNumber,
          position: position,
        );
        return result;
      } catch (e) {
        if (e is AppFailure) rethrow;
        // If network failure, fall back to local
      }
    }
    return local.sendJoinRequest(
      team: team,
      candidate: candidate,
      shirtNumber: shirtNumber,
      position: position,
    );
  }

  @override
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    if (await _isOnline()) {
      try {
        final result = await remote!.respondToJoinRequest(
          requestId: requestId,
          accept: accept,
        );
        try {
          await local.respondToJoinRequest(
            requestId: requestId,
            accept: accept,
          );
        } catch (_) {}
        return result;
      } catch (e) {
        if (e is AppFailure) rethrow;
      }
    }
    return local.respondToJoinRequest(requestId: requestId, accept: accept);
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    if (await _isOnline()) {
      try {
        await remote!.cancelJoinRequest(requestId);
      } catch (_) {}
    }
    await local.cancelJoinRequest(requestId);
  }
}
