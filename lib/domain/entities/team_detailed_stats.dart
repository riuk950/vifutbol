import 'player_performance_profile.dart';
import 'standings_table.dart';
import 'team_enums.dart';

/// Form outcome for the last matches of a team.
enum TeamFormResult {
  win,
  draw,
  loss;

  String get code {
    switch (this) {
      case TeamFormResult.win:
        return 'V';
      case TeamFormResult.draw:
        return 'E';
      case TeamFormResult.loss:
        return 'D';
    }
  }
}

/// Completed match history item for a team.
class TeamMatchHistoryItem {
  const TeamMatchHistoryItem({
    required this.matchId,
    required this.roundNumber,
    required this.roundName,
    required this.scheduledAt,
    required this.opponentTeamId,
    required this.opponentTeamName,
    required this.opponentShortCode,
    required this.isHome,
    required this.teamScore,
    required this.opponentScore,
    this.teamPenaltyScore,
    this.opponentPenaltyScore,
    required this.result,
  });

  final String matchId;
  final int roundNumber;
  final String roundName;
  final DateTime scheduledAt;
  final String opponentTeamId;
  final String opponentTeamName;
  final String opponentShortCode;
  final bool isHome;
  final int teamScore;
  final int opponentScore;
  final int? teamPenaltyScore;
  final int? opponentPenaltyScore;
  final TeamFormResult result;

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'roundNumber': roundNumber,
      'roundName': roundName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'opponentTeamId': opponentTeamId,
      'opponentTeamName': opponentTeamName,
      'opponentShortCode': opponentShortCode,
      'isHome': isHome,
      'teamScore': teamScore,
      'opponentScore': opponentScore,
      'teamPenaltyScore': teamPenaltyScore,
      'opponentPenaltyScore': opponentPenaltyScore,
      'result': result.name,
    };
  }

  factory TeamMatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return TeamMatchHistoryItem(
      matchId: json['matchId'] as String? ?? '',
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      roundName: json['roundName'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      opponentTeamId: json['opponentTeamId'] as String? ?? '',
      opponentTeamName: json['opponentTeamName'] as String? ?? '',
      opponentShortCode: json['opponentShortCode'] as String? ?? '',
      isHome: json['isHome'] as bool? ?? true,
      teamScore: (json['teamScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      teamPenaltyScore: (json['teamPenaltyScore'] as num?)?.toInt(),
      opponentPenaltyScore: (json['opponentPenaltyScore'] as num?)?.toInt(),
      result: TeamFormResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => TeamFormResult.draw,
      ),
    );
  }
}

/// Upcoming scheduled match item for a team.
class TeamUpcomingMatchItem {
  const TeamUpcomingMatchItem({
    required this.matchId,
    required this.roundNumber,
    required this.roundName,
    required this.scheduledAt,
    required this.opponentTeamId,
    required this.opponentTeamName,
    required this.opponentShortCode,
    required this.isHome,
    this.venueName,
    this.pitchName,
  });

  final String matchId;
  final int roundNumber;
  final String roundName;
  final DateTime scheduledAt;
  final String opponentTeamId;
  final String opponentTeamName;
  final String opponentShortCode;
  final bool isHome;
  final String? venueName;
  final String? pitchName;

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'roundNumber': roundNumber,
      'roundName': roundName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'opponentTeamId': opponentTeamId,
      'opponentTeamName': opponentTeamName,
      'opponentShortCode': opponentShortCode,
      'isHome': isHome,
      'venueName': venueName,
      'pitchName': pitchName,
    };
  }

  factory TeamUpcomingMatchItem.fromJson(Map<String, dynamic> json) {
    return TeamUpcomingMatchItem(
      matchId: json['matchId'] as String? ?? '',
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      roundName: json['roundName'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      opponentTeamId: json['opponentTeamId'] as String? ?? '',
      opponentTeamName: json['opponentTeamName'] as String? ?? '',
      opponentShortCode: json['opponentShortCode'] as String? ?? '',
      isHome: json['isHome'] as bool? ?? true,
      venueName: json['venueName'] as String?,
      pitchName: json['pitchName'] as String?,
    );
  }
}

