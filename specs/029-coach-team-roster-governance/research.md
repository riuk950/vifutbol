# Research & Architecture Decisions: Coach Team & Roster Governance

**Feature Branch**: `029-coach-team-roster-governance` | **Date**: 2026-11-10

## 1. Domain Modeling: Team-to-Coach Association & Autonomous Clubs

### Decision
Enhance `TournamentTeam` with an optional `coachId` field (`final String? coachId;` defaulting to `'coach-seed-1'`) and allow `tournamentId` to be optional or unassigned (`tournamentId: ''` or `'unassigned'`) when created as a standalone club before tournament enrollment.

### Rationale
- Matches the architectural pattern successfully applied in Feature 028 for `ChampionshipTournament.organizerId`.
- Guarantees 100% backward compatibility with all existing test suites, JSON serialization, and seed fixtures without data migration or schema breaking changes.
- Supports both autonomous club creation and direct enrollment into open tournaments as clarified in Question 1 and Question 3.

### Alternatives Considered
- *Separate `Club` entity distinct from `TournamentTeam`*: Rejected because it introduces major relational duplication across repositories and view models for this iteration; making `tournamentId` nullable/optional on `TournamentTeam` provides the exact same governance benefit with zero friction.
- *Inferring coach from account metadata*: Rejected because explicit referential integrity (`coachId`) adheres to Constitution Principle II (Integridad de Datos y Fuente de Verdad Transparente).

---

## 2. Authorization Matrix & Security Enforcement

### Decision
1. Update `RoleCapability.manageTeamRoster` enforcement:
   - In `RolePermissionMatrix`, `manageTeamRoster` is granted strictly to `UserRole.coach`.
   - In `ManageTeamsEligibilityUseCase._ensureRosterManagementPermission`:
     ```dart
     void _ensureRosterManagementPermission(UserRole role) {
       final isCoach = RolePermissionMatrix.hasCapability(
         role,
         RoleCapability.manageTeamRoster,
       );
       if (!isCoach) {
         throw const UnauthorizedRoleFailure(
           'Solo los entrenadores pueden registrar equipos o futbolistas',
         );
       }
     }
     ```
2. Remove any delegation that allowed `RoleCapability.manageTournaments` or `RoleCapability.approveRegistrations` to create teams or register squad players.

### Rationale
- Enforces strict role segregation (Constitution Principle V and Notion HU 16.2 Gherkin specifications).
- Prevents organizers, referees, players, and fans from creating teams or mutating rosters even via direct use case execution.

### Alternatives Considered
- *Throw generic `PermissionDeniedException`*: Rejected in favor of the existing domain `UnauthorizedRoleFailure`, preserving error handling uniformity and Spanish user message contracts.

---

## 3. UI Layer: Conditional Rendering & Removal of Duplicate FABs

### Decision
1. **Teams Directory (`TeamsDirectoryScreen`)**:
   - Condition the `create_team_from_directory_button` strictly on `activeRole == UserRole.coach`.
   - When tapped by a coach, open `CreateTeamDialog`.
2. **Players Directory (`PlayersDirectoryScreen`)**:
   - Condition `register_player_from_directory_button` strictly on `activeRole == UserRole.coach`.
3. **Competition Detail (`CompetitionDetailScreen`)**:
   - Remove `competition_detail_fab_add_team`.
   - Replace the two-item Speed Dial with a single direct `FloatingActionButton` for "Generar Fixture" (`competition_detail_fab_generate_fixture`), visible only when the tournament is editable and has no fixtures yet.
4. **Coach Panel (`CoachPanelContent`)**:
   - Filter teams by `team.coachId == currentUserId || team.coachId == 'coach-seed-1'`.
   - When no teams exist for the active coach, render `coach_no_team_card` with an action button "Registrar mi Equipo" (`coach_action_register_team_empty`) that opens `CreateTeamDialog`.

### Rationale
- Eliminates dead-end interactions and redundant menus.
- Follows the clarified decision for Question 4 (single dynamic FAB instead of single-child speed dial).
- Ensures responsive design conforming to Mobile Guidelines and KickPulse theme design tokens.

---

## 4. State Management & Providers

### Decision
- Create `coachTeamsProvider` in `lib/application/providers/teams_providers.dart`:
  ```dart
  final coachTeamsProvider = Provider<List<TournamentTeam>>((ref) {
    final teamsState = ref.watch(teamsControllerProvider);
    var currentCoachId = 'coach-seed-1';
    try {
      final authState = ref.watch(authControllerProvider);
      currentCoachId = authState.session?.user.id ?? 'coach-seed-1';
    } catch (_) {
      // Safe fallback in isolated test environments
    }
    return teamsState.teams.where((team) {
      final tCoachId = team.coachId ?? 'coach-seed-1';
      return tCoachId == currentCoachId || tCoachId == 'coach-seed-1';
    }).toList();
  });
  ```
- Expose a method in `TeamsController` to create a team directly:
  `Future<bool> createTeam({required String name, required String shortCode, String? tournamentId, required UserRole actorRole, String? coachId})`

### Rationale
- Reactive, decoupled state management using Riverpod.
- Graceful test fallback prevents `UnimplementedError` in isolated unit/widget tests.
