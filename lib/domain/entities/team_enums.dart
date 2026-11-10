/// Eligibility status of a team within a championship tournament.
enum TeamEligibilityStatus {
  /// The roster is pending verification, incomplete (< 11 players), or reverted by the organizer.
  pendingVerification,

  /// Officially approved by the organizer with 11 or more players. Eligible for fixture generation and matches.
  eligible;

  /// Retrocompatible JSON deserialization supporting legacy status values.
  static TeamEligibilityStatus fromJson(String value) {
    return switch (value) {
      'eligible' => TeamEligibilityStatus.eligible,
      'pendingVerification' ||
      'pendingQuota' ||
      'readyForApproval' ||
      _ => TeamEligibilityStatus.pendingVerification,
    };
  }

  /// Backward-compatibility getters for legacy enum references.
  @Deprecated('Use pendingVerification instead')
  static TeamEligibilityStatus get pendingQuota => pendingVerification;

  @Deprecated('Use pendingVerification instead')
  static TeamEligibilityStatus get readyForApproval => pendingVerification;
}

/// Tactical player position on the pitch.
enum PlayerPosition { goalkeeper, defender, midfielder, forward }

/// Visual shape geometry for native vector team crests.
enum TeamCrestShape { shield, circle, diamond, hexagon }