/// Detailed consolidated statistics sheet for a team in a tournament (`FR-004`).
class TeamDetailedStats {
  const TeamDetailedStats({
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    this.crestShape = TeamCrestShape.shield,
    this.primaryColorHex = 0xFF00E676,
    required this.standingsRow,
    this.recentForm = const <TeamFormResult>[],
    this.completedMatches = const <TeamMatchHistoryItem>[],
    this.upcomingMatches = const <TeamUpcomingMatchItem>[],
    this.squadStats = const <PlayerPerformanceProfile>[],
  }) : assert(recentForm.length <= 5, 'recentForm can contain at most 5 items');

  final String tournamentId;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final StandingsRow standingsRow;
  final List<TeamFormResult> recentForm;
  final List<TeamMatchHistoryItem> completedMatches;
  final List<TeamUpcomingMatchItem> upcomingMatches;
  final List<PlayerPerformanceProfile> squadStats;

  TeamDetailedStats copyWith({
    String? tournamentId,
    String? teamId,
    String? teamName,
    String? teamShortCode,
    TeamCrestShape? crestShape,
    int? primaryColorHex,
    StandingsRow? standingsRow,
    List<TeamFormResult>? recentForm,
    List<TeamMatchHistoryItem>? completedMatches,
    List<TeamUpcomingMatchItem>? upcomingMatches,
    List<PlayerPerformanceProfile>? squadStats,
  }) {
    return TeamDetailedStats(
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      crestShape: crestShape ?? this.crestShape,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      standingsRow: standingsRow ?? this.standingsRow,
      recentForm: recentForm ?? this.recentForm,
      completedMatches: completedMatches ?? this.completedMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      squadStats: squadStats ?? this.squadStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'crestShape': crestShape.name,
      'primaryColorHex': primaryColorHex,
      'standingsRow': {
        'position': standingsRow.position,
        'teamId': standingsRow.teamId,
        'teamName': standingsRow.teamName,
        'teamShortCode': standingsRow.teamShortCode,
        'played': standingsRow.played,
        'won': standingsRow.won,
        'drawn': standingsRow.drawn,
        'lost': standingsRow.lost,
        'goalsFor': standingsRow.goalsFor,
        'goalsAgainst': standingsRow.goalsAgainst,
        'goalDifference': standingsRow.goalDifference,
        'points': standingsRow.points,
        'yellowCards': standingsRow.yellowCards,
        'secondYellowRedCards': standingsRow.secondYellowRedCards,
        'directRedCards': standingsRow.directRedCards,
        'fairPlayPenaltyPoints': standingsRow.fairPlayPenaltyPoints,
        'isQualified': standingsRow.isQualified,
        'isTiedOnAllCriteria': standingsRow.isTiedOnAllCriteria,
      },
      'recentForm': recentForm.map((f) => f.name).toList(),
      'completedMatches': completedMatches.map((m) => m.toJson()).toList(),
      'upcomingMatches': upcomingMatches.map((m) => m.toJson()).toList(),
      'squadStats': squadStats.map((s) => s.toJson()).toList(),
    };
  }

