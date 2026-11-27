import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, SupabaseClient;
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
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
  Future<List<PlayerDirectoryItem>> fetchAllPlayers();
  Future<List<TeamDirectoryItem>> fetchAllTeams();
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
    List<dynamic> enrollmentRows;
    try {
      final res = await client
          .schema(schema)
          .from('tournament_teams')
          .select(
            '*, teams(*, user_accounts(full_name)), players(*), tournaments(name, category)',
          )
          .order('updated_at', ascending: false);
      enrollmentRows = res as List<dynamic>;
    } catch (_) {
      final res = await client
          .schema(schema)
          .from('tournament_teams')
          .select('*, teams(*), players(*)')
          .order('updated_at', ascending: false);
      enrollmentRows = res as List<dynamic>;
    }

    final enrolledTeams = <TournamentTeam>[];
    final enrolledMasterTeamIds = <String>{};

    for (final r in enrollmentRows) {
      final rowMap = Map<String, dynamic>.from(r as Map);
      enrolledTeams.add(_fromEnrollmentRow(rowMap));
      final masterId = rowMap['team_id'] as String? ??
          (rowMap['teams'] is Map ? (rowMap['teams'] as Map)['id'] as String? : null);
      if (masterId != null && masterId.isNotEmpty) {
        enrolledMasterTeamIds.add(masterId);
      }
    }

    List<dynamic> allTeamsRows;
    try {
      final res = await client
          .schema(schema)
          .from('teams')
          .select('*, user_accounts(full_name)')
          .order('updated_at', ascending: false);
      allTeamsRows = res as List<dynamic>;
    } catch (_) {
      try {
        final res = await client
            .schema(schema)
            .from('teams')
            .select('*')
            .order('updated_at', ascending: false);
        allTeamsRows = res as List<dynamic>;
      } catch (_) {
        allTeamsRows = const [];
      }
    }

    final standaloneTeams = <TournamentTeam>[];
    for (final rawTeam in allTeamsRows) {
      final teamMap = Map<String, dynamic>.from(rawTeam as Map);
      final teamId = teamMap['id'] as String?;
      if (teamId != null && !enrolledMasterTeamIds.contains(teamId)) {
        standaloneTeams.add(_fromStandaloneTeamRow(teamMap));
      }
    }

    return [...enrolledTeams, ...standaloneTeams];
  }

  @override
  Future<List<TournamentTeam>> fetchForTournament(String tournamentId) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    List<dynamic> rows;
    try {
      final res = await client
          .schema(schema)
          .from('tournament_teams')
          .select(
            '*, teams(*, user_accounts(full_name)), players(*), tournaments(name, category)',
          )
          .eq('tournament_id', safeTournamentId)
          .order('updated_at', ascending: false);
      rows = res as List<dynamic>;
    } catch (_) {
      final res = await client
          .schema(schema)
          .from('tournament_teams')
          .select('*, teams(*), players(*)')
          .eq('tournament_id', safeTournamentId)
          .order('updated_at', ascending: false);
      rows = res as List<dynamic>;
    }

    return rows
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

    String? resolvedMasterTeamId = existingEnrollment?['team_id'] as String?;
    String? existingCoachId;
    if (resolvedMasterTeamId == null) {
      final existingMasterByName = await client
          .schema(schema)
          .from('teams')
          .select('id, coach_id')
          .eq('normalized_name', team.normalizedName)
          .maybeSingle();
      resolvedMasterTeamId = existingMasterByName?['id'] as String?;
      existingCoachId = existingMasterByName?['coach_id'] as String?;
    }

    final masterTeamId =
        resolvedMasterTeamId ??
        HybridRepositorySupport.ensureUuid(team.id, 'team');

    // 1. Upsert parent club in `teams` (including offline-first crest upload if local path)
    String? resolvedCrestUrl =
        (team.crestUrl != null && team.crestUrl!.trim().isNotEmpty)
        ? team.crestUrl!.trim()
        : null;
    if (resolvedCrestUrl != null &&
        !resolvedCrestUrl.startsWith('http://') &&
        !resolvedCrestUrl.startsWith('https://')) {
      try {
        final localFile = File(resolvedCrestUrl);
        if (await localFile.exists()) {
          final ext = resolvedCrestUrl.split('.').last.toLowerCase();
          final mime = switch (ext) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          };
          final ownerId =
              client.auth.currentUser?.id ??
              HybridRepositorySupport.uuidOrNull(team.coachId) ??
              masterTeamId;
          final crestPath = '$ownerId/crest_$masterTeamId.$ext';
          final storage = client.storage.from('team-crests');
          await storage.upload(
            crestPath,
            localFile,
            fileOptions: FileOptions(upsert: true, contentType: mime),
          );
          resolvedCrestUrl =
              '${storage.getPublicUrl(crestPath)}?t=${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (_) {
        // Keep local path on temporary storage/network error
      }
    }

    await client.schema(schema).from('teams').upsert({
      'id': masterTeamId,
      'coach_id':
          HybridRepositorySupport.uuidOrNull(team.coachId) ?? existingCoachId,
      'name': team.name,
      'normalized_name': team.normalizedName,
      'short_code': safeCode,
      'crest_shape': team.crestShape.name,
      'primary_color_hex': team.primaryColorHex,
      'secondary_color_hex': team.secondaryColorHex,
      'crest_url': resolvedCrestUrl,
      'delegate_name': (team.delegateName != null && team.delegateName!.trim().isNotEmpty)
          ? team.delegateName!.trim()
          : null,
      'founded_date': team.foundedDate != null
          ? '${team.foundedDate!.year.toString().padLeft(4, '0')}-${team.foundedDate!.month.toString().padLeft(2, '0')}-${team.foundedDate!.day.toString().padLeft(2, '0')}'
          : null,
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
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final keepIds = teams
        .map((t) => HybridRepositorySupport.ensureUuid(t.id, 'tournament_team'))
        .toSet();

    final existingRows = await client
        .schema(schema)
        .from('tournament_teams')
        .select('id')
        .eq('tournament_id', safeTournamentId);

    final staleIds = (existingRows as List<dynamic>)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .where((id) => !keepIds.contains(id))
        .toList();

    if (staleIds.isNotEmpty) {
      await client
          .schema(schema)
          .from('tournament_teams')
          .delete()
          .eq('tournament_id', safeTournamentId)
          .inFilter('id', staleIds);
    }

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
    final enrollment = await client
        .schema(schema)
        .from('tournament_teams')
        .select('team_id')
        .eq('id', safeTeamId)
        .maybeSingle();
    final masterTeamId = enrollment?['team_id'] as String? ?? safeTeamId;

    if (enrollment != null) {
      await client
          .schema(schema)
          .from('tournament_teams')
          .delete()
          .eq('id', safeTeamId);
    }

    final remainingEnrollments = await client
        .schema(schema)
        .from('tournament_teams')
        .select('id')
        .eq('team_id', masterTeamId)
        .limit(1);
    if ((remainingEnrollments as List<dynamic>).isEmpty) {
      await client
          .schema(schema)
          .from('teams')
          .delete()
          .eq('id', masterTeamId);
    }
  }

  TournamentTeam _fromEnrollmentRow(Map<String, dynamic> row) {
    final teamMap = row['teams'] is Map
        ? Map<String, dynamic>.from(row['teams'] as Map)
        : const <String, dynamic>{};
    final tournamentMap = row['tournaments'] is Map
        ? Map<String, dynamic>.from(row['tournaments'] as Map)
        : const <String, dynamic>{};
    final userAccountsMap = teamMap['user_accounts'] is Map
        ? Map<String, dynamic>.from(teamMap['user_accounts'] as Map)
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

    final coachName = userAccountsMap['full_name'] as String? ??
        (row['coach_name'] as String?);
    final categoryLabel = tournamentMap['category'] as String? ??
        (row['category_label'] as String?);

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
      coachName: (coachName != null && coachName.trim().isNotEmpty)
          ? coachName.trim()
          : null,
      categoryLabel: (categoryLabel != null && categoryLabel.trim().isNotEmpty)
          ? categoryLabel.trim()
          : null,
      delegateName: (teamMap['delegate_name'] as String?)?.trim().isNotEmpty == true
          ? (teamMap['delegate_name'] as String).trim()
          : null,
      foundedDate: teamMap['founded_date'] is String
          ? DateTime.tryParse(teamMap['founded_date'] as String)
          : null,
      crestUrl: (teamMap['crest_url'] as String?)?.trim().isNotEmpty == true
          ? (teamMap['crest_url'] as String).trim()
          : null,
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }

  TournamentTeam _fromStandaloneTeamRow(Map<String, dynamic> teamMap) {
    final userAccountsMap = teamMap['user_accounts'] is Map
        ? Map<String, dynamic>.from(teamMap['user_accounts'] as Map)
        : const <String, dynamic>{};
    final coachName = userAccountsMap['full_name'] as String? ??
        (teamMap['coach_name'] as String?);

    return TournamentTeam(
      id: teamMap['id'] as String,
      tournamentId: '',
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
      eligibilityStatus: TeamEligibilityStatus.pendingVerification,
      players: const [],
      groupName: null,
      coachId: teamMap['coach_id'] as String?,
      coachName: (coachName != null && coachName.trim().isNotEmpty)
          ? coachName.trim()
          : null,
      categoryLabel: null,
      delegateName: (teamMap['delegate_name'] as String?)?.trim().isNotEmpty == true
          ? (teamMap['delegate_name'] as String).trim()
          : null,
      foundedDate: teamMap['founded_date'] is String
          ? DateTime.tryParse(teamMap['founded_date'] as String)
          : null,
      crestUrl: (teamMap['crest_url'] as String?)?.trim().isNotEmpty == true
          ? (teamMap['crest_url'] as String).trim()
          : null,
      updatedAt: teamMap['updated_at'] != null
          ? DateTime.parse(teamMap['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  @override
  Future<List<PlayerDirectoryItem>> fetchAllPlayers() async {
    try {
      final rows = await client
          .schema(schema)
          .from('players')
          .select(
            '*, tournament_teams(id, tournament_id, team_id, teams(id, name, short_code)), tournaments(id, name)',
          )
          .order('full_name', ascending: true);

      final List<PlayerDirectoryItem> items = [];
      for (final raw in (rows as List<dynamic>)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final tournamentTeamMap = row['tournament_teams'] is Map
            ? Map<String, dynamic>.from(row['tournament_teams'] as Map)
            : const <String, dynamic>{};
        final teamMap = tournamentTeamMap['teams'] is Map
            ? Map<String, dynamic>.from(tournamentTeamMap['teams'] as Map)
            : const <String, dynamic>{};
        final tournamentMap = row['tournaments'] is Map
            ? Map<String, dynamic>.from(row['tournaments'] as Map)
            : const <String, dynamic>{};

        final player = RegisteredPlayer(
          id: row['id'] as String,
          fullName: row['full_name'] as String,
          documentId: row['document_id'] as String,
          shirtNumber: (row['shirt_number'] as num).toInt(),
          position: PlayerPosition.values.firstWhere(
            (pos) => pos.name == row['position'],
            orElse: () => PlayerPosition.midfielder,
          ),
          isEligible: row['is_eligible'] as bool? ?? false,
        );

        items.add(
          PlayerDirectoryItem(
            player: player,
            teamId:
                tournamentTeamMap['id'] as String? ??
                (row['tournament_team_id'] as String? ?? ''),
            teamName: teamMap['name'] as String? ?? 'Equipo',
            teamShortCode: teamMap['short_code'] as String? ?? 'EQ',
            tournamentId: row['tournament_id'] as String? ?? '',
            tournamentName: tournamentMap['name'] as String? ?? '',
          ),
        );
      }
      items.sort(
        (a, b) => a.player.fullName.toLowerCase().compareTo(
          b.player.fullName.toLowerCase(),
        ),
      );
      return items;
    } catch (_) {
      final teams = await fetchAll();
      final List<PlayerDirectoryItem> items = [];
      for (final team in teams) {
        for (final p in team.players) {
          items.add(
            PlayerDirectoryItem(
              player: p,
              teamId: team.id,
              teamName: team.name,
              teamShortCode: team.shortCode,
              tournamentId: team.tournamentId,
              tournamentName: '',
            ),
          );
        }
      }
      items.sort(
        (a, b) => a.player.fullName.toLowerCase().compareTo(
          b.player.fullName.toLowerCase(),
        ),
      );
      return items;
    }
  }

  @override
  Future<List<TeamDirectoryItem>> fetchAllTeams() async {
    final rows = await client
        .schema(schema)
        .from('teams')
        .select(
          'id, coach_id, name, short_code, crest_shape, primary_color_hex, secondary_color_hex, crest_url, delegate_name, founded_date, updated_at, '
          'tournament_teams(id, tournament_id, eligibility_status, tournaments(name, category), players(id))',
        )
        .order('name', ascending: true);

    final List<TeamDirectoryItem> items = [];
    for (final raw in (rows as List<dynamic>)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final enrollments = (row['tournament_teams'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      int totalPlayers = 0;
      bool hasEligible = false;
      String? singleCategory;
      final Set<String> distinctTournamentIds = {};

      for (final enrollment in enrollments) {
        final tId = enrollment['tournament_id'] as String?;
        if (tId != null && tId.isNotEmpty) {
          distinctTournamentIds.add(tId);
        }
        final status = TeamEligibilityStatus.fromJson(
          enrollment['eligibility_status'] as String? ?? 'pendingVerification',
        );
        if (status == TeamEligibilityStatus.eligible) {
          hasEligible = true;
        }
        final playersList = enrollment['players'] as List<dynamic>? ?? [];
        totalPlayers += playersList.length;

        if (enrollments.length == 1) {
          final tournamentMap = enrollment['tournaments'] is Map
              ? Map<String, dynamic>.from(enrollment['tournaments'] as Map)
              : const <String, dynamic>{};
          final category = tournamentMap['category'] as String?;
          final tName = tournamentMap['name'] as String?;
          singleCategory = (category != null && category.trim().isNotEmpty)
              ? category
              : tName;
        }
      }

      final tournamentCount = distinctTournamentIds.isNotEmpty
          ? distinctTournamentIds.length
          : enrollments.length;

      items.add(
        TeamDirectoryItem(
          id: row['id'] as String,
          name: row['name'] as String? ?? 'Equipo',
          shortCode: row['short_code'] as String? ?? 'EQ',
          crestShape: TeamCrestShape.values.firstWhere(
            (s) => s.name == row['crest_shape'],
            orElse: () => TeamCrestShape.shield,
          ),
          primaryColorHex:
              (row['primary_color_hex'] as num?)?.toInt() ?? 0xFF00E676,
          secondaryColorHex:
              (row['secondary_color_hex'] as num?)?.toInt() ?? 0xFF0A0E17,
          categoryLabel: tournamentCount == 1 ? singleCategory : null,
          tournamentCount: tournamentCount,
          playerCount: totalPlayers,
          eligibilityStatus: hasEligible
              ? TeamEligibilityStatus.eligible
              : TeamEligibilityStatus.pendingVerification,
          coachId: row['coach_id'] as String?,
          delegateName: (row['delegate_name'] as String?)?.trim().isNotEmpty == true
              ? (row['delegate_name'] as String).trim()
              : null,
          foundedDate: row['founded_date'] is String
              ? DateTime.tryParse(row['founded_date'] as String)
              : null,
          crestUrl: (row['crest_url'] as String?)?.trim().isNotEmpty == true
              ? (row['crest_url'] as String).trim()
              : null,
          updatedAt:
              DateTime.tryParse(
                row['updated_at'] as String? ?? '',
              )?.toLocal() ??
              DateTime.now(),
        ),
      );
    }

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
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
  Future<List<PlayerDirectoryItem>> loadAllPlayers() {
    return support.executeRead(
      remoteFetch: () async {
        try {
          final teams = await remote.fetchAll();
          await local.replaceAllCache(teams);
        } catch (_) {}
        return remote.fetchAllPlayers();
      },
      cacheUpdate: (_) async {},
      localFallback: local.loadAllPlayers,
    );
  }

  @override
  Future<List<TeamDirectoryItem>> loadAllTeams() {
    return support.executeRead(
      remoteFetch: remote.fetchAllTeams,
      cacheUpdate: local.cacheDirectoryTeams,
      localFallback: local.loadAllTeams,
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

  TournamentTeam _normalizeTeam(TournamentTeam team) {
    final normalizedId = HybridRepositorySupport.ensureUuid(
      team.id,
      'tournament_team',
    );
    final normalizedTournamentId = HybridRepositorySupport.ensureUuid(
      team.tournamentId,
      'tournament',
    );
    return team.copyWith(
      id: normalizedId,
      tournamentId: normalizedTournamentId,
    );
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) {
    final normalized = _normalizeTeam(team);
    return support.executeMutation(
      localWrite: () => local.saveTeam(normalized),
      remoteWrite: () => remote.upsert(normalized),
      entityType: SyncOutboxEntityType.team,
      entityId: normalized.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'team': normalized.toJson()},
      displayTitle: normalized.name,
    );
  }

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) {
    final normalizedTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final normalizedTeams = teams.map(_normalizeTeam).toList();
    return support.executeMutation(
      localWrite: () => local.replaceTeamsForTournament(
        normalizedTournamentId,
        normalizedTeams,
      ),
      remoteWrite: () =>
          remote.replaceForTournament(normalizedTournamentId, normalizedTeams),
      entityType: SyncOutboxEntityType.team,
      entityId: normalizedTournamentId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': normalizedTournamentId,
        'teams': normalizedTeams.map((t) => t.toJson()).toList(),
      },
      displayTitle: normalizedTournamentId,
    );
  }

  @override
  Future<void> deleteTeam(String teamId) {
    final normalizedId = HybridRepositorySupport.ensureUuid(
      teamId,
      'tournament_team',
    );
    return support.executeMutation(
      localWrite: () => local.deleteTeam(normalizedId),
      remoteWrite: () => remote.deleteById(normalizedId),
      entityType: SyncOutboxEntityType.team,
      entityId: normalizedId,
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {'teamId': normalizedId},
      displayTitle: normalizedId,
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
