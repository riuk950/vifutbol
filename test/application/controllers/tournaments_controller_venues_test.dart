import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

class MockTournamentsRepository extends Mock implements TournamentsRepository {}

class MockVenuesRepository extends Mock implements VenuesRepository {}

class MockLocationPermissionRepository extends Mock
    implements LocationPermissionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ChampionshipTournament(
        id: 'fallback-id',
        name: 'Fallback Tournament',
        category: 'Libre',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    registerFallbackValue(
      SportsVenue(
        id: 'fallback-venue',
        name: 'Fallback Venue',
        address: 'Calle 100 # 20-30',
        urbanReference: '',
        coordinate: const GeoCoordinate(latitude: 4.6, longitude: -74.0),
        pitches: const [
          VenuePitch(
            id: 'p-1',
            name: 'Cancha 1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 14,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  late MockTournamentsRepository mockTournamentsRepo;
  late MockVenuesRepository mockVenuesRepo;
  late MockLocationPermissionRepository mockLocationRepo;

  late ManageTournamentsUseCase manageTournamentsUseCase;
  late ManageVenuesUseCase manageVenuesUseCase;

  late TournamentsController tournamentsController;
  late VenuesController venuesController;

  final storedTournaments = <ChampionshipTournament>[];
  final storedVenues = <SportsVenue>[];

  setUp(() {
    mockTournamentsRepo = MockTournamentsRepository();
    mockVenuesRepo = MockVenuesRepository();
    mockLocationRepo = MockLocationPermissionRepository();

    storedTournaments.clear();
    storedVenues.clear();

    when(
      () => mockTournamentsRepo.loadTournaments(),
    ).thenAnswer((_) async => List.unmodifiable(storedTournaments));
    when(() => mockTournamentsRepo.loadDraft()).thenAnswer((_) async => null);
    when(() => mockTournamentsRepo.clearDraft()).thenAnswer((_) async {});
    when(() => mockTournamentsRepo.saveTournament(any())).thenAnswer((
      inv,
    ) async {
      final t = inv.positionalArguments[0] as ChampionshipTournament;
      final idx = storedTournaments.indexWhere((x) => x.id == t.id);
      if (idx >= 0) {
        storedTournaments[idx] = t;
      } else {
        storedTournaments.add(t);
      }
      return t;
    });

    when(
      () => mockVenuesRepo.loadVenues(),
    ).thenAnswer((_) async => List.unmodifiable(storedVenues));
    when(() => mockVenuesRepo.saveVenue(any())).thenAnswer((inv) async {
      final v = inv.positionalArguments[0] as SportsVenue;
      final idx = storedVenues.indexWhere((x) => x.id == v.id);
      if (idx >= 0) {
        storedVenues[idx] = v;
      } else {
        storedVenues.add(v);
      }
    });

    when(() => mockLocationRepo.getCurrentState()).thenAnswer(
      (_) async => const LocationPermissionState(
        status: LocationPermissionStatus.granted,
        userCoordinate: null,
      ),
    );

    manageTournamentsUseCase = ManageTournamentsUseCase(mockTournamentsRepo);
    manageVenuesUseCase = ManageVenuesUseCase(mockVenuesRepo);

    tournamentsController = TournamentsController(
      tournamentsRepository: mockTournamentsRepo,
      manageTournamentsUseCase: manageTournamentsUseCase,
    );

    venuesController = VenuesController(
      venuesRepository: mockVenuesRepo,
      locationPermissionRepository: mockLocationRepo,
      manageVenuesUseCase: manageVenuesUseCase,
    );
  });

  group('TournamentsController venue linking & global persistence tests (US3)', () {
    test(
      'persists tournament with official venueIds and updates controller state',
      () async {
        final tournament = ChampionshipTournament(
          id: 'tournament-with-venues-1',
          name: 'Liga Premier Bogotá',
          category: 'Mayores',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 11, 30),
          format: TournamentFormat.league,
          status: TournamentStatus.openRegistration,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 6, 1),
          venueIds: const ['venue-central-campin', 'venue-salitre'],
        );

        final success = await tournamentsController.saveTournament(
          tournament: tournament,
          actorRole: UserRole.organizer,
        );

        expect(success, isTrue);
        expect(storedTournaments.length, 1);
        expect(
          storedTournaments.first.venueIds,
          equals(['venue-central-campin', 'venue-salitre']),
        );

        final savedStateTournaments = tournamentsController.state.tournaments;
        expect(savedStateTournaments.length, 1);
        expect(
          savedStateTournaments.first.venueIds,
          equals(['venue-central-campin', 'venue-salitre']),
        );
      },
    );

    test(
      'overrides venueIds when venueIds parameter is explicitly provided',
      () async {
        final tournament = ChampionshipTournament(
          id: 'tournament-param-venues',
          name: 'Torneo Intercolegiado',
          category: 'Sub-17',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 9, 30),
          format: TournamentFormat.league,
          status: TournamentStatus.openRegistration,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 7, 1),
          venueIds: const ['old-venue'],
        );

        final success = await tournamentsController.saveTournament(
          tournament: tournament,
          actorRole: UserRole.organizer,
          venueIds: const ['new-venue-1', 'new-venue-2'],
        );

        expect(success, isTrue);
        expect(storedTournaments.length, 1);
        expect(
          storedTournaments.first.venueIds,
          equals(['new-venue-1', 'new-venue-2']),
        );
      },
    );

    test(
      'end-to-end: new venue saved in VenuesController is linked into new ChampionshipTournament',
      () async {
        // 1. Create and save new sports venue via VenuesController
        final newVenue = SportsVenue(
          id: 'venue-multicanchas-norte',
          name: 'Multicanchas del Norte',
          address: 'Calle 170 # 45-10',
          urbanReference: 'Frente al portal norte',
          coordinate: const GeoCoordinate(latitude: 4.75, longitude: -74.04),
          pitches: const [
            VenuePitch(
              id: 'p-1',
              name: 'Cancha 1',
              surfaceType: PitchSurfaceType.syntheticGrass,
              format: PitchFormat.football7,
              capacity: 14,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
            VenuePitch(
              id: 'p-2',
              name: 'Cancha 2',
              surfaceType: PitchSurfaceType.syntheticGrass,
              format: PitchFormat.football7,
              capacity: 14,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: DateTime(2026, 6, 1),
        );

        final venueSaved = await venuesController.saveVenue(newVenue);
        expect(venueSaved, isTrue);
        expect(storedVenues.length, 1);
        expect(storedVenues.first.id, 'venue-multicanchas-norte');

        // 2. Link this venue into a championship tournament
        final tournament = ChampionshipTournament(
          id: 'tournament-final-link',
          name: 'Copa Regional Norte',
          category: 'Libre',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 12, 15),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.openRegistration,
          rules: const TournamentRulesConfig(),
          updatedAt: DateTime(2026, 8, 1),
          venueIds: [newVenue.id],
        );

        final tournamentSaved = await tournamentsController.saveTournament(
          tournament: tournament,
          actorRole: UserRole.organizer,
        );

        expect(tournamentSaved, isTrue);
        expect(storedTournaments.length, 1);
        expect(
          storedTournaments.first.venueIds,
          contains('venue-multicanchas-norte'),
        );
        expect(
          storedVenues.any(
            (v) => v.id == storedTournaments.first.venueIds.first,
          ),
          isTrue,
        );
      },
    );
  });
}
