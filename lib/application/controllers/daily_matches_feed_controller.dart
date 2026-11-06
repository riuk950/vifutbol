import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

/// Estado de la selección de fecha para el feed diario de partidos.
class DailyMatchesDateState {
  final DateTime selectedDate;
  final MatchesDailyTab activeTab;
  final bool isCustomDate;

  const DailyMatchesDateState({
    required this.selectedDate,
    required this.activeTab,
    this.isCustomDate = false,
  });

  factory DailyMatchesDateState.today() {
    final now = DateTime.now();
    return DailyMatchesDateState(
      selectedDate: DateTime(now.year, now.month, now.day),
      activeTab: MatchesDailyTab.today,
      isCustomDate: false,
    );
  }

  DailyMatchesDateState withTab(MatchesDailyTab tab) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (tab) {
      case MatchesDailyTab.yesterday:
        return DailyMatchesDateState(
          selectedDate: today.subtract(const Duration(days: 1)),
          activeTab: MatchesDailyTab.yesterday,
          isCustomDate: false,
        );
      case MatchesDailyTab.today:
        return DailyMatchesDateState(
          selectedDate: today,
          activeTab: MatchesDailyTab.today,
          isCustomDate: false,
        );
      case MatchesDailyTab.tomorrow:
        return DailyMatchesDateState(
          selectedDate: today.add(const Duration(days: 1)),
          activeTab: MatchesDailyTab.tomorrow,
          isCustomDate: false,
        );
      case MatchesDailyTab.customDate:
        return this;
    }
  }

  DailyMatchesDateState withCustomDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (normalized == today) {
      return DailyMatchesDateState(
        selectedDate: today,
        activeTab: MatchesDailyTab.today,
        isCustomDate: false,
      );
    } else if (normalized == yesterday) {
      return DailyMatchesDateState(
        selectedDate: yesterday,
        activeTab: MatchesDailyTab.yesterday,
        isCustomDate: false,
      );
    } else if (normalized == tomorrow) {
      return DailyMatchesDateState(
        selectedDate: tomorrow,
        activeTab: MatchesDailyTab.tomorrow,
        isCustomDate: false,
      );
    } else {
      return DailyMatchesDateState(
        selectedDate: normalized,
        activeTab: MatchesDailyTab.customDate,
        isCustomDate: true,
      );
    }
  }
}

/// Estado global del feed diario de partidos.
class DailyMatchesFeedState {
  final DailyMatchesDateState dateState;
  final List<TournamentMatchesGroup> tournamentGroups;
  final int pendingScheduleMatchesCount;
  final int unseededTournamentsCount;
  final bool isLoading;
  final String? errorMessage;

  const DailyMatchesFeedState({
    required this.dateState,
    this.tournamentGroups = const [],
    this.pendingScheduleMatchesCount = 0,
    this.unseededTournamentsCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && tournamentGroups.isEmpty;
  bool get hasOrganizerAlerts =>
      pendingScheduleMatchesCount > 0 || unseededTournamentsCount > 0;

  DailyMatchesFeedState copyWith({
    DailyMatchesDateState? dateState,
    List<TournamentMatchesGroup>? tournamentGroups,
    int? pendingScheduleMatchesCount,
    int? unseededTournamentsCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DailyMatchesFeedState(
      dateState: dateState ?? this.dateState,
      tournamentGroups: tournamentGroups ?? this.tournamentGroups,
      pendingScheduleMatchesCount:
          pendingScheduleMatchesCount ?? this.pendingScheduleMatchesCount,
      unseededTournamentsCount:
          unseededTournamentsCount ?? this.unseededTournamentsCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Agrupa una lista de partidos por torneo activo para la fecha objetivo.
List<TournamentMatchesGroup> groupMatchesByActiveTournaments({
  required List<ChampionshipMatch> matches,
  required List<ChampionshipTournament> tournaments,
  required DateTime targetDate,
}) {
  final normalizedTarget = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  );

  final activeTournaments = tournaments.where((t) {
    return t.status == TournamentStatus.openRegistration ||
        t.status == TournamentStatus.inProgress;
  }).toList();

  final activeTournamentsMap = {for (final t in activeTournaments) t.id: t};

  final Map<String, List<ChampionshipMatch>> matchesByTournament = {};

  for (final match in matches) {
    if (match.scheduledStartTime == null) continue;
    final matchDate = DateTime(
      match.scheduledStartTime!.year,
      match.scheduledStartTime!.month,
      match.scheduledStartTime!.day,
    );
    if (matchDate != normalizedTarget) continue;

    if (activeTournamentsMap.containsKey(match.tournamentId)) {
      matchesByTournament.putIfAbsent(match.tournamentId, () => []).add(match);
    }
  }

  final List<TournamentMatchesGroup> groups = [];

  for (final entry in matchesByTournament.entries) {
    final tournament = activeTournamentsMap[entry.key]!;
    final tournamentMatches = entry.value;

    tournamentMatches.sort((a, b) {
      if (a.status == MatchStatus.inProgress &&
          b.status != MatchStatus.inProgress) {
        return -1;
      }
      if (b.status == MatchStatus.inProgress &&
          a.status != MatchStatus.inProgress) {
        return 1;
      }
      final aTime = a.scheduledStartTime ?? DateTime(2099);
      final bTime = b.scheduledStartTime ?? DateTime(2099);
      return aTime.compareTo(bTime);
    });

    groups.add(
      TournamentMatchesGroup(
        tournament: tournament,
        matches: tournamentMatches,
      ),
    );
  }

  groups.sort((a, b) {
    if (a.hasLiveMatches && !b.hasLiveMatches) return -1;
    if (!a.hasLiveMatches && b.hasLiveMatches) return 1;
    return a.tournament.name.compareTo(b.tournament.name);
  });

  return groups;
}

/// Notifier para el feed diario de partidos.
class DailyMatchesFeedController extends StateNotifier<DailyMatchesFeedState> {
  DailyMatchesFeedController(this.ref)
    : super(DailyMatchesFeedState(dateState: DailyMatchesDateState.today())) {
    _init();
  }

  final Ref ref;

  void _init() {
    _computeFeed();
  }

  void selectQuickTab(MatchesDailyTab tab) {
    state = state.copyWith(dateState: state.dateState.withTab(tab));
    _computeFeed();
  }

  void selectCustomDate(DateTime date) {
    state = state.copyWith(dateState: state.dateState.withCustomDate(date));
    _computeFeed();
  }

  void resetToToday() {
    state = state.copyWith(dateState: DailyMatchesDateState.today());
    _computeFeed();
  }

  void _computeFeed() {
    final matchesCatalogState = ref.read(matchesCatalogControllerProvider);
    final tournamentsState = ref.read(tournamentsControllerProvider);

    final pendingCount = matchesCatalogState.matches
        .where((m) => m.status == MatchStatus.pendingSchedule)
        .length;

    final unseededCount = tournamentsState.tournaments
        .where(
          (t) =>
              (t.status == TournamentStatus.openRegistration ||
                  t.status == TournamentStatus.inProgress) &&
              !matchesCatalogState.matches.any((m) => m.tournamentId == t.id),
        )
        .length;

    final groups = groupMatchesByActiveTournaments(
      matches: matchesCatalogState.matches,
      tournaments: tournamentsState.tournaments,
      targetDate: state.dateState.selectedDate,
    );

    state = state.copyWith(
      tournamentGroups: groups,
      pendingScheduleMatchesCount: pendingCount,
      unseededTournamentsCount: unseededCount,
      isLoading: false,
    );
  }

  void refresh() {
    _computeFeed();
  }
}
