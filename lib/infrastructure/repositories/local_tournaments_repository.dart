import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Local repository persisting championship tournaments and temporary creation
/// drafts to [LocalStorageRepository], preloading 3 seed tournaments in `dev`.
class LocalTournamentsRepository implements TournamentsRepository {
  LocalTournamentsRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String catalogStorageKey = 'vifutbol.tournaments.catalog.v1';
  static const String draftStorageKey =
      'vifutbol.tournaments.creation_draft.v1';

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async {
    final raw = await storage.readString(catalogStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      if (config.environment == AppEnvironment.development) {
        final seeds = _buildSeedTournaments();
        await _persistTournaments(seeds);
        return seeds;
      }
      return <ChampionshipTournament>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChampionshipTournament.fromJson)
          .toList();
    } catch (_) {
      if (config.environment == AppEnvironment.development) {
        final seeds = _buildSeedTournaments();
        await _persistTournaments(seeds);
        return seeds;
      }
      return <ChampionshipTournament>[];
    }
  }

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async {
    final existing = await loadTournaments();
    final updated = List<ChampionshipTournament>.from(existing);
    final index = updated.indexWhere((t) => t.id == tournament.id);
    if (index >= 0) {
      updated[index] = tournament;
    } else {
      updated.insert(0, tournament);
    }

    await _persistTournaments(updated);
    return tournament;
  }

  @override
  Future<TournamentDraft?> loadDraft() async {
    final raw = await storage.readString(draftStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return TournamentDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(TournamentDraft draft) async {
    await storage.writeString(draftStorageKey, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clearDraft() async {
    await storage.writeString(draftStorageKey, '');
  }

  Future<void> _persistTournaments(
    List<ChampionshipTournament> tournaments,
  ) async {
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await storage.writeString(catalogStorageKey, jsonEncode(jsonList));
  }

  List<ChampionshipTournament> _buildSeedTournaments() {
    final seedTimestamp = DateTime(2026, 4, 17, 9, 0);

    return <ChampionshipTournament>[
      ChampionshipTournament(
        id: 'tournament-seed-liga-clausura',
        name: 'Liga Clausura ViFutbol 2026',
        category: 'Libre Masculino',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 9, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(
          pointsForWin: 3,
          pointsForDraw: 1,
          pointsForLoss: 0,
          yellowCardSuspensionLimit: 3,
          minPlayersPerTeam: 7,
          maxPlayersPerTeam: 18,
          halfDurationMinutes: 45,
          leagueRounds: 2,
        ),
        updatedAt: seedTimestamp,
      ),
      ChampionshipTournament(
        id: 'tournament-seed-copa-relampago',
        name: 'Copa Relámpago Nocturna',
        category: 'Libre Abierta',
        startDate: DateTime(2026, 4, 10),
        endDate: DateTime(2026, 5, 25),
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.inProgress,
        rules: const TournamentRulesConfig(
          pointsForWin: 3,
          pointsForDraw: 1,
          pointsForLoss: 0,
          yellowCardSuspensionLimit: 2,
          minPlayersPerTeam: 6,
          maxPlayersPerTeam: 14,
          halfDurationMinutes: 30,
          knockoutConfig: KnockoutStageConfig(
            startingRound: KnockoutRound.quarterFinals,
            twoLeggedTies: false,
            directPenaltyShootoutOnDraw: true,
          ),
        ),
        updatedAt: seedTimestamp,
      ),
      ChampionshipTournament(
        id: 'tournament-seed-metropolitano-mixto',
        name: 'Torneo Metropolitano Mixto',
        category: 'Sub-23',
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 10, 20),
        format: TournamentFormat.mixedGroupsAndKnockout,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(
          pointsForWin: 3,
          pointsForDraw: 1,
          pointsForLoss: 0,
          yellowCardSuspensionLimit: 3,
          minPlayersPerTeam: 8,
          maxPlayersPerTeam: 20,
          halfDurationMinutes: 40,
          groupStageConfig: GroupStageConfig(
            groupCount: 4,
            advancingPerGroup: 2,
          ),
          knockoutConfig: KnockoutStageConfig(
            startingRound: KnockoutRound.quarterFinals,
            twoLeggedTies: true,
            directPenaltyShootoutOnDraw: true,
          ),
        ),
        updatedAt: seedTimestamp,
      ),
    ];
  }
}
