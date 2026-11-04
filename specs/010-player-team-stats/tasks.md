# Tasks: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Input**: Design documents from `/specs/010-player-team-stats/`
**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/player-team-stats-contract.md`

**Tests**: Unit and widget tests are included per Constitution Principle VII (`Testing & Quality Gates`) and `plan.md`.

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `US1`, `US2`, `US3`)
- Includes exact file paths and field constraints in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization strings in Spanish (`app_es.arb`) and generated localization classes required by all user stories (`FR-006`, `FR-010`).

- [X] T001 Add Spanish localization keys for player performance profile metrics (`Partidos`, `Titularidades`, `Goles`, `Asistencias`, `Promedio de Gol`, `Tarjetas Amarillas`, `Tarjetas Rojas`), disciplinary badges (`Habilitado`, `Suspendido`), exact zero-participation message (`"Aún no registras participaciones en partidos oficiales de este torneo."`), team detailed stats headings, recent form codes (`V`, `E`, `D`), and `"Mi Perfil Deportivo"` in `lib/l10n/app_es.arb` and regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities and pure deterministic calculation service that back all user stories (`FR-001`..`FR-004`, `SC-001`..`SC-003`).

**⚠️ CRITICAL**: Must be complete before user story UI & application wiring.

- [X] T002 [P] Create `PlayerPerformanceProfile` (`matchesPlayed >= 0`, `startsCount >= 0`, `goals >= 0`, `assists >= 0`, `goalsPerMatchAverage` formatted to 2 decimal places via `formattedGoalsAverage`, `yellowCards >= 0`, `redCards >= 0`, `isSuspended`, `matchParticipations`, `toJson`/`fromJson`) and `PlayerMatchParticipation` entities in `lib/domain/entities/player_performance_profile.dart`
- [X] T003 [P] Create `TeamDetailedStats` (`standingsRow`, `recentForm` of length `0..5` with `TeamFormResult { win, draw, loss }`, `completedMatches`, `upcomingMatches`, `squadStats`), `TeamMatchHistoryItem`, and `TeamUpcomingMatchItem` entities in `lib/domain/entities/team_detailed_stats.dart`
- [X] T004 Implement `PlayerTeamStatsCalculatorService` in `lib/domain/services/player_team_stats_calculator_service.dart` enforcing zero-division protection (`matchesPlayed == 0` -> `0.0`), starter/participation attribution from `MatchLineupConvocation` and closed `DigitalMatchReport` events (`FR-002`), comprehensive disciplinary evaluation (`Habilitado` vs `Suspendido` per `FR-001`), and team 5-match form (`V`, `E`, `D`) + history + upcoming + squad stats (`FR-004`)
- [X] T005 Write unit tests for `PlayerTeamStatsCalculatorService` in `test/unit/domain/player_team_stats_calculator_service_test.dart` covering individual metrics, match-by-match breakdown, zero-division protection (`PJ == 0` -> `0.00`), disciplinary suspension rules, and team 5-match form (`V`, `E`, `D`)

**Checkpoint**: Domain entities and deterministic calculator service verified with unit tests.

---

## Phase 3: User Story 1 - Perfil Individual de Rendimiento e Historial Partido por Partido del Jugador (Priority: P1) 🎯 MVP

**Goal**: Visualizar el perfil individual de rendimiento del jugador con métricas en formato `tabular-nums`, insignia de estado disciplinario (`Habilitado` / `Suspendido`) y desglose histórico partido por partido (`FR-001`, `FR-002`, `FR-008`).

**Independent Test**: Renderizar `PlayerPerformanceProfileCard` / `showPlayerPerformanceProfileSheet` con un jugador que participó en partidos oficiales y verificar las 7 tarjetas de métricas (`tabular-nums`), la insignia `Habilitado`/`Suspendido` y el desglose partido por partido.

### Implementation for User Story 1

- [X] T006 [US1] Implement `PlayerPerformanceProfileCard` and `showPlayerPerformanceProfileSheet` in `lib/presentation/standings/widgets/player_performance_profile_card.dart` with `KickPulseTypography.statMetric` (`tabular-nums`), disciplinary badge (`Key('player_disciplinary_badge')`), metric cards (`Key('player_metric_matches_played')`, `Key('player_metric_starts')`, `Key('player_metric_goals')`, `Key('player_metric_assists')`, `Key('player_metric_goal_average')`, `Key('player_metric_yellow_cards')`, `Key('player_metric_red_cards')`), match-by-match participation rows (`Key('player_match_participation_<matchId>')`), optional player switcher, and empty state message (`Key('player_empty_participations_message')`)

**Checkpoint**: User Story 1 UI component is functional and independently testable.

---

## Phase 4: User Story 2 - Ficha de Estadísticas Detalladas, Racha Reciente e Historial del Equipo (Priority: P2)

**Goal**: Presentar la ficha detallada del equipo con su posición actual, resumen de goles/puntos, racha de los últimos 5 partidos (`V`, `E`, `D`), historial de resultados, próximos rivales y listado completo de plantilla con navegación al perfil individual de cada jugador (`FR-004`, `FR-005`, `FR-008`).

**Independent Test**: Tocar una fila de equipo en `StandingsTableCard` o `TournamentRankingsCard` para abrir `TeamDetailedStatsCard`, verificar la racha (`V`, `E`, `D`), resultados anteriores, próximos rivales y tocar un jugador de la plantilla para abrir su `PlayerPerformanceProfileCard`.

### Implementation for User Story 2

- [X] T007 [US2] Implement `TeamDetailedStatsCard` and `showTeamDetailedStatsSheet` in `lib/presentation/standings/widgets/team_detailed_stats_card.dart` displaying current position, `StandingsRow` metrics (`tabular-nums`), recent 5-match form strip (`Key('team_recent_form_strip')` with `V`/`E`/`D`), completed match history (`Key('team_history_match_<matchId>')`), upcoming matches (`Key('team_upcoming_match_<matchId>')`), and squad list (`Key('team_squad_player_row_<playerId>')`) with tap navigation to `showPlayerPerformanceProfileSheet`
- [X] T008 [P] [US2] Add optional `onTeamSelected` callback to `StandingsTableCard` in `lib/presentation/standings/widgets/standings_table_card.dart` so tapping `Key('standings_row_<teamId>')` invokes team detailed stats drill-down
- [X] T009 [P] [US2] Add optional `onPlayerSelected` and `onTeamSelected` callbacks to `TournamentRankingsCard` in `lib/presentation/standings/widgets/tournament_rankings_card.dart` so tapping `Key('scorer_row_<playerId>')` / `Key('assist_row_<playerId>')` opens the player profile and tapping `Key('fair_play_row_<teamId>')` opens the team detailed stats

**Checkpoint**: User Stories 1 and 2 widgets and drill-down callbacks are ready.

---

## Phase 5: User Story 3 - Manejo de Estados Vacíos Sin Errores de División por Cero y Persistencia Offline (Priority: P3)

**Goal**: Garantizar estados vacíos en `0` / `0.00` con el mensaje exacto en español cuando no hay participaciones, persistir en caché local offline el perfil del jugador (`cached_player_performance_profile_v1`) e integrar todos los puntos de entrada en `StandingsTabView` (`FR-003`, `FR-005`, `FR-006`, `FR-007`, `FR-009`).

**Independent Test**: Consultar un jugador con `0` partidos jugados verificando contadores en `0`, promedio en `0.00` y el mensaje `"Aún no registras participaciones en partidos oficiales de este torneo."`, verificar persistencia en `LocalStorageRepository`, y probar el botón `"Mi Perfil Deportivo"` y el *drill-down* en `StandingsTabView`.

### Implementation for User Story 3

- [X] T010 [US3] Extend `TournamentCompetitiveSnapshot` and `CalculateTournamentStandingsAndRankingsUseCase` in `lib/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart` and `StandingsAndRankingsController` in `lib/application/controllers/standings_and_rankings_controller.dart` to load team convocations/tracking via `LineupsTrackingRepository`, compute `playerProfilesById` and `teamDetailedStatsById`, and persist/load the cached player profile in `LocalStorageRepository` (`cached_player_performance_profile_v1`)
- [X] T011 [US3] Update unit tests in `test/unit/application/calculate_tournament_standings_and_rankings_use_case_test.dart` to verify `playerProfilesById`, `teamDetailedStatsById`, zero-match states, and offline cache persistence in `LocalStorageRepository`
- [X] T012 [US3] Integrate `"Mi Perfil Deportivo"` quick-access button (`Key('open_my_player_profile_button')`) and team/player drill-down callbacks into `StandingsTabView` in `lib/presentation/shell/tabs/standings_tab_view.dart`

**Checkpoint**: All user stories (US1, US2, US3) are integrated end-to-end with offline caching.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end widget testing (including `320px` width and `130%` text scaling overflow verification) and repository-wide static analysis & formatting gates.

- [X] T013 Create widget tests in `test/widget/player_team_stats_widget_test.dart` verifying US1 (player metrics `tabular-nums`, disciplinary badge, match breakdown), US2 (team detailed stats, 5-match form `V`/`E`/`D`, squad drill-down), US3 (zero-participation state `"Aún no registras participaciones en partidos oficiales de este torneo."` and `0.00` average), and `0 RenderFlex overflows` at `320px` width and `130%` text scale (`SC-004`)
- [X] T014 Run `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and `flutter test --coverage` to validate all quality gates (`0` analyzer warnings, `100%` passing tests)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies (`T001`).
- **Phase 2 (Foundational)**: Depends on `T001`. `T002` and `T003` can run in parallel (`[P]`), followed by `T004` and `T005`.
- **Phase 3 (US1 - MVP)**: Depends on Phase 2 (`T006`).
- **Phase 4 (US2)**: Depends on Phase 2 and `T006` (`T007`, while `T008` and `T009` can run in parallel `[P]`).
- **Phase 5 (US3)**: Depends on Phases 2, 3, and 4 (`T010` → `T011`, `T012`).
- **Phase 6 (Polish)**: Depends on Phase 5 (`T013` → `T014`).

### Parallel Opportunities

- `T002` (`player_performance_profile.dart`) and `T003` (`team_detailed_stats.dart`) operate on independent files and can be executed in parallel.
- `T008` (`standings_table_card.dart`) and `T009` (`tournament_rankings_card.dart`) operate on independent widget files and can be executed in parallel.

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Phase 1 (`T001`) and Phase 2 (`T002`–`T005`).
2. Complete Phase 3 (`T006`) for the Player Performance Profile (`US1`).
3. Add Phase 4 (`T007`–`T009`) for the Team Detailed Stats and drill-down (`US2`).
4. Complete Phase 5 (`T010`–`T012`) for use-case integration, offline caching, and zero-match states (`US3`), followed by Phase 6 verification (`T013`–`T014`).
