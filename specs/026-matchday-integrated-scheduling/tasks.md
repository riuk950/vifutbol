# Tasks: Programación Integral de Partido al Seleccionarlo en la Jornada (Árbitro, Fecha, Sede y Cancha) (HU 15.3)

**Input**: Design documents from `/specs/026-matchday-integrated-scheduling/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/ui-matchday-scheduling-contracts.md](./contracts/ui-matchday-scheduling-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes, sin bloqueos cruzados).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Shared Localization & Infrastructure)

**Purpose**: Añadir las claves de localización en español para el pie de logística de los partidos en la jornada y la confirmación de programación guardada.

- [X] T001 Add Spanish localization keys (`fixtureMatchPendingLogistics` and `matchdayScheduleSavedSuccess`) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Global Catalog Access & Multi-Tournament Preservation)

**Purpose**: Exponer `loadAllMatches()` en el repositorio de partidos y asegurar que `MatchesCatalogController.scheduleMatch` preserve en memoria los partidos de otras competiciones activas.

**⚠️ CRITICAL**: Esta fase bloquea la validación global de colisiones y la sincronización entre vistas.

- [X] T003 Expose `Future<List<ChampionshipMatch>> loadAllMatches()` in `lib/domain/repositories/tournament_matches_repository.dart` and implement it in `lib/infrastructure/repositories/local_tournament_matches_repository.dart`
- [X] T004 Update `MatchesCatalogController.scheduleMatch` to merge updated tournament matches with existing matches from other tournaments (`m.tournamentId != tournament.id`) in `lib/application/controllers/matches_catalog_controller.dart`

**Checkpoint**: `TournamentMatchesRepository` expone el catálogo global de partidos y `MatchesCatalogController` preserva el estado multi-torneo al programar un encuentro.

---

## Phase 3: User Story 1 - Apertura del Formulario de Programación desde la Lista de Jornadas por Rol (Priority: P1) 🎯 MVP

**Goal**: Permitir al `Organizador` tocar cualquier partido en estado `pendingSchedule` o `scheduled` dentro de `CompetitionFixtureTabView` (en un torneo editable `openRegistration` o `inProgress`) para abrir directamente `ScheduleMatchDialog` con el rango de fechas acotado al campeonato y los datos previos precargados, manteniendo el modal de solo lectura para los demás roles o estados.

**Independent Test**: Montar `CompetitionFixtureTabView` como `UserRole.organizer` en un torneo editable y tocar un partido en estado `pendingSchedule` o `scheduled`; verificar que se abre `ScheduleMatchDialog` con los selectores de Fecha, Hora, Sede, Cancha y Árbitro. Cambiar a `UserRole.fan` (o tocar un partido `completed`) y verificar que se abre la hoja modal de solo lectura.

### Implementation & Tests for User Story 1

- [X] T005 [P] [US1] Update `ScheduleMatchDialog` in `lib/presentation/matches/widgets/schedule_match_dialog.dart` to clamp initial date for `pendingSchedule` matches within `[tournament.startDate, tournament.endDate]` and bound `showDatePicker` (`firstDate`/`lastDate`) to the tournament date range with safe boundary expansion
- [X] T006 [US1] Update `CompetitionFixtureTabView` in `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart` to open `ScheduleMatchDialog` directly when `UserRole.organizer` taps a `pendingSchedule` or `scheduled` match in an editable tournament, and fall back to the read-only detail sheet otherwise
- [X] T007 [P] [US1] Add widget tests in `test/presentation/tournaments/competition_fixture_widget_test.dart` verifying that `UserRole.organizer` opens `ScheduleMatchDialog` on `pendingSchedule`/`scheduled` matches while non-organizer roles or `completed` matches open the read-only summary modal

**Checkpoint**: El `Organizador` puede abrir directamente `ScheduleMatchDialog` al seleccionar un partido pendiente o programado en la jornada.

---

## Phase 4: User Story 2 - Asignación Completa de Logística y Sincronización Reactiva (Priority: P1)

**Goal**: Guardar la programación completa (Fecha, Hora, Sede, Cancha y Árbitro), persistir el nombre combinado de Sede y Cancha (`${venue.name} - ${pitch.name}`), mostrar el pie de metadatos logísticos (`Key('fixture_match_logistics_${match.id}')`) directamente en cada tarjeta de la jornada, y refrescar `DailyMatchesFeedController`.

**Independent Test**: En `CompetitionFixtureTabView` como `Organizador`, abrir un partido `pendingSchedule`, seleccionar Sede, Cancha, Fecha, Hora y Árbitro, pulsar `confirm_schedule_match_button` y comprobar que el partido pasa a `scheduled`, exhibe fecha, sede, cancha y árbitro en `Key('fixture_match_logistics_${match.id}')` y aparece en el feed diario de `Partidos`.

### Implementation & Tests for User Story 2

- [X] T008 [US2] Update `FixtureSchedulingUseCase.scheduleMatch` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to format `pitchName` as `'${venue.name} - ${pitch.name}'` (when `pitch.name` does not already include `venue.name`) so both venue and pitch are persisted
- [X] T009 [US2] Render the logistics metadata footer (`Key('fixture_match_logistics_${match.id}')`) in `lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart` displaying `fixtureMatchPendingLogistics` for `pendingSchedule` matches or formatted date, venue/pitch, and referee for scheduled matches, and refresh `dailyMatchesFeedControllerProvider` + show confirmation `SnackBar` upon saving in `ScheduleMatchDialog`
- [X] T010 [P] [US2] Add widget tests in `test/presentation/tournaments/competition_fixture_widget_test.dart` verifying dynamic venue-to-pitch filtering, saving full logistics, updating `Key('fixture_match_logistics_${match.id}')` on the matchday card, and reactive synchronization

**Checkpoint**: Los partidos programados muestran su fecha, sede, cancha y árbitro directamente en la jornada y se sincronizan con el feed diario.

---

## Phase 5: User Story 3 - Validación y Bloqueo de Colisiones de Horario en Cancha y Árbitro (Priority: P1)

**Goal**: Validar globalmente contra todos los partidos programados del catálogo (`loadAllMatches()`) que no exista conflicto de horario en la misma cancha (`pitchId`) ni con el mismo árbitro (`refereeId`), excluyendo al propio partido al reprogramar, y mostrar la alerta `Key('schedule_error_message')` bloqueando el guardado.

**Independent Test**: Programar un partido en una cancha y árbitro a una fecha/hora determinada, e intentar programar otro partido (del mismo o de otro torneo) en la misma cancha o con el mismo árbitro en un horario superpuesto; verificar que se lanza `FixtureScheduleValidationFailure` y se muestra `Key('schedule_error_message')` en `ScheduleMatchDialog`.

### Implementation & Tests for User Story 3

- [X] T011 [US3] Update `FixtureSchedulingUseCase.scheduleMatch` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to load all catalog matches via `matchesRepository.loadAllMatches()` when running `detectCollisions`, enforcing cross-tournament pitch and referee collision detection while excluding `candidateMatchId`
- [X] T012 [P] [US3] Add unit tests in `test/unit/application/fixture_scheduling_use_case_test.dart` verifying cross-tournament pitch and referee schedule collision blocking and self-exclusion when rescheduling an existing match

**Checkpoint**: Las 3 historias de usuario (`US1`, `US2`, `US3`) funcionan de forma integrada con detección global de colisiones.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación en pantallas compactas ($320 \times 640\text{ px}$ @ $130\%$ text scale), análisis estático y formato de código.

- [X] T013 [P] Add compact viewport ($320 \times 640\text{ px}$ at $130\%$ text scale) overflow verification test for `CompetitionFixtureTabView` with logistics footers and `ScheduleMatchDialog` in `test/presentation/tournaments/competition_fixture_widget_test.dart`
- [X] T014 Run target and full test suites (`flutter test`), static analysis (`flutter analyze`), and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) to verify zero errors and zero warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sin dependencias — se ejecuta de inmediato.
- **Phase 2 (Foundational)**: Depende de Phase 1 — bloquea `US1`, `US2` y `US3`.
- **Phase 3 (US1 - P1)**: Depende de Phase 2.
- **Phase 4 (US2 - P1)**: Depende de Phase 3 (`CompetitionFixtureTabView` y `ScheduleMatchDialog`).
- **Phase 5 (US3 - P1)**: Depende de Phase 2 (`loadAllMatches()` en `FixtureSchedulingUseCase`).
- **Phase 6 (Polish)**: Depende de completar las fases 3, 4 y 5.

### Parallel Opportunities

- `T005` (`ScheduleMatchDialog`) y `T008`/`T011` (`FixtureSchedulingUseCase`) modifican archivos distintos y pueden ejecutarse en paralelo tras completar la Fase 2.
- `T007`, `T010` y `T012` pueden ejecutarse en paralelo sobre archivos de prueba unitarios y de widgets separados.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# Una vez completada Phase 2 (T003-T004), pueden ejecutarse en paralelo:
Task T005: "Update ScheduleMatchDialog date range clamping in lib/presentation/matches/widgets/schedule_match_dialog.dart"
Task T008 & T011: "Update FixtureSchedulingUseCase.scheduleMatch in lib/application/use_cases/fixture_scheduling_use_case.dart"
Task T012: "Add cross-tournament collision unit tests in test/unit/application/fixture_scheduling_use_case_test.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2 + User Story 1)

1. Completar `Phase 1` (Localización) y `Phase 2` (`loadAllMatches` y preservación multi-torneo).
2. Completar `Phase 3 (US1)` habilitando la apertura directa de `ScheduleMatchDialog` al seleccionar un partido en la jornada como `Organizador`.
3. Completar `Phase 4 (US2)` mostrando la logística completa en el pie de la tarjeta de la jornada y sincronizando con el feed diario.
4. Completar `Phase 5 (US3)` asegurando el bloqueo global de colisiones de cancha y árbitro.
5. Ejecutar `Phase 6 (Polish)` para certificar cero errores en `flutter analyze`, `dart format` y tests.
