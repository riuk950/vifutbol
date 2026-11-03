import 'package:vifutbol/domain/entities/tournament_enums.dart';

bool _sameTiebreakerList(
  List<TiebreakerCriterion> a,
  List<TiebreakerCriterion> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Configuration for knockout elimination brackets.
class KnockoutStageConfig {
  const KnockoutStageConfig({
    this.startingRound = KnockoutRound.quarterFinals,
    this.twoLeggedTies = false,
    this.directPenaltyShootoutOnDraw = true,
  });

  final KnockoutRound startingRound;
  final bool twoLeggedTies;
  final bool directPenaltyShootoutOnDraw;

  /// Ordered sequence of knockout rounds from [startingRound] through [KnockoutRound.finalMatch].
  List<KnockoutRound> get activeRoundsSequence {
    const allRounds = KnockoutRound.values;
    final startIndex = allRounds.indexOf(startingRound);
    return allRounds.sublist(startIndex);
  }

  KnockoutStageConfig copyWith({
    KnockoutRound? startingRound,
    bool? twoLeggedTies,
    bool? directPenaltyShootoutOnDraw,
  }) {
    return KnockoutStageConfig(
      startingRound: startingRound ?? this.startingRound,
      twoLeggedTies: twoLeggedTies ?? this.twoLeggedTies,
      directPenaltyShootoutOnDraw:
          directPenaltyShootoutOnDraw ?? this.directPenaltyShootoutOnDraw,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startingRound': startingRound.name,
      'twoLeggedTies': twoLeggedTies,
      'directPenaltyShootoutOnDraw': directPenaltyShootoutOnDraw,
    };
  }

  factory KnockoutStageConfig.fromJson(Map<String, dynamic> json) {
    final roundName = json['startingRound'] as String?;
    final startingRound = KnockoutRound.values.firstWhere(
      (r) => r.name == roundName,
      orElse: () => KnockoutRound.quarterFinals,
    );
    return KnockoutStageConfig(
      startingRound: startingRound,
      twoLeggedTies: json['twoLeggedTies'] as bool? ?? false,
      directPenaltyShootoutOnDraw:
          json['directPenaltyShootoutOnDraw'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnockoutStageConfig &&
        other.startingRound == startingRound &&
        other.twoLeggedTies == twoLeggedTies &&
        other.directPenaltyShootoutOnDraw == directPenaltyShootoutOnDraw;
  }

  @override
  int get hashCode =>
      Object.hash(startingRound, twoLeggedTies, directPenaltyShootoutOnDraw);
}

/// Configuration for group stage in [TournamentFormat.mixedGroupsAndKnockout].
class GroupStageConfig {
  const GroupStageConfig({this.groupCount = 4, this.advancingPerGroup = 2});

  final int groupCount;
  final int advancingPerGroup;

  bool get isValid =>
      groupCount >= 2 &&
      groupCount <= 8 &&
      advancingPerGroup >= 1 &&
      advancingPerGroup <= 4;

  GroupStageConfig copyWith({int? groupCount, int? advancingPerGroup}) {
    return GroupStageConfig(
      groupCount: groupCount ?? this.groupCount,
      advancingPerGroup: advancingPerGroup ?? this.advancingPerGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'groupCount': groupCount,
      'advancingPerGroup': advancingPerGroup,
    };
  }

  factory GroupStageConfig.fromJson(Map<String, dynamic> json) {
    return GroupStageConfig(
      groupCount: json['groupCount'] as int? ?? 4,
      advancingPerGroup: json['advancingPerGroup'] as int? ?? 2,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupStageConfig &&
        other.groupCount == groupCount &&
        other.advancingPerGroup == advancingPerGroup;
  }

  @override
  int get hashCode => Object.hash(groupCount, advancingPerGroup);
}

/// Official custom rules configuration acting as the single source of truth
/// for points calculation, tiebreakers, disciplinary suspensions, and squad limits.
class TournamentRulesConfig {
  const TournamentRulesConfig({
    this.pointsForWin = 3,
    this.pointsForDraw = 1,
    this.pointsForLoss = 0,
    this.tiebreakerOrder = defaultTiebreakerOrder,
    this.yellowCardSuspensionLimit = 3,
    this.minPlayersPerTeam = 7,
    this.maxPlayersPerTeam = 18,
    this.halfDurationMinutes = 45,
    this.leagueRounds = 1,
    this.knockoutConfig = const KnockoutStageConfig(),
    this.groupStageConfig = const GroupStageConfig(),
  });

  static const List<TiebreakerCriterion> defaultTiebreakerOrder =
      <TiebreakerCriterion>[
        TiebreakerCriterion.goalDifference,
        TiebreakerCriterion.goalsFor,
        TiebreakerCriterion.headToHead,
        TiebreakerCriterion.fairPlay,
      ];

  final int pointsForWin;
  final int pointsForDraw;
  final int pointsForLoss;
  final List<TiebreakerCriterion> tiebreakerOrder;
  final int yellowCardSuspensionLimit;
  final int minPlayersPerTeam;
  final int maxPlayersPerTeam;
  final int halfDurationMinutes;
  final int leagueRounds;
  final KnockoutStageConfig knockoutConfig;
  final GroupStageConfig groupStageConfig;

  bool get hasValidPointsDistribution =>
      pointsForWin > pointsForDraw &&
      pointsForDraw >= pointsForLoss &&
      pointsForLoss >= 0;

  bool get hasValidTiebreakerOrder =>
      tiebreakerOrder.isNotEmpty &&
      tiebreakerOrder.toSet().length == tiebreakerOrder.length;

  bool get hasValidYellowCardLimit =>
      yellowCardSuspensionLimit >= 2 && yellowCardSuspensionLimit <= 10;

  bool get hasValidSquadSizeRange =>
      minPlayersPerTeam >= 5 &&
      maxPlayersPerTeam >= minPlayersPerTeam &&
      maxPlayersPerTeam <= 35;

  bool get hasValidHalfDuration =>
      halfDurationMinutes >= 10 && halfDurationMinutes <= 60;

  bool get hasValidLeagueRounds => leagueRounds == 1 || leagueRounds == 2;

  bool hasSameScoringPoints(TournamentRulesConfig other) {
    return pointsForWin == other.pointsForWin &&
        pointsForDraw == other.pointsForDraw &&
        pointsForLoss == other.pointsForLoss;
  }

  TournamentRulesConfig copyWith({
    int? pointsForWin,
    int? pointsForDraw,
    int? pointsForLoss,
    List<TiebreakerCriterion>? tiebreakerOrder,
    int? yellowCardSuspensionLimit,
    int? minPlayersPerTeam,
    int? maxPlayersPerTeam,
    int? halfDurationMinutes,
    int? leagueRounds,
    KnockoutStageConfig? knockoutConfig,
    GroupStageConfig? groupStageConfig,
  }) {
    return TournamentRulesConfig(
      pointsForWin: pointsForWin ?? this.pointsForWin,
      pointsForDraw: pointsForDraw ?? this.pointsForDraw,
      pointsForLoss: pointsForLoss ?? this.pointsForLoss,
      tiebreakerOrder: tiebreakerOrder ?? this.tiebreakerOrder,
      yellowCardSuspensionLimit:
          yellowCardSuspensionLimit ?? this.yellowCardSuspensionLimit,
      minPlayersPerTeam: minPlayersPerTeam ?? this.minPlayersPerTeam,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
      halfDurationMinutes: halfDurationMinutes ?? this.halfDurationMinutes,
      leagueRounds: leagueRounds ?? this.leagueRounds,
      knockoutConfig: knockoutConfig ?? this.knockoutConfig,
      groupStageConfig: groupStageConfig ?? this.groupStageConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pointsForWin': pointsForWin,
      'pointsForDraw': pointsForDraw,
      'pointsForLoss': pointsForLoss,
      'tiebreakerOrder': tiebreakerOrder.map((c) => c.name).toList(),
      'yellowCardSuspensionLimit': yellowCardSuspensionLimit,
      'minPlayersPerTeam': minPlayersPerTeam,
      'maxPlayersPerTeam': maxPlayersPerTeam,
      'halfDurationMinutes': halfDurationMinutes,
      'leagueRounds': leagueRounds,
      'knockoutConfig': knockoutConfig.toJson(),
      'groupStageConfig': groupStageConfig.toJson(),
    };
  }

  factory TournamentRulesConfig.fromJson(Map<String, dynamic> json) {
    final rawTiebreakers = json['tiebreakerOrder'] as List<dynamic>?;
    final parsedTiebreakers = rawTiebreakers == null
        ? defaultTiebreakerOrder
        : rawTiebreakers
              .map(
                (item) => TiebreakerCriterion.values.firstWhere(
                  (c) => c.name == item,
                  orElse: () => TiebreakerCriterion.goalDifference,
                ),
              )
              .toSet()
              .toList();

    return TournamentRulesConfig(
      pointsForWin: json['pointsForWin'] as int? ?? 3,
      pointsForDraw: json['pointsForDraw'] as int? ?? 1,
      pointsForLoss: json['pointsForLoss'] as int? ?? 0,
      tiebreakerOrder: parsedTiebreakers.isEmpty
          ? defaultTiebreakerOrder
          : parsedTiebreakers,
      yellowCardSuspensionLimit: json['yellowCardSuspensionLimit'] as int? ?? 3,
      minPlayersPerTeam: json['minPlayersPerTeam'] as int? ?? 7,
      maxPlayersPerTeam: json['maxPlayersPerTeam'] as int? ?? 18,
      halfDurationMinutes: json['halfDurationMinutes'] as int? ?? 45,
      leagueRounds: json['leagueRounds'] as int? ?? 1,
      knockoutConfig: json['knockoutConfig'] is Map<String, dynamic>
          ? KnockoutStageConfig.fromJson(
              json['knockoutConfig'] as Map<String, dynamic>,
            )
          : const KnockoutStageConfig(),
      groupStageConfig: json['groupStageConfig'] is Map<String, dynamic>
          ? GroupStageConfig.fromJson(
              json['groupStageConfig'] as Map<String, dynamic>,
            )
          : const GroupStageConfig(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentRulesConfig &&
        other.pointsForWin == pointsForWin &&
        other.pointsForDraw == pointsForDraw &&
        other.pointsForLoss == pointsForLoss &&
        _sameTiebreakerList(other.tiebreakerOrder, tiebreakerOrder) &&
        other.yellowCardSuspensionLimit == yellowCardSuspensionLimit &&
        other.minPlayersPerTeam == minPlayersPerTeam &&
        other.maxPlayersPerTeam == maxPlayersPerTeam &&
        other.halfDurationMinutes == halfDurationMinutes &&
        other.leagueRounds == leagueRounds &&
        other.knockoutConfig == knockoutConfig &&
        other.groupStageConfig == groupStageConfig;
  }

  @override
  int get hashCode => Object.hash(
    pointsForWin,
    pointsForDraw,
    pointsForLoss,
    Object.hashAll(tiebreakerOrder),
    yellowCardSuspensionLimit,
    minPlayersPerTeam,
    maxPlayersPerTeam,
    halfDurationMinutes,
    leagueRounds,
    knockoutConfig,
    groupStageConfig,
  );
}
