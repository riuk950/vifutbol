/// Tactical role of a player within a match convocation.
enum PlayerConvocationRole { notConvoked, starter, substitute }

/// Disciplinary state of a player calculated from tournament suspension rules.
enum PlayerDisciplinaryState { eligible, warningAccumulation, suspended }

/// Lifecycle status of the match convocation.
enum ConvocationStatus { draft, confirmed }
