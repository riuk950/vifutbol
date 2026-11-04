import 'dart:convert';
import '../../domain/entities/championship_tournament.dart';
import '../../domain/entities/knockout_bracket.dart';
import '../../domain/entities/match_lineup_convocation.dart';
import '../../domain/entities/player_internal_tracking.dart';
import '../../domain/entities/player_performance_profile.dart';
import '../../domain/entities/standings_table.dart';
import '../../domain/entities/team_detailed_stats.dart';
import '../../domain/entities/tournament_enums.dart';
import '../../domain/entities/tournament_rankings.dart';
import '../../domain/repositories/lineups_tracking_repository.dart';
import '../../domain/repositories/local_storage_repository.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/repositories/tournament_matches_repository.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../../domain/services/knockout_bracket_service.dart';
import '../../domain/services/player_team_stats_calculator_service.dart';
import '../../domain/services/sports_rankings_calculator_service.dart';
import '../../domain/services/standings_calculator_service.dart';

/// Immutable snapshot of all competitive tables, knockout brackets, rankings,
/// player performance profiles, and team detailed stats for a tournament.
class TournamentCompetitiveSnapshot {
  const TournamentCompetitiveSnapshot({
    required this.tournament,
    required this.mainStandingsTable,
    this.groupStandingsTables = const <StandingsTable>[],
    this.knockoutBracket,
    required this.rankings,
    this.playerProfilesById = const <String, PlayerPerformanceProfile>{},
    this.teamDetailedStatsById = const <String, TeamDetailedStats>{},
    this.cachedMyPlayerProfile,
  });

  final ChampionshipTournament tournament;
  final StandingsTable mainStandingsTable;
  final List<StandingsTable> groupStandingsTables;
  final KnockoutBracket? knockoutBracket;
  final TournamentRankingsBundle rankings;
  final Map<String, PlayerPerformanceProfile> playerProfilesById;
  final Map<String, TeamDetailedStats> teamDetailedStatsById;
  final PlayerPerformanceProfile? cachedMyPlayerProfile;
}

