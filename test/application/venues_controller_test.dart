import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/application/use_cases/query_venues_geolocation_use_case.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

class MockVenuesRepository implements VenuesRepository {
  List<SportsVenue> venues = [];

  @override
  Future<List<SportsVenue>> loadVenues() async => List.unmodifiable(venues);

  @override
  Future<void> saveVenue(SportsVenue venue) async {
    final index = venues.indexWhere((v) => v.id == venue.id);
    if (index >= 0) {
      venues[index] = venue;
    } else {
      venues.add(venue);
    }
  }

  @override
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {
    final index = venues.indexWhere((v) => v.id == venueId);
    if (index >= 0) {
      venues[index] = venues[index].copyWith(status: status);
    }
  }

  @override
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {
    final venueIndex = venues.indexWhere((v) => v.id == venueId);
    if (venueIndex >= 0) {
      final current = venues[venueIndex];
      final updatedPitches = current.pitches.map((p) {
        if (p.id == pitchId) return p.copyWith(status: status);
        return p;
      }).toList();
      venues[venueIndex] = current.copyWith(pitches: updatedPitches);
    }
  }

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() async =>
      List.unmodifiable(venues);
}

class MockLocationPermissionRepository implements LocationPermissionRepository {
  LocationPermissionState state = LocationPermissionState.initial;

  static const GeoCoordinate mockUserLocation = GeoCoordinate(
    latitude: 4.6584,
    longitude: -74.0938,
  );

  @override
  Future<LocationPermissionState> getCurrentState() async => state;

  @override
  Future<LocationPermissionState> requestPermissionAndLocation() async {
    state = const LocationPermissionState(
      status: LocationPermissionStatus.granted,
      userCoordinate: mockUserLocation,
    );
    return state;
  }

  @override
  Future<LocationPermissionState> simulatePermissionStatusForDev(
    LocationPermissionStatus status,
  ) async {
    final coord = status == LocationPermissionStatus.granted
        ? mockUserLocation
        : null;
    state = LocationPermissionState(status: status, userCoordinate: coord);
    return state;
  }
}

