import 'dart:math';
import 'match_event.dart';
import 'match_report_enums.dart';

/// Aggregates the official live state, timestamp-based clock, score, and events of a match.
class DigitalMatchReport {
  DigitalMatchReport({
    required this.matchId,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore = 0,
    this.awayScore = 0,
    this.homePenaltyScore,
    this.awayPenaltyScore,
    this.currentPeriod = MatchPeriod.notStarted,
    this.periodStartedAt,
    this.elapsedSecondsBeforeCurrentPeriod = 0,
    List<MatchEvent>? events,
    this.refereeObservations,
    this.closedAt,
    this.closedByUserId,
    DateTime? updatedAt,
  }) : assert(matchId.isNotEmpty, 'matchId cannot be empty'),
       assert(tournamentId.isNotEmpty, 'tournamentId cannot be empty'),
       assert(homeTeamId.isNotEmpty, 'homeTeamId cannot be empty'),
       assert(awayTeamId.isNotEmpty, 'awayTeamId cannot be empty'),
       assert(
         homeTeamId != awayTeamId,
         'homeTeamId and awayTeamId must be different',
       ),
       assert(homeScore >= 0, 'homeScore cannot be negative'),
       assert(awayScore >= 0, 'awayScore cannot be negative'),
       assert(
         homePenaltyScore == null || homePenaltyScore >= 0,
         'homePenaltyScore cannot be negative',
       ),
       assert(
         awayPenaltyScore == null || awayPenaltyScore >= 0,
         'awayPenaltyScore cannot be negative',
       ),
       assert(
         elapsedSecondsBeforeCurrentPeriod >= 0,
         'elapsedSecondsBeforeCurrentPeriod cannot be negative',
       ),
       events = List.unmodifiable(events ?? const <MatchEvent>[]),
       updatedAt = updatedAt ?? DateTime.now();

  final String matchId;
  final String tournamentId;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;
  final MatchPeriod currentPeriod;
  final DateTime? periodStartedAt;
  final int elapsedSecondsBeforeCurrentPeriod;
  final List<MatchEvent> events;
  final String? refereeObservations;
  final DateTime? closedAt;
  final String? closedByUserId;
  final DateTime updatedAt;

  bool get isClosed => currentPeriod == MatchPeriod.closed || closedAt != null;

  int totalElapsedSecondsAt(DateTime now) {
    if (currentPeriod.isRunning && periodStartedAt != null) {
      final runningDiff = max(0, now.difference(periodStartedAt!).inSeconds);
      return elapsedSecondsBeforeCurrentPeriod + runningDiff;
    }
    return elapsedSecondsBeforeCurrentPeriod;
  }

  int currentMatchMinuteAt(DateTime now) {
    final seconds = totalElapsedSecondsAt(now);
    return ((seconds ~/ 60) + 1).clamp(1, 130);
  }

  int yellowCardCountForPlayer(String playerId) {
    return events
        .where(
          (e) =>
              e.type == MatchEventType.yellowCard &&
              e.primaryPlayerId == playerId,
        )
        .length;
  }

  Set<String> get expelledPlayerIds {
    final result = <String>{};
    for (final event in events) {
      if ((event.type == MatchEventType.directRedCard ||
              event.type == MatchEventType.secondYellowRedCard) &&
          event.primaryPlayerId != null) {
        result.add(event.primaryPlayerId!);
      }
    }
    return result;
  }

  bool isPlayerExpelled(String playerId) =>
      expelledPlayerIds.contains(playerId);

  int get pendingSyncCount => events.where((e) => !e.isSynced).length;

  DigitalMatchReport copyWith({
    String? matchId,
    String? tournamentId,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    int? homePenaltyScore,
    bool clearHomePenaltyScore = false,
    int? awayPenaltyScore,
    bool clearAwayPenaltyScore = false,
    MatchPeriod? currentPeriod,
    DateTime? periodStartedAt,
    bool clearPeriodStartedAt = false,
    int? elapsedSecondsBeforeCurrentPeriod,
    List<MatchEvent>? events,
    String? refereeObservations,
    bool clearRefereeObservations = false,
    DateTime? closedAt,
    String? closedByUserId,
    DateTime? updatedAt,
  }) {
    return DigitalMatchReport(
      matchId: matchId ?? this.matchId,
      tournamentId: tournamentId ?? this.tournamentId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homePenaltyScore: clearHomePenaltyScore
          ? null
          : (homePenaltyScore ?? this.homePenaltyScore),
      awayPenaltyScore: clearAwayPenaltyScore
          ? null
          : (awayPenaltyScore ?? this.awayPenaltyScore),
      currentPeriod: currentPeriod ?? this.currentPeriod,
      periodStartedAt: clearPeriodStartedAt
          ? null
          : (periodStartedAt ?? this.periodStartedAt),
      elapsedSecondsBeforeCurrentPeriod:
          elapsedSecondsBeforeCurrentPeriod ??
          this.elapsedSecondsBeforeCurrentPeriod,
      events: events ?? this.events,
      refereeObservations: clearRefereeObservations
          ? null
          : (refereeObservations ?? this.refereeObservations),
      closedAt: closedAt ?? this.closedAt,
      closedByUserId: closedByUserId ?? this.closedByUserId,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homePenaltyScore': homePenaltyScore,
      'awayPenaltyScore': awayPenaltyScore,
      'currentPeriod': currentPeriod.name,
      'periodStartedAt': periodStartedAt?.toIso8601String(),
      'elapsedSecondsBeforeCurrentPeriod': elapsedSecondsBeforeCurrentPeriod,
      'events': events.map((e) => e.toJson()).toList(),
      'refereeObservations': refereeObservations,
      'closedAt': closedAt?.toIso8601String(),
      'closedByUserId': closedByUserId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DigitalMatchReport.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>?;
    final parsedEvents = rawEvents != null
        ? rawEvents
              .whereType<Map<String, dynamic>>()
              .map(MatchEvent.fromJson)
              .toList()
        : <MatchEvent>[];

    return DigitalMatchReport(
      matchId: json['matchId'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      homeTeamId: json['homeTeamId'] as String? ?? '',
      awayTeamId: json['awayTeamId'] as String? ?? '',
      homeScore: (json['homeScore'] as num?)?.toInt() ?? 0,
      awayScore: (json['awayScore'] as num?)?.toInt() ?? 0,
      homePenaltyScore: (json['homePenaltyScore'] as num?)?.toInt(),
      awayPenaltyScore: (json['awayPenaltyScore'] as num?)?.toInt(),
      currentPeriod: MatchPeriod.fromCode(json['currentPeriod'] as String?),
      periodStartedAt: json['periodStartedAt'] != null
          ? DateTime.tryParse(json['periodStartedAt'] as String)
          : null,
      elapsedSecondsBeforeCurrentPeriod:
          (json['elapsedSecondsBeforeCurrentPeriod'] as num?)?.toInt() ?? 0,
      events: parsedEvents,
      refereeObservations:
          (json['refereeObservations'] ?? json['referee_observations'])
              as String?,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'] as String)
          : null,
      closedByUserId: json['closedByUserId'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
