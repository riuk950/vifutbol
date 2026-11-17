// lib/domain/entities/player_personal_enums.dart

/// Represents the biological or legal sex of a player.
enum PlayerSex {
  male('male'),
  female('female'),
  other('other');

  const PlayerSex(this.value);

  /// Canonical database value ('male', 'female', 'other').
  final String value;

  /// Tolerantly parses a raw string input into a [PlayerSex].
  ///
  /// Supports aliases such as 'M', 'F', 'Masculino', 'Femenino', 'Otro'.
  static PlayerSex? fromRaw(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'male':
      case 'm':
      case 'masculino':
        return PlayerSex.male;
      case 'female':
      case 'f':
      case 'femenino':
        return PlayerSex.female;
      case 'other':
      case 'o':
      case 'otro':
        return PlayerSex.other;
      default:
        return null;
    }
  }
}

/// Represents the ABO and Rh blood group of a player.
enum BloodType {
  oPositive('O+'),
  oNegative('O-'),
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-');

  const BloodType(this.value);

  /// Canonical database and medical representation (e.g. 'O+', 'AB-').
  final String value;

  /// Pre-sorted unmodifiable list of all 8 standard blood group values.
  static const List<String> allValues = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];

  /// Tolerantly parses a raw string representation into a [BloodType].
  static BloodType? fromRaw(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    for (final type in BloodType.values) {
      if (type.value == normalized || type.name.toUpperCase() == normalized) {
        return type;
      }
    }
    return null;
  }
}
