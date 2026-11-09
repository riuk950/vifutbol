# Research: Generación de Fixture Independiente por Competición (HU 15.2)

**Feature**: `025-competition-isolated-fixture`  
**Date**: 2026-11-09  

---

## 1. Aislamiento Estricto por Competición en `FixtureSchedulingUseCase` y `MatchesCatalogController`

- **Decision**: Filtrar explícitamente `teams` por `t.tournamentId == tournament.id && t.isEligible` dentro de `FixtureSchedulingUseCase.generateRoundRobinFixture`, reemplazar los partidos del torneo usando `matchesRepository.replaceMatchesForTournament(tournament.id, generatedMatches)` y conservar en `MatchesCatalogController.state.matches` los partidos de otros torneos (`otherTournamentMatches + updatedMatches`).
- **Rationale**:
  - Anteriormente, `FixtureSchedulingUseCase.generateRoundRobinFixture` solo filtraba `teams.where((t) => t.isEligible)`, lo que permitía que si se pasaba `teamsControllerProvider.teams` (que contiene equipos de todos los campeonatos), se generaran partidos mezclando equipos de otros torneos.
  - Asimismo, en `MatchesCatalogController.generateFixture`, conservar en `state.matches` los partidos de otros campeonatos (`m.tournamentId != tournament.id`) evita que las vistas globales (`DailyMatchesFeedController`, `OrganizerPanelContent`) pierdan la referencia a partidos de otros torneos activos en memoria.
- **Alternatives Considered**:
  - Filtrar los equipos únicamente en la capa de presentación antes de invocar el controlador: descartado porque la regla de negocio de aislamiento debe estar protegida en el caso de uso de dominio/aplicación (`FixtureSchedulingUseCase`) para evitar errores desde cualquier punto de entrada.

---

## 2. Retiro Completo del Banner Organizativo en `MatchdayTabView`

- **Decision**: Eliminar `OrganizerPendingMatchesBanner` y los métodos `_onGenerateFixture` y `_onOpenScheduleDialogForPending` de `MatchdayTabView`, dejando la pantalla principal de **Partidos** dedicada 100% a la consulta cronológica de partidos por fecha (*Ayer*, *Hoy*, *Mañana* y *Calendario*) para todos los roles.
- **Rationale**:
  - Cumple el requerimiento de negocio 1 y la clarificación Q1 (`Opción A`): separar por completo el feed diario de consulta respecto a las acciones operativas de administración de torneos, que ahora residen en `/panel` y `/competitions/:id`.
- **Alternatives Considered**:
  - Ocultar únicamente el botón "Generar Fixture" dentro de `OrganizerPendingMatchesBanner`: descartado por decisión explícita del usuario en Q1 (`Opción A`).

---

## 3. FAB Menu Expandible (*Speed Dial*) en `CompetitionDetailScreen`

- **Decision**: Convertir `CompetitionDetailScreen` en `ConsumerStatefulWidget` (o incorporar un widget dedicado `CompetitionDetailFabMenu`) que renderice un `floatingActionButton` de tipo *Speed Dial* únicamente cuando `RolePermissionMatrix.hasCapability(userRole, RoleCapability.manageTournaments)` (`UserRole.organizer`) y `tournament != null && tournament.status.isEditable`.
- **Rationale**:
  - Al pulsar el FAB principal (`Key('competition_detail_fab_menu')`), se alterna el estado expandido mostrando la acción flotante tipo píldora **"Generar Fixture"** (`Key('competition_detail_fab_generate_fixture')`).
  - Al seleccionar **"Generar Fixture"**, el *Speed Dial* se colapsa inmediatamente, se abre `GenerateFixtureConfirmationDialog`, y al confirmar se invoca `matchesCatalogControllerProvider.notifier.generateFixture` para ese `tournament`, mostrando un `SnackBar` con el conteo de partidos generados para la competición (permaneciendo en la pestaña activa según la clarificación de `/speckit-clarify`).
- **Alternatives Considered**:
  - `PopupMenuButton` o `ModalBottomSheet` desde el FAB: descartado por decisión explícita en Q2 (`Opción A`).

---

## 4. Selector Modal de Competición en `OrganizerPanelContent` (`/panel`)

- **Decision**: Crear un componente modal inferior `SelectTournamentForFixtureSheet` (`Key('select_tournament_for_fixture_sheet')`) que se abre cuando el organizador pulsa la acción rápida **"Generar Fixture"** (`Key('organizer_action_generate_fixture')`) en `/panel`.
- **Rationale**:
  - Lista todas las competiciones editables (`TournamentStatus.openRegistration` y `TournamentStatus.inProgress`), mostrando su nombre, categoría, badge de estado y cantidad de equipos elegibles (`teams.where((t) => t.tournamentId == tournament.id && t.isEligible).length`).
  - Al tocar una competición (`Key('select_tournament_fixture_item_${tournament.id}')`), se cierra la hoja modal, se solicita confirmación mediante `GenerateFixtureConfirmationDialog`, se genera el fixture aisladamente para ese torneo, se muestra el `SnackBar` con el conteo de partidos generados y se navega automáticamente a `/competitions/${tournament.id}` (conforme a la clarificación de `/speckit-clarify`).
- **Alternatives Considered**:
  - Seleccionar automáticamente el primer torneo sin fixture: comportamiento previo que impedía al organizador elegir a qué torneo generarle el calendario cuando existían múltiples torneos activos.
