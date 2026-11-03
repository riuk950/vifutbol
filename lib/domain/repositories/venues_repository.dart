import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';

/// Contract for venues and sports pitches persistence, offline retrieval and logical status updates.
abstract class VenuesRepository {
  /// Loads all stored venues for the active environment.
  Future<List<SportsVenue>> loadVenues();

  /// Saves a new or updated sports venue.
  Future<void> saveVenue(SportsVenue venue);

  /// Updates the logical operational status of a venue.
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  });

  /// Updates the logical operational status of an internal pitch within a venue.
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  });

  /// Restores the default 3 realistic urban seed venues in development if the catalog is empty.
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty();
}
