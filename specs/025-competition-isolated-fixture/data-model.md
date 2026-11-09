# Data Model: Generación de Fixture Independiente por Competición (HU 15.2)

**Feature**: `025-competition-isolated-fixture`  
**Date**: 2026-11-09  

---

## 1. Domain Entities & Relationships

Esta funcionalidad opera sobre las entidades existentes del dominio garantizando la integridad referencial por `tournamentId`:

### `ChampionshipTournament` (`lib/domain/entities/championship_tournament.dart`)
- **Identificador**: `id` (`String`)
- **Atributos clave**:
  - `name` (`String`): Nombre oficial de la competición.
  - `category` (`String`): Categoría deportiva.
  - `format` (`TournamentFormat`): `league`, `knockoutCup`, `groupsAndKnockout`.
  - `status` (`TournamentStatus`): `openRegistration`, `inProgress`, `finished`.
  - `status.isEditable` (`bool`): `true` únicamente para `openRegistration` e `inProgress`.
  - `rules` (`TournamentRulesConfig`): Configuración de rondas (`leagueRounds`) y duración de tiempos (`halfDurationMinutes`).

### `TournamentTeam` (`lib/domain/entities/tournament_team.dart`)
- **Identificador**: `id` (`String`)
- **Clave foránea**: `tournamentId` (`String`) — vincula exclusivamente al equipo con su competición.
- **Elegibilidad**: `isEligible` (`bool`, `eligibilityStatus == TeamEligibilityStatus.eligible`).
- **Regla de aislamiento (HU 15.2)**:
  $$\text{eligibleTeams}(T) = \{ t \in \text{teams} \mid t.\text{tournamentId} == T.\text{id} \land t.\text{isEligible} \}$$
  Si $|\text{eligibleTeams}(T)| < 2$, se lanza `FixtureScheduleValidationFailure(FixtureScheduleErrorCode.insufficientTeams)`.

### `ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)
- **Identificador**: `id` (`String`)
- **Clave foránea**: `tournamentId` (`String`)
- **Atributos de jornada**: `roundNumber` (`int`), `roundName` (`String`), `homeTeamId` (`String`), `awayTeamId` (`String`), `status` (`MatchStatus`).

---

## 2. State Transitions & Validation Rules

1. **Verificación de Rol**:
   - Solo `RolePermissionMatrix.hasCapability(userRole, RoleCapability.manageTournaments)` (`UserRole.organizer`) puede invocar `generateRoundRobinFixture`.
2. **Verificación de Estado del Torneo**:
   - Si `tournament.status == TournamentStatus.finished`, se rechaza con `FixtureScheduleErrorCode.tournamentClosed`.
3. **Filtrado de Equipos por Competición**:
   - Se filtran los equipos donde `team.tournamentId == tournament.id && team.isEligible`.
   - Si el total es $< 2$, se rechaza con `FixtureScheduleErrorCode.insufficientTeams`.
4. **Bloqueo de Regeneración**:
   - Si existen partidos previos del mismo `tournament.id` con `status == MatchStatus.inProgress || status == MatchStatus.completed`, se rechaza con `FixtureScheduleErrorCode.regenerationBlocked`.
5. **Persistencia Aislada**:
   - Se reemplazan únicamente los partidos de `tournament.id` (`replaceMatchesForTournament(tournament.id, generatedMatches)`), manteniendo intactos los partidos de cualquier otra competición en almacenamiento y en `MatchesCatalogState.matches`.
