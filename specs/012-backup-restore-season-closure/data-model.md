# Data Model: Exportación e Importación de Respaldos y Cierre Histórico de Temporada (HU 9.2)

**Feature**: `012-backup-restore-season-closure`  
**Date**: 2026-11-05

---

## 1. Entities & Value Objects

### 1.1 `SeasonHonorRoll` (`lib/domain/entities/season_honor_roll.dart`)
Representa el Cuadro de Honor oficial e inmutable generado al clausurar un campeonato (`TournamentStatus.finished`).

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `tournamentId` | `String` | Yes | ID del campeonato clausurado. |
| `tournamentName` | `String` | Yes | Nombre oficial del campeonato al momento del cierre. |
| `closedAt` | `DateTime` | Yes | Fecha y hora UTC del cierre oficial de temporada. |
| `championTeamId` | `String` | Yes | ID del equipo Campeón. |
| `championTeamName` | `String` | Yes | Nombre del equipo Campeón. |
| `championShortCode` | `String` | Yes | Código corto del equipo Campeón. |
| `runnerUpTeamId` | `String` | Yes | ID del equipo Subcampeón. |
| `runnerUpTeamName` | `String` | Yes | Nombre del equipo Subcampeón. |
| `runnerUpShortCode` | `String` | Yes | Código corto del equipo Subcampeón. |
| `topScorerPlayerId` | `String?` | No | ID del jugador Máximo Goleador (`null` si no hubo goles en el torneo). |
| `topScorerPlayerName` | `String?` | No | Nombre del jugador Máximo Goleador (`null` si no hubo goles). |
| `topScorerTeamName` | `String?` | No | Nombre del equipo del Máximo Goleador. |
| `topScorerGoals` | `int` | Yes | Cantidad de goles anotados por el Máximo Goleador (`0` si vacante). |
| `bestDefenseTeamId` | `String` | Yes | ID del equipo con la Valla Menos Vencida. |
| `bestDefenseTeamName` | `String` | Yes | Nombre del equipo con la Valla Menos Vencida. |
| `bestDefenseShortCode` | `String` | Yes | Código corto del equipo con la Valla Menos Vencida. |
| `bestDefenseGoalsAgainst` | `int` | Yes | Total de goles recibidos por la Valla Menos Vencida (`>= 0`). |

**Invariantes de Validación**:
- `tournamentId`, `championTeamId`, `runnerUpTeamId` y `bestDefenseTeamId` no pueden estar vacíos.
- `championTeamId != runnerUpTeamId`.
- `topScorerGoals >= 0` y `bestDefenseGoalsAgainst >= 0`.
- `hasTopScorer`: `topScorerPlayerId != null && topScorerGoals > 0`.

---

### 1.2 `TournamentBackupPackage` (`lib/domain/entities/tournament_backup_package.dart`)
Paquete autónomo y serializable a JSON que encapsula el estado íntegro de un campeonato para exportación e importación.

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `formatSignature` | `String` | Yes | Constante `"vifutbol.tournament_backup"`. |
| `schemaVersion` | `int` | Yes | Versión del esquema de respaldo (actual: `1`). |
| `exportedAt` | `DateTime` | Yes | Fecha y hora UTC de generación del respaldo. |
| `tournament` | `ChampionshipTournament` | Yes | Raíz del campeonato con sus reglas y bitácora de auditoría. |
| `teams` | `List<TournamentTeam>` | Yes | Equipos inscritos con su lista anidada de `RegisteredPlayer`. |
| `matches` | `List<ChampionshipMatch>` | Yes | Partidos del calendario del campeonato. |
| `matchReports` | `List<DigitalMatchReport>` | Yes | Actas digitales y eventos oficiales (`MatchEvent`) de los partidos. |
| `newsItems` | `List<TournamentNewsItem>` | Yes | Comunicados y boletines oficiales del campeonato. |
| `honorRoll` | `SeasonHonorRoll?` | No | Cuadro de honor oficial (presente si `tournament.status == TournamentStatus.finished`). |

**Propiedades calculadas**:
- `suggestedFileName`: `'respaldo_${tournament.id}_${exportedAt.year}${exportedAt.month.toString().padLeft(2, '0')}${exportedAt.day.toString().padLeft(2, '0')}.json'`
- `totalPlayersCount`: suma de `team.players.length` en `teams`.

---

### 1.3 `BackupValidationResult` (`lib/domain/entities/backup_validation_result.dart`)
Resultado inmutable de la validación estructural, de versión y de integridad referencial de un archivo de respaldo antes de su restauración.

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `isValid` | `bool` | Yes | `true` si el respaldo superó todas las validaciones; `false` en caso contrario. |
| `errorMessage` | `String?` | No | Mensaje de error en español cuando `isValid == false`: `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."` |
| `package` | `TournamentBackupPackage?` | No | Paquete validado listo para restaurar cuando `isValid == true`. |

---

## 2. JSON Schema Example (`TournamentBackupPackage`)

```json
{
  "formatSignature": "vifutbol.tournament_backup",
  "schemaVersion": 1,
  "exportedAt": "2026-11-05T15:30:00.000Z",
  "tournament": {
    "id": "t-liga-apertura-2026",
    "name": "Liga Apertura Barrial 2026",
    "category": "Libre Masculino",
    "startDate": "2026-03-01T00:00:00.000",
    "endDate": "2026-06-30T00:00:00.000",
    "format": "league",
    "status": "finished",
    "rules": {},
    "auditTrail": [],
    "updatedAt": "2026-06-30T20:00:00.000Z"
  },
  "teams": [],
  "matches": [],
  "matchReports": [],
  "newsItems": [],
  "honorRoll": {
    "tournamentId": "t-liga-apertura-2026",
    "tournamentName": "Liga Apertura Barrial 2026",
    "closedAt": "2026-06-30T20:00:00.000Z",
    "championTeamId": "team-1",
    "championTeamName": "Atlético Norte",
    "championShortCode": "ATN",
    "runnerUpTeamId": "team-2",
    "runnerUpTeamName": "Deportivo Sur",
    "runnerUpShortCode": "DPS",
    "topScorerPlayerId": "p-10",
    "topScorerPlayerName": "Carlos Valderrama",
    "topScorerTeamName": "Atlético Norte",
    "topScorerGoals": 12,
    "bestDefenseTeamId": "team-1",
    "bestDefenseTeamName": "Atlético Norte",
    "bestDefenseShortCode": "ATN",
    "bestDefenseGoalsAgainst": 4
  }
}
```

---

## 3. Storage Keys (`LocalStorageRepository`)

- `vifutbol.season_honor_rolls.v1`: Mapa JSON (`Map<String, dynamic>`) indexado por `tournamentId` con los objetos `SeasonHonorRoll` persistidos localmente.
- Los repositorios existentes (`LocalTournamentsRepository`, `LocalTeamsRepository`, `LocalTournamentMatchesRepository`, `LocalMatchReportsRepository`, `LocalTournamentNewsRepository`) exponen métodos de reemplazo por `tournamentId` para soportar la restauración atómica de un `TournamentBackupPackage`.
