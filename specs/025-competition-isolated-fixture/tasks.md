# Tasks: Generación de Fixture Independiente por Competición (HU 15.2)

**Input**: Design documents from `/specs/025-competition-isolated-fixture/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/ui-isolated-fixture-contracts.md](./contracts/ui-isolated-fixture-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega e inspección independiente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes, sin bloqueos cruzados).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Shared Localization & Infrastructure)

**Purpose**: Agregar las claves de localización en español necesarias para el FAB Menu de la competición y el selector modal de competiciones en el Panel.

- [X] T001 Add Spanish localization keys for competition FAB menu and panel competition selector (`competitionFabMenuTooltip`, `competitionFabGenerateFixtureLabel`, `selectTournamentForFixtureTitle`, `selectTournamentForFixtureSubtitle`, `selectTournamentEligibleTeamsCount`, `organizerNoEditableTournamentsForFixture`) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Competition-Level Team Isolation in Domain/Application)

**Purpose**: Garantizar que la generación de fixture filtre exclusivamente los equipos cuyo `tournamentId` pertenezca al torneo objetivo y que el estado en memoria conserve los partidos de otros torneos.

**⚠️ CRITICAL**: Esta fase bloquea las historias de usuario `US2` y `US3`.

- [X] T003 Enforce strict team isolation (`team.tournamentId == tournament.id && team.isEligible`) and isolated tournament persistence (`matchesRepository.replaceMatchesForTournament`) in `lib/application/use_cases/fixture_scheduling_use_case.dart`
- [X] T004 Update `MatchesCatalogController.generateFixture` to merge newly generated tournament matches with existing matches from other tournaments (`m.tournamentId != tournament.id`) in `lib/application/controllers/matches_catalog_controller.dart`
- [X] T005 [P] Add unit tests verifying strict `tournamentId` team filtering and multi-tournament match preservation in `test/unit/application/fixture_scheduling_use_case_test.dart`

**Checkpoint**: `FixtureSchedulingUseCase` y `MatchesCatalogController` aíslan 100% los equipos y partidos por `tournamentId`.

---

## Phase 3: User Story 1 - Retiro de Controles de Generación de Fixture de la Vista Principal de Partidos (Priority: P1) 🎯 MVP

**Goal**: Retirar por completo `OrganizerPendingMatchesBanner` y los controles de generación de fixture de `MatchdayTabView`, dejando la pestaña **Partidos** dedicada exclusivamente a la consulta cronológica por fecha (*Ayer*, *Hoy*, *Mañana* y *Calendario*).

**Independent Test**: Montar `MatchdayTabView` con rol `UserRole.organizer` y torneos activos sin fixture; comprobar que no se renderiza `organizer_pending_matches_banner` ni ningún botón de generación de fixture.

### Implementation & Tests for User Story 1

- [X] T006 [US1] Remove `OrganizerPendingMatchesBanner`, `_onGenerateFixture`, and `_onOpenScheduleDialogForPending` from `lib/presentation/shell/tabs/matchday_tab_view.dart`
- [X] T007 [P] [US1] Update widget tests in `test/presentation/shell/tabs/matchday_tab_view_test.dart` and `test/widget/matchday_fixture_widget_test.dart` to verify `MatchdayTabView` renders zero fixture generation banners or buttons for `UserRole.organizer`

**Checkpoint**: `MatchdayTabView` muestra únicamente el feed diario de partidos por fecha para todos los roles.

---

## Phase 4: User Story 2 - Generación de Fixture Aislada desde el FAB Menu en el Detalle de Competición (Priority: P1)

**Goal**: Mostrar un FAB Menu expandible (*Speed Dial*) en `CompetitionDetailScreen` (`/competitions/:id`) para `UserRole.organizer` en torneos editables (`openRegistration` o `inProgress`) con la opción **"Generar Fixture"**, generando las jornadas exclusivamente para esa competición, colapsando el FAB y mostrando el `SnackBar` sin cambiar de pestaña.

**Independent Test**: Montar `CompetitionDetailScreen` como `Organizador` en un torneo editable con $\ge 2$ equipos elegibles, pulsar `competition_detail_fab_menu`, pulsar `competition_detail_fab_generate_fixture`, confirmar en `GenerateFixtureConfirmationDialog` y verificar que se crean únicamente los partidos de ese torneo y que el FAB está oculto para roles no autorizados o torneos finalizados.

### Implementation & Tests for User Story 2

- [X] T008 [US2] Implement expandable Speed Dial FAB Menu (`Key('competition_detail_fab_menu')` and `Key('competition_detail_fab_generate_fixture')`) guarded by `RoleCapability.manageTournaments` and `tournament.status.isEditable`, triggering `GenerateFixtureConfirmationDialog` and isolated fixture generation while preserving the active tab in `lib/presentation/tournaments/competition_detail_screen.dart`
- [X] T009 [P] [US2] Add widget tests in `test/presentation/tournaments/competition_detail_screen_test.dart` covering FAB Menu visibility by role/status, Speed Dial expansion/collapse, isolated fixture generation, and active tab preservation

**Checkpoint**: El Organizador puede generar el fixture de una competición directamente desde su pantalla de detalle (`/competitions/:id`).

---

## Phase 5: User Story 3 - Selección Previa de Competición al Generar Fixture desde el Panel Administrativo (Priority: P2)

**Goal**: Al pulsar **"Generar Fixture"** en `OrganizerPanelContent` (`/panel`), desplegar primero una hoja modal (`SelectTournamentForFixtureSheet`) con las competiciones editables disponibles, y tras elegir una competición y confirmar, generar su fixture de forma aislada, mostrar el `SnackBar` y navegar automáticamente a `/competitions/:id`.

**Independent Test**: En `OrganizerPanelContent` (`/panel`), pulsar `organizer_action_generate_fixture`, seleccionar un torneo en `select_tournament_for_fixture_sheet`, confirmar en `GenerateFixtureConfirmationDialog` y verificar que se genera el fixture solo para ese torneo y se navega a `/competitions/:id`.

### Implementation & Tests for User Story 3

- [X] T010 [P] [US3] Create `SelectTournamentForFixtureSheet` (`Key('select_tournament_for_fixture_sheet')` and `Key('select_tournament_fixture_item_${id}')`) listing editable competitions (`openRegistration` and `inProgress`) with status badge and eligible team count in `lib/presentation/panel/widgets/select_tournament_for_fixture_sheet.dart`
- [X] T011 [US3] Update `_onGenerateFixture` in `lib/presentation/panel/widgets/organizer_panel_content.dart` to open `SelectTournamentForFixtureSheet`, request confirmation via `GenerateFixtureConfirmationDialog`, generate the fixture for the selected tournament, show the confirmation `SnackBar`, and navigate to `/competitions/${tournament.id}`
- [X] T012 [P] [US3] Update widget tests in `test/presentation/panel/organizer_panel_widget_test.dart` to verify tournament selection modal, isolated fixture generation, empty editable tournaments handling, and automatic navigation to `/competitions/:id`

**Checkpoint**: Las 3 historias de usuario (`US1`, `US2`, `US3`) funcionan de forma independiente e integrada.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación en pantallas compactas ($320 \times 640\text{ px}$ @ $130\%$ text scale), análisis estático y formato de código.

- [X] T013 [P] Add compact viewport ($320 \times 640\text{ px}$ at $130\%$ text scale) overflow verification tests for `CompetitionDetailScreen` FAB Menu and `SelectTournamentForFixtureSheet` in `test/presentation/tournaments/competition_detail_screen_test.dart` and `test/presentation/panel/organizer_panel_widget_test.dart`
- [X] T014 Run full test suite (`flutter test`), static analysis (`flutter analyze`), and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) to verify zero errors and zero warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sin dependencias — se ejecuta de inmediato.
- **Phase 2 (Foundational)**: Depende de Phase 1 — bloquea `US2` y `US3`.
- **Phase 3 (US1 - P1)**: Puede ejecutarse tras Phase 1/2 de forma independiente (`lib/presentation/shell/tabs/matchday_tab_view.dart`).
- **Phase 4 (US2 - P1)**: Depende de Phase 2 (`lib/presentation/tournaments/competition_detail_screen.dart`).
- **Phase 5 (US3 - P2)**: Depende de Phase 2 (`lib/presentation/panel/widgets/select_tournament_for_fixture_sheet.dart` y `organizer_panel_content.dart`).
- **Phase 6 (Polish)**: Depende de completar las fases 3, 4 y 5.

### Parallel Opportunities

- `T006`/`T007` (`US1`), `T008`/`T009` (`US2`) y `T010`/`T011`/`T012` (`US3`) modifican archivos de presentación distintos y pueden desarrollarse o probarse sin colisiones de archivos una vez completada la Fase 2.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# Una vez completada Phase 2 (T003-T005), pueden ejecutarse en paralelo:
Task T006: "Remove OrganizerPendingMatchesBanner from lib/presentation/shell/tabs/matchday_tab_view.dart"
Task T008: "Implement expandable Speed Dial FAB Menu in lib/presentation/tournaments/competition_detail_screen.dart"
Task T010: "Create SelectTournamentForFixtureSheet in lib/presentation/panel/widgets/select_tournament_for_fixture_sheet.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2 + User Story 1 & User Story 2)

1. Completar `Phase 1` (Localización) y `Phase 2` (Aislamiento por `tournamentId`).
2. Completar `Phase 3 (US1)` retirando controles de fixture en `MatchdayTabView`.
3. Completar `Phase 4 (US2)` habilitando el FAB Menu en `CompetitionDetailScreen`.
4. Completar `Phase 5 (US3)` habilitando el selector de competición en `/panel` con redirección a `/competitions/:id`.
5. Ejecutar `Phase 6 (Polish)` para certificar cero errores en `flutter test` y `flutter analyze`.