  factory TeamDetailedStats.fromJson(Map<String, dynamic> json) {
    final rawForm = json['recentForm'] as List<dynamic>?;
    final parsedForm = rawForm != null
        ? rawForm
              .map(
                (f) => TeamFormResult.values.firstWhere(
                  (e) => e.name == f,
                  orElse: () => TeamFormResult.draw,
                ),
              )
              .toList()
        : const <TeamFormResult>[];

    final rawCompleted = json['completedMatches'] as List<dynamic>?;
    final parsedCompleted = rawCompleted != null
        ? rawCompleted
              .whereType<Map<String, dynamic>>()
              .map(TeamMatchHistoryItem.fromJson)
              .toList()
        : const <TeamMatchHistoryItem>[];

    final rawUpcoming = json['upcomingMatches'] as List<dynamic>?;
    final parsedUpcoming = rawUpcoming != null
        ? rawUpcoming
              .whereType<Map<String, dynamic>>()
              .map(TeamUpcomingMatchItem.fromJson)
              .toList()
        : const <TeamUpcomingMatchItem>[];

    final rawSquad = json['squadStats'] as List<dynamic>?;
    final parsedSquad = rawSquad != null
        ? rawSquad
              .whereType<Map<String, dynamic>>()
              .map(PlayerPerformanceProfile.fromJson)
              .toList()
        : const <PlayerPerformanceProfile>[];

    final rowMap = json['standingsRow'] as Map<String, dynamic>?;
    final standingsRow = rowMap != null
        ? StandingsRow(
            position: (rowMap['position'] as num?)?.toInt() ?? 1,
            teamId:
                rowMap['teamId'] as String? ?? json['teamId'] as String? ?? '',
            teamName:
                rowMap['teamName'] as String? ??
                json['teamName'] as String? ??
                '',
            teamShortCode:
                rowMap['teamShortCode'] as String? ??
                json['teamShortCode'] as String? ??
                '',
            played: (rowMap['played'] as num?)?.toInt() ?? 0,
            won: (rowMap['won'] as num?)?.toInt() ?? 0,
            drawn: (rowMap['drawn'] as num?)?.toInt() ?? 0,
            lost: (rowMap['lost'] as num?)?.toInt() ?? 0,
            goalsFor: (rowMap['goalsFor'] as num?)?.toInt() ?? 0,
            goalsAgainst: (rowMap['goalsAgainst'] as num?)?.toInt() ?? 0,
            goalDifference: (rowMap['goalDifference'] as num?)?.toInt() ?? 0,
            points: (rowMap['points'] as num?)?.toInt() ?? 0,
            yellowCards: (rowMap['yellowCards'] as num?)?.toInt() ?? 0,
            secondYellowRedCards:
                (rowMap['secondYellowRedCards'] as num?)?.toInt() ?? 0,
            directRedCards: (rowMap['directRedCards'] as num?)?.toInt() ?? 0,
            fairPlayPenaltyPoints:
                (rowMap['fairPlayPenaltyPoints'] as num?)?.toInt() ?? 0,
            isQualified: rowMap['isQualified'] as bool? ?? false,
            isTiedOnAllCriteria:
                rowMap['isTiedOnAllCriteria'] as bool? ?? false,
          )
        : StandingsRow(
            position: 1,
            teamId: json['teamId'] as String? ?? '',
            teamName: json['teamName'] as String? ?? '',
            teamShortCode: json['teamShortCode'] as String? ?? '',
            played: 0,
            won: 0,
            drawn: 0,
            lost: 0,
            goalsFor: 0,
            goalsAgainst: 0,
            goalDifference: 0,
            points: 0,
          );

    return TeamDetailedStats(
      tournamentId: json['tournamentId'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      teamShortCode: json['teamShortCode'] as String? ?? '',
      crestShape: TeamCrestShape.values.firstWhere(
        (e) => e.name == json['crestShape'],
        orElse: () => TeamCrestShape.shield,
      ),
      primaryColorHex: (json['primaryColorHex'] as num?)?.toInt() ?? 0xFF00E676,
      standingsRow: standingsRow,
      recentForm: parsedForm,
      completedMatches: parsedCompleted,
      upcomingMatches: parsedUpcoming,
      squadStats: parsedSquad,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamDetailedStats &&
        other.tournamentId == tournamentId &&
        other.teamId == teamId &&
        other.standingsRow == standingsRow;
  }

  @override
  int get hashCode => Object.hash(tournamentId, teamId, standingsRow);
}
