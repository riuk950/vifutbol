# UI & Controller Contracts: Coach Team & Roster Governance

**Feature Branch**: `029-coach-team-roster-governance` | **Date**: 2026-11-10

## 1. Widget: `CreateTeamDialog`

Modal dialog allowing authenticated coaches to create a team/club.

### Keys & Components

| Component | Widget Key | Type | Description |
|---|---|---|---|
| Dialog root | `create_team_dialog` | `AlertDialog` | Dialog container. |
| Name Input | `create_team_name_input` | `TextFormField` | Team name field ($\ge 3$ characters). |
| ShortCode Input | `create_team_short_code_input` | `TextFormField` | Team short code field (2–4 uppercase chars). |
| Tournament Dropdown | `create_team_tournament_dropdown` | `DropdownButtonFormField<String?>` | Optional selection of open tournaments or `null` for unassigned. |
| Submit Button | `create_team_submit_button` | `KickPulseButton` | Primary action to save team. |
| Cancel Button | `create_team_cancel_button` | `TextButton` | Closes dialog without saving. |

---

## 2. Widget: `CoachPanelContent` Updates

### Keys & Empty State

| Component | Widget Key | Type | Behavior |
|---|---|---|---|
| Empty State Card | `coach_no_team_card` | `KickPulseCard` | Rendered when `coachTeams.isEmpty`. |
| Register Team Action | `coach_action_register_team_empty` | `KickPulseButton` | Tapping opens `CreateTeamDialog`. |
| Normal Roster Action | `coach_action_manage_roster` | `KickPulseButton` | Rendered when a team is present; navigates to roster. |

---

## 3. Directory Screen Contracts

### `TeamsDirectoryScreen`

- `create_team_from_directory_button`:
  - `find.byKey(const Key('create_team_from_directory_button'))`
  - **Visible IF AND ONLY IF**: `activeUserRole == UserRole.coach` (or `capabilities.contains(RoleCapability.manageTeamRoster)`).
  - **Hidden for**: `UserRole.organizer`, `UserRole.referee`, `UserRole.player`, `UserRole.fan`.

### `PlayersDirectoryScreen`

- `register_player_from_directory_button`:
  - `find.byKey(const Key('register_player_from_directory_button'))`
  - **Visible IF AND ONLY IF**: `activeUserRole == UserRole.coach`.
  - **Hidden for**: all non-coach roles.

### `CompetitionDetailScreen`

- `competition_detail_fab_generate_fixture`:
  - Single direct `FloatingActionButton` shown to the organizer if the competition is editable and lacks a fixture.
  - Speed Dial FAB menu and team enrollment FAB are completely removed.

---

## 4. Use Case Contract: `ManageTeamsEligibilityUseCase`

```dart
Future<TournamentTeam> registerOrUpdateTeam({
  required TournamentTeam team,
  ChampionshipTournament? tournament,
  required UserRole actorRole,
});
```

### Exceptions & Error Codes

- If `!RolePermissionMatrix.hasCapability(actorRole, RoleCapability.manageTeamRoster)`:
  - Throws `UnauthorizedRoleFailure('Solo los entrenadores pueden registrar equipos o futbolistas')`.
- If `team.name.trim().length < 3`:
  - Throws `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.invalidTeamName, 'El nombre del equipo debe tener al menos 3 caracteres')`.
- If `team.shortCode.trim().length < 2 || > 4`:
  - Throws `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.invalidShortCode, 'La sigla debe tener entre 2 y 4 caracteres')`.
- If `tournament != null && tournament.status != TournamentStatus.openRegistration`:
  - Throws `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.tournamentRegistrationsClosed, 'Las inscripciones de este campeonato están cerradas')`.
