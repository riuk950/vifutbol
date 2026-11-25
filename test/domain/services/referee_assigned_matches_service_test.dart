import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/services/referee_assigned_matches_service.dart';

void main() {
  final baseUpdatedAt = DateTime(2026, 11, 25, 10, 0);

  ChampionshipMatch buildMatch({
    required String id,
    String tournamentId = 't-1',
    int roundNumber = 1,
    MatchStatus status = MatchStatus.scheduled,
    String? refereeId,
    DateTime? scheduledStartTime,
    DateTime? updatedAt,
  }) {
    return ChampionshipMatch(
      id: id,
      tournamentId: tournamentId,
      roundNumber: roundNumber,
      roundName: 'Jornada $roundNumber',
      homeTeamId: 'home-$id',
      awayTeamId: 'away-$id',
      refereeId: refereeId,
      status: status,
      scheduledStartTime: scheduledStartTime,
      updatedAt: updatedAt ?? baseUpdatedAt,
    );
  }

  group('RefereeAssignedMatchesService', () {
    test('matches by linkedRefereeId or fallback userId and excludes others', () {
      final byLinked = buildMatch(id: 'm1', refereeId: 'ref-profile-1');
      final byUserId = buildMatch(id: 'm2', refereeId: 'user-1');
      final otherRef = buildMatch(id: 'm3', refereeId: 'ref-other');
      final unassigned = buildMatch(id: 'm4', refereeId: null);

      expect(
        RefereeAssignedMatchesService.isAssignedToReferee(
          byLinked,
          userId: 'user-1',
          linkedRefereeId: 'ref-profile-1',
        ),
        isTrue,
      );
      expect(
        RefereeAssignedMatchesService.isAssignedToReferee(
          byUserId,
          userId: 'user-1',
          linkedRefereeId: 'ref-profile-1',
        ),
        isTrue,
      );
      expect(
        RefereeAssignedMatchesService.isAssignedToReferee(
          otherRef,
          userId: 'user-1',
          linkedRefereeId: 'ref-profile-1',
        ),
        isFalse,
      );
      expect(
        RefereeAssignedMatchesService.isAssignedToReferee(
          unassigned,
          userId: 'user-1',
          linkedRefereeId: 'ref-profile-1',
        ),
        isFalse,
      );
    });

    test('sorts operationally: inProgress first, scheduled asc, completed desc', () {
      final completedOld = buildMatch(
        id: 'c-old',
        refereeId: 'ref-1',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 11, 20, 14),
      );
      final completedNew = buildMatch(
        id: 'c-new',
        refereeId: 'ref-1',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 11, 24, 18),
      );
      final scheduledLater = buildMatch(
        id: 's-later',
        refereeId: 'ref-1',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 11, 27, 16),
      );
      final scheduledSoon = buildMatch(
        id: 's-soon',
        refereeId: 'ref-1',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 11, 26, 10),
      );
      final scheduledUnset = buildMatch(
        id: 's-unset',
        refereeId: 'ref-1',
        status: MatchStatus.scheduled,
        scheduledStartTime: null,
      );
      final live = buildMatch(
        id: 'live',
        refereeId: 'ref-1',
        status: MatchStatus.inProgress,
        scheduledStartTime: DateTime(2026, 11, 25, 15),
      );

      final result = RefereeAssignedMatchesService.filterAndSort(
        [
          completedOld,
          scheduledLater,
          scheduledUnset,
          live,
          completedNew,
          scheduledSoon,
        ],
        linkedRefereeId: 'ref-1',
      );

      expect(
        result.map((m) => m.id).toList(),
        ['live', 's-soon', 's-later', 's-unset', 'c-new', 'c-old'],
      );
    });

    test('filters by status accurately', () {
      final matches = [
        buildMatch(id: '1', refereeId: 'ref-1', status: MatchStatus.inProgress),
        buildMatch(id: '2', refereeId: 'ref-1', status: MatchStatus.scheduled),
        buildMatch(id: '3', refereeId: 'ref-1', status: MatchStatus.completed),
      ];

      expect(
        RefereeAssignedMatchesService.filterAndSort(
          matches,
          linkedRefereeId: 'ref-1',
          filter: RefereeMatchFilter.inProgress,
        ).map((m) => m.id),
        ['1'],
      );
      expect(
        RefereeAssignedMatchesService.filterAndSort(
          matches,
          linkedRefereeId: 'ref-1',
          filter: RefereeMatchFilter.scheduled,
        ).map((m) => m.id),
        ['2'],
      );
      expect(
        RefereeAssignedMatchesService.filterAndSort(
          matches,
          linkedRefereeId: 'ref-1',
          filter: RefereeMatchFilter.completed,
        ).map((m) => m.id),
        ['3'],
      );
    });
  });
}
