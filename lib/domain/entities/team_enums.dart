/// Eligibility status of a team within a championship tournament.
enum TeamEligibilityStatus {
  /// The roster has fewer players than the tournament's minimum requirement.
  pendingQuota,

  /// The roster meets or exceeds the minimum player quota and is ready for organizer approval.
  readyForApproval,

  /// Officially approved by the organizer. All players are marked eligible for match calls.
  eligible,
}

/// Tactical player position on the pitch.
enum PlayerPosition { goalkeeper, defender, midfielder, forward }

/// Visual shape geometry for native vector team crests.
enum TeamCrestShape { shield, circle, diamond, hexagon }
