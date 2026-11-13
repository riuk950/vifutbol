import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `teams`, `tournament_teams`, and `players`.
abstract interface class TeamsRemoteDataSource {
  Future<List<TournamentTeam>> fetchAll();
  Future<List<TournamentTeam>> fetchForTournament(String tournamentId);
  Future<TournamentTeam> upsert(TournamentTeam team);
  Future<void> replaceForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  );
  Future<void> deleteById(String teamId);
}

/// PostgREST implementation targeting `vifutboldev.teams`, `tournament_teams`, and `players`.
class PostgrestTeamsRemoteDataSource implements TeamsRemoteDataSource {
  PostgrestTeamsRemoteDataSource({required this.client, required this.schema});

  final SupabaseClient client;
  final String schema;

  static String _normalizeShortCode(String code, String fallbackName) {
    final trimmed = code.trim();
    if (trimmed.length >= 2 && trimmed.length <= 4) {
      return trimmed.toUpperCase();
    }
    if (trimmed.length > 4) {
      return trimmed.substring(0, 4).toUpperCase();
    }
    final cleanName = fallbackName.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final combined = '${trimmed.toUpperCase()}$cleanName';
    if (combined.length >= 2) {
      return combined.substring(0, combined.length >= 3 ? 3 : 2);
    }
    return 'TM';
  }

  @override
  Future<List<TournamentTeam>> fetchAll() async {
    final rows = await client
        .schema(schema)
        .from('tournament_teams')
        .select('*, teams(*), players(*)')
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => _fromEnrollmentRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<TournamentTeam>> fetchForTournament(String tournamentId) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final rows = await client
        .schema(schema)
        .from('tournament_teams')
        .select('*, teams(*), players(*)')
        .eq('tournament_id', safeTournamentId)
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => _fromEnrollmentRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<TournamentTeam> upsert(TournamentTeam team) async {
    final nowIso = team.updatedAt.toUtc().toIso8601String();
    final safeCode = _normalizeShortCode(team.shortCode, team.name);
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      team.id,
      'tournament_team',
    );

    // Check if an enrollment row already points to an existing master team_id.
    final existingEnrollment = await client
        .schema(schema)
        .from('tournament_teams')
        .select('team_id')
        .eq('id', safeTeamId)
        .maybeSingle();

    final masterTeamId = (existingEnrollment?['team_id'] as String?) ??
        HybridRepositorySupport.ensureUuid(team.id, 'team');

    // 1. Upsert parent club in `teams`
    await client.schema(schema).from('teams').upsert({
      'id': masterTeamId,
      'coach_id': HybridRepositorySupport.uuidOrNull(team.coachId),
      'name': team.name,
      'normalized_name': team.normalizedName,
      'short_code': safeCode,
      'crest_shape': team.crestShape.name,
      'primary_color_hex': team.primaryColorHex,
      'secondary_color_hex': team.secondaryColorHex,
      'updated_at': nowIso,
    }, onConflict: 'id');

    // 2. Upsert enrollment in `tournament_teams` when tournamentId is present
    if (team.tournamentId.trim().isNotEmpty) {
      final safeTournamentId = HybridRepositorySupport.ensureUuid(
        team.tournamentId,
        'tournament',
      );
      await client.schema(schema).from('tournament_teams').upsert({
        'id': safeTeamId,
        'tournament_id': safeTournamentId,
        'team_id': masterTeamId,
        'group_name': team.groupName,
        'eligibility_status': team.eligibilityStatus.name,
        'updated_at': nowIso,
      }, onConflict: 'id');

      // 3. Upsert players and prune removed roster entries
      final desiredPlayerIds = team.players
          .map((p) => HybridRepositorySupport.ensureUuid(p.id, 'player'))
          .toSet();
      final existingPlayersRows = await client
          .schema(schema)
          .from('players')
          .select('id')
          .eq('tournament_team_id', safeTeamId);
      final removedIds = (existingPlayersRows as List<dynamic>)
          .map((r) => (r as Map)['id'] as String)
          .where((id) => !desiredPlayerIds.contains(id))
          .toList();
      if (removedIds.isNotEmpty) {
        await client
            .schema(schema)
            .from('players')
            .delete()
            .inFilter('id', removedIds);
      }

      if (team.players.isNotEmpty) {
        final playerRows = team.players
            .map(
              (p) => <String, dynamic>{
                'id': HybridRepositorySupport.ensureUuid(p.id, 'player'),
                'tournament_team_id': safeTeamId,
                'tournament_id': safeTournamentId,
                'full_name': p.fullName,
                'document_id': p.documentId,
                'normalized_document_id': p.normalizedDocumentId,
                'shirt_number': p.shirtNumber,
                'position': p.position.name,
                'is_eligible': p.isEligible,
                'updated_at': nowIso,
              },
            )
            .toList();
        await client
            .schema(schema)
            .from('players')
            .upsert(playerRows, onConflict: 'id');
      }
    }

    return team;
  }

