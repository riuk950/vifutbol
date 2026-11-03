import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';

/// Helper data holder combining a venue with its computed distance (if location is available).
class VenueWithDistance {
  const VenueWithDistance({required this.venue, this.distanceInKm});

  final SportsVenue venue;
  final double? distanceInKm;

  /// Returns the formatted distance with 1 decimal place (e.g. "2.4").
  String? get formattedDistance {
    if (distanceInKm == null) return null;
    return distanceInKm!.toStringAsFixed(1);
  }
}

/// Use case for filtering and sorting sports venues by search query, surface,
/// night lighting, and geographical proximity.
class QueryVenuesGeolocationUseCase {
  const QueryVenuesGeolocationUseCase();

  /// Applies filters and proximity sorting to the [venues] catalog.
  List<VenueWithDistance> execute({
    required List<SportsVenue> venues,
    String searchQuery = '',
    PitchSurfaceType? surfaceFilter,
    bool onlyWithLighting = false,
    bool sortByProximity = false,
    GeoCoordinate? userCoordinate,
  }) {
    final String query = searchQuery.trim().toLowerCase();

    // 1. Filter venues
    final filtered = venues.where((venue) {
      if (query.isNotEmpty) {
        final matchesName = venue.name.toLowerCase().contains(query);
        final matchesAddress = venue.address.toLowerCase().contains(query);
        final matchesRef = venue.urbanReference.toLowerCase().contains(query);
        if (!matchesName && !matchesAddress && !matchesRef) {
          return false;
        }
      }

      if (surfaceFilter != null) {
        if (!venue.surfaces.contains(surfaceFilter)) {
          return false;
        }
      }

      if (onlyWithLighting) {
        if (!venue.hasNightLighting) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2. Map with distances
    final withDistances = filtered.map((venue) {
      final double? distance = userCoordinate?.distanceInKilometersTo(
        venue.coordinate,
      );
      return VenueWithDistance(venue: venue, distanceInKm: distance);
    }).toList();

    // 3. Sort by proximity if requested and user location is available
    if (sortByProximity && userCoordinate != null) {
      withDistances.sort((a, b) {
        final distA = a.distanceInKm ?? double.infinity;
        final distB = b.distanceInKm ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return withDistances;
  }
}
