import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';

void main() {
  group('MatchEvent Entity Tests', () {
    test('instantiates valid MatchEvent and serializes to/from JSON', () {
      final now = DateTime.utc(2026, 11, 4, 15, 0);
      final event = MatchEvent(
        id: 'evt-1',
        matchId: 'match-1',
        type: MatchEventType.goal,
        minute: 34,
        teamId: 'team-a',
        primaryPlayerId: 'p-1',
        primaryPlayerName: 'Radamel Falcao',
        primaryPlayerShirtNumber: 9,
        secondaryPlayerId: 'p-2',
        secondaryPlayerName: 'James Rodríguez',
        secondaryPlayerShirtNumber: 10,
        description: 'Golazo de media distancia',
        isSynced: false,
        createdAt: now,
      );

      expect(event.id, equals('evt-1'));
      expect(event.minute, equals(34));
      expect(event.isSynced, isFalse);

      final json = event.toJson();
      final fromJson = MatchEvent.fromJson(json);

      expect(fromJson.id, equals(event.id));
      expect(fromJson.matchId, equals(event.matchId));
      expect(fromJson.type, equals(MatchEventType.goal));
      expect(fromJson.minute, equals(34));
      expect(fromJson.teamId, equals('team-a'));
      expect(fromJson.primaryPlayerId, equals('p-1'));
      expect(fromJson.primaryPlayerName, equals('Radamel Falcao'));
      expect(fromJson.primaryPlayerShirtNumber, equals(9));
      expect(fromJson.secondaryPlayerId, equals('p-2'));
      expect(fromJson.secondaryPlayerName, equals('James Rodríguez'));
      expect(fromJson.secondaryPlayerShirtNumber, equals(10));
      expect(fromJson.description, equals('Golazo de media distancia'));
      expect(fromJson.isSynced, isFalse);
    });

    test('validates assertion constraints on MatchEvent constructor', () {
      expect(
        () => MatchEvent(
          id: '',
          matchId: 'm-1',
          type: MatchEventType.goal,
          minute: 10,
          teamId: 't-1',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MatchEvent(
          id: 'e-1',
          matchId: '',
          type: MatchEventType.goal,
          minute: 10,
          teamId: 't-1',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MatchEvent(
          id: 'e-1',
          matchId: 'm-1',
          type: MatchEventType.goal,
          minute: 0,
          teamId: 't-1',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MatchEvent(
          id: 'e-1',
          matchId: 'm-1',
          type: MatchEventType.goal,
          minute: 131,
          teamId: 't-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DigitalMatchReport Aggregate Tests', () {
    test('instantiates valid report and serializes to/from JSON', () {
      final report = DigitalMatchReport(
        matchId: 'match-100',
        tournamentId: 'tourn-1',
        homeTeamId: 'team-home',
        awayTeamId: 'team-away',
        homeScore: 2,
        awayScore: 1,
        currentPeriod: MatchPeriod.firstHalf,
        elapsedSecondsBeforeCurrentPeriod: 0,
        events: [
          MatchEvent(
            id: 'e-1',
            matchId: 'match-100',
            type: MatchEventType.goal,
            minute: 15,
            teamId: 'team-home',
            primaryPlayerId: 'p-1',
            isSynced: true,
          ),
        ],
      );

      expect(report.homeScore, equals(2));
      expect(report.awayScore, equals(1));
      expect(report.currentPeriod, equals(MatchPeriod.firstHalf));
      expect(report.events.length, equals(1));

      final json = report.toJson();
      final fromJson = DigitalMatchReport.fromJson(json);

      expect(fromJson.matchId, equals('match-100'));
      expect(fromJson.homeScore, equals(2));
      expect(fromJson.awayScore, equals(1));
      expect(fromJson.currentPeriod, equals(MatchPeriod.firstHalf));
      expect(fromJson.events.length, equals(1));
      expect(fromJson.events.first.id, equals('e-1'));
    });

    test(
      'calculates exact elapsed seconds and match minute across background intervals',
      () {
        final start = DateTime.utc(2026, 11, 4, 14, 0, 0);

        // Period 1: Running
        final reportFirstHalf = DigitalMatchReport(
          matchId: 'match-1',
          tournamentId: 'tourn-1',
          homeTeamId: 'team-home',
          awayTeamId: 'team-away',
          currentPeriod: MatchPeriod.firstHalf,
          periodStartedAt: start,
          elapsedSecondsBeforeCurrentPeriod: 0,
        );

        // At start: 0 seconds elapsed -> minute 1
        expect(reportFirstHalf.totalElapsedSecondsAt(start), equals(0));
        expect(reportFirstHalf.currentMatchMinuteAt(start), equals(1));

        // 34 minutes and 15 seconds later (e.g. after phone screen locked)
        final timeAtMinute34 = start.add(
          const Duration(minutes: 34, seconds: 15),
        );
        expect(
          reportFirstHalf.totalElapsedSecondsAt(timeAtMinute34),
          equals(2055),
        );
        expect(
          reportFirstHalf.currentMatchMinuteAt(timeAtMinute34),
          equals(35),
        );

        // Half Time: Clock is paused at 2700 seconds (45 min)
        final reportHalfTime = reportFirstHalf.copyWith(
          currentPeriod: MatchPeriod.halfTime,
          clearPeriodStartedAt: true,
          elapsedSecondsBeforeCurrentPeriod: 2700,
        );
        final duringBreak = start.add(const Duration(minutes: 50));
        expect(reportHalfTime.totalElapsedSecondsAt(duringBreak), equals(2700));
        expect(reportHalfTime.currentMatchMinuteAt(duringBreak), equals(46));

        // Period 2: Resumed from 2700 seconds
        final secondHalfStart = start.add(const Duration(minutes: 60));
        final reportSecondHalf = reportHalfTime.copyWith(
          currentPeriod: MatchPeriod.secondHalf,
          periodStartedAt: secondHalfStart,
          elapsedSecondsBeforeCurrentPeriod: 2700,
        );

        final atMinute68 = secondHalfStart.add(
          const Duration(minutes: 23, seconds: 10),
        );
        // 2700 + 1390 = 4090 seconds (68 minutes and 10 seconds -> minute 69)
        expect(
          reportSecondHalf.totalElapsedSecondsAt(atMinute68),
          equals(4090),
        );
        expect(reportSecondHalf.currentMatchMinuteAt(atMinute68), equals(69));
      },
    );

    test('evaluates double-yellow and direct red expulsions accurately', () {
      final events = [
        MatchEvent(
          id: 'yc-1',
          matchId: 'm-1',
          type: MatchEventType.yellowCard,
          minute: 25,
          teamId: 'home',
          primaryPlayerId: 'player-5',
        ),
        MatchEvent(
          id: 'yc-2',
          matchId: 'm-1',
          type: MatchEventType.yellowCard,
          minute: 68,
          teamId: 'home',
          primaryPlayerId: 'player-5',
        ),
        MatchEvent(
          id: 'rc-2',
          matchId: 'm-1',
          type: MatchEventType.secondYellowRedCard,
          minute: 68,
          teamId: 'home',
          primaryPlayerId: 'player-5',
          linkedParentEventId: 'yc-2',
        ),
        MatchEvent(
          id: 'rc-direct',
          matchId: 'm-1',
          type: MatchEventType.directRedCard,
          minute: 75,
          teamId: 'away',
          primaryPlayerId: 'player-8',
        ),
      ];

      final report = DigitalMatchReport(
        matchId: 'm-1',
        tournamentId: 't-1',
        homeTeamId: 'home',
        awayTeamId: 'away',
        events: events,
      );

      expect(report.yellowCardCountForPlayer('player-5'), equals(2));
      expect(report.yellowCardCountForPlayer('player-8'), equals(0));
      expect(report.expelledPlayerIds, containsAll(['player-5', 'player-8']));
      expect(report.isPlayerExpelled('player-5'), isTrue);
      expect(report.isPlayerExpelled('player-8'), isTrue);
      expect(report.isPlayerExpelled('player-99'), isFalse);
    });

    test('counts pending unsynced events correctly', () {
      final report = DigitalMatchReport(
        matchId: 'm-1',
        tournamentId: 't-1',
        homeTeamId: 'home',
        awayTeamId: 'away',
        events: [
          MatchEvent(
            id: 'e-1',
            matchId: 'm-1',
            type: MatchEventType.goal,
            minute: 10,
            teamId: 'home',
            isSynced: true,
          ),
          MatchEvent(
            id: 'e-2',
            matchId: 'm-1',
            type: MatchEventType.yellowCard,
            minute: 20,
            teamId: 'home',
            isSynced: false,
          ),
          MatchEvent(
            id: 'e-3',
            matchId: 'm-1',
            type: MatchEventType.goal,
            minute: 30,
            teamId: 'home',
            isSynced: false,
          ),
        ],
      );

      expect(report.pendingSyncCount, equals(2));
    });
  });
}
