import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/schedule_collision_result.dart';

void main() {
  group('MatchReferee Entity', () {
    test('instantiates valid referee and serializes to/from JSON', () {
      const referee = MatchReferee(
        id: 'ref-1',
        fullName: 'Wilmar Roldán',
        certificationLevel: 'FIFA',
        isActive: true,
      );

      expect(referee.id, 'ref-1');
      expect(referee.fullName, 'Wilmar Roldán');
      expect(referee.certificationLevel, 'FIFA');
      expect(referee.isActive, isTrue);

      final json = referee.toJson();
      final fromJson = MatchReferee.fromJson(json);
      expect(fromJson, equals(referee));
    });

    test('validates assertion constraints on referee constructor', () {
      expect(
        () => MatchReferee(
          id: '',
          fullName: 'Valid Name',
          certificationLevel: 'FIFA',
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => MatchReferee(
          id: 'ref-1',
          fullName: 'No',
          certificationLevel: 'FIFA',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ChampionshipMatch Entity', () {
    test(
      'instantiates with pendingSchedule default and validates constraints',
      () {
        final match = ChampionshipMatch(
          id: 'match-1',
          tournamentId: 'tourn-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
        );

        expect(match.status, MatchStatus.pendingSchedule);
        expect(match.isScheduled, isFalse);
      },
    );

    test('throws assertion error when home and away teams are identical', () {
      expect(
        () => ChampionshipMatch(
          id: 'match-1',
          tournamentId: 'tourn-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-a',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('calculates interval overlap correctly', () {
      final match = ChampionshipMatch(
        id: 'match-1',
        tournamentId: 'tourn-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 6, 1, 14, 0),
        scheduledEndTime: DateTime(2026, 6, 1, 15, 45),
        pitchId: 'pitch-1',
      );

      expect(match.isScheduled, isTrue);

      // Total overlap: 14:30 - 15:30
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 1, 14, 30),
          DateTime(2026, 6, 1, 15, 30),
        ),
        isTrue,
      );

      // Overlap at start: 13:30 - 14:15
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 1, 13, 30),
          DateTime(2026, 6, 1, 14, 15),
        ),
        isTrue,
      );

      // Overlap at end: 15:30 - 16:30
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 1, 15, 30),
          DateTime(2026, 6, 1, 16, 30),
        ),
        isTrue,
      );

      // Boundary touch (end == start): 15:45 - 17:00 (no overlap)
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 1, 15, 45),
          DateTime(2026, 6, 1, 17, 0),
        ),
        isFalse,
      );

      // Completely before: 12:00 - 13:45 (no overlap)
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 1, 12, 0),
          DateTime(2026, 6, 1, 13, 45),
        ),
        isFalse,
      );

      // Different day: 14:00 - 15:45 (no overlap)
      expect(
        match.overlapsWith(
          DateTime(2026, 6, 2, 14, 0),
          DateTime(2026, 6, 2, 15, 45),
        ),
        isFalse,
      );
    });

    test('serializes to and from JSON', () {
      final match = ChampionshipMatch(
        id: 'match-100',
        tournamentId: 'tourn-1',
        roundNumber: 2,
        roundName: 'Jornada 2',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 6, 1, 14, 0),
        scheduledEndTime: DateTime(2026, 6, 1, 15, 45),
        venueId: 'venue-1',
        pitchId: 'pitch-1',
        pitchName: 'Cancha 1',
        refereeId: 'ref-1',
        refereeName: 'Nicolás Gallo',
      );

      final json = match.toJson();
      final reconstructed = ChampionshipMatch.fromJson(json);

      expect(reconstructed.id, match.id);
      expect(reconstructed.tournamentId, match.tournamentId);
      expect(reconstructed.roundNumber, match.roundNumber);
      expect(reconstructed.homeTeamId, match.homeTeamId);
      expect(reconstructed.awayTeamId, match.awayTeamId);
      expect(reconstructed.pitchId, match.pitchId);
      expect(reconstructed.refereeId, match.refereeId);
      expect(reconstructed.status, match.status);
    });
  });

  group('ScheduleCollisionResult', () {
    test('creates none and collision factories accurately', () {
      final none = ScheduleCollisionResult.none();
      expect(none.hasCollision, isFalse);

      final collision = ScheduleCollisionResult.collision(
        collisionType: ScheduleCollisionType.pitchConflict,
        conflictingMatchId: 'm-1',
        conflictingEntityName: 'Cancha 1',
        message: 'Cancha ocupada',
      );
      expect(collision.hasCollision, isTrue);
      expect(collision.collisionType, ScheduleCollisionType.pitchConflict);
      expect(collision.conflictingMatchId, 'm-1');
      expect(collision.conflictingEntityName, 'Cancha 1');
      expect(collision.message, 'Cancha ocupada');
    });
  });
}