void main() {
  late MockVenuesRepository mockVenuesRepo;
  late MockLocationPermissionRepository mockLocationRepo;
  late ManageVenuesUseCase manageUseCase;
  late QueryVenuesGeolocationUseCase queryUseCase;
  late VenuesController controller;

  final now = DateTime(2026, 11, 3, 10, 0);

  final sampleVenue1 = SportsVenue(
    id: 'venue-1',
    name: 'Sede Simón Bolívar',
    address: 'Calle 63 # 50-00',
    urbanReference: 'Cerca a la plaza',
    coordinate: const GeoCoordinate(latitude: 4.6580, longitude: -74.0930),
    pitches: const [
      VenuePitch(
        id: 'p-1',
        name: 'Cancha 1 Sintética',
        surfaceType: PitchSurfaceType.syntheticGrass,
        format: PitchFormat.football11,
        capacity: 500,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      ),
    ],
    status: VenueOperationalStatus.active,
    updatedAt: now,
  );

  final sampleVenue2 = SportsVenue(
    id: 'venue-2',
    name: 'Canchas del Sur',
    address: 'Carrera 10 # 20-30',
    urbanReference: 'Frente al parque sur',
    coordinate: const GeoCoordinate(latitude: 4.5700, longitude: -74.1100),
    pitches: const [
      VenuePitch(
        id: 'p-2',
        name: 'Cancha Natural',
        surfaceType: PitchSurfaceType.naturalGrass,
        format: PitchFormat.football7,
        capacity: 100,
        hasLighting: false,
        status: VenueOperationalStatus.active,
      ),
    ],
    status: VenueOperationalStatus.active,
    updatedAt: now,
  );

  setUp(() {
    mockVenuesRepo = MockVenuesRepository();
    mockLocationRepo = MockLocationPermissionRepository();
    manageUseCase = ManageVenuesUseCase(mockVenuesRepo);
    queryUseCase = const QueryVenuesGeolocationUseCase();
  });

  group('VenuesController - Initialization & UI States', () {
    test('emits UiEmptyState when repository has no venues', () async {
      controller = VenuesController(
        venuesRepository: mockVenuesRepo,
        locationPermissionRepository: mockLocationRepo,
        manageVenuesUseCase: manageUseCase,
        queryUseCase: queryUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(
        controller.state.viewState,
        isA<UiEmptyState<List<SportsVenue>>>(),
      );
      expect(controller.state.venues.isEmpty, isTrue);
    });

    test('emits UiContentState with venues when repository has data', () async {
      mockVenuesRepo.venues = [sampleVenue1, sampleVenue2];

      controller = VenuesController(
        venuesRepository: mockVenuesRepo,
        locationPermissionRepository: mockLocationRepo,
        manageVenuesUseCase: manageUseCase,
        queryUseCase: queryUseCase,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(
        controller.state.viewState,
        isA<UiContentState<List<SportsVenue>>>(),
      );
      expect(controller.state.venues.length, 2);
    });
  });

  group('VenuesController - Filtering & Proximity Sorting', () {
    setUp(() async {
      mockVenuesRepo.venues = [sampleVenue1, sampleVenue2];
      controller = VenuesController(
        venuesRepository: mockVenuesRepo,
        locationPermissionRepository: mockLocationRepo,
        manageVenuesUseCase: manageUseCase,
        queryUseCase: queryUseCase,
      );
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test('filters venues by search query', () {
      controller.setSearchQuery('Bolívar');
      final filtered = controller.getFilteredVenues();
      expect(filtered.length, 1);
      expect(filtered.first.venue.name, 'Sede Simón Bolívar');

      controller.setSearchQuery('inexistente');
      expect(controller.getFilteredVenues().isEmpty, isTrue);
    });

    test('filters venues by surface type and lighting', () {
      controller.setSurfaceFilter(PitchSurfaceType.naturalGrass);
      var filtered = controller.getFilteredVenues();
      expect(filtered.length, 1);
      expect(filtered.first.venue.name, 'Canchas del Sur');

      // Toggling lighting filter
      controller.clearFilters();
      controller.toggleOnlyWithLighting();
      filtered = controller.getFilteredVenues();
      expect(filtered.length, 1);
      expect(filtered.first.venue.name, 'Sede Simón Bolívar');
    });

    test(
      'toggleProximitySort requests location just-in-time and sorts',
      () async {
        expect(
          controller.state.locationState.status,
          LocationPermissionStatus.notRequested,
        );

        await controller.toggleProximitySort();

        expect(
          controller.state.locationState.status,
          LocationPermissionStatus.granted,
        );
        expect(controller.state.sortByProximity, isTrue);

        final sorted = controller.getFilteredVenues();
        expect(sorted.length, 2);
        // Sede Simón Bolívar is ~0.1 km from user coordinate (4.6584, -74.0938)
        // Canchas del Sur is ~10 km away
        expect(sorted.first.venue.name, 'Sede Simón Bolívar');
        expect(sorted.first.distanceInKm, isNotNull);
        expect(sorted.first.distanceInKm!, lessThan(sorted.last.distanceInKm!));
      },
    );

    test('clearFilters restores default search and filter parameters', () {
      controller.setSearchQuery('algo');
      controller.setSurfaceFilter(PitchSurfaceType.hardCourt);
      controller.toggleOnlyWithLighting();

      controller.clearFilters();

      expect(controller.state.searchQuery, '');
      expect(controller.state.surfaceFilter, isNull);
      expect(controller.state.onlyWithLighting, isFalse);
    });
  });

  group('VenuesController - Geolocation Permissions & Dev Simulator', () {
    setUp(() async {
      mockVenuesRepo.venues = [sampleVenue1];
      controller = VenuesController(
        venuesRepository: mockVenuesRepo,
        locationPermissionRepository: mockLocationRepo,
        manageVenuesUseCase: manageUseCase,
        queryUseCase: queryUseCase,
      );
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test(
      'simulates granted, denied, and permanentlyDenied statuses in dev',
      () async {
        // 1. Simulate Granted
        await controller.simulateDevLocationStatus(
          LocationPermissionStatus.granted,
        );
        expect(
          controller.state.locationState.status,
          LocationPermissionStatus.granted,
        );
        expect(controller.state.locationState.userCoordinate, isNotNull);

        // 2. Simulate Denied
        await controller.simulateDevLocationStatus(
          LocationPermissionStatus.denied,
        );
        expect(
          controller.state.locationState.status,
          LocationPermissionStatus.denied,
        );
        expect(controller.state.locationState.userCoordinate, isNull);
        expect(controller.state.sortByProximity, isFalse);

        // 3. Simulate Permanently Denied
        await controller.simulateDevLocationStatus(
          LocationPermissionStatus.permanentlyDenied,
        );
        expect(
          controller.state.locationState.status,
          LocationPermissionStatus.permanentlyDenied,
        );
        expect(controller.state.locationState.userCoordinate, isNull);
      },
    );

    test(
      'LocationPermissionState redacts coordinate in toString (FR-009 Privacy)',
      () {
        const stateWithLocation = LocationPermissionState(
          status: LocationPermissionStatus.granted,
          userCoordinate: GeoCoordinate(latitude: 4.6584, longitude: -74.0938),
        );

        final stringOutput = stateWithLocation.toString();
        expect(stringOutput, contains('[REDACTED_USER_LOCATION]'));
        expect(stringOutput.contains('4.6584'), isFalse);
        expect(stringOutput.contains('-74.0938'), isFalse);
      },
    );
  });
}
