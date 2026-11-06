# Data Model: Pantalla de Detalle de Competición y Fixture Completo

**Feature**: `018-competition-detail-fixture`
**Date**: 2026-11-06

---

## 1. Agregados y Modelos de Presentación

### 1.1 `MatchdayFixtureGroup`
Agrupación pura de partidos de una misma jornada o etapa del campeonato.

```dart
class MatchdayFixtureGroup {
  final int roundNumber;
  final String roundName;
  final List<ChampionshipMatch> matches;

  const MatchdayFixtureGroup({
    required this.roundNumber,
    required this.roundName,
    required this.matches,
  });
}
```

### 1.2 `CompetitionDetailState`
Estado inmutable de presentación para `CompetitionDetailScreen`.

```dart
class CompetitionDetailState {
  final ChampionshipTournament? tournament;
  final List<MatchdayFixtureGroup> fixtureGroups;
  final Map<String, TournamentTeam> teamsById;
  final bool isLoading;
  final String? errorMessage;

  const CompetitionDetailState({
    this.tournament,
    this.fixtureGroups = const [],
    this.teamsById = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasFixture => fixtureGroups.isNotEmpty;
  int get totalMatches => fixtureGroups.fold(0, (sum, g) => sum + g.matches.length);
}
```

---

## 2. Entidades del Dominio Existentes Reutilizadas

### 2.1 `ChampionshipTournament`
- `id`: Identificador único de la competición.
- `name`: Nombre comercial/oficial del torneo (ej. "Liga Apertura 2026").
- `edition`: Edición del torneo.
- `status`: Estado operativo (`openRegistration`, `inProgress`, `finished`).
- `category`: Categoría deportiva (ej. "Libre", "Sub-20", "Veteranos").
- `format`: Formato de disputa (`league`, `knockout`, `groupStageKnockout`).

### 2.2 `ChampionshipMatch`
- `id`: Identificador del partido.
- `tournamentId`: Vinculación referencial al campeonato.
- `roundNumber`: Número secuencial de jornada (1..N).
- `roundName`: Denominación oficial (ej. "Jornada 1", "Cuartos de Final").
- `homeTeamId`, `awayTeamId`: Identificadores de los equipos contendientes.
- `status`: Estado del juego (`pendingSchedule`, `scheduled`, `inProgress`, `finished`).
- `scheduledStartTime`: Fecha y hora de inicio programada.
- `venueId`, `pitchId`, `pitchName`: Sede y cancha asignadas.
- `homeScore`, `awayScore`: Marcador oficial registrado.

---

## 3. Relaciones y Mapeos

```
[ChampionshipTournament]
        │ 1:N
        ▼
[ChampionshipMatch] ◄─── agrupados deterministamente por (roundNumber, roundName) ───► [MatchdayFixtureGroup]
        │
        ├── homeTeamId ──► [TournamentTeam]
        └── awayTeamId ──► [TournamentTeam]
```
