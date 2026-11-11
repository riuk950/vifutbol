import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

/// Use case that orchestrates sports venue and internal pitch creation, editing,
/// and logical operational status toggling.
class ManageVenuesUseCase {
  const ManageVenuesUseCase(this._venuesRepository);

  final VenuesRepository _venuesRepository;

  /// Validates and saves a sports venue with its internal pitches.
  ///
  /// Throws [InvalidVenueDataFailure] if any validation constraint is violated.
  Future<void> saveVenue(SportsVenue venue) async {
    final String trimmedName = venue.name.trim();
    if (trimmedName.length < 3) {
      throw const InvalidVenueDataFailure(
        'El nombre debe tener al menos 3 caracteres',
      );
    }

    final existingVenues = await _venuesRepository.loadVenues();
    final isDuplicate = existingVenues.any(
      (v) =>
          v.id != venue.id &&
          v.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    );
    if (isDuplicate) {
      throw const InvalidVenueDataFailure(
        'Ya existe una sede con este nombre. Selecciónala de la lista o elige otro nombre.',
      );
    }

    final String trimmedAddress = venue.address.trim();
    if (trimmedAddress.length < 5) {
      throw const InvalidVenueDataFailure(
        'La dirección debe tener al menos 5 caracteres',
      );
    }

    if (!GeoCoordinate.isValidCoordinate(
      venue.coordinate.latitude,
      venue.coordinate.longitude,
    )) {
      throw const InvalidVenueDataFailure(
        'Coordenadas geográficas fuera de rango',
      );
    }

    if (venue.pitches.isEmpty || venue.activePitchesCount < 1) {
      throw const InvalidVenueDataFailure(
        'Debes agregar al menos 1 cancha interna activa',
      );
    }

    for (final pitch in venue.pitches) {
      if (pitch.name.trim().length < 2) {
        throw const InvalidVenueDataFailure(
          'El nombre de la cancha debe tener al menos 2 caracteres',
        );
      }
      if (pitch.capacity < 0) {
        throw const InvalidVenueDataFailure(
          'La capacidad de la cancha no puede ser negativa',
        );
      }
    }

    await _venuesRepository.saveVenue(venue);
  }

  /// Updates the logical operational status of an entire venue (active <-> maintenance).
  Future<void> setVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {
    await _venuesRepository.updateVenueStatus(venueId: venueId, status: status);
  }

  /// Updates the logical operational status of a specific internal pitch (active <-> maintenance).
  Future<void> setPitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {
    await _venuesRepository.updatePitchStatus(
      venueId: venueId,
      pitchId: pitchId,
      status: status,
    );
  }
}
