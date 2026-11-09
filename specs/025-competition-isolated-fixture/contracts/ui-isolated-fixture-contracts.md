# UI Contracts: Generación de Fixture Independiente por Competición (HU 15.2)

**Feature**: `025-competition-isolated-fixture`  
**Date**: 2026-11-09  

---

## 1. `MatchdayTabView` (`lib/presentation/shell/tabs/matchday_tab_view.dart`)

- **Retiro de Controles Administrativos**:
  - `Key('organizer_pending_matches_banner')`: **NO DEBE** existir en `MatchdayTabView` bajo ningún rol.
  - `Key('organizer_generate_fixture_button')` / `Key('generate_fixture_button')`: **NO DEBE** existir en `MatchdayTabView`.
- **Elementos Conservados**:
  - `Key('daily_matches_tab_bar')`: Barra rápida de fechas (*Ayer*, *Hoy*, *Mañana*).
  - `Key('tournament_group_${tournamentId}')`: Tarjetas de partidos agrupados por competición para la fecha seleccionada.

---

## 2. `CompetitionDetailScreen` FAB Menu (`lib/presentation/tournaments/competition_detail_screen.dart`)

- **Condición de Visibilidad**:
  - Visible **únicamente** si `activeUserRoleProvider == UserRole.organizer` (capacidad `RoleCapability.manageTournaments`) **Y** `tournament != null && tournament.status.isEditable` (`openRegistration` o `inProgress`).
  - Oculto para `Aficionado`, `Jugador`, `Entrenador`, `Árbitro` y para torneos en estado `finished`.
- **Widget Keys**:
  - `Key('competition_detail_fab_menu')`: Botón flotante principal (*Speed Dial* toggle) que alterna la visualización de las acciones rápidas de la competición.
  - `Key('competition_detail_fab_generate_fixture')`: Acción flotante expandida tipo píldora con etiqueta **"Generar Fixture"** e icono `Icons.alt_route` / `Icons.auto_awesome`.
- **Flujo de Interacción**:
  1. Tocar `competition_detail_fab_menu` despliega `competition_detail_fab_generate_fixture`.
  2. Tocar `competition_detail_fab_generate_fixture` colapsa el *Speed Dial* y abre `GenerateFixtureConfirmationDialog`.
  3. Confirmar en `confirm_generate_fixture_button` ejecuta `generateFixture` para la competición actual (`tournament`), actualiza las jornadas, permanece en la pestaña actual y muestra un `SnackBar` con `matchdayFixtureGeneratedSuccess(count)`.

---

## 3. Selector de Competición en `/panel` (`lib/presentation/panel/widgets/organizer_panel_content.dart`)

- **Punto de Entrada**:
  - Botón `Key('organizer_action_generate_fixture')` en `OrganizerPanelContent`.
- **Hoja Modal de Selección (`SelectTournamentForFixtureSheet`)**:
  - `Key('select_tournament_for_fixture_sheet')`: Contenedor principal del `ModalBottomSheet`.
  - `Key('select_tournament_fixture_item_${tournament.id}')`: Ítem seleccionable para cada competición editable (`openRegistration` o `inProgress`), mostrando nombre, categoría, estado y conteo de equipos habilitados.
- **Flujo de Interacción**:
  1. Si no existen competiciones editables, muestra un `SnackBar` informativo indicando que no hay competiciones activas disponibles.
  2. Si existen competiciones editables, despliega `select_tournament_for_fixture_sheet`.
  3. Al tocar `select_tournament_fixture_item_${tournament.id}`, se cierra el selector y se muestra `GenerateFixtureConfirmationDialog`.
  4. Al confirmar en `confirm_generate_fixture_button`, se genera el fixture exclusivamente para la competición seleccionada, se muestra el `SnackBar` con el conteo de partidos generados y se navega automáticamente a `/competitions/${tournament.id}`.
