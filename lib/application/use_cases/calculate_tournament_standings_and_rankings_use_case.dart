import '../../domain/entities/championship_tournament.dart';
import '../../domain/entities/knockout_bracket.dart';
import '../../domain/entities/standings_table.dart';
import '../../domain/entities/tournament_enums.dart';
import '../../domain/entities/tournament_rankings.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/repositories/tournament_matches_repository.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../../domain/services/knockout_bracket_service.dart';
import '../../domain/services/sports_rankings_calculator_service.dart';
import '../../domain/services/standings_calculator_service.dart';

/// Immutable snapshot of all competitive tables, knockout brackets, and rankings
/// for a tournament.
class TournamentCompetitiveSnapshot {
  const TournamentCompetitiveSnapshot({
    required this.tournament,
    required this.mainStandingsTable,
    this.groupStandingsTables = const <StandingsTable>[],
    this.knockoutBracket,
    required this.rankings,
  });

  final ChampionshipTournament tournament;
  final StandingsTable mainStandingsTable;
  final List<StandingsTable> groupStandingsTables;
  final KnockoutBracket? knockoutBracket;
  final TournamentRankingsBundle rankings;
}

/// Application use case that loads local tournament data, teams, matches, and
/// closed official match reports, and deterministically calculates:
/// 1. League and Group Standings Tables (`US1`)
/// 2. Knockout Elimination Brackets with automatic winner advancement (`US2`)
/// 3. Top Scorers, Top Assists, and Fair Play Rankings (`US3`)
class CalculateTournamentStandingsAndRankingsUseCase {
  const CalculateTournamentStandingsAndRankingsUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.tournamentMatchesRepository,
    required this.matchReportsRepository,
    this.standingsCalculator = const StandingsCalculatorService(),
    this.knockoutBracketService = const KnockoutBracketService(),
    this.rankingsCalculator = const SportsRankingsCalculatorService(),
  });

  final TournamentsRepository tournamentsRepository;
  final TeamsRepository teamsRepository;
  final TournamentMatchesRepository tournamentMatchesRepository;
  final MatchReportsRepository matchReportsRepository;
  final StandingsCalculatorService standingsCalculator;
  final KnockoutBracketService knockoutBracketService;
  final SportsRankingsCalculatorService rankingsCalculator;

  Future<TournamentCompetitiveSnapshot> execute(String tournamentId) async {
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

    return TournamentCompetitiveSnapshot(
      tournament: tournament,
      mainStandingsTable: mainStandingsTable,
      groupStandingsTables: groupStandingsTables,
      knockoutBracket: knockoutBracket,
      rankings: rankings,
    );
  }
}
