import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// Local repository persisting teams and squad rosters to [LocalStorageRepository].
class LocalTeamsRepository implements TeamsRepository {
  LocalTeamsRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String catalogStorageKey = 'vifutbol.teams.catalog.v1';
  static const String directoryStorageKey = 'vifutbol.teams.directory.v1';

  @override
  Future<List<TournamentTeam>> loadTeams() async {
    final raw = await storage.readString(catalogStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <TournamentTeam>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TournamentTeam.fromJson)
          .toList();
    } catch (_) {
      return <TournamentTeam>[];
    }
  }

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    final allTeams = await loadTeams();
    return allTeams.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async {
    final existing = await loadTeams();
    final updated = List<TournamentTeam>.from(existing);
    final index = updated.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      updated[index] = team;
    } else {
      updated.insert(0, team);
    }
    await _persistTeams(updated);
    return team;
  }

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) async {
    final allTeams = await loadTeams();
    final otherTeams = allTeams
        .where((t) => t.tournamentId != tournamentId)
        .toList();
    final updated = [...otherTeams, ...teams];
    await _persistTeams(updated);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    final allTeams = await loadTeams();
    final updated = allTeams.where((t) => t.id != teamId).toList();
    await _persistTeams(updated);
  }

  /// Replaces the local teams cache across tournaments with fresh remote data.
  Future<void> replaceAllCache(List<TournamentTeam> teams) {
    return _persistTeams(teams);
  }

  @override
  Future<List<PlayerDirectoryItem>> loadAllPlayers() async {
    final teams = await loadTeams();
    final List<PlayerDirectoryItem> items = [];
    for (final team in teams) {
      for (final player in team.players) {
        items.add(
          PlayerDirectoryItem(
            player: player,
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

  /// Replaces the cached global teams directory items in local storage.
  Future<void> cacheDirectoryTeams(List<TeamDirectoryItem> teams) async {
    final sorted = [...teams]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final serialized = jsonEncode(sorted.map((t) => t.toJson()).toList());
    await storage.writeString(directoryStorageKey, serialized);
  }

  @override
  Future<List<TeamDirectoryItem>> loadAllTeams() async {
    final raw = await storage.readString(directoryStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final items =
            decoded
                .whereType<Map<String, dynamic>>()
                .map(TeamDirectoryItem.fromJson)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        return items;
      } catch (_) {}
    }

    // Fallback: derive unique clubs from legacy catalogStorageKey if directory cache is empty.
    final legacyTeams = await loadTeams();
    final Map<String, TeamDirectoryItem> byKey = {};
    for (final team in legacyTeams) {
      final key = team.normalizedName;
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = TeamDirectoryItem(
          id: team.id,
          name: team.name,
          shortCode: team.shortCode,
          crestShape: team.crestShape,
          primaryColorHex: team.primaryColorHex,
          secondaryColorHex: team.secondaryColorHex,
          categoryLabel: team.groupName,
          tournamentCount: team.tournamentId.trim().isEmpty ? 0 : 1,
          playerCount: team.players.length,
          eligibilityStatus: team.eligibilityStatus,
          coachId: team.coachId,
          updatedAt: team.updatedAt,
        );
      } else {
        final updatedStatus =
            (existing.eligibilityStatus == TeamEligibilityStatus.eligible ||
                team.eligibilityStatus == TeamEligibilityStatus.eligible)
            ? TeamEligibilityStatus.eligible
            : TeamEligibilityStatus.pendingVerification;
        byKey[key] = TeamDirectoryItem(
          id: existing.id,
          name: existing.name,
          shortCode: existing.shortCode,
          crestShape: existing.crestShape,
          primaryColorHex: existing.primaryColorHex,
          secondaryColorHex: existing.secondaryColorHex,
          categoryLabel: existing.categoryLabel ?? team.groupName,
          tournamentCount:
              existing.tournamentCount +
              (team.tournamentId.trim().isEmpty ? 0 : 1),
          playerCount: existing.playerCount + team.players.length,
          eligibilityStatus: updatedStatus,
          coachId: existing.coachId ?? team.coachId,
          updatedAt: team.updatedAt.isAfter(existing.updatedAt)
              ? team.updatedAt
              : existing.updatedAt,
        );
      }
    }

    final items = byKey.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<void> _persistTeams(List<TournamentTeam> teams) async {
    final serialized = jsonEncode(teams.map((t) => t.toJson()).toList());
    await storage.writeString(catalogStorageKey, serialized);
  }
}
