# Research & Architecture Decisions: Aprobación de Equipos y Habilitación para Fixture con Mínimo 11 Jugadores

**Feature Branch**: `030-team-approval-fixture-eligibility` | **Date**: 2026-11-10

## 1. Domain Modeling: `TeamEligibilityStatus` Lifecycle & Retrocompatibility

### Decision
Unify `TeamEligibilityStatus` into 2 canonical states:
- `pendingVerification`: Nómina aún no verificada, incompleta (< 11 jugadores) o revertida por el organizador.
- `eligible`: Nómina con 11 o más jugadores formalmente aprobada por el organizador para competir y participar en el fixture.

Implement transparent JSON deserialization in `TournamentTeam.fromJson` and `TeamEligibilityStatus`:
```dart
static TeamEligibilityStatus fromJson(String value) {
  return switch (value) {
    'eligible' => TeamEligibilityStatus.eligible,
    'pendingVerification' || 'pendingQuota' || 'readyForApproval' || _ =>
      TeamEligibilityStatus.pendingVerification,
  };
}
```

### Rationale
- Aligns directly with Notion HU 16.3 business rules and the clarified decision from Question 3.
- Simplifies state transitions across the application and presentation layers while maintaining 100% backward compatibility with persisted fixtures and test seeds.
- Retains `team.isEligible => eligibilityStatus == TeamEligibilityStatus.eligible`.

### Alternatives Considered
- *Maintaining 3 states (`pendingQuota`, `readyForApproval`, `eligible`)*: Rejected because it creates ambiguity regarding when a team is officially eligible vs semi-eligible, violating the single source of truth principle.
- *Boolean flag `isApproved`*: Rejected because enum-based state modeling supports future status expansions (e.g. `disqualified`, `suspended`) without schema redesign.

---

## 2. Domain & Application Logic: Approval, Reversal, and Auto-Demotion

### Decision
1. **Approval (`approveTeamEligibility`)**:
   - Verify `actorRole` has `RoleCapability.approveRegistrations` (exclusive to `UserRole.organizer`).
   - Validate `team.players.length >= 11`.
   - If `team.players.length < 11`, throw `TeamEligibilityValidationFailure`:
     `'El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: ${team.players.length})'`.
   - Transition team to `TeamEligibilityStatus.eligible`.

2. **Revocation (`revokeTeamEligibility`)**:
   - Verify `actorRole` has `RoleCapability.approveRegistrations`.
   - Verify no matches in the tournament are `inProgress` or `completed`.
   - If scheduled matches exist involving this team, invalidate/remove them to preserve calendar integrity (Option B from Clarifications).
   - Transition team back to `TeamEligibilityStatus.pendingVerification`.

3. **Automatic Demotion on Player Removal (`unenrollPlayerFromRoster`)**:
   - When a player is removed from an already `eligible` team and the remaining player count drops below 11 (`updatedPlayers.length < 11`), automatically set `eligibilityStatus = TeamEligibilityStatus.pendingVerification` (Option A from Clarifications).

### Rationale
- Enforces non-negotiable regulatory quota (Constitution Principle II and VII).
- Prevents invalid tournament states where a team with fewer than 11 players enters a match or fixture draw.
- Clear, descriptive error messages in Spanish satisfying Constitution Principle VI.

---

## 3. Fixture Generation Enforcement

### Decision
In `FixtureSchedulingUseCase.generateRoundRobinFixture`:
1. Filter participating teams strictly:
   ```dart
   final eligibleTeams = teams
       .where((t) => t.tournamentId == tournament.id && t.isEligible)
       .toList();
   ```
2. Verify `eligibleTeams.length >= 2`. If `< 2`, throw `FixtureScheduleValidationFailure`:
   `'Se requieren al menos dos equipos habilitados con nómina completa'`.

### Rationale
- Direct requirement from Notion HU 16.3 DoD and Acceptance Criteria.
- Protects the mathematical integrity of round-robin and bracket fixture compilation.

---

## 4. UI Layer: Team Cards & Responsive Dialogs

### Decision
1. **Roster Status Indicator in `CompetitionTeamsTabView`**:
   - If `team.players.length < 11`:
     `l10n.competitionTeamPlayersIncomplete(team.players.length)` $\rightarrow$ `"${team.players.length}/11 jugadores - Incompleto"` with `KickPulseTypography.captionMeta`.
   - If `team.players.length >= 11`:
     `l10n.competitionTeamPlayersComplete(team.players.length)` $\rightarrow$ `"${team.players.length} jugadores - Nómina válida"`.

2. **Action Row for Organizer**:
   - Embedded inside `KickPulseCard` via a responsive `Wrap` or vertical action section.
   - When `team.eligibilityStatus != TeamEligibilityStatus.eligible`:
     Render `KickPulseButton` ("Habilitar Equipo").
     - If `team.players.length < 11`: Trigger `AlertDialog` ("Cuota reglamentaria insuficiente") displaying `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: ${team.players.length})"` with button `"Entendido"`.
     - If `team.players.length >= 11`: Execute approval via `teamsControllerProvider.notifier.approveTeamEligibility(...)`.
   - When `team.eligibilityStatus == TeamEligibilityStatus.eligible`:
     Render `KickPulseButton` ("Inhabilitar").
     - On tap: Execute revocation via `teamsControllerProvider.notifier.revokeTeamEligibility(...)`.
3. **Role Visibility Gate**:
   - The action row is strictly conditioned on `canManage` (Organizer). Non-organizers (`coach`, `referee`, `player`, `fan`) do not see the action buttons.
4. **Mobile Layout & Scaled Fonts**:
   - Actions utilize `Wrap` with `spacing: 8` and `runSpacing: 8` to avoid `RenderFlex` overflows on $320 \times 640\text{ px}$ viewports with 130% text scaling.

---

## 5. Localization Strategy (`lib/l10n/app_es.arb`)

### Decision
Add the following keys:
- `teamEligibilityPendingVerification`: `"Pendiente de verificación"`
- `teamEligibilityQuotaInsufficientTitle`: `"Cuota reglamentaria insuficiente"`
- `teamEligibilityQuotaInsufficientMessage`: `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})"`
- `teamEligibilityActionApprove`: `"Habilitar Equipo"`
- `teamEligibilityActionRevoke`: `"Inhabilitar"`
- `teamEligibilityActionUnderstood`: `"Entendido"`
- `competitionTeamPlayersIncomplete`: `"{count}/11 jugadores - Incompleto"`
- `competitionTeamPlayersComplete`: `"{count} jugadores - Nómina válida"`
- `competitionFixtureMinEligibleTeamsError`: `"Se requieren al menos dos equipos habilitados con nómina completa"`
- `teamEligibilityRevokedSuccess`: `"El equipo ha sido inhabilitado para el campeonato"`
