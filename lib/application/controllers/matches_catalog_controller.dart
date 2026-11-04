import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';

class MatchesCatalogController extends StateNotifier<MatchesCatalogState> {
  MatchesCatalogController({
    required this.matchesRepository,
    required this.fixtureSchedulingUseCase,
  }) : super(const MatchesCatalogState());

  final TournamentMatchesRepository matchesRepository;
  final FixtureSchedulingUseCase fixtureSchedulingUseCase;

  Future<void> loadTournamentMatches(String tournamentId) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final matches = await matchesRepository.loadMatchesForTournament(
        tournamentId,
      );
      final referees = await matchesRepository.loadOfficialReferees();

      int selectedRound = state.selectedRound;
      if (matches.isNotEmpty) {
        final available = matches.map((m) => m.roundNumber).toSet().toList()
          ..sort();
        if (!available.contains(selectedRound)) {
          selectedRound = available.first;
        }
      }

      state = state.copyWith(
        matches: matches,
        referees: referees,
        selectedRound: selectedRound,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e is AppFailure ? e.message : e.toString(),
      );
    }
  }

  void selectRound(int roundNumber) {
    state = state.copyWith(selectedRound: roundNumber);
  }

  void setStatusFilter(MatchStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void setTeamFilter(String? teamId) {
    state = state.copyWith(teamFilter: () => teamId);
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: () => null);
  }

  Future<bool> generateFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await fixtureSchedulingUseCase.generateRoundRobinFixture(
        tournament: tournament,
        teams: teams,
        userRole: userRole,
      );

      final updatedMatches = await matchesRepository.loadMatchesForTournament(
        tournament.id,
      );

      int selectedRound = 1;
      if (updatedMatches.isNotEmpty) {
        final available =
            updatedMatches.map((m) => m.roundNumber).toSet().toList()..sort();
        selectedRound = available.first;
      }

      state = state.copyWith(
        matches: updatedMatches,
        selectedRound: selectedRound,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> scheduleMatch({
    required String matchId,
    required ChampionshipTournament tournament,
    required DateTime scheduledStartTime,
    required SportsVenue venue,
    required VenuePitch pitch,
    required MatchReferee referee,
    required UserRole userRole,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await fixtureSchedulingUseCase.scheduleMatch(
        matchId: matchId,
        tournament: tournament,
        scheduledStartTime: scheduledStartTime,
        venue: venue,
        pitch: pitch,
        referee: referee,
        userRole: userRole,
      );

      final updatedMatches = await matchesRepository.loadMatchesForTournament(
        tournament.id,
      );

      state = state.copyWith(matches: updatedMatches, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }
}
