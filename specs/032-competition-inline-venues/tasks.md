# Tasks: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Input**: Design documents from `/specs/032-competition-inline-venues/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/inline-venue-contracts.md](./contracts/inline-venue-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes, sin dependencias cruzadas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Shared Localization & Project Config)

**Purpose**: Incorporar las claves de localización en español e inglés requeridas para las secciones de sedes y el subformulario modal.

- [X] T001 Add localization keys for venue selection and bottom sheet (`venuesSectionTitle`, `venuesSectionSubtitle`, `noVenuesRegistered`, `createNewVenue`, `venueNameLabel`, `venueAddressLabel`, `venuePitchesCountLabel`, `venueNameTooShort`, `venueAddressTooShort`, `venuePitchesInvalid`, `venueNameDuplicate`) in `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb`, then run `flutter gen-l10n`

---

## Phase 2: Foundational (Domain Entities & Uniqueness Invariants)

**Purpose**: Extender los modelos de dominio para soportar `venueIds` y agregar la validación de unicidad de sedes antes de la implementación de la interfaz de usuario.

**⚠️ CRITICAL**: Ninguna historia de usuario puede arrancar hasta completar esta fase.

- [X] T002 [P] Extend `ChampionshipTournament` in `lib/domain/entities/championship_tournament.dart` to add `venueIds: List<String>` (default `const <String>[]`), updating `copyWith`, `toJson`, `fromJson`, and equality
- [X] T003 [P] Extend `TournamentDraft` in `lib/domain/entities/tournament_draft.dart` to add `venueIds: List<String>` (default `const <String>[]`), updating `copyWith`, `toJson`, `fromJson`, and equality
- [X] T004 [P] Add unit tests in `test/domain/championship_tournament_venues_test.dart` verifying `ChampionshipTournament` and `TournamentDraft` default empty `venueIds`, copyWith, JSON serialization/deserialization, and immutability
- [X] T005 Update `ManageVenuesUseCase` in `lib/application/use_cases/manage_venues_use_case.dart` to enforce case-insensitive and trimmed name uniqueness check against `_venuesRepository.getVenues()`, throwing `InvalidVenueDataFailure`
- [X] T006 [P] Add unit tests in `test/application/use_cases/manage_venues_duplicate_validation_test.dart` verifying `ManageVenuesUseCase` uniqueness validation on duplicate venue names (case-insensitive and trimmed) and allowing edits of existing IDs

**Checkpoint**: Modelos de dominio y reglas de negocio de sedes listos y testeados; implementación de historias de usuario desbloqueada.

---

## Phase 3: User Story 1 - Despliegue de Selector y Registro en Línea de Nueva Sede (Priority: P1) 🎯 MVP

**Goal**: Permitir al organizador visualizar sedes existentes en `TournamentFormScreen` y abrir el `CreateVenueBottomSheet` para registrar una nueva sede y seleccionarla automáticamente.

**Independent Test**: Abrir `TournamentFormScreen`, presionar "Crear Nueva Sede", registrar una sede con nombre, dirección y $N$ canchas, y verificar que se crea y se añade a la lista de seleccionadas.

### Tests for User Story 1

- [X] T007 [P] [US1] Create widget tests in `test/presentation/venues/create_venue_bottom_sheet_test.dart` verifying `CreateVenueBottomSheet` displays required fields, keyboard scrolling padding, and auto-generates sequential pitches on valid submission

### Implementation for User Story 1

- [X] T008 [US1] Implement `CreateVenueBottomSheet` and `showCreateVenueBottomSheet` in `lib/presentation/venues/widgets/create_venue_bottom_sheet.dart` with name, address, pitches count inputs, sequential pitch generation ("Cancha 1", ..., "Cancha N"), and `ManageVenuesUseCase` persistence
- [X] T009 [US1] Update `TournamentsController` in `lib/application/controllers/tournaments_controller.dart` to accept `venueIds: List<String>` in `saveTournament` and persist them into `ChampionshipTournament`
- [X] T010 [US1] Update `TournamentFormScreen` in `lib/presentation/tournaments/tournament_form_screen.dart` to add the "Sedes Oficiales" section, multiselect chips/dropdown with existing venues from `venuesControllerProvider`, the "+ Crear Nueva Sede" button invoking `showCreateVenueBottomSheet`, and auto-selecting the newly created venue

**Checkpoint**: Flujo de alta y selección en línea operativo como MVP independiente.

---

## Phase 4: User Story 2 - Validación Robusta y Preservación Atómica del Estado del Torneo (Priority: P2)

**Goal**: Validar campos de sede en tiempo real con mensajes en español, prevenir duplicados, y garantizar que abrir, cancelar o fallar en el bottom sheet preserva el 100% de los datos del formulario del torneo.

