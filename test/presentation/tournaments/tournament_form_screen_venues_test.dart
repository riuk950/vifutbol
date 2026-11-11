import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';

class _InMemoryStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => false;
}

class _FakeVenuesRepository implements VenuesRepository {
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

class _FakeLocationRepository implements LocationPermissionRepository {
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

void main() {
  late _InMemoryStorage storage;
  late LocalTournamentsRepository tournamentsRepo;
  late ManageTournamentsUseCase tournamentsUseCase;
  late TournamentsController tournamentsController;

  late _FakeVenuesRepository venuesRepo;
  late ManageVenuesUseCase venuesUseCase;
  late VenuesController venuesController;

  final initialExistingVenue = SportsVenue(
    id: 'venue-existing-1',
    name: 'Cancha Los Sauces',
    address: 'Calle 100 # 15-20',
    urbanReference: 'Norte',
    coordinate: const GeoCoordinate(latitude: 4.69, longitude: -74.05),
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
  );

  setUp(() {
    storage = _InMemoryStorage();
    tournamentsRepo = LocalTournamentsRepository(
      storage: storage,
      config: EnvironmentConfig.production(),
    );
    tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
    tournamentsController = TournamentsController(
      tournamentsRepository: tournamentsRepo,
      manageTournamentsUseCase: tournamentsUseCase,
    );

    venuesRepo = _FakeVenuesRepository()..list = [initialExistingVenue];
    venuesUseCase = ManageVenuesUseCase(venuesRepo);
    venuesController = VenuesController(
      venuesRepository: venuesRepo,
      locationPermissionRepository: _FakeLocationRepository(),
      manageVenuesUseCase: venuesUseCase,
    );
  });

  Widget buildFormHarness({ChampionshipTournament? initialTournament}) {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(
          EnvironmentConfig.production(),
        ),
        localStorageRepositoryProvider.overrideWithValue(storage),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
        manageTournamentsUseCaseProvider.overrideWithValue(tournamentsUseCase),
        activeUserRoleProvider.overrideWithValue(UserRole.organizer),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(UserRole.organizer),
        ),
        tournamentsControllerProvider.overrideWith(
          (_) => tournamentsController,
        ),
        venuesControllerProvider.overrideWith((_) => venuesController),
      ],
      child: MaterialApp(
        theme: KickPulseTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: TournamentFormScreen(initialTournament: initialTournament),
      ),
    );
  }

  group('TournamentFormScreen Venues & Non-Destructive Flow Tests (US2)', () {
    testWidgets(
      'cancelling bottom sheet preserves all tournament form fields intact',
      (tester) async {
        await tester.pumpWidget(buildFormHarness());
        await tester.pumpAndSettle();

        // Enter tournament details
        await tester.enterText(
          find.byKey(const Key('tournament_name_input')),
          'Copa Bogota Nocturna',
        );
        await tester.enterText(
          find.byKey(const Key('tournament_category_input')),
          'Empresarial',
        );

        // Verify "Sedes Oficiales" section exists
        await tester.ensureVisible(
          find.byKey(const Key('create_new_venue_inline_button')),
        );
        expect(find.text('Sedes Oficiales'), findsOneWidget);
        expect(
          find.byKey(const Key('create_new_venue_inline_button')),
          findsOneWidget,
        );

        // Open bottom sheet
        await tester.tap(
          find.byKey(const Key('create_new_venue_inline_button')),
        );
        await tester.pumpAndSettle();

        // Form inside bottom sheet should appear
        expect(find.byKey(const Key('createVenueNameField')), findsOneWidget);

        // Enter partial text inside sheet
        await tester.enterText(
          find.byKey(const Key('createVenueNameField')),
          'Sede Cancelada',
        );

        // Cancel bottom sheet
        await tester.tap(find.byKey(const Key('createVenueCancelButton')));
        await tester.pumpAndSettle();

        // Bottom sheet is closed, tournament form still has entered values
        expect(find.byKey(const Key('createVenueNameField')), findsNothing);
        expect(find.text('Copa Bogota Nocturna'), findsOneWidget);
        expect(find.text('Empresarial'), findsOneWidget);
      },
    );

    testWidgets(
      'creating a venue inline selects it and preserves tournament form',
      (tester) async {
        await tester.pumpWidget(buildFormHarness());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('tournament_name_input')),
          'Torneo Clausura',
        );

        // Select existing venue
        await tester.ensureVisible(
          find.byKey(Key('venue_chip_${initialExistingVenue.id}')),
        );
        await tester.tap(
          find.byKey(Key('venue_chip_${initialExistingVenue.id}')),
        );
        await tester.pumpAndSettle();

        // Open modal to create second venue
        await tester.ensureVisible(
          find.byKey(const Key('create_new_venue_inline_button')),
        );
        await tester.tap(
          find.byKey(const Key('create_new_venue_inline_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('createVenueNameField')),
          'Centro Deportivo El Salitre 2',
        );
        await tester.enterText(
          find.byKey(const Key('createVenueAddressField')),
          'Avenida 68 # 63-00',
        );
        await tester.enterText(
          find.byKey(const Key('createVenuePitchesCountField')),
          '2',
        );

        await tester.tap(find.byKey(const Key('createVenueSubmitButton')));
        await tester.pumpAndSettle();

        // Modal closed, newly created venue should exist in repository and be selected
        expect(venuesRepo.list.length, 2);
        final createdVenue = venuesRepo.list.firstWhere(
          (v) => v.name == 'Centro Deportivo El Salitre 2',
        );
        expect(createdVenue.pitches.length, 2);

        // Both existing and new venue should be checked
        expect(find.text('Torneo Clausura'), findsOneWidget);
        expect(
          find.byKey(Key('venue_chip_${createdVenue.id}')),
          findsOneWidget,
        );
      },
    );
  });
}
