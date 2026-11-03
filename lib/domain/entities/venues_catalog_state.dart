import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';

/// Immutable state for the venues and sports pitches catalog view and geolocation features.
class VenuesCatalogState {
  const VenuesCatalogState({
    required this.viewState,
    required this.venues,
    this.selectedVenueId,
    this.searchQuery = '',
    this.surfaceFilter,
    this.onlyWithLighting = false,
    this.sortByProximity = false,
    this.locationState = LocationPermissionState.initial,
    this.isSubmitting = false,
    this.draftVenueName = '',
    this.draftAddress = '',
    this.draftUrbanReference = '',
    this.lastFailure,
  });

  final UiViewState<List<SportsVenue>> viewState;
  final List<SportsVenue> venues;
  final String? selectedVenueId;
  final String searchQuery;
  final PitchSurfaceType? surfaceFilter;
  final bool onlyWithLighting;
  final bool sortByProximity;
  final LocationPermissionState locationState;
  final bool isSubmitting;
  final String draftVenueName;
  final String draftAddress;
  final String draftUrbanReference;
  final AppFailure? lastFailure;

  static const VenuesCatalogState initial = VenuesCatalogState(
    viewState: UiLoadingState<List<SportsVenue>>(),
    venues: <SportsVenue>[],
  );

  /// Currently selected venue, if any.
  SportsVenue? get selectedVenue {
    if (selectedVenueId == null) return null;
    try {
      return venues.firstWhere((venue) => venue.id == selectedVenueId);
    } catch (_) {
      return null;
    }
  }

  VenuesCatalogState copyWith({
    UiViewState<List<SportsVenue>>? viewState,
    List<SportsVenue>? venues,
    String? selectedVenueId,
    bool clearSelectedVenue = false,
    String? searchQuery,
    PitchSurfaceType? surfaceFilter,
    bool clearSurfaceFilter = false,
    bool? onlyWithLighting,
    bool? sortByProximity,
    LocationPermissionState? locationState,
    bool? isSubmitting,
    String? draftVenueName,
    String? draftAddress,
    String? draftUrbanReference,
    AppFailure? lastFailure,
    bool clearLastFailure = false,
  }) {
    return VenuesCatalogState(
      viewState: viewState ?? this.viewState,
      venues: venues ?? this.venues,
      selectedVenueId: clearSelectedVenue
          ? null
          : (selectedVenueId ?? this.selectedVenueId),
      searchQuery: searchQuery ?? this.searchQuery,
      surfaceFilter: clearSurfaceFilter
          ? null
          : (surfaceFilter ?? this.surfaceFilter),
      onlyWithLighting: onlyWithLighting ?? this.onlyWithLighting,
      sortByProximity: sortByProximity ?? this.sortByProximity,
      locationState: locationState ?? this.locationState,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      draftVenueName: draftVenueName ?? this.draftVenueName,
      draftAddress: draftAddress ?? this.draftAddress,
      draftUrbanReference: draftUrbanReference ?? this.draftUrbanReference,
      lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VenuesCatalogState) return false;
    if (other.selectedVenueId != selectedVenueId ||
        other.searchQuery != searchQuery ||
        other.surfaceFilter != surfaceFilter ||
        other.onlyWithLighting != onlyWithLighting ||
        other.sortByProximity != sortByProximity ||
        other.locationState != locationState ||
        other.isSubmitting != isSubmitting ||
        other.draftVenueName != draftVenueName ||
        other.draftAddress != draftAddress ||
        other.draftUrbanReference != draftUrbanReference ||
        other.lastFailure != lastFailure ||
        other.venues.length != venues.length) {
      return false;
    }
    for (int i = 0; i < venues.length; i++) {
      if (venues[i] != other.venues[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    viewState,
    Object.hashAll(venues),
    selectedVenueId,
    searchQuery,
    surfaceFilter,
    onlyWithLighting,
    sortByProximity,
    locationState,
    isSubmitting,
    draftVenueName,
    draftAddress,
    draftUrbanReference,
    lastFailure,
  );
}
