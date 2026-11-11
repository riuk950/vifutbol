# Tasks: Reorganización del Panel de Organización: Menú en AppBar y Depuración de Acciones Rápidas (HU 18.2)

**Input**: Design documents from `/specs/033-organizer-panel-menu/`  
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/panel-menu-contracts.md](./contracts/panel-menu-contracts.md)  
**Tests**: Incluidos conforme al Principio III de la Constitución (*Pruebas Automatizadas como Puerta de Calidad*).  
**Organization**: Tareas agrupadas por fases (Setup, Foundational, US1, US2, US3 y Polish) para habilitar entrega y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Ejecutable en paralelo (archivos independientes, sin dependencias cruzadas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`).
- Todas las descripciones incluyen las rutas de archivo exactas.

---

## Phase 1: Setup (Models & Shared Infrastructure)

**Purpose**: Definir la enumeración de acciones del menú de organización y verificar claves de localización compartidas.

- [X] T001 [P] Create `OrganizerMenuAction` enum in `lib/presentation/panel/models/organizer_menu_action.dart` with values `publishNews` and `backup`

---

## Phase 2: Foundational (AppBar Menu Component & Base Tests)

**Purpose**: Construir el componente del menú contextual (`PopupMenuButton`) con sus dos opciones alusivas antes de integrarlo en la pantalla del panel.

**⚠️ CRITICAL**: Ninguna historia de usuario puede arrancar hasta completar esta fase.

- [X] T002 [P] Create unit/widget tests in `test/presentation/panel/organizer_panel_appbar_menu_test.dart` verifying `OrganizerPanelAppBarMenu` renders a `PopupMenuButton` with key `organizer_panel_appbar_menu` and displays exactly two items with icons and text (`organizer_menu_publish_news` and `organizer_menu_backup`)
- [X] T003 Implement `OrganizerPanelAppBarMenu` in `lib/presentation/panel/widgets/organizer_panel_appbar_menu.dart` with `PopupMenuButton<OrganizerMenuAction>`, themed styling (`KickPulseColors.surfaceElevated`, `KickPulseRadiiSpacing.chipBorderRadius`), icons and labels

**Checkpoint**: Componente base del menú probado y listo para integración en el panel.

---

## Phase 3: User Story 1 - Retiro de Acciones Rápidas del Cuerpo del Panel (Priority: P1) 🎯 MVP

**Goal**: Limpiar el cuerpo del panel del organizador retirando la sección de tarjetas de "Acciones Rápidas" y los botones de fixture y calendario, optimizando la visibilidad de métricas y competiciones.

**Independent Test**: Renderizar `OrganizerPanelContent` y verificar que el bloque de "Acciones Rápidas" no existe en el árbol de widgets y que las métricas están seguidas directamente por `OrganizerCompetitionsSection`.

### Tests for User Story 1

- [X] T004 [US1] Update widget tests in `test/presentation/panel/organizer_panel_widget_test.dart` to assert that `organizer_action_generate_fixture`, `organizer_action_schedule_matches`, `organizer_action_publish_news`, and `organizer_action_backup` are no longer present in `OrganizerPanelContent`

### Implementation for User Story 1

- [X] T005 [US1] Refactor `OrganizerPanelContent` in `lib/presentation/panel/widgets/organizer_panel_content.dart` to remove the "Acciones Rápidas" header, `KickPulseCard` with quick action buttons, and obsolete fixture/schedule handler methods, leaving metrics followed directly by `OrganizerCompetitionsSection`

**Checkpoint**: Cuerpo del panel del organizador limpio y sin accesos redundantes; MVP visual completado.

---

## Phase 4: User Story 2 - Menú Contextual en la Barra Superior con Acciones Depuradas (Priority: P2)

**Goal**: Incorporar el menú contextual en el `AppBar` de `PanelScreen` exclusivo para el rol de Organizador, excluyéndolo para otros roles.

**Independent Test**: Abrir `PanelScreen` como Organizador y verificar presencia de `organizer_panel_appbar_menu`; conmutar a Entrenador, Árbitro o Jugador y verificar que el menú no se renderiza.

### Tests for User Story 2

- [X] T006 [P] [US2] Create widget tests in `test/presentation/panel/organizer_panel_menu_test.dart` verifying that `PanelScreen` displays `organizer_panel_appbar_menu` when `activeRole == UserRole.organizer` and hides it for `UserRole.coach`, `UserRole.referee`, `UserRole.player`, and `UserRole.fan`

### Implementation for User Story 2

- [X] T007 [US2] Update `PanelScreen` in `lib/presentation/panel/panel_screen.dart` to include `OrganizerPanelAppBarMenu` in `appBar.actions` conditionally when `activeRole == UserRole.organizer`

**Checkpoint**: Barra superior del panel adaptada dinámicamente con segregación estricta por rol.

---

## Phase 5: User Story 3 - Ejecución de Acciones Globales desde el Menú Contextual (Priority: P3)

**Goal**: Conectar las opciones del menú contextual en el AppBar para abrir el diálogo de noticias (con soporte para comunicados generales si no hay torneos) y la hoja de respaldo/cierre de temporada.

**Independent Test**: Seleccionar "Publicar Noticia" en el menú contextual y verificar la apertura de `CreateNewsDialog`; seleccionar "Copia de Seguridad" y verificar la apertura de `TournamentBackupSheet`.

### Tests for User Story 3

- [X] T008 [P] [US3] Add widget tests in `test/presentation/panel/organizer_panel_menu_test.dart` verifying that selecting `organizer_menu_publish_news` opens `CreateNewsDialog` (using fallback `tournamentId: 'general'` if no editable tournaments exist) and selecting `organizer_menu_backup` opens `TournamentBackupSheet`

### Implementation for User Story 3

- [X] T009 [US3] Implement action handlers in `OrganizerPanelAppBarMenu` in `lib/presentation/panel/widgets/organizer_panel_appbar_menu.dart` to invoke `CreateNewsDialog.show` (with general announcement fallback if tournaments list is empty) and `TournamentBackupSheet.show`

**Checkpoint**: Flujo de acciones globales completamente operativo desde la barra superior del panel.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verificación de análisis estático, formato de código y ejecución de la suite completa de pruebas del panel.

- [X] T010 [P] Run static analysis (`flutter analyze`) and code formatting (`dart format --output=none --set-exit-if-changed lib/ test/`) ensuring zero errors and zero warnings
- [X] T011 Run all panel test suites (`flutter test test/presentation/panel/organizer_panel_widget_test.dart test/presentation/panel/organizer_panel_appbar_menu_test.dart test/presentation/panel/organizer_panel_menu_test.dart`) ensuring 100% passing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — se ejecuta de inmediato.
- **Foundational (Phase 2)**: Depende de Phase 1 — bloquea US1, US2 y US3.
- **User Story 1 (Phase 3 - P1 MVP)**: Depende de Phase 2.
- **User Story 2 (Phase 4 - P2)**: Depende de Phase 2 (puede avanzar en paralelo o tras US1).
- **User Story 3 (Phase 5 - P3)**: Depende de Phase 4 (menú integrado en AppBar listo para navegación).
- **Polish (Final Phase)**: Depende de todas las fases anteriores.

### Parallel Opportunities

- `T001` (enum) y `T002` (test base) pueden escribirse en paralelo.
- `T004` (test US1) y `T006` (test US2) pueden avanzar en paralelo.
- `T008` (test US3) puede escribirse antes de conectar handlers en `T009`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1: Setup (`T001`).
2. Completar Phase 2: Foundational (`T002` - `T003`).
3. Completar Phase 3: User Story 1 (`T004` - `T005`).
4. **Validar MVP**: El organizador ve un panel limpio con métricas y competiciones sin tarjetas de acciones obsoletas en el cuerpo.

### Incremental Delivery

1. Añadir User Story 2 (`T006` - `T007`) → Menú contextual en el AppBar para el organizador.
2. Añadir User Story 3 (`T008` - `T009`) → Ejecución de acciones de noticias y respaldos con fallback general.
3. Polish (`T010` - `T011`) → Análisis estático, formateo y suite de pruebas del panel.
