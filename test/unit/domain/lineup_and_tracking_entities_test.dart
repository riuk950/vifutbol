import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';

void main() {
  group('PlayerInternalTracking & Disciplinary Rules', () {
    test(
      'calculates suspension correctly when pendingSuspensionMatches > 0',
      () {
        const tracking = PlayerInternalTracking(
          playerId: 'p-1',
          teamId: 't-1',
          tournamentId: 'tour-1',
          pendingSuspensionMatches: 1,
          yellowCards: 1,
        );

        expect(tracking.effectiveSuspensionMatches(3), equals(1));
        expect(tracking.isSuspended(3), isTrue);
        expect(
          tracking.disciplinaryState(3),
          equals(PlayerDisciplinaryState.suspended),
        );
      },
    );

    test('calculates suspension when yellow cards reach limit', () {
      const tracking = PlayerInternalTracking(
        playerId: 'p-2',
        teamId: 't-1',
        tournamentId: 'tour-1',
        yellowCards: 3,
        pendingSuspensionMatches: 0,
      );

      expect(tracking.effectiveSuspensionMatches(3), equals(1));
      expect(tracking.isSuspended(3), isTrue);
      expect(
        tracking.disciplinaryState(3),
        equals(PlayerDisciplinaryState.suspended),
      );
    });

    test('flags warning accumulation when 1 yellow card away from limit', () {
      const tracking = PlayerInternalTracking(
        playerId: 'p-3',
        teamId: 't-1',
        tournamentId: 'tour-1',
        yellowCards: 2,
        pendingSuspensionMatches: 0,
      );

      expect(tracking.effectiveSuspensionMatches(3), equals(0));
      expect(tracking.isSuspended(3), isFalse);
      expect(tracking.isAtYellowCardWarning(3), isTrue);
      expect(
        tracking.disciplinaryState(3),
        equals(PlayerDisciplinaryState.warningAccumulation),
      );
    });

    test(
      'evaluates eligible when no sanctions and yellow cards below warning',
      () {
        const tracking = PlayerInternalTracking(
          playerId: 'p-4',
          teamId: 't-1',
          tournamentId: 'tour-1',
          yellowCards: 1,
          pendingSuspensionMatches: 0,
        );

        expect(tracking.isSuspended(3), isFalse);
        expect(tracking.isAtYellowCardWarning(3), isFalse);
        expect(
          tracking.disciplinaryState(3),
          equals(PlayerDisciplinaryState.eligible),
        );
      },
    );

    test('serializes and deserializes correctly', () {
      const tracking = PlayerInternalTracking(
        playerId: 'p-5',
        teamId: 't-1',
        tournamentId: 'tour-1',
        matchesPlayed: 4,
        goals: 3,
        assists: 2,
        yellowCards: 1,
        redCards: 0,
        pendingSuspensionMatches: 0,
      );

      final json = tracking.toJson();
      final fromJson = PlayerInternalTracking.fromJson(json);

      expect(fromJson, equals(tracking));
    });
  });

  group('MatchLineupConvocation', () {
    test('reports player role and referee report sync status correctly', () {
      final convocation = MatchLineupConvocation(
        id: 'conv-1',
        tournamentId: 'tour-1',
        teamId: 'team-1',
        starterPlayerIds: const ['p-1', 'p-2'],
        substitutePlayerIds: const ['p-3'],
        captainPlayerId: 'p-1',
        status: ConvocationStatus.draft,
      );

      expect(
        convocation.roleForPlayer('p-1'),
        equals(PlayerConvocationRole.starter),
      );
      expect(
        convocation.roleForPlayer('p-3'),
        equals(PlayerConvocationRole.substitute),
      );
      expect(
        convocation.roleForPlayer('p-4'),
        equals(PlayerConvocationRole.notConvoked),
      );
      expect(convocation.isCaptain('p-1'), isTrue);
      expect(convocation.isSyncedWithRefereeReport, isFalse);

      final confirmed = convocation.copyWith(
        status: ConvocationStatus.confirmed,
        confirmedStarterPlayerIds: ['p-1', 'p-2'],
        confirmedSubstitutePlayerIds: ['p-3'],
        confirmedCaptainPlayerId: () => 'p-1',
        confirmedAt: () => DateTime(2026, 11, 4),
      );

      expect(confirmed.isSyncedWithRefereeReport, isTrue);
    });
  });
}