**Independent Test**: Diligenciar el formulario del torneo hasta la mitad, abrir el modal de sede, forzar errores de validación (nombre < 3, dirección < 5, canchas < 1, nombre duplicado), cancelar el modal y verificar que los datos del torneo siguen intactos.

### Tests for User Story 2

- [X] T011 [P] [US2] Create widget tests in `test/presentation/tournaments/tournament_form_screen_venues_test.dart` verifying non-destructive lifecycle: tournament fields (name, category, rules) remain intact when venue bottom sheet is cancelled or fails validation

### Implementation for User Story 2

- [X] T012 [US2] Enhance `CreateVenueBottomSheet` in `lib/presentation/venues/widgets/create_venue_bottom_sheet.dart` with inline form validation, error message display in Spanish, double-tap prevention on submission, and name uniqueness check feedback
- [X] T013 [US2] Update draft preservation in `TournamentFormScreen` in `lib/presentation/tournaments/tournament_form_screen.dart` to include `_selectedVenueIds` in `TournamentDraft` when the app moves to background or state changes

**Checkpoint**: Validación robusta, no destructiva y resiliente ante interrupciones móviles.

---

## Phase 5: User Story 3 - Persistencia Global y Vinculación Oficial en la Competición (Priority: P3)

**Goal**: Asegurar que las sedes vinculadas persisten en el torneo guardado y que la nueva sede queda disponible en el catálogo general (`VenuesRepository`) para futuros torneos y partidos.

**Independent Test**: Crear una sede desde el formulario de torneo, guardar el torneo, y verificar que `tournamentsControllerProvider` contiene el torneo con los `venueIds` y `venuesControllerProvider` contiene la sede persistida.

### Tests for User Story 3

- [X] T014 [P] [US3] Create integration tests in `test/application/controllers/tournaments_controller_venues_test.dart` verifying end-to-end saving of tournament with associated `venueIds` and availability in `VenuesRepository`

### Implementation for User Story 3

- [X] T015 [US3] Connect `TournamentFormScreen` submit flow in `lib/presentation/tournaments/tournament_form_screen.dart` to pass `_selectedVenueIds` to `saveTournament` and navigate/display confirmation feedback upon successful save

**Checkpoint**: Persistencia global de sedes y vinculación oficial completada end-to-end.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verificación de análisis estático, formato de código y ejecución de la suite completa de pruebas de la característica.

- [X] T016 [P] Run static analysis (`flutter analyze`) and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) ensuring zero errors and zero warnings
- [X] T017 Run all unit, use case, and widget test suites for this feature (`flutter test test/domain/championship_tournament_venues_test.dart test/application/use_cases/manage_venues_duplicate_validation_test.dart test/presentation/venues/create_venue_bottom_sheet_test.dart test/presentation/tournaments/tournament_form_screen_venues_test.dart test/application/controllers/tournaments_controller_venues_test.dart`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — se ejecuta de inmediato.
- **Foundational (Phase 2)**: Depende de Phase 1 — bloquea `US1`, `US2` y `US3`.
- **User Story 1 (Phase 3 - P1 MVP)**: Depende de Phase 2.
- **User Story 2 (Phase 4 - P2)**: Depende de Phase 3 (subformulario implementado en US1).
- **User Story 3 (Phase 5 - P3)**: Depende de Phase 3 y Phase 4 (flujo completo listo para persistencia final).
- **Polish (Final Phase)**: Depende de todas las fases anteriores.

### Parallel Opportunities

- En Phase 2: `T002` (torneo), `T003` (draft), `T004` (tests de modelos) y `T006` (tests de duplicados) pueden avanzar en paralelo.
- En Phase 3: `T007` (widget test bottom sheet) se escribe antes o en paralelo con `T008` (bottom sheet).
- En Phase 4: `T011` (tests de ciclo no destructivo) corre en paralelo con mejoras de validación.
- En Phase 5: `T014` (test de integración) corre en paralelo antes de `T015`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1: Setup (`T001`).
2. Completar Phase 2: Foundational (`T002` - `T006`).
3. Completar Phase 3: User Story 1 (`T007` - `T010`).
4. **Validar MVP**: El organizador puede abrir el bottom sheet, registrar una sede y verla seleccionada en el formulario del torneo.

### Incremental Delivery

1. Añadir User Story 2 (`T011` - `T013`) → Validación estricta, unicidad de nombre y preservación atómica de borradores ante interrupciones.
2. Añadir User Story 3 (`T014` - `T015`) → Persistencia total y vinculación oficial en el campeonato guardado.
3. Polish (`T016` - `T017`) → Análisis estático, formateo y suite completa de pruebas.
