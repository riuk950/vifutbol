import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/venues/widgets/create_venue_bottom_sheet.dart';

class FakeVenuesRepo implements VenuesRepository {
  List<SportsVenue> list = [];

  @override
  Future<List<SportsVenue>> loadVenues() async => List.unmodifiable(list);

  @override
  Future<void> saveVenue(SportsVenue venue) async {
    final idx = list.indexWhere((v) => v.id == venue.id);
    if (idx >= 0) {
      list[idx] = venue;
    } else {
      list.add(venue);
    }
  }

  @override
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {}

  @override
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {}

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() async =>
      List.unmodifiable(list);
}

class FakeLocationRepo implements LocationPermissionRepository {
  @override
  Future<LocationPermissionState> getCurrentState() async {
    return const LocationPermissionState(
      status: LocationPermissionStatus.granted,
      userCoordinate: null,
    );
  }

  @override
  Future<LocationPermissionState> requestPermissionAndLocation() async {
    return const LocationPermissionState(
      status: LocationPermissionStatus.granted,
      userCoordinate: null,
    );
  }

  @override
  Future<LocationPermissionState> simulatePermissionStatusForDev(
    LocationPermissionStatus status,
  ) async {
    return LocationPermissionState(status: status, userCoordinate: null);
  }
}

Widget buildTestWidget({required FakeVenuesRepo repo, Widget? child}) {
  return ProviderScope(
    overrides: [
      venuesControllerProvider.overrideWith((ref) {
        return VenuesController(
          venuesRepository: repo,
          locationPermissionRepository: FakeLocationRepo(),
          manageVenuesUseCase: ManageVenuesUseCase(repo),
        );
      }),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body:
            child ??
            Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('openSheetButton'),
                  onPressed: () => showCreateVenueBottomSheet(context),
                  child: const Text('Open'),
                );
              },
            ),
      ),
    ),
  );
}

void main() {
  late FakeVenuesRepo fakeRepo;

  setUp(() {
    fakeRepo = FakeVenuesRepo();
  });

  group('CreateVenueBottomSheet Widget Tests', () {
    testWidgets('renders all required form fields and buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(repo: fakeRepo, child: const CreateVenueBottomSheet()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createVenueNameField')), findsOneWidget);
      expect(find.byKey(const Key('createVenueAddressField')), findsOneWidget);
      expect(
        find.byKey(const Key('createVenuePitchesCountField')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('createVenueSubmitButton')), findsOneWidget);
      expect(find.byKey(const Key('createVenueCancelButton')), findsOneWidget);
    });

    testWidgets('shows validation errors for empty/invalid fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(repo: fakeRepo, child: const CreateVenueBottomSheet()),
      );
      await tester.pumpAndSettle();

      // Clear pitches field to make it invalid
      await tester.enterText(
        find.byKey(const Key('createVenuePitchesCountField')),
        '0',
      );
      await tester.tap(find.byKey(const Key('createVenueSubmitButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre debe tener al menos 3 caracteres'),
        findsOneWidget,
      );
      expect(
        find.text('La dirección debe tener al menos 5 caracteres'),
        findsOneWidget,
      );
      expect(find.text('Debe tener al menos 1 cancha'), findsOneWidget);
      expect(fakeRepo.list, isEmpty);
    });

    testWidgets(
      'creates venue with sequential pitches on valid submission and closes sheet',
      (tester) async {
        SportsVenue? createdVenue;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              venuesControllerProvider.overrideWith((ref) {
                return VenuesController(
                  venuesRepository: fakeRepo,
                  locationPermissionRepository: FakeLocationRepo(),
                  manageVenuesUseCase: ManageVenuesUseCase(fakeRepo),
                );
              }),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      key: const Key('openSheetButton'),
                      onPressed: () async {
                        createdVenue = await showCreateVenueBottomSheet(
                          context,
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('openSheetButton')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('createVenueNameField')),
          'Complejo Los Arrayanes',
        );
        await tester.enterText(
          find.byKey(const Key('createVenueAddressField')),
          'Avenida Suba # 120-45',
        );
        await tester.enterText(
          find.byKey(const Key('createVenuePitchesCountField')),
          '3',
        );

        await tester.tap(find.byKey(const Key('createVenueSubmitButton')));
        await tester.pumpAndSettle();

        expect(createdVenue, isNotNull);
        expect(createdVenue!.name, 'Complejo Los Arrayanes');
        expect(createdVenue!.address, 'Avenida Suba # 120-45');
        expect(createdVenue!.pitches.length, 3);
        expect(createdVenue!.pitches[0].name, 'Cancha 1');
        expect(createdVenue!.pitches[1].name, 'Cancha 2');
        expect(createdVenue!.pitches[2].name, 'Cancha 3');
        expect(fakeRepo.list.length, 1);
      },
    );
  });
}
