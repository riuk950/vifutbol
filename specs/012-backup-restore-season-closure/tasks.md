# Tasks: Exportación e Importación de Respaldos (Backup/Restore) y Cierre Histórico de Temporada (HU 9.2)

**Input**: Design documents from `/specs/012-backup-restore-season-closure/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Localization strings in Spanish for backups, validation errors, two-step confirmations, season closure, and the official Honor Roll

- [X] T001 Add localized strings in `lib/l10n/app_es.arb` (including exact error message `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."` and `"Sin goles registrados"`) and regenerate localization classes via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, repository contracts, and atomic per-tournament replacement methods that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Implement `SeasonHonorRoll` entity with validation invariants (`tournamentId`, `championTeamId`, `runnerUpTeamId`, `bestDefenseTeamId` non-empty, `championTeamId != runnerUpTeamId`, `topScorerGoals >= 0`, `bestDefenseGoalsAgainst >= 0`, `hasTopScorer`) and JSON serialization in `lib/domain/entities/season_honor_roll.dart`
- [X] T003 [P] Implement `TournamentBackupPackage` entity (`formatSignature: "vifutbol.tournament_backup"`, `schemaVersion: 1`, `exportedAt`, `tournament`, `teams`, `matches`, `matchReports`, `newsItems`, `honorRoll`, `suggestedFileName`, `totalPlayersCount`, JSON serialization) in `lib/domain/entities/tournament_backup_package.dart`
- [X] T004 [P] Implement `BackupValidationResult` entity (`isValid`, `errorMessage`, `package`) in `lib/domain/entities/backup_validation_result.dart`
- [X] T005 [P] Unit tests for `SeasonHonorRoll`, `TournamentBackupPackage`, and `BackupValidationResult` invariants and JSON serialization in `test/unit/domain/backup_and_honor_roll_entities_test.dart`
- [X] T006 [P] Define `SeasonHonorRollRepository` contract (`loadHonorRollForTournament`, `saveHonorRoll`, `deleteHonorRollForTournament`) in `lib/domain/repositories/season_honor_roll_repository.dart`
- [X] T007 [P] Implement `LocalSeasonHonorRollRepository` with persistence in `vifutbol.season_honor_rolls.v1` in `lib/infrastructure/repositories/local_season_honor_roll_repository.dart`
- [X] T008 [P] Extend `TeamsRepository` and `LocalTeamsRepository` with `replaceTeamsForTournament(String tournamentId, List<TournamentTeam> teams)` in `lib/domain/repositories/teams_repository.dart` and `lib/infrastructure/repositories/local_teams_repository.dart`
- [X] T009 [P] Extend `TournamentMatchesRepository` and `LocalTournamentMatchesRepository` with `replaceMatchesForTournament(String tournamentId, List<ChampionshipMatch> matches)` in `lib/domain/repositories/tournament_matches_repository.dart` and `lib/infrastructure/repositories/local_tournament_matches_repository.dart`
- [X] T010 [P] Extend `MatchReportsRepository` and `LocalMatchReportsRepository` with `replaceReportsForTournament(String tournamentId, List<DigitalMatchReport> reports)` in `lib/domain/repositories/match_reports_repository.dart` and `lib/infrastructure/repositories/local_match_reports_repository.dart`
- [X] T011 [P] Extend `TournamentNewsRepository` and `LocalTournamentNewsRepository` with `replaceNewsForTournament(String tournamentId, List<TournamentNewsItem> items)` in `lib/domain/repositories/tournament_news_repository.dart` and `lib/infrastructure/repositories/local_tournament_news_repository.dart`
- [X] T012 [P] Extend `TournamentValidationErrorCode` in `lib/domain/failures/app_failure.dart` with codes for invalid backup, missing two-step confirmation, and pending mandatory matches before season closure

**Checkpoint**: Foundation ready - User Story 1, 2, and 3 implementation can proceed.

---

## Phase 3: User Story 1 - Exportación e Importación Validada de Respaldos del Campeonato (Priority: P1) 🎯 MVP

**Goal**: Permitir al `Organizador` exportar un respaldo completo del campeonato con versión de esquema (`schemaVersion: 1`), validar la integridad estructural y referencial cruzada de archivos importados (rechazando archivos corruptos sin alterar datos locales) y restaurar de forma aislada (`upsert`) tras confirmación de seguridad de dos pasos.

**Independent Test**: Como `Organizador`, exportar un respaldo completo de un torneo, verificar que un JSON corrupto o con referencias huérfanas es rechazado con `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."` sin modificar la base de datos local, y restaurar un paquete válido tras confirmar la casilla de seguridad de dos pasos.

### Implementation for User Story 1

