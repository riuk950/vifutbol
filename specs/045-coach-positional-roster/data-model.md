# Data Model: Visualización de Plantilla Agrupada por Posición (HU 20.2)

**Feature**: `045-coach-positional-roster`

## 1. Existing Models Reused (No DB Schema Changes)

### 1.1 `TeamSquadRoster` (`lib/presentation/teams/models/team_squad_roster.dart`)
Modelo inmutable derivado de `TournamentTeam.players` mediante `TeamSquadRoster.fromCatalog`:
- `teamId` (`String`)
- `team` (`TournamentTeam?`)
- `goalkeepers` (`List<TeamSquadPlayerItem>`) — ordenado por `shirtNumber` ascendente
- `defenders` (`List<TeamSquadPlayerItem>`) — ordenado por `shirtNumber` ascendente
- `midfielders` (`List<TeamSquadPlayerItem>`) — ordenado por `shirtNumber` ascendente
- `forwards` (`List<TeamSquadPlayerItem>`) — ordenado por `shirtNumber` ascendente

### 1.2 `TeamSquadPlayerItem`
- `player` (`RegisteredPlayer`): `id`, `fullName`, `documentId`, `shirtNumber`, `position`, `isEligible`
- `isEligible` (`bool`): determina `"Elegible"` vs `"Inactivo / Sancionado"`

## 2. Tactical Ordering & Validation Rules

1. **Orden de bloques posicionales**:
   1. `PlayerPosition.goalkeeper` (`Porteros`)
   2. `PlayerPosition.defender` (`Defensas`)
   3. `PlayerPosition.midfielder` (`Mediocampistas`)
   4. `PlayerPosition.forward` (`Delanteros`)
2. **Orden interno por dorsal**: `a.shirtNumber.compareTo(b.shirtNumber)` ascendente.
3. **Alerta de balance táctico**: `roster.goalkeepers.isEmpty` activa la alerta preventiva visible por ausencia de porteros.
