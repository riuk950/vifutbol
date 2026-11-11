import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

class MockVenuesRepository extends Mock implements VenuesRepository {}

void main() {
  late MockVenuesRepository mockVenuesRepository;
  late ManageVenuesUseCase useCase;

  final List<VenuePitch> samplePitches = [
    const VenuePitch(
      id: 'p-1',
      name: 'Cancha 1',
      surfaceType: PitchSurfaceType.syntheticGrass,
      format: PitchFormat.football7,
      hasLighting: true,
      status: VenueOperationalStatus.active,
      capacity: 14,
    ),
  ];

  final existingVenue = SportsVenue(
    id: 'venue-101',
    name: 'Sede Central Campin',
    address: 'Calle 53 # 30-10',
    urbanReference: 'Frente al estadio',
    coordinate: const GeoCoordinate(latitude: 4.64, longitude: -74.07),
    pitches: samplePitches,
    status: VenueOperationalStatus.active,
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(existingVenue);
  });

  setUp(() {
    mockVenuesRepository = MockVenuesRepository();
    useCase = ManageVenuesUseCase(mockVenuesRepository);

    when(
      () => mockVenuesRepository.loadVenues(),
    ).thenAnswer((_) async => [existingVenue]);
    when(() => mockVenuesRepository.saveVenue(any())).thenAnswer((_) async {});
  });

  group('ManageVenuesUseCase duplicate name validation', () {
    test(
      'throws InvalidVenueDataFailure when creating a venue with identical name',
      () async {
        final newVenue = SportsVenue(
          id: 'venue-202',
          name: 'Sede Central Campin',
          address: 'Carrera 7 # 45-20',
          urbanReference: 'Sector Chapinero',
          coordinate: const GeoCoordinate(latitude: 4.63, longitude: -74.06),
          pitches: samplePitches,
          status: VenueOperationalStatus.active,
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(
          () => useCase.saveVenue(newVenue),
          throwsA(
            isA<InvalidVenueDataFailure>().having(
              (e) => e.message,
              'message',
              contains('Ya existe una sede con este nombre'),
            ),
          ),
        );
        verifyNever(() => mockVenuesRepository.saveVenue(any()));
      },
    );

    test(
      'throws InvalidVenueDataFailure on case-insensitive and trimmed match',
      () async {
        final newVenueWithWhitespaceAndLower = SportsVenue(
          id: 'venue-203',
          name: '   sede central campin   ',
          address: 'Avenida 68 # 80-00',
          urbanReference: 'Norte',
          coordinate: const GeoCoordinate(latitude: 4.68, longitude: -74.08),
          pitches: samplePitches,
          status: VenueOperationalStatus.active,
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(
          () => useCase.saveVenue(newVenueWithWhitespaceAndLower),
          throwsA(
            isA<InvalidVenueDataFailure>().having(
              (e) => e.message,
              'message',
              contains('Ya existe una sede con este nombre'),
            ),
          ),
        );
        verifyNever(() => mockVenuesRepository.saveVenue(any()));
      },
    );

    test(
      'allows updating existing venue with the same name and same id',
      () async {
        final updatedExistingVenue = existingVenue.copyWith(
          address: 'Calle 53 # 30-15 (Dirección Actualizada)',
        );

        await expectLater(useCase.saveVenue(updatedExistingVenue), completes);
        verify(
          () => mockVenuesRepository.saveVenue(updatedExistingVenue),
        ).called(1);
      },
    );

    test('allows creating a venue with a distinct unique name', () async {
      final uniqueVenue = SportsVenue(
        id: 'venue-303',
        name: 'Club Arrayanes Norte',
        address: 'Autopista Norte # 200-00',
        urbanReference: 'Extremo norte',
        coordinate: const GeoCoordinate(latitude: 4.80, longitude: -74.05),
        pitches: samplePitches,
        status: VenueOperationalStatus.active,
        updatedAt: DateTime(2026, 1, 1),
      );

      await expectLater(useCase.saveVenue(uniqueVenue), completes);
      verify(() => mockVenuesRepository.saveVenue(uniqueVenue)).called(1);
    });
  });
}
