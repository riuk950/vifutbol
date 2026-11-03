import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/manage_venues_use_case.dart';
import 'package:vifutbol/application/use_cases/query_venues_geolocation_use_case.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venues_catalog_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

/// Central state notifier managing the sports venues and pitches catalog,
/// search/filters, just-in-time geolocation permissions, and venue administration.
class VenuesController extends StateNotifier<VenuesCatalogState> {
  VenuesController({
    required this.venuesRepository,
    required this.locationPermissionRepository,
    required this.manageVenuesUseCase,
    this.queryUseCase = const QueryVenuesGeolocationUseCase(),
  }) : super(VenuesCatalogState.initial) {
    loadCatalog();
  }

  final VenuesRepository venuesRepository;
  final LocationPermissionRepository locationPermissionRepository;
  final ManageVenuesUseCase manageVenuesUseCase;
  final QueryVenuesGeolocationUseCase queryUseCase;

  /// Loads the venues catalog from repository and synchronizes initial UI view state.
  Future<void> loadCatalog() async {
    state = state.copyWith(
      viewState: const UiLoadingState<List<SportsVenue>>(),
      clearLastFailure: true,
    );

    try {
      final venues = await venuesRepository.loadVenues();
      final locState = await locationPermissionRepository.getCurrentState();

      if (venues.isEmpty) {
        state = state.copyWith(
          venues: venues,
          locationState: locState,
          viewState: const UiEmptyState<List<SportsVenue>>(
            message: 'Aún no hay sedes registradas',
            description:
                'No se encontraron sedes deportivas activas para este torneo.',
          ),
        );
      } else {
        state = state.copyWith(
          venues: venues,
          locationState: locState,
          viewState: UiContentState<List<SportsVenue>>(venues),
        );
      }
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(
        viewState: UiErrorState<List<SportsVenue>>(failure),
        lastFailure: failure,
      );
    }
  }

  /// Sets text search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Toggles or sets playing surface filter.
  void setSurfaceFilter(PitchSurfaceType? surface) {
    if (state.surfaceFilter == surface) {
      state = state.copyWith(clearSurfaceFilter: true);
    } else {
      state = state.copyWith(surfaceFilter: surface);
    }
  }

  /// Clears active search and all filters.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearSurfaceFilter: true,
      onlyWithLighting: false,
      sortByProximity: false,
    );
  }

  /// Toggles night lighting requirement filter.
  void toggleOnlyWithLighting() {
    state = state.copyWith(onlyWithLighting: !state.onlyWithLighting);
  }

  /// Toggles proximity sorting, requesting location permission just-in-time if needed.
  Future<void> toggleProximitySort() async {
    if (state.sortByProximity) {
      state = state.copyWith(sortByProximity: false);
      return;
    }

    if (!state.locationState.status.isGranted) {
      final newLocState = await locationPermissionRepository
          .requestPermissionAndLocation();
      state = state.copyWith(
        locationState: newLocState,
        sortByProximity: newLocState.status.isGranted,
      );
    } else {
      state = state.copyWith(sortByProximity: true);
    }
  }

  /// Requests location permission in context (just-in-time).
  Future<void> requestLocationPermission() async {
    final newLocState = await locationPermissionRepository
        .requestPermissionAndLocation();
    state = state.copyWith(locationState: newLocState);
  }

  /// Simulates location permission status in development environment.
  Future<void> simulateDevLocationStatus(
    LocationPermissionStatus status,
  ) async {
    final newLocState = await locationPermissionRepository
        .simulatePermissionStatusForDev(status);
    state = state.copyWith(
      locationState: newLocState,
      sortByProximity: status == LocationPermissionStatus.granted
          ? state.sortByProximity
          : false,
    );
  }

  /// Selects a venue to highlight on the map and sheet.
  void selectVenue(String? venueId) {
    if (venueId == null) {
      state = state.copyWith(clearSelectedVenue: true);
    } else {
      state = state.copyWith(selectedVenueId: venueId);
    }
  }

  /// Preserves draft text fields across mobile lifecycle changes.
  void updateDraft({String? name, String? address, String? urbanReference}) {
    state = state.copyWith(
      draftVenueName: name ?? state.draftVenueName,
      draftAddress: address ?? state.draftAddress,
      draftUrbanReference: urbanReference ?? state.draftUrbanReference,
    );
  }

  /// Saves a sports venue with single-flight submit protection.
  Future<bool> saveVenue(SportsVenue venue) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearLastFailure: true);

    try {
      await manageVenuesUseCase.saveVenue(venue);
      final venues = await venuesRepository.loadVenues();
      state = state.copyWith(
        venues: venues,
        isSubmitting: false,
        draftVenueName: '',
        draftAddress: '',
        draftUrbanReference: '',
        viewState: UiContentState<List<SportsVenue>>(venues),
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : InvalidVenueDataFailure(e.toString());
      state = state.copyWith(isSubmitting: false, lastFailure: failure);
      return false;
    }
  }

  /// Updates logical operational status of a venue.
  Future<void> setVenueStatus(
    String venueId,
    VenueOperationalStatus status,
  ) async {
    await manageVenuesUseCase.setVenueStatus(venueId: venueId, status: status);
    final venues = await venuesRepository.loadVenues();
    state = state.copyWith(
      venues: venues,
      viewState: UiContentState<List<SportsVenue>>(venues),
    );
  }

  /// Updates logical operational status of an internal pitch.
  Future<void> setPitchStatus(
    String venueId,
    String pitchId,
    VenueOperationalStatus status,
  ) async {
    await manageVenuesUseCase.setPitchStatus(
      venueId: venueId,
      pitchId: pitchId,
      status: status,
    );
    final venues = await venuesRepository.loadVenues();
    state = state.copyWith(
      venues: venues,
      viewState: UiContentState<List<SportsVenue>>(venues),
    );
  }

  /// Computes the filtered and proximity-sorted list of venues.
  List<VenueWithDistance> getFilteredVenues() {
    return queryUseCase.execute(
      venues: state.venues,
      searchQuery: state.searchQuery,
      surfaceFilter: state.surfaceFilter,
      onlyWithLighting: state.onlyWithLighting,
      sortByProximity: state.sortByProximity,
      userCoordinate: state.locationState.userCoordinate,
    );
  }
}
