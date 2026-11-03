# UI & Persistence Contracts: Creación de Campeonatos y Reglas Personalizadas (HU 4.1)

**Feature**: `004-tournaments-custom-rules`  
**Date**: 2026-04-17

## 1. Repository Contract (`TournamentsRepository`)

**Path**: `lib/domain/repositories/tournaments_repository.dart`

```dart
abstract interface class TournamentsRepository {
  Future<List<ChampionshipTournament>> loadTournaments();
  Future<ChampionshipTournament> saveTournament(ChampionshipTournament tournament);
  Future<TournamentDraft?> loadDraft();
  Future<void> saveDraft(TournamentDraft draft);
  Future<void> clearDraft();
}
```

### Persistence Keys (`LocalTournamentsRepository`)
- **Catalog Key**: `'vifutbol.tournaments.catalog.v1'` (JSON array of `ChampionshipTournament` records).
- **Creation Draft Key**: `'vifutbol.tournaments.creation_draft.v1'` (JSON object of `TournamentDraft`).
- **Development Seeds (`AppEnvironment.dev`)**:
  1. `"Liga Clausura ViFutbol 2026"` (`TournamentFormat.league`, `TournamentStatus.openRegistration`, `2` vueltas, `3/1/0` puntos, suspensión a `3` amarillas, `7..18` jugadores, `45` min).
  2. `"Copa Relámpago Nocturna"` (`TournamentFormat.knockoutCup`, `TournamentStatus.inProgress`, llaves desde `Cuartos de Final`, partido único, desempate directo por penales activado, suspensión a `2` amarillas, `6..14` jugadores, `30` min).
  3. `"Torneo Metropolitano Mixto"` (`TournamentFormat.mixedGroupsAndKnockout`, `TournamentStatus.openRegistration`, `4` grupos de `2` clasificados + llaves desde `Cuartos de Final`).

## 2. Application Use Case Contract (`ManageTournamentsUseCase`)

**Path**: `lib/application/use_cases/manage_tournaments_use_case.dart`

- `validateAndPrepareTournament(...)`:
  - Verifica permiso `RolePermissionMatrix.hasCapability(actorRole, RoleCapability.manageTournaments)` → lanza `UnauthorizedActionFailure` si no es `Organizador`.
  - Valida nombre (`>= 3` caracteres), categoría no vacía, `!endDate.isBefore(startDate)`.
  - Valida invariantes de `TournamentRulesConfig`:
    - `pointsForWin > pointsForDraw && pointsForDraw >= pointsForLoss && pointsForLoss >= 0`
    - `tiebreakerOrder` no vacío y sin duplicados
    - `yellowCardSuspensionLimit` entre `2` y `10`
    - `minPlayersPerTeam >= 5 && maxPlayersPerTeam >= minPlayersPerTeam && maxPlayersPerTeam <= 35`
    - `halfDurationMinutes` entre `10` y `60`
    - `leagueRounds == 1 || leagueRounds == 2`
    - `groupStageConfig.groupCount` entre `2` y `8`, `advancingPerGroup` entre `1` y `4`
  - Si se edita un campeonato existente:
    - Si `existing.status == TournamentStatus.finished`, lanza `TournamentValidationFailure(TournamentValidationErrorCode.tournamentAlreadyFinished)`.
    - Si `existing.status == TournamentStatus.inProgress` y cambió `format`, `pointsForWin`, `pointsForDraw` o `pointsForLoss`:
      - Si `!confirmCriticalRuleOverride || auditReason == null || auditReason.trim().isEmpty`, lanza `TournamentValidationFailure(TournamentValidationErrorCode.criticalRulesImmutableWithoutAudit)`.
      - Si está confirmado con motivo válido, genera y adjunta un `RuleAuditEntry` con el resumen de los cambios anteriores → nuevos.

## 3. Routing & UI Contract

### Routes (`AppRouter`)
- `/standings`: Abre `AppShellScreen(initialSection: AppShellSection.standings)` mostrando `StandingsTabView`.
- `/tournaments/form`: Abre `TournamentFormScreen` (creación de campeonato nuevo o edición si recibe `ChampionshipTournament` en `RouteSettings.arguments`).

### Role Segregation & Mobile UX
- **Todos los roles**:
  - Visualizan en `StandingsTabView` los filtros por formato (`Todos`, `Liga`, `Copa Eliminatoria`, `Mixto`), la lista de campeonatos y el panel detallado de normativa oficial del campeonato seleccionado (puntuación, orden de criterios de desempate, estructura de llaves eliminatorias/grupos, límite de amarillas, cupo de jugadores, duración por tiempo e historial de auditoría).
- **Exclusivo `Organizador` (`RoleCapability.manageTournaments`)**:
  - Botón primario/acción `"Crear Campeonato"` y banner de borrador pendiente si `hasSavedDraft == true`.
  - Botón `"Editar Reglas"` y acción de cambio de estado (`"Iniciar Campeonato"` / `"Finalizar Campeonato"`) cuando el torneo no está `Finalizado`.
  - En `TournamentFormScreen`:
    - Reordenamiento interactivo de criterios de desempate (botones subir/bajar prioridad).
    - Diálogo de confirmación administrativa con campo obligatorio de motivo cuando se edita el formato o el sistema de puntuación de un campeonato `En Curso`.
    - Diálogo `"¿Deseas descartar los cambios o guardar como borrador?"` al intentar retroceder con cambios sin guardar (`PopScope`).