- [X] T013 [P] [US1] Implement `ExportTournamentBackupUseCase`, `ValidateTournamentBackupUseCase`, and `ImportTournamentBackupUseCase` in `lib/application/use_cases/tournament_backup_use_cases.dart`
- [X] T014 [P] [US1] Unit tests for backup export, corrupted/orphan reference rejection, RBAC guard, two-step confirmation requirement, and isolated tournament `upsert` restoration in `test/unit/application/tournament_backup_use_cases_test.dart`
- [X] T015 [P] [US1] Implement `TournamentBackupSheet` modal bottom sheet (export summary, copy/save action, import JSON input, validation preview, and two-step confirmation checkbox) in `lib/presentation/tournaments/widgets/tournament_backup_sheet.dart`
- [X] T016 [US1] Implement `BackupAndSeasonClosureController` and providers for backup export/validation/import in `lib/application/controllers/backup_and_season_closure_controller.dart` and `lib/application/providers/backup_and_season_closure_providers.dart`
- [X] T017 [US1] Add organizer-only "Respaldo del torneo" action button to `TournamentRulesSummaryCard` in `lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart` and wire it in `lib/presentation/shell/tabs/standings_tab_view.dart`
- [X] T018 [US1] Widget tests for backup export modal, corrupted backup error message, and two-step confirmed restoration in `test/widget/tournament_backup_restore_widget_test.dart`

**Checkpoint**: User Story 1 (MVP) is fully functional and independently testable.

---

## Phase 4: User Story 2 - Cierre Oficial de Temporada y Publicación del Cuadro de Honor (Priority: P2)

**Goal**: Permitir al `Organizador` cerrar oficialmente el campeonato cuando todos los partidos obligatorios o la gran final estén en estado `Finalizado`, exigiendo confirmación de seguridad de dos pasos y publicando el Cuadro de Honor oficial (Campeón, Subcampeón, Máximo Goleador y Valla Menos Vencida) para todos los roles.

**Independent Test**: Configurar un campeonato con sus partidos finalizados, ejecutar "Finalizar Campeonato" como `Organizador`, verificar la vista previa del Cuadro de Honor y la casilla de confirmación de dos pasos, confirmar el cierre y comprobar que el estado cambia a `Finalizado` y el Cuadro de Honor se muestra públicamente a todos los roles.

### Implementation for User Story 2

- [X] T019 [P] [US2] Implement `CloseTournamentSeasonUseCase` (`previewHonorRoll` and `closeSeason` with deterministic Champion, Runner-Up, Top Scorer, and Best Defense calculation) in `lib/application/use_cases/close_tournament_season_use_case.dart`
- [X] T020 [P] [US2] Unit tests for `CloseTournamentSeasonUseCase` (league and knockout closure, rejection when matches are pending, deterministic tiebreakers, and `"Sin goles registrados"` fallback) in `test/unit/application/close_tournament_season_use_case_test.dart`
- [X] T021 [P] [US2] Integrate `previewHonorRoll`, `closeSeason`, and `SeasonHonorRoll` loading into `BackupAndSeasonClosureController` in `lib/application/controllers/backup_and_season_closure_controller.dart` and `lib/application/providers/backup_and_season_closure_providers.dart`
- [X] T022 [P] [US2] Implement `SeasonClosureConfirmationDialog` with Honor Roll preview and mandatory two-step confirmation checkbox in `lib/presentation/tournaments/widgets/season_closure_confirmation_dialog.dart`
- [X] T023 [P] [US2] Implement `SeasonHonorRollCard` displaying Champion, Runner-Up, Top Scorer, and Best Defense in `lib/presentation/standings/widgets/season_honor_roll_card.dart`
- [X] T024 [US2] Wire "Finalizar Campeonato" button and `SeasonHonorRollCard` display into `lib/presentation/shell/tabs/standings_tab_view.dart`
- [X] T025 [US2] Widget tests for season closure two-step dialog, pending matches error notice, and `SeasonHonorRollCard` visibility across roles in `test/widget/season_closure_honor_roll_widget_test.dart`

**Checkpoint**: User Stories 1 and 2 are both functional and independently testable.

---

## Phase 5: User Story 3 - Protección Histórica en Modo de Solo Lectura Permanente (Priority: P3)

**Goal**: Garantizar que todo campeonato en estado `Finalizado` bloquee permanentemente cualquier modificación operativa (reglas, equipos, jugadores, fixture y noticias) mientras preserva el modo de consulta histórica y la exportación de respaldo.

**Independent Test**: En un campeonato `Finalizado`, intentar inscribir un equipo/jugador, generar o reprogramar fixture, o publicar/eliminar una noticia y verificar que los casos de uso rechazan la operación y la interfaz muestra el aviso de solo lectura histórica manteniendo habilitado "Respaldo del torneo".

