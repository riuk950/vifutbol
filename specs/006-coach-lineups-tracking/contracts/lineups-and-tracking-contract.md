# Interface & Storage Contracts: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Feature**: `006-coach-lineups-tracking`  
**Date**: 2026-11-04

## 1. Repository Contract (`lib/domain/repositories/lineups_tracking_repository.dart`)

```dart
abstract class LineupsTrackingRepository {
  Future<List<PlayerInternalTracking>> loadTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  );

  Future<PlayerInternalTracking> savePlayerTracking(
    PlayerInternalTracking tracking,
  );

  Future<MatchLineupConvocation> loadConvocationForTeam(
    String tournamentId,
    String teamId,
  );

  Future<MatchLineupConvocation> saveConvocation(
    MatchLineupConvocation convocation,
  );
}
```

### Storage Keys (`LocalLineupsTrackingRepository`)
- Tracking storage key: `'vifutbol.lineups.tracking.v1'`
- Convocations storage key: `'vifutbol.lineups.convocations.v1'`
- Seed data in `AppEnvironment.development`:
  - Para `'team-seed-atletico-norte'` (`10` jugadores inscritos en plantilla):
    - `p-seed-atn-8` (`Wilmar Barrios`, dorsal `6`): `pendingSuspensionMatches: 1`, `redCards: 1`, `yellowCards: 2` → Aparece como `"Suspendido (1 fecha)"` (`#EF4444`) con control de selección deshabilitado.
    - `p-seed-atn-2` (`Yerry Mina`, dorsal `4`): `yellowCards: 2` (a 1 amarilla del límite `3`) → Aparece con insignia de advertencia `"En capilla (2 TA)"` (`#F59E0B`), habilitado para convocar.
    - Métricas realistas de partidos jugados, goles y asistencias para `Falcao`, `James Rodríguez`, `Luis Díaz`, `David Ospina`, etc.

---

## 2. Use Case Contract (`lib/application/use_cases/manage_lineups_tracking_use_case.dart`)

- `int requiredStartersForTournament(ChampionshipTournament tournament)` → Retorna `min(tournament.rules.minPlayersPerTeam, 11)`.
- `Future<MatchLineupConvocation> updateDraftSelection({...})`:
  - Verifica permisos (`RoleCapability.manageLineups` o `RoleCapability.manageTournaments`).
  - Verifica que ningún jugador en `starterPlayerIds` ni `substitutePlayerIds` esté suspendido según `tracking` y `tournament.rules.yellowCardSuspensionLimit` (si se intenta agregar un jugador suspendido, lanza `LineupConvocationValidationFailure` con `LineupConvocationErrorCode.suspendedPlayerSelected`).
  - Garantiza que `starterPlayerIds` y `substitutePlayerIds` sean disjuntos y que `captainPlayerId` pertenezca a `starterPlayerIds` (si se mueve a suplente o no convocado, limpia `captainPlayerId`).
  - Guarda inmediatamente el borrador en `LineupsTrackingRepository` para preservar el estado ante interrupciones móviles (`FR-006`).
- `Future<MatchLineupConvocation> confirmOfficialConvocation({...})`:
  - Verifica permisos (`Entrenador` u `Organizador`).
  - Verifica que el equipo esté `"Habilitado"` (`TeamEligibilityStatus.eligible`).
  - Verifica que ningún jugador seleccionado esté suspendido.
  - Verifica que `starterPlayerIds.length == requiredStartersForTournament(tournament)`.
  - Verifica que `captainPlayerId != null && starterPlayerIds.contains(captainPlayerId)`.
  - Persiste la convocatoria con `status: ConvocationStatus.confirmed`, copiando `starterPlayerIds`, `substitutePlayerIds` y `captainPlayerId` a los campos `confirmed*` visibles en el acta arbitral del `Árbitro`.
- `Future<PlayerInternalTracking> updatePlayerInternalTracking({...})`:
  - Verifica permisos (`Entrenador` u `Organizador`) y valores no negativos.
  - Si el jugador actualizado queda en estado `suspended`, lo remueve automáticamente de cualquier selección de titular/suplente/capitán en el borrador activo del equipo.

---

## 3. UI & Routing Contract

- **Route**: `/tournaments/teams/lineup` (`AppRouter.teamLineupTrackingPath`) → `CoachLineupTrackingScreen`.
- **Entry Point**: Botón en `TeamRosterDetailScreen` con `Key('open_team_lineup_tracking_button')`.
- **Visual & Accessibility Requirements (`DESIGN.md` & `docs/MOBILE_GUIDELINES.md`)**:
  - Jugador suspendido: Insignia semántica `KickPulseBadgeVariant.live` (`#EF4444`) con texto explícito `"Suspendido ({count} fecha)"` / `"Suspendido ({count} fechas)"` e ícono de bloqueo; controles de selección (`Titular`, `Suplente`, `Capitán`) deshabilitados (`onPressed: null`).
  - Jugador en riesgo de amarillas: Insignia semántica `KickPulseBadgeVariant.warning` (`#F59E0B`) con texto explícito `"En capilla ({yellowCards} TA)"`.
  - Conservación de estado móvil: Uso de `WidgetsBindingObserver` + persistencia inmediata del borrador en `LineupsTrackingController` al seleccionar/deseleccionar titulares, suplentes o capitán.
