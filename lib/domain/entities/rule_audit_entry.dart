/// Immutable audit log entry recorded when critical tournament rules (format or
/// scoring points) are altered while the championship is [TournamentStatus.inProgress].
class RuleAuditEntry {
  const RuleAuditEntry({
    required this.recordedAt,
    required this.summary,
    required this.reason,
    this.recalculationConfirmed = true,
  });

  final DateTime recordedAt;
  final String summary;
  final String reason;
  final bool recalculationConfirmed;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordedAt': recordedAt.toIso8601String(),
      'summary': summary,
      'reason': reason,
      'recalculationConfirmed': recalculationConfirmed,
    };
  }

  factory RuleAuditEntry.fromJson(Map<String, dynamic> json) {
    return RuleAuditEntry(
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      summary: (json['summary'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
      recalculationConfirmed: json['recalculationConfirmed'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuleAuditEntry &&
        other.recordedAt == recordedAt &&
        other.summary == summary &&
        other.reason == reason &&
        other.recalculationConfirmed == recalculationConfirmed;
  }

  @override
  int get hashCode =>
      Object.hash(recordedAt, summary, reason, recalculationConfirmed);
}