### Implementation for User Story 3

- [X] T026 [P] [US3] Enforce `TournamentStatus.finished` read-only guard in `ManageTeamsEligibilityUseCase` (`lib/application/use_cases/manage_teams_eligibility_use_case.dart`), `FixtureSchedulingUseCase` (`lib/application/use_cases/fixture_scheduling_use_case.dart`), and `PublishTournamentNewsUseCase` / `DeleteTournamentNewsUseCase` (`lib/application/use_cases/manage_tournament_news_use_cases.dart`)
- [X] T027 [P] [US3] Update `TournamentRulesSummaryCard` (`lib/presentation/tournaments/widgets/tournament_rules_summary_card.dart`), `TournamentTeamsSection` (`lib/presentation/teams/widgets/tournament_teams_section.dart`), and `TournamentNewsFeedView` (`lib/presentation/news/tournament_news_feed_view.dart`) to hide write actions and display the historical read-only badge when `tournament.status == TournamentStatus.finished` while keeping backup export enabled for the organizer
- [X] T028 [US3] Add unit and widget test assertions verifying permanent historical read-only protection on finished tournaments in `test/unit/application/close_tournament_season_use_case_test.dart` and `test/widget/season_closure_honor_roll_widget_test.dart`

**Checkpoint**: All three User Stories are functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Mobile guidelines compliance (320px width, 130% text scaling), static analysis, formatting, and end-to-end validation

- [X] T029 Verify zero `RenderFlex` overflows at 320px width and 130% text scaling across `SeasonHonorRollCard`, `TournamentBackupSheet`, and `SeasonClosureConfirmationDialog` in `test/widget/season_closure_honor_roll_widget_test.dart`
- [X] T030 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`, and full `flutter test` suite with 0 issues
- [X] T031 Execute end-to-end validation scenarios in `specs/012-backup-restore-season-closure/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately (`T001`).
- **Phase 2 (Foundational)**: Depends on Phase 1 (`T002`–`T012`). Blocks all user stories.
- **Phase 3 (User Story 1 - MVP)**: Depends on Phase 2 (`T013`–`T018`).
- **Phase 4 (User Story 2)**: Depends on Phase 2 (`T019`–`T025`). Integrates cleanly with `BackupAndSeasonClosureController`.
- **Phase 5 (User Story 3)**: Depends on Phase 2 and Phase 4 (`T026`–`T028`).
- **Phase 6 (Polish)**: Depends on completion of all user stories (`T029`–`T031`).

### Parallel Opportunities

- **Phase 2**: `T002`, `T003`, `T004`, `T006`, `T008`, `T009`, `T010`, `T011`, and `T012` operate on independent files and can be executed in parallel.
- **User Story 1**: `T013`, `T014`, and `T015` can proceed in parallel before wiring in `T017`.
- **User Story 2**: `T019`, `T020`, `T022`, and `T023` can proceed in parallel before wiring in `T024`.
- **User Story 3**: `T026` and `T027` can proceed in parallel.

---

## Parallel Example: User Story 1 & 2

```bash
# Foundational entities & repository extensions in parallel:
Task: "T002 [P] Implement SeasonHonorRoll entity in lib/domain/entities/season_honor_roll.dart"
Task: "T003 [P] Implement TournamentBackupPackage entity in lib/domain/entities/tournament_backup_package.dart"
Task: "T008 [P] Extend TeamsRepository and LocalTeamsRepository with replaceTeamsForTournament"
Task: "T009 [P] Extend TournamentMatchesRepository and LocalTournamentMatchesRepository with replaceMatchesForTournament"

# User Story 1 & 2 use cases and widgets in parallel:
Task: "T013 [P] [US1] Implement backup use cases in lib/application/use_cases/tournament_backup_use_cases.dart"
Task: "T019 [P] [US2] Implement CloseTournamentSeasonUseCase in lib/application/use_cases/close_tournament_season_use_case.dart"
Task: "T023 [P] [US2] Implement SeasonHonorRollCard in lib/presentation/standings/widgets/season_honor_roll_card.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`).
2. Complete Phase 2: Foundational (`T002`–`T012`).
3. Complete Phase 3: User Story 1 (`T013`–`T018`).
4. **STOP and VALIDATE**: Verify backup export, corrupted JSON rejection, and two-step confirmed isolated tournament restoration.

### Incremental Delivery

1. **Foundation + US1 (MVP)**: Exportación, validación e importación atómica de respaldos del campeonato.
2. **US2**: Cierre oficial de temporada y publicación del Cuadro de Honor.
3. **US3**: Bloqueo permanente en modo de consulta histórica para campeonatos finalizados.
4. **Polish**: Verificación de accesibilidad (320px / 130%), análisis estático y suite completa de pruebas.
