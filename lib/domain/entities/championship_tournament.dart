import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';

bool _sameAuditList(List<RuleAuditEntry> a, List<RuleAuditEntry> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameStringList(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Aggregate root representing an official championship tournament and its
/// governing custom rules and audit trail.
class ChampionshipTournament {
  const ChampionshipTournament({
    required this.id,
    required this.name,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.format,
    this.status = TournamentStatus.openRegistration,
    this.rules = const TournamentRulesConfig(),
    this.auditTrail = const <RuleAuditEntry>[],
    required this.updatedAt,
    this.organizerId = 'org-seed-1',
    this.venueIds = const <String>[],
  });

  final String id;
  final String name;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final TournamentStatus status;
  final TournamentRulesConfig rules;
  final List<RuleAuditEntry> auditTrail;
  final DateTime updatedAt;
  final String? organizerId;
  final List<String> venueIds;

  /// Returns true if critical rules (format or scoring points) differ between this and [other].
  bool hasCriticalRulesChanged(ChampionshipTournament other) {
    return format != other.format || !rules.hasSameScoringPoints(other.rules);
  }

  ChampionshipTournament copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    TournamentFormat? format,
    TournamentStatus? status,
    TournamentRulesConfig? rules,
    List<RuleAuditEntry>? auditTrail,
    DateTime? updatedAt,
    String? organizerId,
    List<String>? venueIds,
  }) {
    return ChampionshipTournament(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      format: format ?? this.format,
      status: status ?? this.status,
      rules: rules ?? this.rules,
      auditTrail: auditTrail ?? this.auditTrail,
      updatedAt: updatedAt ?? this.updatedAt,
      organizerId: organizerId ?? this.organizerId,
      venueIds: venueIds ?? this.venueIds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'format': format.name,
      'status': status.name,
      'rules': rules.toJson(),
      'auditTrail': auditTrail.map((entry) => entry.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'organizerId': organizerId,
      'venueIds': venueIds,
    };
  }

  factory ChampionshipTournament.fromJson(Map<String, dynamic> json) {
    final formatName = json['format'] as String?;
    final statusName = json['status'] as String?;
    final rawAudit = json['auditTrail'] as List<dynamic>? ?? const <dynamic>[];
    final rawVenues = json['venueIds'] as List<dynamic>? ?? const <dynamic>[];

    return ChampionshipTournament(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ??
          DateTime(2026, 6, 30),
      format: TournamentFormat.values.firstWhere(
        (f) => f.name == formatName,
        orElse: () => TournamentFormat.league,
      ),
      status: TournamentStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => TournamentStatus.openRegistration,
      ),
      rules: json['rules'] is Map<String, dynamic>
          ? TournamentRulesConfig.fromJson(
              json['rules'] as Map<String, dynamic>,
            )
          : const TournamentRulesConfig(),
      auditTrail: rawAudit
          .whereType<Map<String, dynamic>>()
          .map(RuleAuditEntry.fromJson)
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      organizerId: json['organizerId'] as String? ?? 'org-seed-1',
      venueIds: rawVenues.map((e) => e.toString()).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChampionshipTournament &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.format == format &&
        other.status == status &&
        other.rules == rules &&
        _sameAuditList(other.auditTrail, auditTrail) &&
        other.updatedAt == updatedAt &&
        other.organizerId == organizerId &&
        _sameStringList(other.venueIds, venueIds);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    startDate,
    endDate,
    format,
    status,
    rules,
    Object.hashAll(auditTrail),
    updatedAt,
    organizerId,
    Object.hashAll(venueIds),
  );
}
