import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

void main() {
  late MockLocalStorageRepository mockStorage;
  late EnvironmentConfig devConfig;
  late EnvironmentConfig prodConfig;
  late LocalVenuesRepository devRepo;
  late LocalVenuesRepository prodRepo;

  final inMemoryStore = <String, String>{};

  setUp(() {
    mockStorage = MockLocalStorageRepository();
    inMemoryStore.clear();

    when(() => mockStorage.readString(any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      return inMemoryStore[key];
    });

    when(() => mockStorage.writeString(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as String;
      inMemoryStore[key] = val;
    });

    devConfig = EnvironmentConfig.development();
    prodConfig = EnvironmentConfig.production();

    devRepo = LocalVenuesRepository(storage: mockStorage, config: devConfig);

    prodRepo = LocalVenuesRepository(storage: mockStorage, config: prodConfig);
  });

  group('LocalVenuesRepository - Environment Isolation', () {
    test(
      'returns empty list in dev environment when storage is empty without seeding',
      () async {
        final venues = await devRepo.loadVenues();

        expect(venues, isEmpty);
        expect(inMemoryStore[LocalVenuesRepository.storageKey], isNull);
      },
    );

    test(
      'returns empty list in prod environment when storage is empty without seeding',
      () async {
        final venues = await prodRepo.loadVenues();

        expect(venues.isEmpty, isTrue);
        expect(inMemoryStore[LocalVenuesRepository.storageKey], isNull);
      },
    );
  });

  group('LocalVenuesRepository - Persistence & Status Updates', () {
    final customVenue = SportsVenue(
      id: 'custom-venue-1',
      name: 'Complejo Deportivo Campín',
      address: 'Carrera 30 # 53-00',
      urbanReference: 'Estación El Campín',
      coordinate: const GeoCoordinate(latitude: 4.6450, longitude: -74.0780),
      pitches: const [
        VenuePitch(
          id: 'campin-pitch-1',
          name: 'Cancha Central',
          surfaceType: PitchSurfaceType.naturalGrass,
          format: PitchFormat.football11,
          capacity: 1000,
          hasLighting: true,
          status: VenueOperationalStatus.active,
        ),
      ],
      status: VenueOperationalStatus.active,
      updatedAt: DateTime(2026, 11, 3, 10, 0),
    );

    test('saves and loads new venue in storage', () async {
      await prodRepo.saveVenue(customVenue);

      final loaded = await prodRepo.loadVenues();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'custom-venue-1');
      expect(loaded.first.name, 'Complejo Deportivo Campín');
    });

    test('updates logical status of venue without deleting record', () async {
      await prodRepo.saveVenue(customVenue);

      await prodRepo.updateVenueStatus(
        venueId: 'custom-venue-1',
        status: VenueOperationalStatus.maintenance,
      );

      final loaded = await prodRepo.loadVenues();
      expect(loaded.length, 1);
      expect(loaded.first.status, VenueOperationalStatus.maintenance);
      expect(loaded.first.isEligibleForFixtures, isFalse);
    });

    test('updates logical status of internal pitch and persists', () async {
      await prodRepo.saveVenue(customVenue);

      await prodRepo.updatePitchStatus(
        venueId: 'custom-venue-1',
        pitchId: 'campin-pitch-1',
        status: VenueOperationalStatus.maintenance,
      );

      final loaded = await prodRepo.loadVenues();
      expect(
        loaded.first.pitches.first.status,
        VenueOperationalStatus.maintenance,
      );
      expect(loaded.first.activePitchesCount, 0);
    });

    test(
      'loads offline catalog in less than 200 milliseconds (SC-003)',
      () async {
        await devRepo.saveVenue(customVenue);

        final stopwatch = Stopwatch()..start();
        final venues = await devRepo.loadVenues();
        stopwatch.stop();

        expect(venues.length, 1);
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      },
    );
  });
}
