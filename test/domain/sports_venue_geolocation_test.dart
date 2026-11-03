import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';

class FakeVenuesRepository implements VenuesRepository {
  final List<SportsVenue> venues = [];

  @override
  Future<List<SportsVenue>> loadVenues() async {
    return List.unmodifiable(venues);
  }

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
      venues[index] = venues[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
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
      final currentVenue = venues[venueIndex];
      final updatedPitches = currentVenue.pitches.map((p) {
        if (p.id == pitchId) {
          return p.copyWith(status: status);
        }
        return p;
      }).toList();
      venues[venueIndex] = currentVenue.copyWith(
        pitches: updatedPitches,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() async {
    return List.unmodifiable(venues);
  }
}

void main() {
  group('GeoCoordinate Domain Entity', () {
    test(
      'creates valid GeoCoordinate within range [-90, 90] and [-180, 180]',
      () {
        const coord = GeoCoordinate(latitude: 4.6097, longitude: -74.0817);
        expect(coord.latitude, 4.6097);
        expect(coord.longitude, -74.0817);
      },
    );

    test('throws assertion error for out of range coordinates', () {
      expect(
        () => GeoCoordinate(latitude: 91.0, longitude: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeoCoordinate(latitude: -90.5, longitude: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeoCoordinate(latitude: 0.0, longitude: 180.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeoCoordinate(latitude: 0.0, longitude: -180.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'isValidCoordinate returns true only for valid finite coordinates',
      () {
        expect(GeoCoordinate.isValidCoordinate(4.6097, -74.0817), isTrue);
        expect(GeoCoordinate.isValidCoordinate(90.0, 180.0), isTrue);
        expect(GeoCoordinate.isValidCoordinate(-90.0, -180.0), isTrue);

        expect(GeoCoordinate.isValidCoordinate(90.1, 0.0), isFalse);
        expect(GeoCoordinate.isValidCoordinate(0.0, 180.5), isFalse);
        expect(GeoCoordinate.isValidCoordinate(double.nan, 0.0), isFalse);
        expect(GeoCoordinate.isValidCoordinate(0.0, double.infinity), isFalse);
      },
    );

    test('distanceInKilometersTo calculates accurate Haversine distance', () {
      const p1 = GeoCoordinate(
        latitude: 4.6097,
        longitude: -74.0817,
      ); // Plaza Bolívar Bogotá
      const p2 = GeoCoordinate(
        latitude: 4.6584,
        longitude: -74.0938,
      ); // Simón Bolívar Park (~5.5 km)

      final distance = p1.distanceInKilometersTo(p2);
      expect(distance, greaterThan(5.0));
      expect(distance, lessThan(6.0));

      // Same point distance must be 0
      expect(p1.distanceInKilometersTo(p1), closeTo(0.0, 0.0001));
    });

    test('serializes to and from JSON correctly', () {
      const coord = GeoCoordinate(latitude: 4.6097, longitude: -74.0817);
      final json = coord.toJson();
      final restored = GeoCoordinate.fromJson(json);

      expect(restored, equals(coord));
    });
  });

  group('VenuePitch Domain Entity', () {
    test('creates valid VenuePitch with all fields', () {
      const pitch = VenuePitch(
        id: 'pitch-1',
        name: 'Cancha Sintética 1',
        surfaceType: PitchSurfaceType.syntheticGrass,
        format: PitchFormat.football7,
        capacity: 120,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      );

      expect(pitch.id, 'pitch-1');
      expect(pitch.isActive, isTrue);
      expect(pitch.hasLighting, isTrue);
    });

    test(
      'throws assertion error for invalid name length or negative capacity',
      () {
        expect(
          () => VenuePitch(
            id: 'p1',
            name: 'A',
            surfaceType: PitchSurfaceType.naturalGrass,
            format: PitchFormat.football11,
            capacity: 100,
            hasLighting: false,
            status: VenueOperationalStatus.active,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => VenuePitch(
            id: 'p2',
            name: 'Cancha 2',
            surfaceType: PitchSurfaceType.naturalGrass,
            format: PitchFormat.football11,
            capacity: -5,
            hasLighting: false,
            status: VenueOperationalStatus.active,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('serializes to and from JSON correctly', () {
      const pitch = VenuePitch(
        id: 'pitch-1',
        name: 'Cancha Central',
        surfaceType: PitchSurfaceType.naturalGrass,
        format: PitchFormat.football11,
        capacity: 500,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      );

      final json = pitch.toJson();
      final restored = VenuePitch.fromJson(json);

      expect(restored, equals(pitch));
    });
  });

  group('SportsVenue Domain Entity', () {
    final now = DateTime(2026, 11, 3, 10, 0);
    const validPitch = VenuePitch(
      id: 'p-1',
      name: 'Cancha 1',
      surfaceType: PitchSurfaceType.syntheticGrass,
      format: PitchFormat.football7,
      capacity: 80,
      hasLighting: true,
      status: VenueOperationalStatus.active,
    );

    test('creates valid SportsVenue and computes helper getters', () {
      final venue = SportsVenue(
        id: 'venue-1',
        name: 'Complejo Deportivo Norte',
        address: 'Calle 170 # 15-20',
        urbanReference: 'Frente al portal norte',
        coordinate: const GeoCoordinate(latitude: 4.7500, longitude: -74.0500),
        pitches: [validPitch],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      expect(venue.activePitchesCount, 1);
      expect(venue.isEligibleForFixtures, isTrue);
      expect(venue.hasNightLighting, isTrue);
      expect(venue.surfaces, contains(PitchSurfaceType.syntheticGrass));
    });

    test(
      'isEligibleForFixtures is false if venue is in maintenance or has 0 active pitches',
      () {
        final venueMaintenance = SportsVenue(
          id: 'venue-1',
          name: 'Complejo Deportivo Norte',
          address: 'Calle 170 # 15-20',
          urbanReference: '',
          coordinate: const GeoCoordinate(
            latitude: 4.7500,
            longitude: -74.0500,
          ),
          pitches: [validPitch],
          status: VenueOperationalStatus.maintenance,
          updatedAt: now,
        );
        expect(venueMaintenance.isEligibleForFixtures, isFalse);

        final venueAllPitchesMaintenance = SportsVenue(
          id: 'venue-2',
          name: 'Complejo Deportivo Sur',
          address: 'Avenida 1 de Mayo # 20-30',
          urbanReference: '',
          coordinate: const GeoCoordinate(
            latitude: 4.5800,
            longitude: -74.1200,
          ),
          pitches: [
            validPitch.copyWith(status: VenueOperationalStatus.maintenance),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: now,
        );
        expect(venueAllPitchesMaintenance.activePitchesCount, 0);
        expect(venueAllPitchesMaintenance.isEligibleForFixtures, isFalse);
      },
    );

    test('serializes to and from JSON correctly', () {
      final venue = SportsVenue(
        id: 'venue-1',
        name: 'Complejo El Salitre',
        address: 'Carrera 68 # 63-00',
        urbanReference: 'Acceso por puerta 2',
        coordinate: const GeoCoordinate(latitude: 4.6600, longitude: -74.0900),
        pitches: [validPitch],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      final json = venue.toJson();
      final restored = SportsVenue.fromJson(json);

      expect(restored, equals(venue));
    });
  });

  group('ManageVenuesUseCase', () {
    late FakeVenuesRepository repository;
    late ManageVenuesUseCase useCase;
    final now = DateTime(2026, 11, 3, 10, 0);

    setUp(() {
      repository = FakeVenuesRepository();
      useCase = ManageVenuesUseCase(repository);
    });

    test('saves valid venue when all criteria are satisfied', () async {
      final venue = SportsVenue(
        id: 'venue-test-1',
        name: 'Sede Principal',
        address: 'Carrera 7 # 100-20',
        urbanReference: 'Junto al parque',
        coordinate: const GeoCoordinate(latitude: 4.6800, longitude: -74.0400),
        pitches: const [
          VenuePitch(
            id: 'pitch-1',
            name: 'Cancha 1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 100,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      await useCase.saveVenue(venue);

      final savedList = await repository.loadVenues();
      expect(savedList.length, 1);
      expect(savedList.first.name, 'Sede Principal');
    });

    test('rejects venue with name shorter than 3 characters', () async {
      final venue = SportsVenue(
        id: 'venue-err',
        name: '   ',
        address: 'Carrera 7 # 100-20',
        urbanReference: '',
        coordinate: const GeoCoordinate(latitude: 4.6800, longitude: -74.0400),
        pitches: const [
          VenuePitch(
            id: 'pitch-1',
            name: 'Cancha 1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 100,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      expect(
        () => useCase.saveVenue(venue),
        throwsA(isA<InvalidVenueDataFailure>()),
      );
    });

    test('rejects venue with address shorter than 5 characters', () async {
      final venue = SportsVenue(
        id: 'venue-err-2',
        name: 'Sede Válida',
        address: '     ',
        urbanReference: '',
        coordinate: const GeoCoordinate(latitude: 4.6800, longitude: -74.0400),
        pitches: const [
          VenuePitch(
            id: 'pitch-1',
            name: 'Cancha 1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 100,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      expect(
        () => useCase.saveVenue(venue),
        throwsA(isA<InvalidVenueDataFailure>()),
      );
    });

    test('rejects venue with 0 active pitches', () async {
      final venue = SportsVenue(
        id: 'venue-err-3',
        name: 'Sede Sin Canchas Activas',
        address: 'Calle 100 # 15-20',
        urbanReference: '',
        coordinate: const GeoCoordinate(latitude: 4.6800, longitude: -74.0400),
        pitches: const [
          VenuePitch(
            id: 'pitch-1',
            name: 'Cancha Inactiva',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 100,
            hasLighting: true,
            status: VenueOperationalStatus.maintenance,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      );

      expect(
        () => useCase.saveVenue(venue),
        throwsA(isA<InvalidVenueDataFailure>()),
      );
    });

    test(
      'toggles operational status logically without deleting venue',
      () async {
        final venue = SportsVenue(
          id: 'venue-toggle',
          name: 'Sede Para Mantenimiento',
          address: 'Carrera 30 # 45-00',
          urbanReference: '',
          coordinate: const GeoCoordinate(
            latitude: 4.6300,
            longitude: -74.0800,
          ),
          pitches: const [
            VenuePitch(
              id: 'p1',
              name: 'Cancha 1',
              surfaceType: PitchSurfaceType.syntheticGrass,
              format: PitchFormat.football7,
              capacity: 100,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: now,
        );

        await useCase.saveVenue(venue);

        // Change venue status to maintenance
        await useCase.setVenueStatus(
          venueId: 'venue-toggle',
          status: VenueOperationalStatus.maintenance,
        );

        var list = await repository.loadVenues();
        expect(list.first.status, VenueOperationalStatus.maintenance);
        expect(list.first.isEligibleForFixtures, isFalse);

        // Change pitch status to maintenance
        await useCase.setPitchStatus(
          venueId: 'venue-toggle',
          pitchId: 'p1',
          status: VenueOperationalStatus.maintenance,
        );

        list = await repository.loadVenues();
        expect(
          list.first.pitches.first.status,
          VenueOperationalStatus.maintenance,
        );
      },
    );
  });
}
