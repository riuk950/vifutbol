import 'geo_coordinate.dart';
import 'venue_enums.dart';
import 'venue_pitch.dart';

/// Represents a sports complex or venue containing one or more internal pitches.
class SportsVenue {
  const SportsVenue({
    required this.id,
    required this.name,
    required this.address,
    required this.urbanReference,
    required this.coordinate,
    required this.pitches,
    required this.status,
    required this.updatedAt,
  }) : assert(name.length >= 3, 'Venue name must have at least 3 characters'),
       assert(
         address.length >= 5,
         'Venue address must have at least 5 characters',
       ),
       assert(
         pitches.length >= 1,
         'Venue must have at least one internal pitch',
       );

  final String id;
  final String name;
  final String address;
  final String urbanReference;
  final GeoCoordinate coordinate;
  final List<VenuePitch> pitches;
  final VenueOperationalStatus status;
  final DateTime updatedAt;

  /// Number of internal pitches currently active.
  int get activePitchesCount => pitches
      .where((pitch) => pitch.status == VenueOperationalStatus.active)
      .length;

  /// Whether the venue can be assigned to new fixtures in tournament schedules.
  bool get isEligibleForFixtures =>
      status == VenueOperationalStatus.active && activePitchesCount > 0;

  /// Whether at least one internal pitch has night lighting.
  bool get hasNightLighting => pitches.any((pitch) => pitch.hasLighting);

  /// Unique playing surfaces available across all pitches of this venue.
  Set<PitchSurfaceType> get surfaces =>
      pitches.map((pitch) => pitch.surfaceType).toSet();

  bool get isActive => status == VenueOperationalStatus.active;

  SportsVenue copyWith({
    String? id,
    String? name,
    String? address,
    String? urbanReference,
    GeoCoordinate? coordinate,
    List<VenuePitch>? pitches,
    VenueOperationalStatus? status,
    DateTime? updatedAt,
  }) {
    return SportsVenue(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      urbanReference: urbanReference ?? this.urbanReference,
      coordinate: coordinate ?? this.coordinate,
      pitches: pitches ?? this.pitches,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'urbanReference': urbanReference,
      'coordinate': coordinate.toJson(),
      'pitches': pitches.map((pitch) => pitch.toJson()).toList(),
      'status': status.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SportsVenue.fromJson(Map<String, dynamic> json) {
    return SportsVenue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      urbanReference: json['urbanReference'] as String? ?? '',
      coordinate: GeoCoordinate.fromJson(
        json['coordinate'] as Map<String, dynamic>,
      ),
      pitches: (json['pitches'] as List<dynamic>)
          .map((item) => VenuePitch.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: VenueOperationalStatus.fromJson(json['status'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SportsVenue) return false;
    if (other.id != id ||
        other.name != name ||
        other.address != address ||
        other.urbanReference != urbanReference ||
        other.coordinate != coordinate ||
        other.status != status ||
        other.updatedAt.millisecondsSinceEpoch !=
            updatedAt.millisecondsSinceEpoch ||
        other.pitches.length != pitches.length) {
      return false;
    }
    for (int i = 0; i < pitches.length; i++) {
      if (pitches[i] != other.pitches[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    urbanReference,
    coordinate,
    status,
    updatedAt.millisecondsSinceEpoch,
    Object.hashAll(pitches),
  );

  @override
  String toString() {
    return 'SportsVenue(id: $id, name: $name, address: $address, urbanReference: $urbanReference, coordinate: $coordinate, pitchesCount: ${pitches.length}, status: $status, updatedAt: $updatedAt)';
  }
}
