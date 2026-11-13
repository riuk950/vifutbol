import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/venues_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';

/// Remote data source contract for `sports_venues` and `venue_pitches`.
abstract interface class VenuesRemoteDataSource {
  Future<List<SportsVenue>> fetchAll();
  Future<void> upsert(SportsVenue venue, {String? organizerId});
}

/// PostgREST implementation targeting `vifutboldev.sports_venues` & `venue_pitches`.
class PostgrestVenuesRemoteDataSource implements VenuesRemoteDataSource {
  PostgrestVenuesRemoteDataSource({required this.client, required this.schema});

  final SupabaseClient client;
  final String schema;

  static String _toDbSurface(PitchSurfaceType type) => switch (type) {
    PitchSurfaceType.naturalGrass => 'naturalGrass',
    PitchSurfaceType.syntheticGrass => 'syntheticGrass',
    PitchSurfaceType.dirtOrSand => 'dirt',
    PitchSurfaceType.hardCourt => 'indoorCourt',
  };

  static PitchSurfaceType _fromDbSurface(String value) => switch (value) {
    'naturalGrass' => PitchSurfaceType.naturalGrass,
    'syntheticGrass' || 'hybrid' => PitchSurfaceType.syntheticGrass,
    'dirt' => PitchSurfaceType.dirtOrSand,
    'indoorCourt' => PitchSurfaceType.hardCourt,
    _ => PitchSurfaceType.syntheticGrass,
  };

  static String _toDbFormat(PitchFormat format) => switch (format) {
    PitchFormat.football11 => 'football11',
    PitchFormat.football8 => 'football9',
    PitchFormat.football7 => 'football7',
    PitchFormat.football5 => 'football5',
  };

  static PitchFormat _fromDbFormat(String value) => switch (value) {
    'football11' => PitchFormat.football11,
    'football9' => PitchFormat.football8,
    'football7' => PitchFormat.football7,
    'football5' => PitchFormat.football5,
    _ => PitchFormat.football7,
  };

  @override
  Future<List<SportsVenue>> fetchAll() async {
    final rows = await client
        .schema(schema)
        .from('sports_venues')
        .select('*, venue_pitches(*)')
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<void> upsert(SportsVenue venue, {String? organizerId}) async {
    final nowIso = venue.updatedAt.toUtc().toIso8601String();
    final venueId = HybridRepositorySupport.ensureUuid(venue.id, 'venue');
    await client.schema(schema).from('sports_venues').upsert({
      'id': venueId,
      if (organizerId != null)
        'organizer_id': HybridRepositorySupport.uuidOrNull(organizerId),
      'name': venue.name,
      'address': venue.address,
      'urban_reference': venue.urbanReference,
      'latitude': venue.coordinate.latitude,
      'longitude': venue.coordinate.longitude,
      'status': venue.status.name,
      'updated_at': nowIso,
    }, onConflict: 'id');

    if (venue.pitches.isNotEmpty) {
      final pitchRows = venue.pitches
          .map(
            (p) => <String, dynamic>{
              'id': HybridRepositorySupport.ensureUuid(p.id, 'pitch'),
              'venue_id': venueId,
              'name': p.name,
              'surface_type': _toDbSurface(p.surfaceType),
              'format': _toDbFormat(p.format),
              'capacity': p.capacity,
              'has_lighting': p.hasLighting,
              'status': p.status.name,
              'updated_at': nowIso,
            },
          )
          .toList();
      await client
          .schema(schema)
          .from('venue_pitches')
          .upsert(pitchRows, onConflict: 'id');
    }
  }

  SportsVenue _fromRow(Map<String, dynamic> row) {
    final rawPitches = (row['venue_pitches'] as List<dynamic>?) ?? const [];
    final pitches = rawPitches
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .map(
          (p) => VenuePitch(
            id: p['id'] as String,
            name: p['name'] as String,
            surfaceType: _fromDbSurface(p['surface_type'] as String? ?? ''),
            format: _fromDbFormat(p['format'] as String? ?? ''),
            capacity: (p['capacity'] as num?)?.toInt() ?? 0,
            hasLighting: p['has_lighting'] as bool? ?? false,
            status: VenueOperationalStatus.fromJson(
              p['status'] as String? ?? 'active',
            ),
          ),
        )
        .toList();

    return SportsVenue(
      id: row['id'] as String,
      name: row['name'] as String,
      address: row['address'] as String,
      urbanReference: row['urban_reference'] as String? ?? '',
      coordinate: GeoCoordinate(
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
      ),
      pitches: pitches.isEmpty
          ? [
              VenuePitch(
                id: '${row['id']}-default',
                name: 'Cancha Principal',
                surfaceType: PitchSurfaceType.syntheticGrass,
                format: PitchFormat.football7,
                capacity: 0,
                hasLighting: false,
                status: VenueOperationalStatus.active,
              ),
            ]
          : pitches,
      status: VenueOperationalStatus.fromJson(
        row['status'] as String? ?? 'active',
      ),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

/// Offline-first hybrid [VenuesRepository] coordinating local cache, Supabase, and FIFO outbox.
class HybridVenuesRepository implements VenuesRepository {
  HybridVenuesRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalVenuesRepository local;
  final VenuesRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<SportsVenue>> loadVenues() {
    return support.executeRead(
      remoteFetch: remote.fetchAll,
      cacheUpdate: local.replaceAllCache,
      localFallback: local.loadVenues,
    );
  }

  @override
  Future<void> saveVenue(SportsVenue venue) {
    return support.executeMutation(
      localWrite: () => local.saveVenue(venue),
      remoteWrite: () => remote.upsert(venue),
      entityType: SyncOutboxEntityType.venue,
      entityId: venue.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'venue': venue.toJson()},
      displayTitle: venue.name,
    );
  }

  @override
  Future<void> updateVenueStatus({
    required String venueId,
    required VenueOperationalStatus status,
  }) async {
    final venues = await local.loadVenues();
    final idx = venues.indexWhere((v) => v.id == venueId);
    if (idx < 0) {
      await local.updateVenueStatus(venueId: venueId, status: status);
      return;
    }
    final updatedVenue = venues[idx].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await saveVenue(updatedVenue);
  }

  @override
  Future<void> updatePitchStatus({
    required String venueId,
    required String pitchId,
    required VenueOperationalStatus status,
  }) async {
    final venues = await local.loadVenues();
    final idx = venues.indexWhere((v) => v.id == venueId);
    if (idx < 0) {
      await local.updatePitchStatus(
        venueId: venueId,
        pitchId: pitchId,
        status: status,
      );
      return;
    }
    final target = venues[idx];
    final updatedPitches = target.pitches
        .map((p) => p.id == pitchId ? p.copyWith(status: status) : p)
        .toList();
    final updatedVenue = target.copyWith(
      pitches: updatedPitches,
      updatedAt: DateTime.now(),
    );
    await saveVenue(updatedVenue);
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    final raw = item.payloadJson['venue'];
    if (raw is Map) {
      final venue = SportsVenue.fromJson(Map<String, dynamic>.from(raw));
      await remote.upsert(venue);
    }
  }

  @override
  Future<List<SportsVenue>> restoreSeedCatalogIfEmpty() =>
      local.restoreSeedCatalogIfEmpty();
}
