# Contract: Cierre Histórico de Temporada y Cuadro de Honor Oficial

**Feature**: `012-backup-restore-season-closure`  
**Layer**: Domain & Application (`lib/domain/repositories/season_honor_roll_repository.dart`, `lib/application/use_cases/close_tournament_season_use_case.dart`)

---

## 1. Repository Contract (`SeasonHonorRollRepository`)

```dart
abstract interface class SeasonHonorRollRepository {
  /// Loads the persisted official honor roll for [tournamentId], if the season was closed.
  Future<SeasonHonorRoll?> loadHonorRollForTournament(String tournamentId);

  /// Persists or updates the official [SeasonHonorRoll] for its tournament.
  Future<SeasonHonorRoll> saveHonorRoll(SeasonHonorRoll honorRoll);

  /// Removes any honor roll associated with [tournamentId] (used if restoring an in-progress backup).
  Future<void> deleteHonorRollForTournament(String tournamentId);
}
```

---

## 2. Use Case Contract (`CloseTournamentSeasonUseCase`)

```dart
class CloseTournamentSeasonUseCase {
  /// Previews the calculated [SeasonHonorRoll] if the tournament is eligible for closure,
  /// or throws [TournamentValidationFailure] if mandatory matches are still pending.
  Future<SeasonHonorRoll> previewHonorRoll({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  });

  /// Officially closes the tournament season (`TournamentStatus.finished`),
  /// persists the [SeasonHonorRoll], and locks the tournament in permanent historical read-only mode.
  Future<SeasonHonorRoll> closeSeason({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    required bool isTwoStepConfirmed,
  });
}
```

### Reglas de Contrato:
1. **Autorización RBAC**: Exclusivo para `UserRole.organizer`. Cualquier otro rol recibe `UnauthorizedRoleFailure`.
2. **Validación de Partidos Completados**:
   - El torneo debe contar con al menos 2 equipos elegibles y al menos 1 partido finalizado (`MatchStatus.completed`).
   - En formato `TournamentFormat.league`: **todos** los partidos registrados en el calendario del campeonato deben estar en estado `MatchStatus.completed`.
   - En formato `TournamentFormat.knockoutCup` o `TournamentFormat.mixedGroupsAndKnockout`: el partido correspondiente a la Gran Final (`KnockoutRound.finalMatch`) debe existir y estar en estado `MatchStatus.completed` (y ningún partido obligatorio puede estar `inProgress`).
   - Si no se cumple, lanza `TournamentValidationFailure` en español indicando que aún existen partidos pendientes por finalizar.
3. **Confirmación de 2 pasos**: `closeSeason` exige `isTwoStepConfirmed == true`.
4. **Inmutabilidad Post-Cierre**: Una vez cerrado (`TournamentStatus.finished`), las operaciones de escritura sobre el torneo, equipos, fixture y noticias quedan bloqueadas con mensaje explicativo en español.