  @override
  Future<void> replaceForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) async {
    for (final team in teams) {
      await upsert(team);
    }
  }

  @override
  Future<void> deleteById(String teamId) async {
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      teamId,
      'tournament_team',
    );
    await client
        .schema(schema)
        .from('tournament_teams')
        .delete()
        .eq('id', safeTeamId);
  }

  TournamentTeam _fromEnrollmentRow(Map<String, dynamic> row) {
    final teamMap = row['teams'] is Map
        ? Map<String, dynamic>.from(row['teams'] as Map)
        : const <String, dynamic>{};
    final rawPlayers = (row['players'] as List<dynamic>?) ?? const [];

    final players = rawPlayers
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .map(
          (p) => RegisteredPlayer(
            id: p['id'] as String,
            fullName: p['full_name'] as String,
            documentId: p['document_id'] as String,
            shirtNumber: (p['shirt_number'] as num).toInt(),
            position: PlayerPosition.values.firstWhere(
              (pos) => pos.name == p['position'],
              orElse: () => PlayerPosition.midfielder,
            ),
            isEligible: p['is_eligible'] as bool? ?? false,
          ),
        )
        .toList();

    return TournamentTeam(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String? ?? '',
      name: teamMap['name'] as String? ?? 'Equipo',
      shortCode: teamMap['short_code'] as String? ?? 'EQ',
      crestShape: TeamCrestShape.values.firstWhere(
        (s) => s.name == teamMap['crest_shape'],
        orElse: () => TeamCrestShape.shield,
      ),
      primaryColorHex:
          (teamMap['primary_color_hex'] as num?)?.toInt() ?? 0xFF00E676,
      secondaryColorHex:
          (teamMap['secondary_color_hex'] as num?)?.toInt() ?? 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.fromJson(
        row['eligibility_status'] as String? ?? 'pendingVerification',
      ),
      players: players,
      groupName: row['group_name'] as String?,
      coachId: teamMap['coach_id'] as String?,
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

/// Offline-first hybrid [TeamsRepository] coordinating local cache, Supabase, and FIFO outbox.
class HybridTeamsRepository implements TeamsRepository {
  HybridTeamsRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalTeamsRepository local;
  final TeamsRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<TournamentTeam>> loadTeams() {
    return support.executeRead(
      remoteFetch: remote.fetchAll,
      cacheUpdate: local.replaceAllCache,
      localFallback: local.loadTeams,
    );
  }

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId) {
    return support.executeRead(
      remoteFetch: () => remote.fetchForTournament(tournamentId),
      cacheUpdate: (teams) =>
          local.replaceTeamsForTournament(tournamentId, teams),
      localFallback: () => local.loadTeamsForTournament(tournamentId),
    );
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) {
    return support.executeMutation(
      localWrite: () => local.saveTeam(team),
      remoteWrite: () => remote.upsert(team),
      entityType: SyncOutboxEntityType.team,
      entityId: team.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'team': team.toJson()},
      displayTitle: team.name,
    );
  }

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) {
    return support.executeMutation(
      localWrite: () => local.replaceTeamsForTournament(tournamentId, teams),
      remoteWrite: () => remote.replaceForTournament(tournamentId, teams),
      entityType: SyncOutboxEntityType.team,
      entityId: tournamentId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': tournamentId,
        'teams': teams.map((t) => t.toJson()).toList(),
      },
      displayTitle: tournamentId,
    );
  }

  @override
  Future<void> deleteTeam(String teamId) {
    return support.executeMutation(
      localWrite: () => local.deleteTeam(teamId),
      remoteWrite: () => remote.deleteById(teamId),
      entityType: SyncOutboxEntityType.team,
      entityId: teamId,
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {'teamId': teamId},
      displayTitle: teamId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    switch (item.operation) {
      case SyncOutboxOperation.delete:
        await remote.deleteById(item.entityId);
      case SyncOutboxOperation.upsert:
        final raw = item.payloadJson['team'];
        if (raw is Map) {
          await remote.upsert(
            TournamentTeam.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      case SyncOutboxOperation.replaceBatch:
        final tournamentId = item.payloadJson['tournamentId'] as String? ?? '';
        final rawTeams = (item.payloadJson['teams'] as List<dynamic>?) ?? [];
        final teams = rawTeams
            .whereType<Map>()
            .map((m) => TournamentTeam.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        await remote.replaceForTournament(tournamentId, teams);
    }
  }
}
