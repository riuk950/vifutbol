# UI & Localization Contracts: Gestión de Equipos Inscritos en Competición (HU 15.4)

**Feature**: `027-competition-teams-management`  
**Date**: 2026-11-10

## 1. Widget Keys Contract

| Component | Widget Key | Description |
|-----------|------------|-------------|
| `CompetitionDetailScreen` | `Key('competition_detail_tab_teams')` | Pestaña **"Equipos"** en el `TabBar` de la competición |
| `CompetitionDetailScreen` | `Key('competition_detail_fab_add_team')` | Botón extendido **"Agregar Equipo"** dentro del FAB Speed Dial Menu |
| `CompetitionTeamsTabView` | `Key('competition_teams_tab_view')` | Contenedor raíz de la pestaña de equipos inscritos |
| `CompetitionTeamsTabView` | `Key('competition_teams_empty_state')` | Estado vacío cuando el campeonato no tiene equipos inscritos |
| `CompetitionTeamsTabView` | `Key('competition_team_group_header_${groupName}')` | Encabezado de sección por grupo (*Grupo A*, *Grupo B*, ...) en torneos `mixedGroupsAndKnockout` |
| `CompetitionTeamsTabView` | `Key('competition_team_card_${team.id}')` | Tarjeta de equipo inscrito en el campeonato |
| `CompetitionTeamsTabView` | `Key('competition_team_group_badge_${team.id}')` | Insignia de grupo asignado (*Grupo A*, *Grupo B*, ...) en torneos `mixedGroupsAndKnockout` |
| `CompetitionTeamsTabView` | `Key('competition_team_move_group_${team.id}')` | Botón/acción del Organizador para trasladar al equipo de grupo |
| `CompetitionTeamsTabView` | `Key('competition_team_remove_${team.id}')` | Botón/acción del Organizador para quitar el equipo del campeonato |
| `CompetitionTeamsTabView` | `Key('competition_move_group_dialog')` | Diálogo/modal para seleccionar el nuevo grupo del equipo |
| `CompetitionTeamsTabView` | `Key('competition_move_group_option_${groupName}')` | Opción seleccionable de grupo en el modal de traslado |
| `CompetitionTeamsTabView` | `Key('competition_remove_team_confirm_dialog')` | Diálogo de confirmación para retirar el equipo del campeonato |
| `CompetitionTeamsTabView` | `Key('competition_remove_team_confirm_button')` | Botón de confirmación destructiva en el diálogo de retiro |
| `CompetitionEnrollTeamDialog` | `Key('competition_enroll_team_dialog')` | Diálogo para inscribir un equipo desde el FAB Menu |
| `CompetitionEnrollTeamDialog` | `Key('enroll_team_existing_club_dropdown')` | Selector opcional para pre-cargar datos de un club existente de otros torneos |
| `CompetitionEnrollTeamDialog` | `Key('enroll_team_name_field')` | Campo de texto para el nombre oficial del equipo |
| `CompetitionEnrollTeamDialog` | `Key('enroll_team_short_code_field')` | Campo de texto para la sigla (`shortCode`) de 2 a 4 caracteres |
| `CompetitionEnrollTeamDialog` | `Key('enroll_team_group_dropdown')` | Selector de grupo inicial cuando el torneo es `mixedGroupsAndKnockout` |
| `CompetitionEnrollTeamDialog` | `Key('enroll_team_submit_button')` | Botón de envío para confirmar la inscripción del equipo |

---

## 2. Localization Keys (`lib/l10n/app_es.arb`)

| Key | Spanish Value |
|-----|---------------|
| `competitionDetailTabTeams` | `"Equipos"` |
| `competitionFabAddTeamLabel` | `"Agregar Equipo"` |
| `competitionTeamsEmptyTitle` | `"Sin equipos inscritos"` |
| `competitionTeamsEmptyDescription` | `"Aún no hay clubes registrados en esta competición. Usa el botón de acciones para inscribir equipos."` |
| `competitionTeamsHeaderCount` | `"Equipos Inscritos ({count})"` |
| `competitionTeamPlayersCount` | `"{count} jugadores"` |
| `competitionTeamMoveGroupTooltip` | `"Trasladar de grupo"` |
| `competitionTeamRemoveTooltip` | `"Quitar del campeonato"` |
| `competitionMoveGroupDialogTitle` | `"Trasladar de Grupo"` |
| `competitionMoveGroupSuccess` | `"{teamName} trasladado a {groupName}"` |
| `competitionRemoveTeamConfirmTitle` | `"Quitar Equipo del Campeonato"` |
| `competitionRemoveTeamConfirmMessage` | `"¿Estás seguro de que deseas retirar a {teamName} de esta competición?"` |
| `competitionRemoveTeamConfirmAction` | `"Quitar Equipo"` |
| `competitionRemoveTeamSuccess` | `"Equipo retirado del campeonato"` |
| `competitionRemoveTeamHasPlayedMatchesError` | `"No se puede retirar un equipo que ya tiene partidos en curso o finalizados"` |
| `competitionEnrollTeamDialogTitle` | `"Inscribir Equipo en Competición"` |
| `competitionEnrollTeamExistingClubLabel` | `"Copiar de club existente (opcional)"` |
| `competitionEnrollTeamNewClubOption` | `"Crear nuevo equipo"` |
| `competitionEnrollTeamGroupLabel` | `"Grupo asignado"` |
| `competitionEnrollTeamSubmitAction` | `"Inscribir Equipo"` |
| `competitionEnrollTeamSuccess` | `"Equipo {teamName} inscrito en la competición"` |
