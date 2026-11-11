# Tasks: Navegación a Detalles de la Competición desde "Mis Competiciones" en el Panel (HU 18.3)

**Input**: Design documents from `/specs/034-organizer-competition-navigation/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/competition-navigation-contracts.md](./contracts/competition-navigation-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes o sin dependencias cruzadas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Contracts & Navigation Infrastructure)

**Purpose**: Verificar la configuración del enrutador de detalles de competición y preparar las dependencias compartidas.

- [X] T001 [P] Verify route `/competitions/:id` mapping to `CompetitionDetailScreen` in `lib/presentation/navigation/app_router.dart` and contract compatibility in `specs/034-organizer-competition-navigation/contracts/competition-navigation-contracts.md`

---

## Phase 2: Foundational (Stateful Widget Transition & Base Helpers)

**Purpose**: Adaptar `OrganizerCompetitionsSection` a `ConsumerStatefulWidget` para alojar de forma segura el control de estado de toques y debouncing.

**⚠️ CRITICAL**: Ninguna historia de usuario puede arrancar hasta completar esta fase.

- [X] T002 Refactor `OrganizerCompetitionsSection` in `lib/presentation/panel/widgets/organizer_competitions_section.dart` to a `ConsumerStatefulWidget` with state holding `DateTime? _lastNavigationTap` and optional `onTapTournament` callback

**Checkpoint**: Componente base preparado para gestionar navegación y eventos de toque.

---

## Phase 3: User Story 1 - Navegación Directa al Detalle de la Competición (Priority: P1) 🎯 MVP

**Goal**: Permitir que el organizador pulse sobre cualquier tarjeta de torneo en "Mis Competiciones" para sincronizar el torneo seleccionado y navegar a `/competitions/:id`.

**Independent Test**: Renderizar `OrganizerCompetitionsSection` con torneos, simular `tap` sobre `Key('organizer_competition_card_${tournament.id}')` y verificar que se llama a `tournamentsController.selectTournament(id)` y se empuja la ruta `/competitions/${tournament.id}`.

### Tests for User Story 1

- [X] T003 [P] [US1] Add widget test in `test/presentation/panel/organizer_competitions_section_test.dart` verifying tapping `organizer_competition_card_${tournament.id}` selects the tournament and pushes `/competitions/${tournament.id}` displaying `CompetitionDetailScreen`

### Implementation for User Story 1

- [X] T004 [US1] Implement `_handleTournamentTap` in `lib/presentation/panel/widgets/organizer_competitions_section.dart` invoking `tournamentsController.selectTournament(tournament.id)`, executing route navigation to `/competitions/${tournament.id}`, and passing `onTap` to `KickPulseCard`

**Checkpoint**: Flujo primario de navegación por tap completamente funcional e independientemente probado (MVP).

---

## Phase 4: User Story 2 - Aislamiento del Menú Contextual de Opciones Secundarias (Priority: P2)

**Goal**: Garantizar que la pulsación del icono de tres puntos de la tarjeta despliegue el menú emergente sin disparar la navegación al detalle del torneo.

**Independent Test**: Tocar `Key('organizer_competition_menu_button_${tournament.id}')` y verificar que el menú de tres puntos se despliega con sus opciones y que la navegación hacia `/competitions/:id` no se activa.

### Tests for User Story 2

- [X] T005 [P] [US2] Add widget test in `test/presentation/panel/organizer_competitions_section_test.dart` verifying tapping `organizer_competition_menu_button_${tournament.id}` opens the popup menu items ("Editar metadatos", "Cambiar estado de competición", "Eliminar competición") without triggering card navigation

### Implementation for User Story 2

- [X] T006 [US2] Verify and ensure pointer event isolation and independent hit test handling for `PopupMenuButton` inside `KickPulseCard` in `lib/presentation/panel/widgets/organizer_competitions_section.dart`

**Checkpoint**: Menú secundario perfectamente aislado del gesto de toque de la tarjeta.

---

## Phase 5: User Story 3 - Resiliencia ante Pulsaciones Rápidas o Múltiples (Priority: P3)

**Goal**: Proteger la navegación contra toques repetidos o accidentales (< 500 ms) evitando apilar pantallas repetidas en la pila del navegador.

**Independent Test**: Simular múltiples toques rápidos consecutivos sobre la misma tarjeta y validar que la navegación se efectúa exactamente una sola vez.

### Tests for User Story 3

- [X] T007 [P] [US3] Add widget test in `test/presentation/panel/organizer_competitions_section_test.dart` verifying rapid successive taps (< 500ms) on `organizer_competition_card_${tournament.id}` trigger navigation exactly once

### Implementation for User Story 3

- [X] T008 [US3] Implement 500ms debouncing guard using `_lastNavigationTap` in `_handleTournamentTap` inside `lib/presentation/panel/widgets/organizer_competitions_section.dart`

**Checkpoint**: Protección contra duplicaciones de pantalla validada y operativa.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verificación de análisis estático, formato de código y ejecución de la suite completa de pruebas del panel.

- [X] T009 [P] Run static analysis (`flutter analyze`) and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) ensuring zero errors and zero warnings
- [X] T010 Run all panel test suites (`flutter test test/presentation/panel/organizer_competitions_section_test.dart test/presentation/panel/organizer_panel_widget_test.dart test/presentation/panel/organizer_panel_appbar_menu_test.dart test/presentation/panel/organizer_panel_menu_test.dart`) ensuring 100% passing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — se ejecuta de inmediato.
- **Foundational (Phase 2)**: Depende de Phase 1 — bloquea US1, US2 y US3.
- **User Story 1 (Phase 3 - P1 MVP)**: Depende de Phase 2.
- **User Story 2 (Phase 4 - P2)**: Depende de Phase 3 (tarjeta interactiva con navegación activa).
- **User Story 3 (Phase 5 - P3)**: Depende de Phase 3 (lógica de navegación base).
- **Polish (Final Phase)**: Depende de todas las fases anteriores.

### Parallel Opportunities

- `T003` (test US1), `T005` (test US2), y `T007` (test US3) pueden prepararse en paralelo una vez completada la fase fundacional.
- `T009` (análisis estático y formato) puede correr concurrentemente con la preparación de la suite completa en `T010`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1: Setup (`T001`).
2. Completar Phase 2: Foundational (`T002`).
3. Completar Phase 3: User Story 1 (`T003` - `T004`).
4. **Validar MVP**: El organizador puede tocar cualquier tarjeta de torneo en "Mis Competiciones" y navegar con éxito a la pantalla de detalle del campeonato.

### Incremental Delivery

1. Añadir User Story 2 (`T005` - `T006`) → Aislamiento verificado del menú de tres puntos.
2. Añadir User Story 3 (`T007` - `T008`) → Debouncing para resiliencia móvil ante pulsaciones repetidas.
3. Polish (`T009` - `T010`) → Análisis estático y suite completa de pruebas del panel.
