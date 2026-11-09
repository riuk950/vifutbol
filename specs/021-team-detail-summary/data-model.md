# Data Model: Pantalla de Detalle de Equipo con Pestañas y Resumen (HU 14.1)

**Feature**: `021-team-detail-summary`  
**Date**: 2026-11-09

---

## 1. Modelos de Presentación y Proyecciones

### 1.1 `TeamMatchSummary`
Proyección inmutable que encapsula el contexto competitivo resuelto de un equipo para la pantalla `TeamDetailScreen` y su pestaña "Información".

```dart
class TeamMatchSummary {
  final TournamentTeam? team;
  final ChampionshipTournament? tournament;
  final ChampionshipMatch? lastPlayedMatch;
  final TournamentTeam? lastMatchOpponent;
  final bool isLastMatchHome;
  final ChampionshipMatch? nextScheduledMatch;
  final TournamentTeam? nextMatchOpponent;
  final bool isNextMatchHome;

  const TeamMatchSummary({
    required this.team,
    required this.tournament,
    this.lastPlayedMatch,
    this.lastMatchOpponent,
    this.isLastMatchHome = true,
    this.nextScheduledMatch,
    this.nextMatchOpponent,
    this.isNextMatchHome = true,
  });

  bool get hasTeam => team != null;
  bool get hasLastPlayedMatch => lastPlayedMatch != null;
  bool get hasNextScheduledMatch => nextScheduledMatch != null;
}
```

### 1.2 Reglas de Derivación (`TeamMatchSummary.fromCatalog`)
- **Entrada**:
  - `String teamId`
  - `List<TournamentTeam> teams`
  - `List<ChampionshipTournament> tournaments`
  - `List<ChampionshipMatch> matches`
- **Resolución de Entidades**:
  - `team`: equipo en `teams` cuyo `id == teamId` (`null` si no existe).
  - `tournament`: torneo en `tournaments` cuyo `id == team.tournamentId` (`null` si no existe).
  - `teamMatches`: subconjunto de `matches` donde `m.homeTeamId == teamId || m.awayTeamId == teamId`.
- **Resolución de `lastPlayedMatch`**:
  - Filtra `teamMatches` con `status == MatchStatus.completed`.
  - Ordena por `scheduledStartTime` descendente (nulos al final) y luego por `roundNumber` descendente.
  - Determina `isLastMatchHome = lastPlayedMatch.homeTeamId == teamId` y resuelve `lastMatchOpponent` desde el mapa de equipos.
- **Resolución de `nextScheduledMatch`**:
  - Filtra `teamMatches` con `status` en `{MatchStatus.inProgress, MatchStatus.scheduled, MatchStatus.pendingSchedule}`.
  - Ordena priorizando:
    1. `MatchStatus.inProgress` primero.
    2. Partidos con `scheduledStartTime != null` ordenados por `scheduledStartTime` ascendente.
    3. Desempate y partidos `pendingSchedule` sin fecha por `roundNumber` ascendente.
  - Determina `isNextMatchHome = nextScheduledMatch.homeTeamId == teamId` y resuelve `nextMatchOpponent` desde el mapa de equipos.

---

## 2. Entidades del Dominio Existentes Reutilizadas

### 2.1 `TournamentTeam` (`lib/domain/entities/tournament_team.dart`)
- `id`: Identificador único del club.
- `tournamentId`: Identificador del torneo al que pertenece.
- `name`: Nombre oficial del club (ej. `"Atlético Norte FC"`).
- `shortCode`: Código corto de 3 caracteres en mayúsculas (ej. `"ATN"`).
- `crestShape`: Geometría del escudo (`shield`, `circle`, `diamond`, `hexagon`).
- `primaryColorHex`: Color primario institucional en formato entero ARGB.
- `secondaryColorHex`: Color secundario institucional en formato entero ARGB.
- `eligibilityStatus`: Estado de elegibilidad (`pendingQuota`, `readyForApproval`, `eligible`).
- `players`: Lista inmutable de jugadores inscritos (`RegisteredPlayer`).

### 2.2 `ChampionshipTournament` (`lib/domain/entities/championship_tournament.dart`)
- `id`: Identificador único del campeonato.
- `name`: Nombre oficial de la competición.
- `category`: Categoría deportiva.
- `status`: Estado del campeonato (`openRegistration`, `inProgress`, `finished`).

### 2.3 `ChampionshipMatch` (`lib/domain/entities/championship_match.dart`)
- `id`, `tournamentId`, `roundNumber`, `roundName`.
- `homeTeamId`, `awayTeamId`.
- `scheduledStartTime`, `pitchName`, `venueId`.
- `status` (`pendingSchedule`, `scheduled`, `inProgress`, `completed`, `cancelled`).
- `homeScore`, `awayScore`.

---

## 3. Diagrama de Relaciones

```text
[ChampionshipTournament] 1 ◄──── N [TournamentTeam]
                                         │
              ┌──────────────────────────┴──────────────────────────┐
              ▼ (homeTeamId / awayTeamId)                           ▼
    [ChampionshipMatch] (completed)                       [ChampionshipMatch] (inProgress / scheduled / pendingSchedule)
              │                                                     │
              ▼                                                     ▼
   lastPlayedMatch + Rival                               nextScheduledMatch + Rival
              └──────────────────────────┬──────────────────────────┘
                                         ▼
                                [TeamMatchSummary]
```
