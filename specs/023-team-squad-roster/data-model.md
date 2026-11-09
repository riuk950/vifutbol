# Data Model: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Feature**: `023-team-squad-roster`  
**Date**: 2026-11-09

---

## 1. Enumeración de Dominio Reutilizada: `PlayerPosition`

Ubicación existente: `lib/domain/entities/team_enums.dart`

| Valor | Orden de Bloque | Etiqueta de Bloque (`l10n`) | Etiqueta de Badge (`l10n`) |
|-------|-----------------|-----------------------------|----------------------------|
| `goalkeeper` | 1 | *"Porteros"* (`teamSquadGoalkeepersSectionTitle`) | *"Portero"* (`teamSquadPositionGoalkeeper`) |
| `defender` | 2 | *"Defensas"* (`teamSquadDefendersSectionTitle`) | *"Defensa"* (`teamSquadPositionDefender`) |
| `midfielder` | 3 | *"Centrocampistas"* (`teamSquadMidfieldersSectionTitle`) | *"Centrocampista"* (`teamSquadPositionMidfielder`) |
| `forward` | 4 | *"Delanteros"* (`teamSquadForwardsSectionTitle`) | *"Delantero"* (`teamSquadPositionForward`) |

---

## 2. Entidad de Ítem de Jugador en Plantilla: `TeamSquadPlayerItem`

Ubicación: `lib/presentation/teams/models/team_squad_roster.dart`

Agrupa un jugador inscrito (`RegisteredPlayer`) con el contexto de su club y su proyección `PlayerPerformanceProfile` lista para el modal de rendimiento.

### Atributos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `player` | `RegisteredPlayer` | Entidad de dominio inmutable del jugador inscrito (`id`, `fullName`, `documentId`, `shirtNumber`, `position`, `isEligible`). |
| `teamId` | `String` | Identificador del equipo al que pertenece. |
| `teamName` | `String` | Nombre oficial del equipo. |
| `teamShortCode` | `String` | Código corto del equipo (ej. `ATN`). |
| `tournamentId` | `String` | Identificador del torneo del equipo. |
| `performanceProfile` | `PlayerPerformanceProfile` | Proyección del perfil de rendimiento sincronizada con `isSuspended: !player.isEligible`. |

### Propiedades Derivadas

- `isEligible` (`bool`): `player.isEligible`.
- `shirtNumber` (`int`): `player.shirtNumber`.
- `fullName` (`String`): `player.fullName`.
- `position` (`PlayerPosition`): `player.position`.

---

## 3. Modelo de Proyección de Pestaña: `TeamSquadRoster`

Ubicación: `lib/presentation/teams/models/team_squad_roster.dart`

### Atributos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `teamId` | `String` | Identificador del equipo consultado. |
| `team` | `TournamentTeam?` | Entidad resuelta del equipo (`null` si no existe en el catálogo). |
| `goalkeepers` | `List<TeamSquadPlayerItem>` | Lista inmutable de porteros ordenados por `shirtNumber` ascendente. |
| `defenders` | `List<TeamSquadPlayerItem>` | Lista inmutable de defensas ordenados por `shirtNumber` ascendente. |
| `midfielders` | `List<TeamSquadPlayerItem>` | Lista inmutable de centrocampistas ordenados por `shirtNumber` ascendente. |
| `forwards` | `List<TeamSquadPlayerItem>` | Lista inmutable de delanteros ordenados por `shirtNumber` ascendente. |
| `allProfiles` | `List<PlayerPerformanceProfile>` | Lista inmutable de todos los perfiles de la plantilla ordenados por `shirtNumber` ascendente. |

### Propiedades Derivadas

- `totalPlayers` (`int`): `goalkeepers.length + defenders.length + midfielders.length + forwards.length`.
- `hasPlayers` (`bool`): `totalPlayers > 0`.
- `playersForPosition(PlayerPosition position)` (`List<TeamSquadPlayerItem>`): Retorna la lista inmutable correspondiente al bloque táctico solicitado.

---

## 4. Reglas Deterministas de Agrupación y Ordenamiento (`TeamSquadRoster.fromCatalog`)

1. **Resolución del Equipo**:
   - Se busca `TournamentTeam` en el catálogo donde `t.id == teamId`.
   - Si el equipo no existe o `team.players` está vacío, las 4 listas (`goalkeepers`, `defenders`, `midfielders`, `forwards`) y `allProfiles` se retornan vacías (`const []`).

2. **Ordenamiento por Dorsal (`shirtNumber`)**:
   - Se ordenan todos los jugadores de `team.players` mediante:
     1. `a.shirtNumber.compareTo(b.shirtNumber)` ascendente.
     2. Desempate determinista por `a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())` y luego `a.id.compareTo(b.id)`.

3. **Partición en los 4 Bloques Tácticos**:
   - `goalkeepers`: jugadores con `position == PlayerPosition.goalkeeper`.
   - `defenders`: jugadores con `position == PlayerPosition.defender`.
   - `midfielders`: jugadores con `position == PlayerPosition.midfielder`.
   - `forwards`: jugadores con `position == PlayerPosition.forward`.
   - Cada sublista preserva el orden ascendente por `shirtNumber`.
