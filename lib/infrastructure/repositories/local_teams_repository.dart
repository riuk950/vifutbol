import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/infrastructure/data/twenty_teams_seed.dart';

/// Local repository persisting teams and squad rosters to [LocalStorageRepository],
/// preloading 20 representative seed teams in `dev`.
class LocalTeamsRepository implements TeamsRepository {
  LocalTeamsRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String catalogStorageKey = 'vifutbol.teams.catalog.v1';

  @override
  Future<List<TournamentTeam>> loadTeams() async {
    final raw = await storage.readString(catalogStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      if (config.environment == AppEnvironment.development) {
        final seeds = _buildSeedTeams();
        await _persistTeams(seeds);
        return seeds;
      }
      return <TournamentTeam>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TournamentTeam.fromJson)
          .toList();
    } catch (_) {
      if (config.environment == AppEnvironment.development) {
        final seeds = _buildSeedTeams();
        await _persistTeams(seeds);
        return seeds;
      }
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

  Future<void> _persistTeams(List<TournamentTeam> teams) async {
    final serialized = jsonEncode(teams.map((t) => t.toJson()).toList());
    await storage.writeString(catalogStorageKey, serialized);
  }

  List<TournamentTeam> _buildSeedTeams() {
    return TwentyTeamsSeedData.generate(
      tournamentId: 'tournament-seed-liga-clausura',
    );
  }
}
