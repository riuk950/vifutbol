# Data Model: Panel del Árbitro y Gestión Completa del Partido

**Feature**: `059-referee-panel-match-management` (HU 26.1)
**Date**: 2026-11-25

## 1. Relational Schema Changes (`vifutboldev`)

### Table: `vifutboldev.match_reports`

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `referee_observations` *(new)* | `text` | YES | `NULL` | Observaciones arbitrales generales del encuentro (incidencias, estado de cancha, comportamiento, etc.), editables antes del cierre oficial y de solo lectura tras cerrar el acta. |

*Migración idempotente*: `supabase/migrations/202611250004_match_report_referee_observations.sql` (`ALTER TABLE IF EXISTS vifutboldev.match_reports ADD COLUMN IF NOT EXISTS referee_observations text; NOTIFY pgrst, 'reload schema';`).

## 2. Domain Entities Updates

### `DigitalMatchReport`
- Nuevo campo opcional: `final String? refereeObservations;`
- Incluido en `copyWith({String? refereeObservations, bool clearRefereeObservations = false})`, `toJson()` (`'refereeObservations': refereeObservations`) y `fromJson(Map<String, dynamic>)` (leyendo `'refereeObservations' ?? 'referee_observations'`).

### `DigitalMatchReportState`
- Nuevos campos booleanos con default `true` (compatibles con llamadas existentes):
  - `final bool homeConvocationConfirmed;`
  - `final bool awayConvocationConfirmed;`
- Getter derivado: `bool get hasUnconfirmedConvocation => !homeConvocationConfirmed || !awayConvocationConfirmed;`

### `RefereeMatchFilter` (Enum en `referee_assigned_matches_service.dart`)
- `all` (`Todos`)
- `inProgress` (`En juego`)
- `scheduled` (`Programados`)
- `completed` (`Finalizados`)

## 3. Matching, Ordering & Ownership Rules

1. **Emparejamiento de designaciones (`RefereeAssignedMatchesService.isAssignedToReferee`)**:
   - Identificadores válidos del árbitro: `{linkedRefereeId, userId}` (trim, no vacíos).
   - Un partido está asignado al árbitro si `match.refereeId != null && validIds.contains(match.refereeId!.trim())`.
2. **Ordenamiento operativo (`RefereeAssignedMatchesService.sortOperational`)**:
   - Prioridad de estado:
     - `0`: `MatchStatus.inProgress` (desempate: `scheduledStartTime` ascendente)
     - `1`: `MatchStatus.scheduled`, `MatchStatus.pending` (desempate: `scheduledStartTime` ascendente; nulos al final)
     - `2`: `MatchStatus.completed`, `MatchStatus.cancelled` (desempate: `scheduledStartTime ?? updatedAt` descendente)
3. **Propiedad de edición del acta**:
   - Permitido si `activeRole == UserRole.organizer` (con `RoleCapability.manageTournaments`).
   - Permitido si `activeRole == UserRole.referee` Y (`match.refereeId == null` O `isAssignedToReferee(match, userId: actorUserId, linkedRefereeId: actorRefereeId)`).
   - Bloqueado en caso contrario (modo solo lectura + error `MatchReportErrorCode.unauthorizedRole` en caso de intento de mutación).

## 4. State Transitions (Match Lifecycle)

1. **`Programado` (`MatchStatus.scheduled`, `MatchPeriod.notStarted`)** → árbitro inicia partido (`transitionPeriod(MatchPeriod.firstHalf)`):
   - Actualiza `ChampionshipMatch.status = MatchStatus.inProgress` (guardado local + outbox/Supabase vía `HybridTournamentMatchesRepository.saveMatch`).
   - Crea evento `MatchEventType.periodTransition` y guarda `DigitalMatchReport` (local + nube).
2. **`En juego` (`MatchStatus.inProgress`)**:
   - Registra goles, asistencias, amarillas, doble amarilla → roja automática, roja directa, sustituciones, transiciones (`halfTime`, `secondHalf`, `extraTimeFirstHalf`, `extraTimeSecondHalf`, `penalties`) y `refereeObservations`.
   - Todas las mutaciones tienen guarda `if (state.isSubmitting) return false;` (`single-flight`).
3. **`Finalizado` (`MatchStatus.completed`, `MatchPeriod.closed`, `closedAt != null`)**:
   - Árbitro confirma diálogo de cierre → `closeOfficialMatchReport` persiste `MatchStatus.completed` + marcador definitivo + `closedAt`/`closedByUserId` + actualiza llaves/clasificación.
   - El acta queda inmutable (`report.isClosed == true`, `canEdit == false`).
   - Al volver a `RefereePanelContent`, el panel recarga el catálogo y refleja `Finalizado` y el marcador final.
