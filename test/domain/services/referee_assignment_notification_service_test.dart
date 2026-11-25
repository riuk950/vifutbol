import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/services/referee_assignment_notification_service.dart';

void main() {
  final now = DateTime(2026, 11, 25, 14, 0);

  group('RefereeAssignmentNotificationService', () {
    test('shouldNotify returns true only when referee changes to a non-empty id', () {
      expect(
        RefereeAssignmentNotificationService.shouldNotify(
          previousRefereeId: null,
          newRefereeId: 'ref-1',
        ),
        isTrue,
      );
      expect(
        RefereeAssignmentNotificationService.shouldNotify(
          previousRefereeId: 'ref-1',
          newRefereeId: 'ref-2',
        ),
        isTrue,
      );
      expect(
        RefereeAssignmentNotificationService.shouldNotify(
          previousRefereeId: 'ref-1',
          newRefereeId: 'ref-1',
        ),
        isFalse,
      );
      expect(
        RefereeAssignmentNotificationService.shouldNotify(
          previousRefereeId: 'ref-1',
          newRefereeId: null,
        ),
        isFalse,
      );
    });

    test('buildAssignmentAlert creates targeted Spanish alert and skips when recipientUserId is null', () {
      final match = ChampionshipMatch(
        id: 'match-1',
        tournamentId: 't-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'h-1',
        awayTeamId: 'a-1',
        refereeId: 'ref-1',
        pitchName: 'Cancha Central',
        scheduledStartTime: DateTime.utc(2026, 11, 26, 20, 0),
        status: MatchStatus.scheduled,
        updatedAt: now,
      );

      final alert = RefereeAssignmentNotificationService.buildAssignmentAlert(
        match: match,
        recipientUserId: 'user-ref-1',
        homeTeamName: 'Atlético Norte',
        awayTeamName: 'Deportivo Sur',
        tournamentName: 'Copa Apertura',
        now: now,
      );

      expect(alert, isNotNull);
      expect(alert!.type, MatchAlertType.refereeMatchAssigned);
      expect(alert.recipientUserId, 'user-ref-1');
      expect(alert.title, 'Nuevo partido asignado');
      expect(alert.message, contains('Atlético Norte vs Deportivo Sur'));
      expect(alert.message, contains('Copa Apertura'));
      expect(alert.message, contains('Cancha Central'));
      expect(alert.isRead, isFalse);

      final skipped = RefereeAssignmentNotificationService.buildAssignmentAlert(
        match: match,
        recipientUserId: null,
        homeTeamName: 'Atlético Norte',
        awayTeamName: 'Deportivo Sur',
        tournamentName: 'Copa Apertura',
        now: now,
      );
      expect(skipped, isNull);
    });
  });
}
