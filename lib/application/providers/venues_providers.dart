import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/venues_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/application/use_cases/query_venues_geolocation_use_case.dart';
import 'package:vifutbol/domain/entities/venues_catalog_state.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/infrastructure/location/device_location_permission_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';

/// Provider exposing the concrete [VenuesRepository] implementation.
final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);

  return LocalVenuesRepository(storage: storage, config: config);
});

/// Provider exposing the [LocationPermissionRepository] implementation.
final locationPermissionRepositoryProvider =
    Provider<LocationPermissionRepository>((ref) {
      return DeviceLocationPermissionRepository();
    });

/// Provider exposing [ManageVenuesUseCase].
final manageVenuesUseCaseProvider = Provider<ManageVenuesUseCase>((ref) {
  final repository = ref.watch(venuesRepositoryProvider);
  return ManageVenuesUseCase(repository);
});

/// Provider exposing [QueryVenuesGeolocationUseCase].
final queryVenuesGeolocationUseCaseProvider =
    Provider<QueryVenuesGeolocationUseCase>((ref) {
      return const QueryVenuesGeolocationUseCase();
    });

/// StateNotifierProvider exposing the central [VenuesController].
final venuesControllerProvider =
    StateNotifierProvider<VenuesController, VenuesCatalogState>((ref) {
      final venuesRepository = ref.watch(venuesRepositoryProvider);
      final locationRepository = ref.watch(
        locationPermissionRepositoryProvider,
      );
      final manageUseCase = ref.watch(manageVenuesUseCaseProvider);
      final queryUseCase = ref.watch(queryVenuesGeolocationUseCaseProvider);

      return VenuesController(
        venuesRepository: venuesRepository,
        locationPermissionRepository: locationRepository,
        manageVenuesUseCase: manageUseCase,
        queryUseCase: queryUseCase,
      );
    });

/// Reactive provider of the filtered and proximity-sorted list of venues.
final filteredVenuesProvider = Provider<List<VenueWithDistance>>((ref) {
  final controller = ref.watch(venuesControllerProvider.notifier);
  // Re-run when state changes
  ref.watch(venuesControllerProvider);
  return controller.getFilteredVenues();
});
