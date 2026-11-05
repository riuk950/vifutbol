import 'championship_match.dart';
import 'match_enums.dart';
import 'match_referee.dart';

class MatchesCatalogState {
  const MatchesCatalogState({
    this.matches = const [],
    this.referees = const [],
    this.selectedRound = 1,
    this.selectedDate,
    this.statusFilter,
    this.teamFilter,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<ChampionshipMatch> matches;
  final List<MatchReferee> referees;
  final int selectedRound;
  final DateTime? selectedDate;
  final MatchStatus? statusFilter;
  final String? teamFilter;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  /// Helper to normalize a DateTime to pure date without time components
  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  List<int> get availableRounds {
    if (matches.isEmpty) return const [];
    final rounds = matches.map((m) => m.roundNumber).toSet().toList()..sort();
    return rounds;
  }

  /// Available distinct calendar dates including at least Hoy and Mañana
  List<DateTime> get availableCalendarDates {
    final now = DateTime.now();
    final today = normalizeDate(now);
    final tomorrow = normalizeDate(now.add(const Duration(days: 1)));
    final dates = <DateTime>{today, tomorrow};

    for (final match in matches) {
      if (match.scheduledStartTime != null) {
        dates.add(normalizeDate(match.scheduledStartTime!));
      }
    }

    final sorted = dates.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  /// Matches currently in progress, highlighted at the top
  List<ChampionshipMatch> get liveMatches {
    return matches.where((m) => m.status == MatchStatus.inProgress).toList();
  }

  /// Unscheduled matches without assigned date/time or in pendingSchedule state
  List<ChampionshipMatch> get unscheduledMatches {
    return matches.where((m) {
      return m.scheduledStartTime == null ||
          m.status == MatchStatus.pendingSchedule;
    }).toList();
  }

  /// Matches scheduled for the selected calendar date
  List<ChampionshipMatch> get scheduledMatchesForSelectedDate {
    final targetDate = selectedDate ?? normalizeDate(DateTime.now());
    return matches.where((match) {
      if (match.scheduledStartTime == null) return false;
      final matchDate = normalizeDate(match.scheduledStartTime!);
      if (matchDate != targetDate) return false;

      if (statusFilter != null && match.status != statusFilter) {
        return false;
      }
      if (teamFilter != null &&
          teamFilter!.isNotEmpty &&
          match.homeTeamId != teamFilter &&
          match.awayTeamId != teamFilter) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      final aStart = a.scheduledStartTime ?? DateTime(0);
      final bStart = b.scheduledStartTime ?? DateTime(0);
      return aStart.compareTo(bStart);
    });
  }

  List<ChampionshipMatch> get filteredMatches {
    return matches.where((match) {
      if (availableRounds.isNotEmpty && match.roundNumber != selectedRound) {
        return false;
      }
      if (statusFilter != null && match.status != statusFilter) {
        return false;
      }
      if (teamFilter != null &&
          teamFilter!.isNotEmpty &&
          match.homeTeamId != teamFilter &&
          match.awayTeamId != teamFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  MatchesCatalogState copyWith({
    List<ChampionshipMatch>? matches,
    List<MatchReferee>? referees,
    int? selectedRound,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    MatchStatus? Function()? statusFilter,
    String? Function()? teamFilter,
    bool? isLoading,
    bool? isSaving,
    String? Function()? errorMessage,
  }) {
    return MatchesCatalogState(
      matches: matches ?? this.matches,
      referees: referees ?? this.referees,
      selectedRound: selectedRound ?? this.selectedRound,
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      teamFilter: teamFilter != null ? teamFilter() : this.teamFilter,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchesCatalogState &&
        other.matches == matches &&
        other.referees == referees &&
        other.selectedRound == selectedRound &&
        other.selectedDate == selectedDate &&
        other.statusFilter == statusFilter &&
        other.teamFilter == teamFilter &&
        other.isLoading == isLoading &&
        other.isSaving == isSaving &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    matches,
    referees,
    selectedRound,
    selectedDate,
    statusFilter,
    teamFilter,
    isLoading,
    isSaving,
    errorMessage,
  );
}
