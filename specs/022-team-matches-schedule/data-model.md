# Data Model: Pestaña de Calendario de Partidos del Equipo (HU 14.2)

**Feature**: `022-team-matches-schedule`  
**Date**: 2026-11-09

---

## 1. Enumeración Semántica: `TeamMatchOutcome`

Representa el desenlace deportivo de un partido finalizado (`MatchStatus.completed`) evaluado siempre desde la perspectiva del equipo consultado (`teamId`).

| Valor | Condición Matemática | Variante Visual (`KickPulseBadgeVariant`) | Color Base (`KickPulseColors`) | Etiqueta `l10n` (ES) |
|-------|----------------------|-------------------------------------------|--------------------------------|----------------------|
| `win` | `teamGoals > opponentGoals` | `KickPulseBadgeVariant.success` | `accentPrimary` (`#22C55E`) | *"Victoria"* |
| `draw` | `teamGoals == opponentGoals` | `KickPulseBadgeVariant.warning` | `accentWarning` (`#F59E0B`) | *"Empate"* |
| `loss` | `teamGoals < opponentGoals` | `KickPulseBadgeVariant.live` | `accentLive` (`#EF4444`) | *"Derrota"* |

Donde:
- Si `isHome == true`: `teamGoals = match.homeScore ?? 0`, `opponentGoals = match.awayScore ?? 0`.
- Si `isHome == false`: `teamGoals = match.awayScore ?? 0`, `opponentGoals = match.homeScore ?? 0`.

---

## 2. Entidad de Ítem de Calendario: `TeamScheduledMatchItem`

Ubicación: `lib/presentation/teams/models/team_matches_schedule.dart`

Agrupa un partido oficial junto con los equipos resueltos y el contexto relativo al equipo consultado.

### Atributos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `match` | `ChampionshipMatch` | Partido oficial del catálogo. |
| `homeTeam` | `TournamentTeam?` | Entidad resuelta del equipo local. |
| `awayTeam` | `TournamentTeam?` | Entidad resuelta del equipo visitante. |
| `isHome` | `bool` | `true` si `match.homeTeamId == teamId`, `false` si actúa como visitante. |
| `outcome` | `TeamMatchOutcome?` | Resultado (`win`, `draw`, `loss`) si `match.status == MatchStatus.completed`; `null` para partidos no finalizados. |

### Propiedades Derivadas

- `opponentTeam` (`TournamentTeam?`): Retorna `awayTeam` si `isHome == true`, o `homeTeam` si `isHome == false`.
- `isCompleted` (`bool`): `match.status == MatchStatus.completed`.

---

## 3. Modelo de Proyección de Pestaña: `TeamMatchesSchedule`

Ubicación: `lib/presentation/teams/models/team_matches_schedule.dart`

### Atributos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `teamId` | `String` | Identificador del equipo consultado. |
| `upcomingMatches` | `List<TeamScheduledMatchItem>` | Lista inmutable de próximos partidos (`inProgress`, `scheduled`, `pendingSchedule`) ordenados cronológicamente de menor a mayor fecha. |
| `completedMatches` | `List<TeamScheduledMatchItem>` | Lista inmutable de partidos finalizados (`completed`) ordenados del más reciente al más antiguo. |

### Propiedades Derivadas

- `hasAnyMatches` (`bool`): `upcomingMatches.isNotEmpty || completedMatches.isNotEmpty`.
- `hasUpcomingMatches` (`bool`): `upcomingMatches.isNotEmpty`.
- `hasCompletedMatches` (`bool`): `completedMatches.isNotEmpty`.

---

## 4. Reglas Deterministas de Filtrado y Ordenamiento (`TeamMatchesSchedule.fromCatalog`)

1. **Filtro de Participación Exclusiva**:
   - Se seleccionan únicamente los partidos donde `m.homeTeamId == teamId || m.awayTeamId == teamId`.
   - Los partidos con `m.status == MatchStatus.cancelled` se excluyen de ambas secciones activas.

2. **Sección "Próximos Partidos" (`upcomingMatches`)**:
   - Estados incluidos: `{MatchStatus.inProgress, MatchStatus.scheduled, MatchStatus.pendingSchedule}`.
   - Criterio de ordenamiento:
     1. `MatchStatus.inProgress` primero.
     2. `MatchStatus.scheduled` ordenados por `scheduledStartTime` ascendente (del más próximo al más lejano).
     3. `MatchStatus.pendingSchedule` al final.
     4. Desempate por `roundNumber` ascendente y luego `id` ascendente.

3. **Sección "Resultados Anteriores" (`completedMatches`)**:
   - Estados incluidos: `{MatchStatus.completed}`.
   - Criterio de ordenamiento:
     1. `scheduledStartTime` descendente (del más reciente al más antiguo; fechas no nulas antes que nulas).
     2. Desempate por `roundNumber` descendente y luego `id` descendente.
   - Para cada partido se calcula `TeamMatchOutcome` comparando los goles del equipo consultado frente a los goles del rival.
