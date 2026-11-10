import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

void main() {
  group('TeamEligibilityStatus Domain Entity & Serialization Tests', () {
    test('contains canonical states pendingVerification and eligible', () {
      expect(
        TeamEligibilityStatus.values,
        contains(TeamEligibilityStatus.pendingVerification),
      );
      expect(
        TeamEligibilityStatus.values,
        contains(TeamEligibilityStatus.eligible),
      );
      expect(TeamEligibilityStatus.values.length, equals(2));
    });

    test('isEligible returns true only for eligible status', () {
      final teamPending = TournamentTeam(
        id: 'team-1',
        name: 'Team Pending',
        shortCode: 'PEN',
        eligibilityStatus: TeamEligibilityStatus.pendingVerification,
      );
      final teamEligible = TournamentTeam(
        id: 'team-2',
        name: 'Team Eligible',
        shortCode: 'ELI',
        eligibilityStatus: TeamEligibilityStatus.eligible,
      );

      expect(teamPending.isEligible, isFalse);
      expect(teamEligible.isEligible, isTrue);
    });

    test('TeamEligibilityStatus.fromJson decodes eligible properly', () {
      expect(
        TeamEligibilityStatus.fromJson('eligible'),
        equals(TeamEligibilityStatus.eligible),
      );
    });

    test(
      'TeamEligibilityStatus.fromJson decodes pendingVerification properly',
      () {
        expect(
          TeamEligibilityStatus.fromJson('pendingVerification'),
          equals(TeamEligibilityStatus.pendingVerification),
        );
      },
    );

    test(
      'TeamEligibilityStatus.fromJson maps legacy pendingQuota to pendingVerification',
      () {
        expect(
          TeamEligibilityStatus.fromJson('pendingQuota'),
          equals(TeamEligibilityStatus.pendingVerification),
        );
      },
    );

    test(
      'TeamEligibilityStatus.fromJson maps legacy readyForApproval to pendingVerification',
      () {
        expect(
          TeamEligibilityStatus.fromJson('readyForApproval'),
          equals(TeamEligibilityStatus.pendingVerification),
        );
      },
    );

    test(
      'TeamEligibilityStatus.fromJson maps unknown or empty to pendingVerification',
      () {
        expect(
          TeamEligibilityStatus.fromJson(''),
          equals(TeamEligibilityStatus.pendingVerification),
        );
        expect(
          TeamEligibilityStatus.fromJson('unknown_value'),
          equals(TeamEligibilityStatus.pendingVerification),
        );
      },
    );

    test(
      'TournamentTeam.fromJson correctly deserializes legacy JSON payload',
      () {
        final legacyJson = {
          'id': 'legacy-team-1',
          'tournamentId': 'tourn-1',
          'name': 'Legacy FC',
          'shortCode': 'LEG',
          'crestShape': 'shield',
          'primaryColorHex': 0xFF00E676,
          'secondaryColorHex': 0xFF0A0E17,
          'eligibilityStatus': 'pendingQuota',
          'players': [],
          'coachId': 'coach-seed-1',
        };

        final team = TournamentTeam.fromJson(legacyJson);
        expect(
          team.eligibilityStatus,
          equals(TeamEligibilityStatus.pendingVerification),
        );
        expect(team.isEligible, isFalse);
      },
    );
  });
}