/// Application use case that loads local tournament data, teams, matches, and
/// closed official match reports, and deterministically calculates:
/// 1. League and Group Standings Tables (`US1`)
/// 2. Knockout Elimination Brackets with automatic winner advancement (`US2`)
/// 3. Top Scorers, Top Assists, and Fair Play Rankings (`US3`)
/// 4. Player Performance Profiles and Team Detailed Stats (`HU 8.2`)
class CalculateTournamentStandingsAndRankingsUseCase {
  const CalculateTournamentStandingsAndRankingsUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.tournamentMatchesRepository,
    required this.matchReportsRepository,
    this.lineupsTrackingRepository,
    this.localStorageRepository,
    this.standingsCalculator = const StandingsCalculatorService(),
    this.knockoutBracketService = const KnockoutBracketService(),
    this.rankingsCalculator = const SportsRankingsCalculatorService(),
    this.playerTeamStatsCalculator = const PlayerTeamStatsCalculatorService(),
  });

  final TournamentsRepository tournamentsRepository;
  final TeamsRepository teamsRepository;
  final TournamentMatchesRepository tournamentMatchesRepository;
  final MatchReportsRepository matchReportsRepository;
  final LineupsTrackingRepository? lineupsTrackingRepository;
  final LocalStorageRepository? localStorageRepository;
  final StandingsCalculatorService standingsCalculator;
  final KnockoutBracketService knockoutBracketService;
  final SportsRankingsCalculatorService rankingsCalculator;
  final PlayerTeamStatsCalculatorService playerTeamStatsCalculator;

  static const String cachedProfileStorageKey =
      'cached_player_performance_profile_v1';

  Future<TournamentCompetitiveSnapshot> execute(
    String tournamentId, {
    String? currentUserId,
  }) async {
    final tournaments = await tournamentsRepository.loadTournaments();
    final tournament = tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => tournaments.isNotEmpty
          ? tournaments.first
          : throw StateError('Tournament not found: $tournamentId'),
    );

    final teams = await teamsRepository.loadTeamsForTournament(tournament.id);
    var matches = await tournamentMatchesRepository.loadMatchesForTournament(
      tournament.id,
    );
    final reports = await matchReportsRepository.loadReportsForTournament(
      tournament.id,
    );
    final closedReports = reports.where((r) => r.isClosed).toList();

    // Ensure any newly decided knockout ties propagate their winners into next-round matches
    if (tournament.format.hasKnockoutBracket) {
      final advancedUpdates = knockoutBracketService
          .computeUpdatedMatchesWithAdvancement(
            tournament: tournament,
            teams: teams,
            currentMatches: matches,
            reports: reports,
          );
      if (advancedUpdates.isNotEmpty) {
        await tournamentMatchesRepository.saveMatchesBatch(advancedUpdates);
        matches = await tournamentMatchesRepository.loadMatchesForTournament(
          tournament.id,
        );
      }
    }

    final mainStandingsTable = standingsCalculator.calculateTable(
      tournament: tournament,
      teams: teams,
      matches: matches,
      closedReports: closedReports,
    );

    final groupStandingsTables =
        tournament.format == TournamentFormat.mixedGroupsAndKnockout
        ? standingsCalculator.calculateGroupStageTables(
            tournament: tournament,
            teams: teams,
            matches: matches,
            closedReports: closedReports,
          )
        : const <StandingsTable>[];

    final knockoutBracket = tournament.format.hasKnockoutBracket
        ? knockoutBracketService.buildBracket(
            tournament: tournament,
            teams: teams,
            matches: matches,
            reports: reports,
          )
        : null;

    final rankings = rankingsCalculator.calculateRankings(
      tournament: tournament,
      teams: teams,
      closedReports: closedReports,
    );

    // Load Convocations and Tracking maps if repository is available
    final convocationsMap = <String, MatchLineupConvocation>{};
    final trackingMap = <String, PlayerInternalTracking>{};

    if (lineupsTrackingRepository != null) {
      for (final team in teams) {
        try {
          final conv = await lineupsTrackingRepository!.loadConvocationForTeam(
            tournament.id,
            team.id,
          );
          convocationsMap[team.id] = conv;

          final trackings = await lineupsTrackingRepository!
              .loadTrackingForTeam(tournament.id, team.id, team.players);
          for (final t in trackings) {
            trackingMap[t.playerId] = t;
          }
        } catch (_) {
          // Ignore individual team convocation load failures in resilient mode
        }
      }
    }

    final playerTeamResults = playerTeamStatsCalculator.calculateAll(
      tournament: tournament,
      teams: teams,
      mainStandingsTable: mainStandingsTable,
      matches: matches,
      reports: reports,
      convocationsByTeamId: convocationsMap,
      trackingByPlayerId: trackingMap,
    );

    // Check cached profile or select active player
    PlayerPerformanceProfile? myProfile;
    if (currentUserId != null &&
        playerTeamResults.playerProfilesById.containsKey(currentUserId)) {
      myProfile = playerTeamResults.playerProfilesById[currentUserId];
    }

    // Attempt to persist or load cached profile via LocalStorageRepository
    if (localStorageRepository != null) {
      try {
        if (myProfile != null) {
          await localStorageRepository!.writeString(
            cachedProfileStorageKey,
            jsonEncode(myProfile.toJson()),
          );
        } else {
          final cachedJson = await localStorageRepository!.readString(
            cachedProfileStorageKey,
          );
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
            myProfile = PlayerPerformanceProfile.fromJson(decoded);
          }
        }
      } catch (_) {
        // Fallback gracefully without throwing
      }
    }

    return TournamentCompetitiveSnapshot(
      tournament: tournament,
      mainStandingsTable: mainStandingsTable,
      groupStandingsTables: groupStandingsTables,
      knockoutBracket: knockoutBracket,
      rankings: rankings,
      playerProfilesById: playerTeamResults.playerProfilesById,
      teamDetailedStatsById: playerTeamResults.teamStatsById,
      cachedMyPlayerProfile: myProfile,
    );
  }
}
