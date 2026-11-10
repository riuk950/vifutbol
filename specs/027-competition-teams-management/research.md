# Research & Technical Decisions: Gestión de Equipos Inscritos en Competición (HU 15.4)

**Feature**: `027-competition-teams-management`  
**Date**: 2026-11-10

## 1. Persistencia y Asignación de Grupos en `TournamentTeam` y `StandingsCalculatorService`

- **Decision**: Añadir el atributo opcional `final String? groupName` a `TournamentTeam` (serializado como `'groupName'` en JSON) y actualizar `StandingsCalculatorService.calculateGroupStageTables` para asignar primero los equipos cuyo `groupName` coincida con uno de los grupos configurados (`Grupo A` .. `Grupo <N>`) y distribuir de manera determinista por índice (`i % groupCount`) únicamente aquellos equipos con `groupName == null` o cuyo `groupName` exceda el número de grupos actuales.
- **Rationale**: Garantiza 100% de retrocompatibilidad con los equipos semilla (`twenty_teams_seed.dart`) y pruebas existentes que no especifican `groupName`, a la vez que permite al Organizador trasladar explícitamente cualquier equipo a otro grupo y ver el resultado reflejado de inmediato tanto en la pestaña **Equipos** como en las tablas por grupo de **Clasificación**.
- **Alternatives considered**:
  - *Guardar un mapa `Map<String, String> teamGroups` dentro de `ChampionshipTournament`*: Descartado porque acopla el agregado de torneo a las mutaciones de equipos y complica la sincronización con `TeamsRepository`.

## 2. Flujo de Inscripción desde el FAB Menu (`CompetitionEnrollTeamDialog`)

- **Decision**: En `CompetitionDetailScreen`, cuando `_isSpeedDialOpen == true`, renderizar dos botones `FloatingActionButton.extended`:
  1. `Key('competition_detail_fab_add_team')` ("Agregar Equipo", icono `Icons.group_add`)
  2. `Key('competition_detail_fab_generate_fixture')` ("Generar Fixture", icono `Icons.alt_route`)
  Al tocar `competition_detail_fab_add_team`, abrir `CompetitionEnrollTeamDialog`, que permite:
  - **Modo "Nuevo Equipo"** (por defecto) o pre-llenado rápido seleccionando un club existente de otros torneos (`Key('enroll_team_existing_club_dropdown')`) que aún no esté inscrito en esta competición.
  - Campos de **Nombre del equipo** (`Key('enroll_team_name_field')`), **Código corto (Sigla)** (`Key('enroll_team_short_code_field')`), **Forma de escudo** y **Selector de Grupo** (`Key('enroll_team_group_dropdown')`, visible cuando `tournament.format == TournamentFormat.mixedGroupsAndKnockout`).
- **Rationale**: Satisface tanto la creación rápida de un club nuevo para el campeonato como la reutilización de clubes del directorio general en un solo diálogo compacto y sin salir de `/competitions/:id`.
- **Alternatives considered**:
  - *Navegar fuera de la competición hacia el Panel Administrativo*: Descartado porque rompe el contexto del organizador que está configurando la competición en `/competitions/:id`.

## 3. Reglas de Permisos del Organizador en `ManageTeamsEligibilityUseCase`

- **Decision**: Incorporar tres métodos específicos en `ManageTeamsEligibilityUseCase` y `TeamsController` sin alterar el comportamiento existente de `registerOrUpdateTeam`:
  - `enrollTeamInCompetition({required TournamentTeam team, required ChampionshipTournament tournament, required UserRole actorRole})`: Requiere `RoleCapability.manageTournaments` (`UserRole.organizer`) y `tournament.status.isEditable` (`openRegistration` o `inProgress`), validando longitud de nombre ($\ge 3$), sigla ($2\text{–}4$ caracteres) y unicidad de nombre normalizado en el torneo.
  - `removeTeamFromCompetition({required String teamId, required ChampionshipTournament tournament, required UserRole actorRole})`: Requiere `RoleCapability.manageTournaments` y `tournament.status.isEditable`, verificando que el equipo pertenezca al `tournament.id` y eliminándolo mediante `TeamsRepository.deleteTeam(teamId)`.
  - `moveTeamToGroup({required String teamId, required String groupName, required ChampionshipTournament tournament, required UserRole actorRole})`: Requiere `RoleCapability.manageTournaments` y `tournament.status.isEditable`, validando que `groupName` no esté vacío y actualizando el equipo con `team.copyWith(groupName: groupName, updatedAt: DateTime.now())`.
- **Rationale**: Preserva intactos todos los tests unitarios existentes de `registerOrUpdateTeam` (que prueban el flujo de inscripción de entrenadores restringido a `openRegistration`), mientras habilita al Organizador para administrar equipos mientras la competición sea editable (`openRegistration` o `inProgress`).
- **Alternatives considered**:
  - *Modificar `_ensureOpenRegistration` globalmente*: Descartado porque rompería los tests unitarios existentes que verifican el bloqueo de `registerOrUpdateTeam` fuera de `openRegistration`.

## 4. Diseño del `TabBar` de 4 Pestañas en `CompetitionDetailScreen` ($320 \times 640\text{ px}$ @ $130\%$)

- **Decision**: Actualizar `DefaultTabController(length: 4)` en `CompetitionDetailScreen` con las pestañas:
  1. `Partidos` (`Key('competition_detail_tab_matches')`)
  2. `Clasificación` (`Key('competition_detail_tab_standings')`)
  3. `Equipos` (`Key('competition_detail_tab_teams')`)
  4. `Información` (`Key('competition_detail_tab_info')`)
  Configurar `labelPadding: const EdgeInsets.symmetric(horizontal: 6)` y `TextOverflow.ellipsis` / `maxLines: 1` en las pestañas para que las 4 pestañas sean siempre visibles y pulsables directamente en pantallas de $320\text{ px}$ de ancho con escalado de texto del $130\%$ sin necesidad de scroll horizontal ni desbordamiento (`RenderFlex overflow`).
- **Rationale**: Mantiene la compatibilidad con los tests de responsividad existentes (`directories_responsive_widget_test.dart` y `competition_detail_screen_test.dart`) que pulsan directamente `competition_detail_tab_info` sin hacer scroll horizontal del `TabBar`.
- **Alternatives considered**:
  - *Usar `isScrollable: true` en el `TabBar`*: Descartado porque en $320\text{ px}$ con $130\%$ de texto la cuarta pestaña (`competition_detail_tab_info`) quedaría fuera del viewport horizontal, haciendo fallar los tests existentes que llaman a `tester.tap(find.byKey(const Key('competition_detail_tab_info')))` directamente.
