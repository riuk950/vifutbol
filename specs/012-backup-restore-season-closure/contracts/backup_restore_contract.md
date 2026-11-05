# Contract: Exportación, Validación e Importación de Respaldos de Campeonato

**Feature**: `012-backup-restore-season-closure`  
**Layer**: Domain & Application (`lib/domain/repositories/`, `lib/application/use_cases/`)

---

## 1. Repository Extensions for Atomic Per-Tournament Restoration

Cada repositorio de dominio expone un método para reemplazar las entidades asociadas a un `tournamentId` específico sin alterar otros campeonatos:

```dart
// lib/domain/repositories/teams_repository.dart
Future<void> replaceTeamsForTournament(
  String tournamentId,
  List<TournamentTeam> teams,
);

// lib/domain/repositories/tournament_matches_repository.dart
Future<void> replaceMatchesForTournament(
  String tournamentId,
  List<ChampionshipMatch> matches,
);

// lib/domain/repositories/match_reports_repository.dart
Future<void> replaceReportsForTournament(
  String tournamentId,
  List<DigitalMatchReport> reports,
);

// lib/domain/repositories/tournament_news_repository.dart
Future<void> replaceNewsForTournament(
  String tournamentId,
  List<TournamentNewsItem> items,
);
```

---

## 2. Use Cases (`lib/application/use_cases/tournament_backup_use_cases.dart`)

```dart
/// Exports a complete, schema-versioned backup package for a single tournament.
class ExportTournamentBackupUseCase {
  Future<TournamentBackupPackage> execute({
    required String tournamentId,
    required UserRole actorRole,
  });
}

/// Validates a raw JSON backup string before any storage modification.
class ValidateTournamentBackupUseCase {
  static const String invalidBackupMessage =
      'El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.';

  BackupValidationResult execute(String rawJson);
}

/// Atomically restores a validated TournamentBackupPackage for a single tournament
/// after explicit two-step confirmation by the Organizer.
class ImportTournamentBackupUseCase {
  Future<ChampionshipTournament> execute({
    required String rawJson,
    required UserRole actorRole,
    required bool isTwoStepConfirmed,
  });
}
```

### Reglas de Contrato:
1. **Autorización RBAC**: Si `actorRole != UserRole.organizer`, `ExportTournamentBackupUseCase` e `ImportTournamentBackupUseCase` lanzan `UnauthorizedRoleFailure`.
2. **Confirmación de 2 pasos**: Si `isTwoStepConfirmed == false` en `ImportTournamentBackupUseCase`, lanza `TournamentValidationFailure` indicando que se requiere confirmación explícita.
3. **Transaccionalidad y Rechazo Seguro**: `ImportTournamentBackupUseCase` invoca primero `ValidateTournamentBackupUseCase`. Si `result.isValid == false`, aborta antes de llamar a cualquier repositorio y lanza `TournamentValidationFailure` con el mensaje exacto:
   `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."`
