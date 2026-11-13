import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

/// Local repository persisting venues to [LocalStorageRepository] with environment
/// namespace isolation.
class LocalVenuesRepository implements VenuesRepository {
  LocalVenuesRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String storageKey = 'venues_catalog';

  @override
  Future<List<SportsVenue>> loadVenues() async {
    final raw = await storage.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <SportsVenue>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SportsVenue.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <SportsVenue>[];
    }
  }

  @override
  Future<void> saveVenue(SportsVenue venue) async {
    final venues = await loadVenues();
    final updatedList = List<SportsVenue>.from(venues);

    final index = updatedList.indexWhere((v) => v.id == venue.id);
    if (index >= 0) {
      updatedList[index] = venue;
    } else {
      updatedList.add(venue);
    }

    await _persistVenues(updatedList);
  }

  @override
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {
    final venues = await loadVenues();
    final updatedList = venues.map((venue) {
      if (venue.id == venueId) {
        return venue.copyWith(status: status, updatedAt: DateTime.now());
      }
      return venue;
    }).toList();

    await _persistVenues(updatedList);
  }

  @override
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {
    final venues = await loadVenues();
    final updatedList = venues.map((venue) {
      if (venue.id == venueId) {
        final updatedPitches = venue.pitches.map((pitch) {
          if (pitch.id == pitchId) {
            return pitch.copyWith(status: status);
          }
          return pitch;
        }).toList();

        return venue.copyWith(
          pitches: updatedPitches,
          updatedAt: DateTime.now(),
        );
      }
      return venue;
    }).toList();

    await _persistVenues(updatedList);
  }

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() async {
    return <SportsVenue>[];
  }

  /// Replaces the local venues cache with fresh remote data.
  Future<void> replaceAllCache(List<SportsVenue> venues) {
    return _persistVenues(venues);
  }

  Future<void> _persistVenues(List<SportsVenue> venues) async {
    final jsonList = venues.map((v) => v.toJson()).toList();
    await storage.writeString(storageKey, jsonEncode(jsonList));
  }
}
