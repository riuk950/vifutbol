// lib/domain/entities/colombia_location_catalog.dart

import 'package:vifutbol/domain/data/colombia_municipalities_data.dart';

/// Service providing access, cascading lookups, and accent-insensitive search
/// over all 32 departments of Colombia, Bogotá D.C., and their official municipalities.
abstract final class ColombiaLocationCatalog {
  /// Unmodifiable sorted list of all 33 Colombian territorial entities
  /// (32 departments + 'Bogotá, D.C.').
  static final List<String> departments = List.unmodifiable(
    kColombiaMunicipalitiesByDepartment.keys.toList()..sort(),
  );

  /// Returns an unmodifiable sorted list of municipalities for [department].
  ///
  /// Returns an empty unmodifiable list if the department is not recognized.
  static List<String> municipalitiesFor(String department) {
    final list = kColombiaMunicipalitiesByDepartment[department];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  /// Searches departments with case-insensitive and accent-insensitive matching.
  static List<String> searchDepartments(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return departments;

    return departments
        .where((dep) => _normalize(dep).contains(normalizedQuery))
        .toList(growable: false);
  }

  /// Searches municipalities within [department] with case-insensitive and
  /// accent-insensitive matching.
  static List<String> searchMunicipalities(String department, String query) {
    final list = municipalitiesFor(department);
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return list;

    return list
        .where((mun) => _normalize(mun).contains(normalizedQuery))
        .toList(growable: false);
  }

  /// Validates whether [municipality] is a registered official municipality
  /// within [department].
  static bool isValidPair(String? department, String? municipality) {
    if (department == null || municipality == null) return false;
    final list = kColombiaMunicipalitiesByDepartment[department];
    if (list == null) return false;
    return list.contains(municipality);
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}
