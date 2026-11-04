import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tournament_enums.dart';
import '../providers/digital_match_report_providers.dart';
import '../providers/matches_catalog_providers.dart';
import '../providers/teams_providers.dart';
import '../providers/tournaments_providers.dart';
import '../use_cases/calculate_tournament_standings_and_rankings_use_case.dart';

/// Active competitive sub-view inside `StandingsTabView`.
enum CompetitiveViewMode { standings, brackets, rankings }

/// Immutable state for the tournament standings, brackets, and rankings controller.
class StandingsAndRankingsState {
  const StandingsAndRankingsState({
    this.isLoading = false,
    this.snapshot,
    this.activeViewMode = CompetitiveViewMode.standings,
    this.errorMessage,
  });

  final bool isLoading;
  final TournamentCompetitiveSnapshot? snapshot;
  final CompetitiveViewMode activeViewMode;
  final String? errorMessage;

  StandingsAndRankingsState copyWith({
    bool? isLoading,
    TournamentCompetitiveSnapshot? snapshot,
    CompetitiveViewMode? activeViewMode,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StandingsAndRankingsState(
      isLoading: isLoading ?? this.isLoading,
      snapshot: snapshot ?? this.snapshot,
      activeViewMode: activeViewMode ?? this.activeViewMode,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class StandingsAndRankingsController
    extends StateNotifier<StandingsAndRankingsState> {
  StandingsAndRankingsController({
    required this.useCase,
    required this.tournamentId,
    required this.initialFormat,
  }) : super(
         StandingsAndRankingsState(
           isLoading: true,
           activeViewMode: initialFormat == TournamentFormat.knockoutCup
               ? CompetitiveViewMode.brackets
               : CompetitiveViewMode.standings,
         ),
       ) {
    loadCompetitiveSnapshot();
  }

  final CalculateTournamentStandingsAndRankingsUseCase useCase;
  final String tournamentId;
  final TournamentFormat initialFormat;

  Future<void> loadCompetitiveSnapshot() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final snapshot = await useCase.execute(tournamentId);
      state = state.copyWith(isLoading: false, snapshot: snapshot);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectViewMode(CompetitiveViewMode mode) {
    if (state.activeViewMode == mode) return;
    state = state.copyWith(activeViewMode: mode);
  }
}

final calculateTournamentStandingsAndRankingsUseCaseProvider =
    Provider<CalculateTournamentStandingsAndRankingsUseCase>((ref) {
      return CalculateTournamentStandingsAndRankingsUseCase(
        tournamentsRepository: ref.watch(tournamentsRepositoryProvider),
        teamsRepository: ref.watch(teamsRepositoryProvider),
        tournamentMatchesRepository: ref.watch(
          tournamentMatchesRepositoryProvider,
        ),
        matchReportsRepository: ref.watch(matchReportsRepositoryProvider),
      );
    });

final standingsAndRankingsControllerProvider = StateNotifierProvider.family
    .autoDispose<
      StandingsAndRankingsController,
      StandingsAndRankingsState,
      String
    >((ref, tournamentId) {
      final useCase = ref.watch(
        calculateTournamentStandingsAndRankingsUseCaseProvider,
      );
      final catalog = ref.watch(tournamentsControllerProvider);
      final selectedFormat =
          catalog.tournaments
              .where((t) => t.id == tournamentId)
              .firstOrNull
              ?.format ??
          TournamentFormat.league;

      return StandingsAndRankingsController(
        useCase: useCase,
        tournamentId: tournamentId,
        initialFormat: selectedFormat,
      );
    });
