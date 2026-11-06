# UI & Navigation Contracts: Panel Administrativo Dinámico por Rol (HU 12.2)

**Feature**: `017-role-dynamic-panel`
**Date**: 2026-11-06

---

## 1. Contrato de Títulos Dinámicos de AppBar

| Rol Activo | Clave de Localización | Texto Localizado (ES) | Clave de Test |
| :--- | :--- | :--- | :--- |
| `UserRole.organizer` | `panelTitleOrganizer` | "Panel de Organización" | `Key('panel_screen_title')` |
| `UserRole.coach` | `panelTitleCoach` | "Panel Técnico" | `Key('panel_screen_title')` |
| `UserRole.referee` | `panelTitleReferee` | "Panel Arbitral" | `Key('panel_screen_title')` |
| `UserRole.player` | `panelTitlePlayer` | "Ficha del Jugador" | `Key('panel_screen_title')` |
| `UserRole.fan` | `drawerPanel` | "Panel" | `Key('panel_screen_title')` |

---

## 2. Contratos de Widgets y Keys de Prueba

### 2.1 `OrganizerPanelContent`
- **Key raíz**: `Key('organizer_panel_content')`
- **Métricas**:
  - `Key('organizer_metric_active_tournaments')`
  - `Key('organizer_metric_pending_matches')`
  - `Key('organizer_metric_unseeded_tournaments')`
- **Acciones Rápidas**:
  - `Key('organizer_action_generate_fixture')` ("Generar Fixture")
  - `Key('organizer_action_schedule_matches')` ("Programar Partido")
  - `Key('organizer_action_backup')` ("Copia de Seguridad")

### 2.2 `CoachPanelContent`
- **Key raíz**: `Key('coach_panel_content')`
- **Métricas**:
  - `Key('coach_metric_total_players')`
  - `Key('coach_metric_eligible_players')`
  - `Key('coach_metric_suspended_players')`
- **Acciones Rápidas**:
  - `Key('coach_action_match_lineup')` ("Convocatoria para el Próximo Partido")
  - `Key('coach_action_manage_roster')` ("Gestionar Plantilla")

### 2.3 `RefereePanelContent`
- **Key raíz**: `Key('referee_panel_content')`
- **Lista de Partidos Asignados**:
  - `Key('referee_assigned_matches_list')`
  - Por partido: `Key('referee_match_item_${match.id}')`
  - Acción por partido: `Key('referee_open_match_report_${match.id}')` ("Acta Digital")
- **Estado Vacío**:
  - `Key('referee_empty_matches_state')`

### 2.4 `PlayerPanelContent`
- **Key raíz**: `Key('player_panel_content')`
- **Elegibilidad**:
  - `Key('player_eligibility_badge')` ("Habilitado" o "Sancionado")
- **Estadísticas de Temporada**:
  - `Key('player_stat_goals')`
  - `Key('player_stat_assists')`
  - `Key('player_stat_yellow_cards')`
  - `Key('player_stat_red_cards')`
  - `Key('player_stat_matches_played')`

### 2.5 `FanPanelRestrictedContent`
- **Key raíz**: `Key('fan_panel_restricted_content')`
- **Mensaje**:
  - Texto explicando la exclusividad del panel
- **Botón de Retorno**:
  - `Key('fan_restricted_return_matches_button')` ("Volver a Partidos")
  - Comportamiento: Navega a `/matches` y restablece la pestaña del Shell.
