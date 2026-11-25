import '../entities/championship_match.dart';
import '../entities/match_enums.dart';

/// Filter options for the referee's assigned matches list.
enum RefereeMatchFilter {
  all,
  inProgress,
  scheduled,
  completed,
}

/// Pure domain service for matching, filtering, and operationally sorting
/// championship matches assigned to an authenticated referee.
class RefereeAssignedMatchesService {
  const RefereeAssignedMatchesService._();

  /// Returns true if [match] is assigned to the referee identified by
  /// [linkedRefereeId] or fallback [userId].
  static bool isAssignedToReferee(
    ChampionshipMatch match, {
    String? userId,
    String? linkedRefereeId,
  }) {
    final matchRefereeId = match.refereeId?.trim();
    if (matchRefereeId == null || matchRefereeId.isEmpty) {
      return false;
    }

    final validIds = <String>{
      if (linkedRefereeId != null && linkedRefereeId.trim().isNotEmpty)
        linkedRefereeId.trim(),
      if (userId != null && userId.trim().isNotEmpty) userId.trim(),
    };

    return validIds.contains(matchRefereeId);
  }

  /// Filters [matches] assigned to the referee and applies [filter] plus
  /// operational ordering:
  /// 1. In progress (`inProgress`) ascending by scheduled start time.
  /// 2. Scheduled / pending (`scheduled`, `pending`) ascending by start time (nulls last).
  /// 3. Completed / cancelled (`completed`, `cancelled`) descending by most recent time.
  static List<ChampionshipMatch> filterAndSort(
    List<ChampionshipMatch> matches, {
    String? userId,
    String? linkedRefereeId,
    RefereeMatchFilter filter = RefereeMatchFilter.all,
  }) {
    final assigned = matches
        .where(
          (m) => isAssignedToReferee(
            m,
            userId: userId,
            linkedRefereeId: linkedRefereeId,
          ),
        )
        .where((m) => _matchesFilter(m.status, filter))
        .toList();

    assigned.sort(compareOperational);
    return assigned;
  }

  static bool _matchesFilter(MatchStatus status, RefereeMatchFilter filter) {
    return switch (filter) {
      RefereeMatchFilter.all => true,
      RefereeMatchFilter.inProgress => status == MatchStatus.inProgress,
      RefereeMatchFilter.scheduled =>
        status == MatchStatus.scheduled || status == MatchStatus.pendingSchedule,
      RefereeMatchFilter.completed =>
        status == MatchStatus.completed || status == MatchStatus.cancelled,
    };
  }

  static int _statusPriority(MatchStatus status) {
    return switch (status) {
      MatchStatus.inProgress => 0,
      MatchStatus.scheduled || MatchStatus.pendingSchedule => 1,
      MatchStatus.completed || MatchStatus.cancelled => 2,
    };
  }

  /// Comparator implementing operational priority for referee matches.
  static int compareOperational(ChampionshipMatch a, ChampionshipMatch b) {
    final pA = _statusPriority(a.status);
    final pB = _statusPriority(b.status);
    if (pA != pB) return pA.compareTo(pB);

    final timeA = a.scheduledStartTime;
    final timeB = b.scheduledStartTime;

    if (pA == 2) {
      // Completed/cancelled: most recent first
      final effA = timeA ?? a.updatedAt;
      final effB = timeB ?? b.updatedAt;
      return effB.compareTo(effA);
    }

    // In-progress and scheduled: earliest first, unscheduled last
    if (timeA == null && timeB == null) {
      return a.roundNumber.compareTo(b.roundNumber);
    }
    if (timeA == null) return 1;
    if (timeB == null) return -1;
    final cmp = timeA.compareTo(timeB);
    return cmp != 0 ? cmp : a.roundNumber.compareTo(b.roundNumber);
  }
}
