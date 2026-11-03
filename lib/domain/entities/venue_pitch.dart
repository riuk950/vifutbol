import 'venue_enums.dart';

/// Represents an individual pitch within a sports complex or venue.
class VenuePitch {
  const VenuePitch({
    required this.id,
    required this.name,
    required this.surfaceType,
    required this.format,
    required this.capacity,
    required this.hasLighting,
    required this.status,
  }) : assert(name.length >= 2, 'Pitch name must have at least 2 characters'),
       assert(capacity >= 0, 'Capacity cannot be negative');

  final String id;
  final String name;
  final PitchSurfaceType surfaceType;
  final PitchFormat format;
  final int capacity;
  final bool hasLighting;
  final VenueOperationalStatus status;

  bool get isActive => status == VenueOperationalStatus.active;

  VenuePitch copyWith({
    String? id,
    String? name,
    PitchSurfaceType? surfaceType,
    PitchFormat? format,
    int? capacity,
    bool? hasLighting,
    VenueOperationalStatus? status,
  }) {
    return VenuePitch(
      id: id ?? this.id,
      name: name ?? this.name,
      surfaceType: surfaceType ?? this.surfaceType,
      format: format ?? this.format,
      capacity: capacity ?? this.capacity,
      hasLighting: hasLighting ?? this.hasLighting,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surfaceType': surfaceType.toJson(),
      'format': format.toJson(),
      'capacity': capacity,
      'hasLighting': hasLighting,
      'status': status.toJson(),
    };
  }

  factory VenuePitch.fromJson(Map<String, dynamic> json) {
    return VenuePitch(
      id: json['id'] as String,
      name: json['name'] as String,
      surfaceType: PitchSurfaceType.fromJson(json['surfaceType'] as String),
      format: PitchFormat.fromJson(json['format'] as String),
      capacity: json['capacity'] as int,
      hasLighting: json['hasLighting'] as bool,
      status: VenueOperationalStatus.fromJson(json['status'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenuePitch &&
        other.id == id &&
        other.name == name &&
        other.surfaceType == surfaceType &&
        other.format == format &&
        other.capacity == capacity &&
        other.hasLighting == hasLighting &&
        other.status == status;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, surfaceType, format, capacity, hasLighting, status);

  @override
  String toString() {
    return 'VenuePitch(id: $id, name: $name, surfaceType: $surfaceType, format: $format, capacity: $capacity, hasLighting: $hasLighting, status: $status)';
  }
}
