import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// Local repository persisting teams and squad rosters to [LocalStorageRepository],
/// preloading 2 representative seed teams in `dev`.
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

  Future<void> _persistTeams(List<TournamentTeam> teams) async {
    final serialized = jsonEncode(teams.map((t) => t.toJson()).toList());
    await storage.writeString(catalogStorageKey, serialized);
  }

  List<TournamentTeam> _buildSeedTeams() {
    return [
      TournamentTeam(
        id: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        name: 'Atlético Norte FC',
        shortCode: 'ATN',
        crestShape: TeamCrestShape.shield,
        primaryColorHex: 0xFF00E676,
        secondaryColorHex: 0xFF0A0E17,
        eligibilityStatus: TeamEligibilityStatus.eligible,
        players: const [
          RegisteredPlayer(
            id: 'p-seed-atn-1',
            fullName: 'David Ospina',
            documentId: '10100001',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-2',
            fullName: 'Yerry Mina',
            documentId: '10100002',
            shirtNumber: 4,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-3',
            fullName: 'Dávinson Sánchez',
            documentId: '10100003',
            shirtNumber: 5,
            position: PlayerPosition.defender,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-4',
            fullName: 'Mateus Uribe',
            documentId: '10100004',
            shirtNumber: 8,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-5',
            fullName: 'Radamel Falcao',
            documentId: '10100005',
            shirtNumber: 9,
            position: PlayerPosition.forward,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-6',
            fullName: 'James Rodríguez',
            documentId: '10100006',
            shirtNumber: 10,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
          RegisteredPlayer(
            id: 'p-seed-atn-7',
            fullName: 'Luis Díaz',
            documentId: '10100007',
            shirtNumber: 11,
            position: PlayerPosition.forward,
            isEligible: true,
          ),
        ],
      ),
      TournamentTeam(
        id: 'team-seed-real-sabana',
        tournamentId: 'tournament-seed-liga-clausura',
        name: 'Real Sabana Club',
        shortCode: 'RSC',
        crestShape: TeamCrestShape.hexagon,
        primaryColorHex: 0xFF2979FF,
        secondaryColorHex: 0xFF1A237E,
        eligibilityStatus: TeamEligibilityStatus.pendingQuota,
        players: const [
          RegisteredPlayer(
            id: 'p-seed-rsc-1',
            fullName: 'Camilo Vargas',
            documentId: '20200001',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
            isEligible: false,
          ),
          RegisteredPlayer(
            id: 'p-seed-rsc-2',
            fullName: 'Daniel Muñoz',
            documentId: '20200002',
            shirtNumber: 2,
            position: PlayerPosition.defender,
            isEligible: false,
          ),
          RegisteredPlayer(
            id: 'p-seed-rsc-3',
            fullName: 'Jefferson Lerma',
            documentId: '20200003',
            shirtNumber: 6,
            position: PlayerPosition.midfielder,
            isEligible: false,
          ),
          RegisteredPlayer(
            id: 'p-seed-rsc-4',
            fullName: 'Luis Sinisterra',
            documentId: '20200004',
            shirtNumber: 7,
            position: PlayerPosition.forward,
            isEligible: false,
          ),
          RegisteredPlayer(
            id: 'p-seed-rsc-5',
            fullName: 'Juan Fernando Quintero',
            documentId: '20200005',
            shirtNumber: 10,
            position: PlayerPosition.midfielder,
            isEligible: false,
          ),
        ],
      ),
    ];
  }
}
