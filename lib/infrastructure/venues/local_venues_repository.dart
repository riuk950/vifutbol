import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';

/// Local repository persisting venues to [LocalStorageRepository] with environment
/// namespace isolation and 3 realistic urban seed venues preloaded in development.
class LocalVenuesRepository implements VenuesRepository {
  LocalVenuesRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String storageKey = 'venues_catalog';

  @override
  Future<List<SportsVenue>> loadVenues() async {
    final raw = await storage.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      if (config.environment == AppEnvironment.development) {
        return restoreSeedCatalogIfEmpty();
      }
      return <SportsVenue>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SportsVenue.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (config.environment == AppEnvironment.development) {
        return restoreSeedCatalogIfEmpty();
      }
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
    final seedVenues = _buildSeedVenues();
    await _persistVenues(seedVenues);
    return seedVenues;
  }

  Future<void> _persistVenues(List<SportsVenue> venues) async {
    final jsonList = venues.map((v) => v.toJson()).toList();
    await storage.writeString(storageKey, jsonEncode(jsonList));
  }

  List<SportsVenue> _buildSeedVenues() {
    final now = DateTime(2026, 11, 3, 10, 0);

    return [
      SportsVenue(
        id: 'venue-seed-salitre',
        name: 'Complejo Deportivo El Salitre',
        address: 'Calle 63 # 68-45',
        urbanReference:
            'Costado oriental del Parque Simón Bolívar, entrada por puerta 4',
        coordinate: const GeoCoordinate(latitude: 4.6584, longitude: -74.0938),
        pitches: const [
          VenuePitch(
            id: 'pitch-salitre-1',
            name: 'Cancha Sintética Principal',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football11,
            capacity: 800,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
          VenuePitch(
            id: 'pitch-salitre-2',
            name: 'Cancha Sintética Norte',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 150,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
          VenuePitch(
            id: 'pitch-salitre-3',
            name: 'Cancha Futsal 1',
            surfaceType: PitchSurfaceType.hardCourt,
            format: PitchFormat.football5,
            capacity: 200,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      ),
      SportsVenue(
        id: 'venue-seed-candelaria',
        name: 'Centro Deportivo La Candelaria',
        address: 'Carrera 3 # 12-40',
        urbanReference: 'Frente a la plazoleta del Chorro de Quevedo',
        coordinate: const GeoCoordinate(latitude: 4.5975, longitude: -74.0705),
        pitches: const [
          VenuePitch(
            id: 'pitch-candelaria-1',
            name: 'Cancha Los Comuneros',
            surfaceType: PitchSurfaceType.naturalGrass,
            format: PitchFormat.football8,
            capacity: 250,
            hasLighting: false,
            status: VenueOperationalStatus.active,
          ),
          VenuePitch(
            id: 'pitch-candelaria-2',
            name: 'Cancha Colonial Futsal',
            surfaceType: PitchSurfaceType.hardCourt,
            format: PitchFormat.football5,
            capacity: 100,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      ),
      SportsVenue(
        id: 'venue-seed-norte',
        name: 'Polideportivo Metropolitano Norte',
        address: 'Autopista Norte # 175-10',
        urbanReference: 'Estación Portal Norte, costado occidental',
        coordinate: const GeoCoordinate(latitude: 4.7550, longitude: -74.0450),
        pitches: const [
          VenuePitch(
            id: 'pitch-norte-1',
            name: 'Cancha Césped Sintético 1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football11,
            capacity: 600,
            hasLighting: true,
            status: VenueOperationalStatus.active,
          ),
          VenuePitch(
            id: 'pitch-norte-2',
            name: 'Cancha Formativa Tierra',
            surfaceType: PitchSurfaceType.dirtOrSand,
            format: PitchFormat.football7,
            capacity: 80,
            hasLighting: false,
            status: VenueOperationalStatus.maintenance,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: now,
      ),
    ];
  }
}
