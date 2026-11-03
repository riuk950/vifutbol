/// Supported competition formats for a championship tournament.
enum TournamentFormat {
  league,
  knockoutCup,
  mixedGroupsAndKnockout;

  bool get hasStandingsTable =>
      this == TournamentFormat.league ||
      this == TournamentFormat.mixedGroupsAndKnockout;

  bool get hasKnockoutBracket =>
      this == TournamentFormat.knockoutCup ||
      this == TournamentFormat.mixedGroupsAndKnockout;

  bool get hasGroupStage => this == TournamentFormat.mixedGroupsAndKnockout;
}

/// Official lifecycle status machine for a championship tournament.
enum TournamentStatus {
  openRegistration,
  inProgress,
  finished;

  bool get isEditable => this != TournamentStatus.finished;

  bool get requiresAuditForCriticalRules => this == TournamentStatus.inProgress;
}

/// Ordered tiebreaker criteria for standings table resolution.
enum TiebreakerCriterion { goalDifference, goalsFor, headToHead, fairPlay }

/// Knockout bracket round definitions ordered from earliest to final.
enum KnockoutRound {
  roundOf16(16),
  quarterFinals(8),
  semiFinals(4),
  finalMatch(2);

  const KnockoutRound(this.teamSlots);

  /// Total number of teams competing in this round.
  final int teamSlots;

  /// Total number of head-to-head ties in this round.
  int get tieCount => teamSlots ~/ 2;
}
