import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';

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
  });

  final String name;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final TournamentRulesConfig rules;
  final DateTime savedAt;

  TournamentDraft copyWith({
    String? name,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    TournamentFormat? format,
    TournamentRulesConfig? rules,
    DateTime? savedAt,
  }) {
    return TournamentDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
      rules: rules ?? this.rules,
      savedAt: savedAt ?? this.savedAt,
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
    };
  }

  factory TournamentDraft.fromJson(Map<String, dynamic> json) {
    final formatName = json['format'] as String?;
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
        other.savedAt == savedAt;
  }

  @override
  int get hashCode =>
      Object.hash(name, category, startDate, endDate, format, rules, savedAt);
}
