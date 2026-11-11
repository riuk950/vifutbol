import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
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
  group('MatchesCatalogController', () {
    late LocalTournamentMatchesRepository repository;
    late FixtureSchedulingUseCase useCase;
    late MatchesCatalogController controller;
    late ChampionshipTournament testTournament;
    late List<TournamentTeam> testTeams;

    setUp(() {
      final storage = _InMemoryLocalStorageRepository();
      repository = LocalTournamentMatchesRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
      useCase = FixtureSchedulingUseCase(matchesRepository: repository);
      controller = MatchesCatalogController(
        matchesRepository: repository,
        fixtureSchedulingUseCase: useCase,
      );

      testTournament = ChampionshipTournament(
        id: 'tourn-ctrl-1',
        name: 'Liga de Prueba',
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
          name: 'Equipo 1',
          shortCode: 'E1',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-2',
          tournamentId: testTournament.id,
          name: 'Equipo 2',
          shortCode: 'E2',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
      ];
    });

    test('initial state has empty matches and default round 1', () {
      expect(controller.state.matches, isEmpty);
      expect(controller.state.selectedRound, 1);
      expect(controller.state.isLoading, isFalse);
    });

    test('loads matches and preloads seed referees in development', () async {
      await controller.loadTournamentMatches('tournament-seed-liga-clausura');

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.matches.length, 2);
      expect(controller.state.referees.length, 3);
      expect(controller.state.availableRounds, [1, 2]);
    });

    test('generates fixture through controller and updates state', () async {
      final success = await controller.generateFixture(
        tournament: testTournament,
        teams: testTeams,
        userRole: UserRole.organizer,
      );

      expect(success, isTrue);
      expect(controller.state.matches.isNotEmpty, isTrue);
      expect(controller.state.errorMessage, isNull);
    });

    test('navigates rounds and applies status filters in state', () async {
      await controller.generateFixture(
        tournament: testTournament,
        teams: testTeams,
        userRole: UserRole.organizer,
      );

      controller.selectRound(1);
      expect(controller.state.selectedRound, 1);

      controller.setStatusFilter(MatchStatus.scheduled);
      expect(controller.state.statusFilter, MatchStatus.scheduled);
      // Currently all matches are pendingSchedule, so filteredMatches is empty
      expect(controller.state.filteredMatches, isEmpty);

      controller.setStatusFilter(MatchStatus.pendingSchedule);
      expect(controller.state.filteredMatches.isNotEmpty, isTrue);
    });

    test(
      'schedules match via controller',
      () => withClock(Clock.fixed(DateTime(2026, 6, 1, 9, 0)), () async {
        await controller.generateFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final match = controller.state.matches.first;
        final referees = await repository.loadOfficialReferees();
        const pitch = VenuePitch(
          id: 'pitch-ctrl-1',
          name: 'Cancha 1',
          surfaceType: PitchSurfaceType.syntheticGrass,
          format: PitchFormat.football11,
          capacity: 100,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        );
        final venue = SportsVenue(
          id: 'venue-ctrl-1',
          name: 'Sede Central',
          address: 'Calle 10',
          urbanReference: 'Centro',
          coordinate: const GeoCoordinate(latitude: 4.6, longitude: -74.0),
          pitches: const [pitch],
          status: VenueOperationalStatus.active,
          updatedAt: DateTime.now(),
        );

        final pastSuccess = await controller.scheduleMatch(
          matchId: match.id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 5, 31, 14, 0),
          venue: venue,
          pitch: pitch,
          referee: referees.first,
          userRole: UserRole.organizer,
        );
        expect(pastSuccess, isFalse);
        expect(controller.state.errorMessage, isNotNull);

        final success = await controller.scheduleMatch(
          matchId: match.id,
          tournament: testTournament,
          scheduledStartTime: DateTime(2026, 7, 1, 14, 0),
          venue: venue,
          pitch: pitch,
          referee: referees.first,
          userRole: UserRole.organizer,
        );

        expect(success, isTrue);
        final scheduled = controller.state.matches.firstWhere(
          (m) => m.id == match.id,
        );
        expect(scheduled.status, MatchStatus.scheduled);
        expect(scheduled.refereeName, referees.first.fullName);
        // Auto transitions selectedDate to scheduled day
        expect(controller.state.selectedDate, DateTime(2026, 7, 1));
      }),
    );

    test(
      'calendar date filtering, unscheduled matches and date selection',
      () async {
        await controller.loadTournamentMatches('tournament-seed-liga-clausura');

        // Seed matches include 1 scheduled and 1 pendingSchedule
        expect(controller.state.unscheduledMatches.length, 1);
        expect(
          controller.state.unscheduledMatches.first.id,
          'match-seed-clausura-2',
        );

        // availableCalendarDates includes at least today, tomorrow, and match scheduled date
        expect(
          controller.state.availableCalendarDates.length,
          greaterThanOrEqualTo(2),
        );

        final scheduledMatch = controller.state.matches.firstWhere(
          (m) => m.status == MatchStatus.scheduled,
        );
        final scheduledDay = MatchesCatalogState.normalizeDate(
          scheduledMatch.scheduledStartTime!,
        );

        // Select that specific calendar day
        controller.selectDate(scheduledDay);
        expect(controller.state.selectedDate, scheduledDay);
        expect(controller.state.scheduledMatchesForSelectedDate.length, 1);
        expect(
          controller.state.scheduledMatchesForSelectedDate.first.id,
          scheduledMatch.id,
        );

        // Select today (no matches scheduled in seed)
        final today = MatchesCatalogState.normalizeDate(DateTime.now());
        controller.selectDate(today);
        expect(controller.state.scheduledMatchesForSelectedDate, isEmpty);
      },
    );
  });
}
