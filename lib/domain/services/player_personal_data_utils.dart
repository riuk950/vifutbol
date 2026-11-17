// lib/domain/services/player_personal_data_utils.dart

import 'package:vifutbol/domain/entities/detailed_football_position.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';

/// Pure domain utilities for player personal data computations,
/// name harmonization, age calculation, and tactical line derivation.
abstract final class PlayerPersonalDataUtils {
  /// Calculates completed years of age based on [birthDate].
  ///
  /// If [referenceDate] is provided, uses it as the anchor date (useful for deterministic tests).
  /// Respects birthday boundaries (day and month) and clamps negative results to 0.
  static int calculateAge(DateTime birthDate, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    var age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age < 0 ? 0 : age;
  }

  /// Harmonizes discrete name components into a single clean full name string.
  ///
  /// Trims whitespace, ignores empty optionals, and prevents double spaces.
  static String composeFullName({
    required String firstName,
    String? secondName,
    required String firstSurname,
    String? secondSurname,
  }) {
    final parts = <String>[];

    final cleanFirst = firstName.trim();
    if (cleanFirst.isNotEmpty) {
      parts.add(cleanFirst);
    }

    final cleanSecond = secondName?.trim() ?? '';
    if (cleanSecond.isNotEmpty) {
      parts.add(cleanSecond);
    }

    final cleanFirstSurname = firstSurname.trim();
    if (cleanFirstSurname.isNotEmpty) {
      parts.add(cleanFirstSurname);
    }

    final cleanSecondSurname = secondSurname?.trim() ?? '';
    if (cleanSecondSurname.isNotEmpty) {
      parts.add(cleanSecondSurname);
    }

    return parts.join(' ');
  }

  /// Deterministically derives the macro tactical [PlayerPosition] line
  /// from the selected [DetailedFootballPosition] demarcations.
  ///
  /// Defaults to [PlayerPosition.midfielder] if the positions list is empty.
  static PlayerPosition derivePrimaryPosition(
    List<DetailedFootballPosition> positions,
  ) {
    if (positions.isEmpty) {
      return PlayerPosition.midfielder;
    }
    return positions.first.tacticalLine;
  }
}
