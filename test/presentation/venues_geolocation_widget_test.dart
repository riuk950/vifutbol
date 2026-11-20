import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/application/use_cases/query_venues_geolocation_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/shell/tabs/venues_tab_view.dart';
import 'package:vifutbol/presentation/venues/widgets/kick_pulse_urban_map_canvas.dart';

class FakeTestVenuesRepository implements VenuesRepository {
  List<SportsVenue> venues = [];

  @override
  Future<List<SportsVenue>> loadVenues() async => List.unmodifiable(venues);

  @override
  Future<void> saveVenue(SportsVenue venue) async {
    final idx = venues.indexWhere((v) => v.id == venue.id);
    if (idx >= 0) {
      venues[idx] = venue;
    } else {
      venues.add(venue);
    }
  }

  @override
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {
    final idx = venues.indexWhere((v) => v.id == venueId);
    if (idx >= 0) venues[idx] = venues[idx].copyWith(status: status);
  }

  @override
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {}

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() async =>
      List.unmodifiable(venues);
}

class FakeTestLocationRepository implements LocationPermissionRepository {
  LocationPermissionState state = const LocationPermissionState(
    status: LocationPermissionStatus.denied,
    userCoordinate: null,
  );

  @override
  Future<LocationPermissionState> getCurrentState() async => state;

  @override
  Future<LocationPermissionState> requestPermissionAndLocation() async {
    state = const LocationPermissionState(
      status: LocationPermissionStatus.granted,
      userCoordinate: GeoCoordinate(latitude: 4.6584, longitude: -74.0938),
    );
    return state;
  }

  @override
  Future<LocationPermissionState> simulatePermissionStatusForDev(
    LocationPermissionStatus status,
  ) async {
    state = LocationPermissionState(
      status: status,
      userCoordinate: status == LocationPermissionStatus.granted
          ? const GeoCoordinate(latitude: 4.6584, longitude: -74.0938)
          : null,
    );
    return state;
  }
}

void main() {
  late FakeTestVenuesRepository fakeVenuesRepo;
  late FakeTestLocationRepository fakeLocationRepo;
  late EnvironmentConfig devConfig;

  final sampleVenue = SportsVenue(
    id: 'venue-widget-1',
    name: 'Complejo Deportivo Salitre',
    address: 'Calle 63 # 68-45',
    urbanReference: 'Puerta 4',
    coordinate: const GeoCoordinate(latitude: 4.6584, longitude: -74.0938),
    pitches: const [
      VenuePitch(
        id: 'p-1',
        name: 'Cancha Sintética 1',
        surfaceType: PitchSurfaceType.syntheticGrass,
        format: PitchFormat.football11,
        capacity: 400,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      ),
    ],
    status: VenueOperationalStatus.active,
    updatedAt: DateTime(2026, 11, 3),
  );

  setUp(() {
    fakeVenuesRepo = FakeTestVenuesRepository();
    fakeLocationRepo = FakeTestLocationRepository();
    fakeVenuesRepo.venues = [sampleVenue];
    devConfig = EnvironmentConfig.development();
  });

  Widget buildHarness({
    required Widget child,
    UserRole role = UserRole.fan,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(devConfig),
        venuesRepositoryProvider.overrideWithValue(fakeVenuesRepo),
        locationPermissionRepositoryProvider.overrideWithValue(
          fakeLocationRepo,
        ),
        activeUserRoleProvider.overrideWithValue(role),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(role),
        ),
        venuesControllerProvider.overrideWith(
          (ref) => VenuesController(
            venuesRepository: fakeVenuesRepo,
            locationPermissionRepository: fakeLocationRepo,
            manageVenuesUseCase: ManageVenuesUseCase(fakeVenuesRepo),
            queryUseCase: const QueryVenuesGeolocationUseCase(),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: KickPulseTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
            size: const Size(400, 800),
          ),
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders VenuesTabView header, map canvas, and venue cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(child: const VenuesTabView(), role: UserRole.fan),
    );
    await tester.pumpAndSettle();

    expect(find.text('Directorio de Sedes'), findsOneWidget);
    expect(find.byType(KickPulseUrbanMapCanvas), findsOneWidget);
    expect(find.text('Complejo Deportivo Salitre'), findsOneWidget);
    expect(find.text('Calle 63 # 68-45'), findsOneWidget);
  });

  testWidgets('RBAC: Nueva sede button is visible only for Organizer', (
    tester,
  ) async {
    // 1. As Fan: No create button
    await tester.pumpWidget(
      buildHarness(child: const VenuesTabView(), role: UserRole.fan),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nueva sede'), findsNothing);

    // 2. As Organizer: Create button visible
    await tester.pumpWidget(
      buildHarness(child: const VenuesTabView(), role: UserRole.organizer),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nueva sede'), findsOneWidget);
  });

  testWidgets('displays non-blocking fallback banner when GPS is denied', (
    tester,
  ) async {
    fakeLocationRepo.state = const LocationPermissionState(
      status: LocationPermissionStatus.denied,
      userCoordinate: null,
    );

    await tester.pumpWidget(
      buildHarness(child: const VenuesTabView(), role: UserRole.fan),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ubicación desactivada: mostrando sedes por referencia urbana'),
      findsOneWidget,
    );
    expect(find.text('Activar ubicación'), findsOneWidget);
  });

  testWidgets('tapping a venue card opens VenueDetailSheet with pitches', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(child: const VenuesTabView(), role: UserRole.fan),
    );
    await tester.pumpAndSettle();

    // Tap on venue card
    await tester.tap(find.text('Complejo Deportivo Salitre'));
    await tester.pumpAndSettle();

    // Detail sheet is presented
    expect(find.text('Canchas internas'), findsOneWidget);
    expect(find.text('Cancha Sintética 1'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('renders without overflow at 130% text scale', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        child: const VenuesTabView(),
        role: UserRole.organizer,
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Directorio de Sedes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
