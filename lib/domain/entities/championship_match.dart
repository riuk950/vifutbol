import 'match_enums.dart';

class ChampionshipMatch {
  ChampionshipMatch({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.roundName,
    required this.homeTeamId,
    required this.awayTeamId,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.venueId,
    this.pitchId,
    this.pitchName,
    this.refereeId,
    this.refereeName,
    this.status = MatchStatus.pendingSchedule,
    this.homeScore,
    this.awayScore,
    DateTime? updatedAt,
  }) : assert(id.isNotEmpty, 'Match id cannot be empty'),
       assert(tournamentId.isNotEmpty, 'Tournament id cannot be empty'),
       assert(roundNumber >= 1, 'roundNumber must be >= 1'),
       assert(roundName.isNotEmpty, 'roundName cannot be empty'),
       assert(homeTeamId.isNotEmpty, 'homeTeamId cannot be empty'),
       assert(awayTeamId.isNotEmpty, 'awayTeamId cannot be empty'),
       assert(
         homeTeamId != awayTeamId,
         'homeTeamId and awayTeamId must be different',
       ),
       assert(homeScore == null || homeScore >= 0, 'homeScore must be >= 0'),
       assert(awayScore == null || awayScore >= 0, 'awayScore must be >= 0'),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String tournamentId;
  final int roundNumber;
  final String roundName;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final String? venueId;
  final String? pitchId;
  final String? pitchName;
  final String? refereeId;
  final String? refereeName;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final DateTime updatedAt;

  bool get isScheduled =>
      status == MatchStatus.scheduled &&
      scheduledStartTime != null &&
      scheduledEndTime != null;

  /// Checks if this match's scheduled window overlaps with [candidateStart, candidateEnd].
  /// Overlap exists if max(start1, start2) < min(end1, end2).
  bool overlapsWith(DateTime candidateStart, DateTime candidateEnd) {
    if (scheduledStartTime == null || scheduledEndTime == null) {
      return false;
    }
    final latestStart = scheduledStartTime!.isAfter(candidateStart)
        ? scheduledStartTime!
        : candidateStart;
    final earliestEnd = scheduledEndTime!.isBefore(candidateEnd)
        ? scheduledEndTime!
        : candidateEnd;
    return latestStart.isBefore(earliestEnd);
  }

  ChampionshipMatch copyWith({
    String? id,
    String? tournamentId,
    int? roundNumber,
    String? roundName,
    String? homeTeamId,
    String? awayTeamId,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? venueId,
    String? pitchId,
    String? pitchName,
    String? refereeId,
    String? refereeName,
    MatchStatus? status,
    int? homeScore,
    bool clearHomeScore = false,
    int? awayScore,
    bool clearAwayScore = false,
    DateTime? updatedAt,
  }) {
    return ChampionshipMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundNumber: roundNumber ?? this.roundNumber,
      roundName: roundName ?? this.roundName,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      venueId: venueId ?? this.venueId,
      pitchId: pitchId ?? this.pitchId,
      pitchName: pitchName ?? this.pitchName,
      refereeId: refereeId ?? this.refereeId,
      refereeName: refereeName ?? this.refereeName,
      status: status ?? this.status,
      homeScore: clearHomeScore ? null : (homeScore ?? this.homeScore),
      awayScore: clearAwayScore ? null : (awayScore ?? this.awayScore),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'roundNumber': roundNumber,
      'roundName': roundName,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'scheduledEndTime': scheduledEndTime?.toIso8601String(),
      'venueId': venueId,
      'pitchId': pitchId,
      'pitchName': pitchName,
      'refereeId': refereeId,
      'refereeName': refereeName,
      'status': status.name,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChampionshipMatch.fromJson(Map<String, dynamic> json) {
    return ChampionshipMatch(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      roundNumber: json['roundNumber'] as int? ?? 1,
      roundName: json['roundName'] as String? ?? '',
      homeTeamId: json['homeTeamId'] as String? ?? '',
      awayTeamId: json['awayTeamId'] as String? ?? '',
      scheduledStartTime: json['scheduledStartTime'] != null
          ? DateTime.tryParse(json['scheduledStartTime'] as String)
          : null,
      scheduledEndTime: json['scheduledEndTime'] != null
          ? DateTime.tryParse(json['scheduledEndTime'] as String)
          : null,
      venueId: json['venueId'] as String?,
      pitchId: json['pitchId'] as String?,
      pitchName: json['pitchName'] as String?,
      refereeId: json['refereeId'] as String?,
      refereeName: json['refereeName'] as String?,
      status: MatchStatus.fromCode(json['status'] as String?),
      homeScore: (json['homeScore'] as num?)?.toInt(),
      awayScore: (json['awayScore'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChampionshipMatch &&
        other.id == id &&
        other.tournamentId == tournamentId &&
        other.roundNumber == roundNumber &&
        other.roundName == roundName &&
        other.homeTeamId == homeTeamId &&
        other.awayTeamId == awayTeamId &&
        other.scheduledStartTime == scheduledStartTime &&
        other.scheduledEndTime == scheduledEndTime &&
        other.venueId == venueId &&
        other.pitchId == pitchId &&
        other.pitchName == pitchName &&
        other.refereeId == refereeId &&
        other.refereeName == refereeName &&
        other.status == status &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore;
  }

  @override
  int get hashCode => Object.hash(
    id,
    tournamentId,
    roundNumber,
    homeTeamId,
    awayTeamId,
    scheduledStartTime,
    scheduledEndTime,
    pitchId,
    refereeId,
    status,
    homeScore,
    awayScore,
  );
}
