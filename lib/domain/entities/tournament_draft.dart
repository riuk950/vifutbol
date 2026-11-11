import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';

bool _sameStringList(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Local draft value object preserved when the organizer exits the creation
/// wizard or when the mobile application moves to the background.
class TournamentDraft {
  const TournamentDraft({
    required this.name,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.format = TournamentFormat.league,
    this.rules = const TournamentRulesConfig(),
    required this.savedAt,
    this.venueIds = const <String>[],
  });

  final String name;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final TournamentRulesConfig rules;
  final DateTime savedAt;
  final List<String> venueIds;

  TournamentDraft copyWith({
    String? name,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    TournamentFormat? format,
    TournamentRulesConfig? rules,
    DateTime? savedAt,
    List<String>? venueIds,
  }) {
    return TournamentDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
      rules: rules ?? this.rules,
      savedAt: savedAt ?? this.savedAt,
      venueIds: venueIds ?? this.venueIds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'format': format.name,
      'rules': rules.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'venueIds': venueIds,
    };
  }

  factory TournamentDraft.fromJson(Map<String, dynamic> json) {
    final formatName = json['format'] as String?;
    final rawVenues = json['venueIds'] as List<dynamic>? ?? const <dynamic>[];
    return TournamentDraft(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime(2026, 6, 1),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ??
          DateTime(2026, 8, 30),
      format: TournamentFormat.values.firstWhere(
        (f) => f.name == formatName,
        orElse: () => TournamentFormat.league,
      ),
      rules: json['rules'] is Map<String, dynamic>
          ? TournamentRulesConfig.fromJson(
              json['rules'] as Map<String, dynamic>,
            )
          : const TournamentRulesConfig(),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime(2026, 6, 1),
      venueIds: rawVenues.map((e) => e.toString()).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentDraft &&
        other.name == name &&
        other.category == category &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.format == format &&
        other.rules == rules &&
        other.savedAt == savedAt &&
        _sameStringList(other.venueIds, venueIds);
  }

  @override
  int get hashCode => Object.hash(
    name,
    category,
    startDate,
    endDate,
    format,
    rules,
    savedAt,
    Object.hashAll(venueIds),
  );
}
