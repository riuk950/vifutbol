import 'user_role.dart';

/// Operative capabilities and permissions enforceable across sports roles.
enum RoleCapability {
  /// Create and configure tournaments, leagues, and knockout fixtures.
  manageTournaments,

  /// Register and edit sports complexes and geolocated pitches.
  manageVenues,

  /// Approve registrations for clubs, teams, and players.
  approveRegistrations,

  /// Assign referees to scheduled fixtures.
  assignReferees,

  /// Register and manage team roster players.
  manageTeamRoster,

  /// Manage tactical lineups and matchday call-ups.
  manageLineups,

  /// Record live match events (goals, assists, cards, substitutions).
  recordMatchEvents,

  /// Finalize, sign, and close official match reports.
  closeMatchReport,

  /// View personal player/coach statistics and individual call-ups.
  viewPersonalStats,

  /// Browse public tournament standings, fixtures, results, and venues.
  viewPublicContent,

  /// View the persistent cloud sync indicator and outbox summary drawer in the AppBar.
  viewCloudSyncIndicator,
}

/// Pure domain matrix defining access control rules and role capabilities.
class RolePermissionMatrix {
  const RolePermissionMatrix._();

  static const Map<UserRole, Set<RoleCapability>> _matrix = {
    UserRole.organizer: {
      RoleCapability.manageTournaments,
      RoleCapability.manageVenues,
      RoleCapability.approveRegistrations,
      RoleCapability.assignReferees,
      RoleCapability.recordMatchEvents,
      RoleCapability.closeMatchReport,
      RoleCapability.viewPersonalStats,
      RoleCapability.viewPublicContent,
      RoleCapability.viewCloudSyncIndicator,
    },
    UserRole.coach: {
      RoleCapability.manageTeamRoster,
      RoleCapability.manageLineups,
      RoleCapability.viewPersonalStats,
      RoleCapability.viewPublicContent,
      RoleCapability.viewCloudSyncIndicator,
    },
    UserRole.referee: {
      RoleCapability.recordMatchEvents,
      RoleCapability.closeMatchReport,
      RoleCapability.viewPersonalStats,
      RoleCapability.viewPublicContent,
      RoleCapability.viewCloudSyncIndicator,
    },
    UserRole.player: {
      RoleCapability.viewPersonalStats,
      RoleCapability.viewPublicContent,
    },
    UserRole.fan: {RoleCapability.viewPublicContent},
  };

  /// Returns the set of authorized capabilities for a given [UserRole].
  static Set<RoleCapability> capabilitiesForRole(UserRole role) {
    return _matrix[role] ?? const {RoleCapability.viewPublicContent};
  }

  /// Checks if a [UserRole] is authorized to perform a specific [RoleCapability].
  static bool hasCapability(UserRole role, RoleCapability capability) {
    return capabilitiesForRole(role).contains(capability);
  }
}
