# Contracts: Team Approval & Fixture Eligibility

**Feature Branch**: `030-team-approval-fixture-eligibility` | **Date**: 2026-11-10

## 1. Application Layer Use Case Contract

### `ManageTeamsEligibilityUseCase`

```dart
abstract class IManageTeamsEligibilityUseCase {
  /// Officially approves a team for tournament competition and fixture draws.
  ///
  /// Preconditions:
  /// - [actorRole] must have [RoleCapability.approveRegistrations] (UserRole.organizer).
  /// - [tournament.status] must not be finished.
  /// - Team must have at least 11 players registered in its roster.
  ///
  /// Throws:
  /// - [UnauthorizedRoleFailure] if [actorRole] is not authorized.
  /// - [TeamEligibilityValidationFailure] with code [insufficientPlayersForApproval]
  ///   if player count < 11.
  Future<TournamentTeam> approveTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  });

  /// Revokes the eligibility of an approved team, reverting it to pending verification.
  ///
  /// Preconditions:
  /// - [actorRole] must have [RoleCapability.approveRegistrations] (UserRole.organizer).
  /// - Tournament must not have matches in progress or completed.
  ///
  /// Postconditions:
  /// - Team status becomes [TeamEligibilityStatus.pendingVerification].
  /// - Any scheduled matches in the tournament involving this team are invalidated.
  Future<TournamentTeam> revokeTeamEligibility({
    required String teamId,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  });
}
```

---

## 2. Fixture Scheduling Contract

### `FixtureSchedulingUseCase`

```dart
abstract class IFixtureSchedulingUseCase {
  /// Generates round robin fixture for the given tournament using eligible teams.
  ///
  /// Preconditions:
  /// - [userRole] must have [RoleCapability.manageTournaments] (UserRole.organizer).
  /// - [tournament.status] must not be finished.
  /// - At least 2 teams belonging to [tournament.id] must have [isEligible == true].
  ///
  /// Throws:
  /// - [FixtureScheduleValidationFailure] with code [insufficientTeams]
  ///   if count of eligible teams < 2.
  Future<List<ChampionshipMatch>> generateRoundRobinFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  });
}
```

---

## 3. UI Component Contract

### `CompetitionTeamsTabView`

| UI Key | Type | Description | Visibility Gate |
|---|---|---|---|
| `competition_team_card_{teamId}` | `KickPulseCard` | Card representing the enrolled team | Public (All roles) |
| `competition_team_players_count_{teamId}` | `Text` | Label indicating player count status (`X/11 jugadores - Incompleto` or `X jugadores - Nómina válida`) | Public (All roles) |
| `competition_team_status_badge_{teamId}` | `KickPulseBadge` | Status badge (`Pendiente de verificación` or `Habilitado para competir`) | Public (All roles) |
| `competition_team_action_approve_{teamId}` | `KickPulseButton` | Button to approve team eligibility | Organizer only (`canManage`) & `!team.isEligible` |
| `competition_team_action_revoke_{teamId}` | `KickPulseButton` | Button to revoke team eligibility | Organizer only (`canManage`) & `team.isEligible` |
| `competition_team_insufficient_quota_dialog` | `AlertDialog` | Dialog warning organizer of < 11 players | Triggered on tapping approve when < 11 players |
| `competition_team_dialog_confirm_button` | `TextButton` / `ElevatedButton` | "Entendido" button to dismiss dialog | Inside insufficient quota dialog |
