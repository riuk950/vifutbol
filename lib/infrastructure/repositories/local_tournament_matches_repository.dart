import 'dart:async';
import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';

class LocalTournamentMatchesRepository implements TournamentMatchesRepository {
  LocalTournamentMatchesRepository({
    required this.storage,
    required this.config,
  });

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  final StreamController<List<ChampionshipMatch>> _matchesStreamController =
      StreamController<List<ChampionshipMatch>>.broadcast();

  static const String matchesStorageKey = 'vifutbol.matches.v1';
  static const String refereesStorageKey = 'vifutbol.referees.v1';

  @override
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  ) async {
    final allMatches = await _loadAllMatches();
    return allMatches.where((m) => m.tournamentId == tournamentId).toList();
  }

  @override
  Stream<List<ChampionshipMatch>> watchMatchesForTournament(
    String tournamentId,
  ) async* {
    final initial = await loadMatchesForTournament(tournamentId);
    yield initial;
    yield* _matchesStreamController.stream.map(
      (matches) =>
          matches.where((m) => m.tournamentId == tournamentId).toList(),
    );
  }

  @override
  Future<ChampionshipMatch> saveMatch(ChampionshipMatch match) async {
    final allMatches = await _loadAllMatches();
    final updatedList = List<ChampionshipMatch>.from(allMatches);
    final index = updatedList.indexWhere((m) => m.id == match.id);
    if (index >= 0) {
      updatedList[index] = match;
    } else {
      updatedList.add(match);
    }
    await _persistMatches(updatedList);
    return match;
  }

  @override
  Future<List<ChampionshipMatch>> saveMatchesBatch(
    List<ChampionshipMatch> matches,
  ) async {
    if (matches.isEmpty) return const [];
    final allMatches = await _loadAllMatches();
    final updatedList = List<ChampionshipMatch>.from(allMatches);

    for (final match in matches) {
      final index = updatedList.indexWhere((m) => m.id == match.id);
      if (index >= 0) {
        updatedList[index] = match;
      } else {
        updatedList.add(match);
      }
    }

    await _persistMatches(updatedList);
    return matches;
  }

  @override
  Future<List<MatchReferee>> loadOfficialReferees() async {
    final raw = await storage.readString(refereesStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MatchReferee.fromJson)
            .toList();
      } catch (_) {}
    }

    if (config.environment == AppEnvironment.development) {
      final seeds = _buildSeedReferees();
      await _persistReferees(seeds);
      return seeds;
    }

    return const <MatchReferee>[];
  }

  Future<List<ChampionshipMatch>> _loadAllMatches() async {
    final raw = await storage.readString(matchesStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ChampionshipMatch.fromJson)
            .toList();
      } catch (_) {}
    }

    if (config.environment == AppEnvironment.development) {
      final seeds = _buildSeedMatches();
      await _persistMatches(seeds);
      return seeds;
    }

    return const <ChampionshipMatch>[];
  }

  Future<void> _persistMatches(List<ChampionshipMatch> matches) async {
    final jsonList = matches.map((m) => m.toJson()).toList();
    await storage.writeString(matchesStorageKey, jsonEncode(jsonList));
    if (!_matchesStreamController.isClosed) {
      _matchesStreamController.add(matches);
    }
  }

  Future<void> _persistReferees(List<MatchReferee> referees) async {
    final jsonList = referees.map((r) => r.toJson()).toList();
    await storage.writeString(refereesStorageKey, jsonEncode(jsonList));
  }

  List<MatchReferee> _buildSeedReferees() {
    return const [
      MatchReferee(
        id: 'ref-seed-1',
        fullName: 'Nicolás Gallo',
        certificationLevel: 'FIFA',
        isActive: true,
      ),
      MatchReferee(
        id: 'ref-seed-2',
        fullName: 'Wilmar Roldán',
        certificationLevel: 'FIFA',
        isActive: true,
      ),
      MatchReferee(
        id: 'ref-seed-3',
        fullName: 'Andrés Rojas',
        certificationLevel: 'Nacional',
        isActive: true,
      ),
    ];
  }

  List<ChampionshipMatch> _buildSeedMatches() {
    final now = DateTime.now();
    final firstMatchStart = DateTime(now.year, now.month, now.day + 2, 14, 0);
    final firstMatchEnd = DateTime(now.year, now.month, now.day + 2, 15, 45);

    return [
      ChampionshipMatch(
        id: 'match-seed-clausura-1',
        tournamentId: 'tournament-seed-liga-clausura',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-seed-atletico-norte',
        awayTeamId: 'team-seed-real-sabana',
        scheduledStartTime: firstMatchStart,
        scheduledEndTime: firstMatchEnd,
        venueId: 'venue-seed-campin',
        pitchId: 'pitch-campin-1',
        pitchName: 'Cancha Principal (F11)',
        refereeId: 'ref-seed-2',
        refereeName: 'Wilmar Roldán',
        status: MatchStatus.scheduled,
      ),
      ChampionshipMatch(
        id: 'match-seed-clausura-2',
        tournamentId: 'tournament-seed-liga-clausura',
        roundNumber: 2,
        roundName: 'Jornada 2',
        homeTeamId: 'team-seed-real-sabana',
        awayTeamId: 'team-seed-atletico-norte',
        status: MatchStatus.pendingSchedule,
      ),
    ];
  }
}
