import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';

class _InMemoryLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _store.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('FixtureSchedulingUseCase', () {
    late LocalTournamentMatchesRepository repository;
    late FixtureSchedulingUseCase useCase;
    late ChampionshipTournament testTournament;
    late List<TournamentTeam> testTeams;
    late SportsVenue testVenue;
    late VenuePitch testPitch1;
    late VenuePitch testPitch2;
    late MatchReferee testReferee1;
    late MatchReferee testReferee2;

    setUp(() {
      final storage = _InMemoryLocalStorageRepository();
      repository = LocalTournamentMatchesRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
      useCase = FixtureSchedulingUseCase(matchesRepository: repository);

      testTournament = ChampionshipTournament(
        id: 'tourn-usecase-1',
        name: 'Torneo Apertura 2026',
        category: 'Libre',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 8, 30),
        format: TournamentFormat.league,
        rules: const TournamentRulesConfig(
          halfDurationMinutes: 45,
          leagueRounds: 1,
        ),
        updatedAt: DateTime(2026, 5, 1),
      );

      testTeams = [
        TournamentTeam(
          id: 'team-1',
          tournamentId: testTournament.id,
          name: 'Equipo Alfa',
          shortCode: 'ALF',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-2',
          tournamentId: testTournament.id,
          name: 'Equipo Beta',
          shortCode: 'BET',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-3',
          tournamentId: testTournament.id,
          name: 'Equipo Gamma',
          shortCode: 'GAM',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-4',
          tournamentId: testTournament.id,
          name: 'Equipo Delta',
          shortCode: 'DEL',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
      ];

      testPitch1 = const VenuePitch(
        id: 'pitch-1',
        name: 'Cancha 1 (Sintética)',
        surfaceType: PitchSurfaceType.syntheticGrass,
        format: PitchFormat.football11,
        capacity: 200,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      );
      testPitch2 = const VenuePitch(
        id: 'pitch-2',
        name: 'Cancha 2 (Natural)',
        surfaceType: PitchSurfaceType.naturalGrass,
        format: PitchFormat.football11,
        capacity: 150,
        hasLighting: false,
        status: VenueOperationalStatus.active,
      );

      testVenue = SportsVenue(
        id: 'venue-1',
        name: 'Complejo Deportivo Norte',
        address: 'Calle 100 # 15-20',
        urbanReference: 'Frente al parque',
        coordinate: const GeoCoordinate(latitude: 4.6097, longitude: -74.0817),
        pitches: [testPitch1, testPitch2],
        status: VenueOperationalStatus.active,
        updatedAt: DateTime(2026, 5, 1),
      );

      testReferee1 = const MatchReferee(
        id: 'ref-1',
        fullName: 'Wilmar Roldán',
        certificationLevel: 'FIFA',
      );
      testReferee2 = const MatchReferee(
        id: 'ref-2',
        fullName: 'Nicolás Gallo',
        certificationLevel: 'FIFA',
      );
    });

    test('enforces organizer authorization to generate fixture', () async {
      expect(
        () => useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.fan,
        ),
        throwsA(
          isA<FixtureScheduleValidationFailure>().having(
            (f) => f.code,
            'code',
            FixtureScheduleErrorCode.unauthorizedRole,
          ),
        ),
      );
    });

    test(
      'isolates teams by tournamentId and ignores teams from other tournaments',
      () async {
        final mixedTeams = [
          ...testTeams,
          TournamentTeam(
            id: 'team-other-1',
            tournamentId: 'other-tournament-id',
            name: 'Equipo Foráneo 1',
            shortCode: 'EF1',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
          TournamentTeam(
            id: 'team-other-2',
            tournamentId: 'other-tournament-id',
            name: 'Equipo Foráneo 2',
            shortCode: 'EF2',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
        ];

        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: mixedTeams,
          userRole: UserRole.organizer,
        );

        // testTeams has 4 teams -> 4*3/2 = 6 matches
        expect(matches.length, 6);
        for (final m in matches) {
          expect(m.tournamentId, testTournament.id);
          expect(m.homeTeamId, isNot(contains('team-other')));
          expect(m.awayTeamId, isNot(contains('team-other')));
        }
      },
    );

    test('fails if fewer than 2 teams are eligible', () async {
      final ineligibleTeams = [
        testTeams.first,
        testTeams[1].copyWith(
          eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        ),
      ];

      expect(
        () => useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: ineligibleTeams,
          userRole: UserRole.organizer,
        ),
        throwsA(
          isA<FixtureScheduleValidationFailure>().having(
            (f) => f.code,
            'code',
            FixtureScheduleErrorCode.insufficientTeams,
          ),
        ),
      );
    });

    test('generates and persists round-robin fixture for organizer', () async {
      final matches = await useCase.generateRoundRobinFixture(
        tournament: testTournament,
        teams: testTeams,
        userRole: UserRole.organizer,
      );

      expect(matches.length, 6);
      final persisted = await repository.loadMatchesForTournament(
        testTournament.id,
      );
      expect(persisted.length, 6);
    });

    test(
      'blocks regeneration if any match is inProgress or completed',
      () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Advance one match to inProgress
        await repository.saveMatch(
          matches.first.copyWith(status: MatchStatus.inProgress),
        );

        expect(
          () => useCase.generateRoundRobinFixture(
            tournament: testTournament,
            teams: testTeams,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.regenerationBlocked,
            ),
          ),
        );
      },
    );

    test(
      'schedules match with calculated end time and assigns pitch and referee',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final matchToSchedule = matches.first;
        final startTime = DateTime(2026, 6, 6, 14, 0);

        final scheduled = await useCase.scheduleMatch(
          matchId: matchToSchedule.id,
          tournament: testTournament,
          scheduledStartTime: startTime,
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        expect(scheduled.status, MatchStatus.scheduled);
        expect(scheduled.scheduledStartTime, startTime);
        // 45*2 + 15 = 105 minutes duration -> 15:45
        expect(scheduled.scheduledEndTime, DateTime(2026, 6, 6, 15, 45));
        expect(scheduled.pitchId, testPitch1.id);
        expect(scheduled.refereeId, testReferee1.id);
      }),
    );

    test(
      'allows scheduling in present minute and future, and blocks past dates or times',
      () => withClock(Clock.fixed(DateTime(2026, 6, 10, 11, 30, 45)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Past day -> rejected
        await expectLater(
          () => useCase.scheduleMatch(
            matchId: matches[0].id,
            tournament: testTournament,
            scheduledStartTime: DateTime(2026, 6, 9, 23, 59),
            venue: testVenue,
            pitch: testPitch1,
            referee: testReferee1,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.invalidScheduleTimes,
            ),
          ),
        );

        // Earlier minute today -> rejected
        await expectLater(
          () => useCase.scheduleMatch(
            matchId: matches[0].id,
            tournament: testTournament,
            scheduledStartTime: DateTime(2026, 6, 10, 11, 29),
            venue: testVenue,
            pitch: testPitch1,
            referee: testReferee1,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.invalidScheduleTimes,
            ),
          ),
        );

        // Present minute (11:30:00 while clock is 11:30:45) -> allowed
        final presentScheduled = await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 10, 11, 30),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );
        expect(presentScheduled.status, MatchStatus.scheduled);

        // Future day -> allowed
        final futureScheduled = await useCase.scheduleMatch(
          matchId: matches[1].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 15, 16, 0),
          venue: testVenue,
          pitch: testPitch2,
          referee: testReferee2,
          userRole: UserRole.organizer,
        );
        expect(futureScheduled.status, MatchStatus.scheduled);
      }),
    );

    test(
      'detects and blocks pitch schedule collision',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Match 1 scheduled on Pitch 1: 14:00 - 15:45
        await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        // Attempt to schedule Match 2 on Pitch 1: 15:00 - 16:45 (overlap)
        expect(
          () => useCase.scheduleMatch(
            matchId: matches[1].id,
            tournament: testTournament,
            scheduledStartTime: DateTime(2026, 6, 6, 15, 0),
            venue: testVenue,
            pitch: testPitch1,
            referee: testReferee2,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.pitchScheduleCollision,
            ),
          ),
        );
      }),
    );

    test(
      'detects and blocks referee schedule collision across different pitches',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Match 1 with Referee 1 on Pitch 1: 14:00 - 15:45
        await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        // Attempt to schedule Match 2 on Pitch 2 with SAME Referee 1: 15:00 - 16:45
        expect(
          () => useCase.scheduleMatch(
            matchId: matches[1].id,
            tournament: testTournament,
            scheduledStartTime: DateTime(2026, 6, 6, 15, 0),
            venue: testVenue,
            pitch: testPitch2,
            referee: testReferee1,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.refereeScheduleCollision,
            ),
          ),
        );
      }),
    );

    test(
      'formats pitchName including venue name and persists it',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final scheduled = await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        expect(scheduled.pitchName, '${testVenue.name} - ${testPitch1.name}');
      }),
    );

    test(
      'rescheduling an existing match does not collide with itself',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Initial schedule
        final initial = await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );
        expect(initial.status, MatchStatus.scheduled);

        // Reschedule same match at same time and same pitch/referee (e.g. updating venue details)
        final rescheduled = await useCase.scheduleMatch(
          matchId: matches[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        expect(rescheduled.id, matches[0].id);
        expect(rescheduled.status, MatchStatus.scheduled);
      }),
    );

    test(
      'detects cross-tournament pitch and referee collisions',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        // Tournament A
        final matchesA = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // Schedule Match A in Tournament A on Pitch 1 with Referee 1
        await useCase.scheduleMatch(
          matchId: matchesA[0].id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 6, 6, 14, 0),
          venue: testVenue,
          pitch: testPitch1,
          referee: testReferee1,
          userRole: UserRole.organizer,
        );

        // Tournament B
        final tournamentB = ChampionshipTournament(
          id: 'tourn-cross-2',
          name: 'Torneo Clausura 2026',
          category: 'Veteranos',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 8, 30),
          format: TournamentFormat.league,
          rules: const TournamentRulesConfig(
            halfDurationMinutes: 45,
            leagueRounds: 1,
          ),
          updatedAt: DateTime(2026, 5, 1),
        );

        final teamsB = [
          TournamentTeam(
            id: 'team-b1',
            tournamentId: tournamentB.id,
            name: 'Equipo Delta',
            shortCode: 'DEL',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
          TournamentTeam(
            id: 'team-b2',
            tournamentId: tournamentB.id,
            name: 'Equipo Epsilon',
            shortCode: 'EPS',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          ),
        ];

        final matchesB = await useCase.generateRoundRobinFixture(
          tournament: tournamentB,
          teams: teamsB,
          userRole: UserRole.organizer,
        );

        // Attempt 1: Schedule match in Tournament B on same Pitch 1 during overlapping time
        expect(
          () => useCase.scheduleMatch(
            matchId: matchesB[0].id,
            tournament: tournamentB,
            scheduledStartTime: DateTime(2026, 6, 6, 15, 0),
            venue: testVenue,
            pitch: testPitch1,
            referee: testReferee2,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.pitchScheduleCollision,
            ),
          ),
        );

        // Attempt 2: Schedule match in Tournament B on different Pitch 2 but same Referee 1
        expect(
          () => useCase.scheduleMatch(
            matchId: matchesB[0].id,
            tournament: tournamentB,
            scheduledStartTime: DateTime(2026, 6, 6, 15, 0),
            venue: testVenue,
            pitch: testPitch2,
            referee: testReferee1,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.refereeScheduleCollision,
            ),
          ),
        );
      }),
    );

    test(
      'schedules match with date and time only when venue, pitch, and referee are null, while still detecting team collisions',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        final matches = await useCase.generateRoundRobinFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final match1 = matches[0];
        final matchSameTeam = matches.firstWhere(
          (m) =>
              m.id != match1.id &&
              (m.homeTeamId == match1.homeTeamId ||
                  m.awayTeamId == match1.homeTeamId),
        );
        final matchDifferentTeams = matches.firstWhere(
          (m) =>
              m.id != match1.id &&
              m.homeTeamId != match1.homeTeamId &&
              m.awayTeamId != match1.homeTeamId &&
              m.homeTeamId != match1.awayTeamId &&
              m.awayTeamId != match1.awayTeamId,
        );

        final start = DateTime(2026, 6, 7, 16, 0);
        final scheduled1 = await useCase.scheduleMatch(
          matchId: match1.id,
          tournament: testTournament,
          scheduledStartTime: start,
          userRole: UserRole.organizer,
        );

        expect(scheduled1.status, MatchStatus.scheduled);
        expect(scheduled1.scheduledStartTime, start);
        expect(scheduled1.venueId, isNull);
        expect(scheduled1.pitchId, isNull);
        expect(scheduled1.refereeId, isNull);

        // Another match with different teams at same time with null pitch/referee must NOT collide
        final scheduled2 = await useCase.scheduleMatch(
          matchId: matchDifferentTeams.id,
          tournament: testTournament,
          scheduledStartTime: start,
          userRole: UserRole.organizer,
        );
        expect(scheduled2.status, MatchStatus.scheduled);

        // Same team at overlapping time must still fail with teamScheduleCollision
        await expectLater(
          () => useCase.scheduleMatch(
            matchId: matchSameTeam.id,
            tournament: testTournament,
            scheduledStartTime: start,
            userRole: UserRole.organizer,
          ),
          throwsA(
            isA<FixtureScheduleValidationFailure>().having(
              (f) => f.code,
              'code',
              FixtureScheduleErrorCode.teamScheduleCollision,
            ),
          ),
        );
      }),
    );
  });
}
