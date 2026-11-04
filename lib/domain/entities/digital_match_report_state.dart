import 'championship_match.dart';
import 'digital_match_report.dart';
import 'registered_player.dart';
import 'tournament_team.dart';

/// Immutable UI state for DigitalMatchReportController.
class DigitalMatchReportState {
  const DigitalMatchReportState({
    this.match,
    this.report,
    this.homeTeam,
    this.awayTeam,
    this.homeEligiblePlayers = const <RegisteredPlayer>[],
    this.awayEligiblePlayers = const <RegisteredPlayer>[],
    this.isOfflineMode = false,
    this.pendingSyncEventsCount = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastActionFeedback,
  });

  final ChampionshipMatch? match;
  final DigitalMatchReport? report;
  final TournamentTeam? homeTeam;
  final TournamentTeam? awayTeam;
  final List<RegisteredPlayer> homeEligiblePlayers;
  final List<RegisteredPlayer> awayEligiblePlayers;
  final bool isOfflineMode;
  final int pendingSyncEventsCount;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? lastActionFeedback;

  bool get hasData => match != null && report != null;

  DigitalMatchReportState copyWith({
    ChampionshipMatch? match,
    DigitalMatchReport? report,
    TournamentTeam? homeTeam,
    TournamentTeam? awayTeam,
    List<RegisteredPlayer>? homeEligiblePlayers,
    List<RegisteredPlayer>? awayEligiblePlayers,
    bool? isOfflineMode,
    int? pendingSyncEventsCount,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? lastActionFeedback,
    bool clearLastActionFeedback = false,
  }) {
    return DigitalMatchReportState(
      match: match ?? this.match,
      report: report ?? this.report,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeEligiblePlayers: homeEligiblePlayers ?? this.homeEligiblePlayers,
      awayEligiblePlayers: awayEligiblePlayers ?? this.awayEligiblePlayers,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      pendingSyncEventsCount:
          pendingSyncEventsCount ?? this.pendingSyncEventsCount,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      lastActionFeedback: clearLastActionFeedback
          ? null
          : (lastActionFeedback ?? this.lastActionFeedback),
    );
  }
}
