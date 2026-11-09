# Contratos de Interfaz: Pantalla de Detalle de Equipo con Pestañas y Resumen (HU 14.1)

**Feature**: `021-team-detail-summary`  
**Date**: 2026-11-09

---

## 1. Claves de Widgets (`Key`)

### 1.1 `TeamDetailScreen` (`/teams/:id`)
- **Key raíz**: `Key('team_detail_screen')`
- **Botón de Retroceso**: `Key('team_detail_back_button')`
- **Escudo en AppBar**: `Key('team_detail_app_bar_crest')`
- **Nombre del Equipo en AppBar**: `Key('team_detail_title')`
- **Código Corto en AppBar**: `Key('team_detail_short_code')`
- **Nombre de Competición en AppBar**: `Key('team_detail_competition_name')`
- **Insignia de Elegibilidad en AppBar**: `Key('team_detail_eligibility_badge')`
- **Estado Equipo No Encontrado**: `Key('team_detail_not_found_state')`

### 1.2 Barra de Pestañas (`TabBar`)
- **Key de TabBar**: `Key('team_detail_tab_bar')`
- **Pestaña "Información" (índice 0, activa por defecto)**: `Key('team_detail_tab_info')`
- **Pestaña "Partidos" (índice 1)**: `Key('team_detail_tab_matches')`
- **Pestaña "Plantilla" (índice 2)**: `Key('team_detail_tab_squad')`
- **Key de TabBarView**: `Key('team_detail_tab_bar_view')`

### 1.3 Contenido de la Pestaña "Información" (`TeamInfoTabView`)
- **Contenedor Scrollable**: `Key('team_info_tab_scroll_view')`
- **Tarjeta de Ficha del Club**: `Key('team_club_profile_card')`
  - Muestra de color primario: `Key('team_primary_color_swatch')`
  - Muestra de color secundario: `Key('team_secondary_color_swatch')`
- **Tarjeta de "Último Partido"**: `Key('team_last_match_card')`
  - Contenido con partido disputado: `Key('team_last_match_content')`
  - Estado vacío (*"Sin partidos previos disputados"*): `Key('team_last_match_empty_state')`
- **Tarjeta de "Próximo Partido"**: `Key('team_next_match_card')`
  - Contenido con partido programado: `Key('team_next_match_content')`
  - Estado vacío (*"Sin próximos partidos agendados"*): `Key('team_next_match_empty_state')`

### 1.4 Pestañas en Preparación (HU 14.2 y HU 14.3)
- **Contenedor Pestaña "Partidos"**: `Key('team_matches_tab_placeholder')`
- **Contenedor Pestaña "Plantilla"**: `Key('team_squad_tab_placeholder')`

### 1.5 Zonas Táctiles de Equipo en `MatchCenterCard`
- **Zona táctil equipo local**: `Key('match_card_home_team_${match.id}')`
- **Zona táctil equipo visitante**: `Key('match_card_away_team_${match.id}')`

---

## 2. Claves de Internacionalización (`lib/l10n/app_es.arb`)

```json
{
  "teamDetailTabInfo": "Información",
  "teamDetailTabMatches": "Partidos",
  "teamDetailTabSquad": "Plantilla",
  "teamDetailNotFoundTitle": "Equipo no encontrado",
  "teamDetailNotFoundMessage": "No se encontró la información del equipo solicitado en el catálogo local.",
  "teamDetailClubProfileTitle": "Ficha del Club",
  "teamDetailOfficialNameLabel": "Nombre oficial",
  "teamDetailShortCodeLabel": "Código oficial",
  "teamDetailCompetitionLabel": "Competición",
  "teamDetailClubColorsLabel": "Colores distintivos",
  "teamDetailPrimaryColorLabel": "Primario",
  "teamDetailSecondaryColorLabel": "Secundario",
  "teamDetailLastMatchTitle": "Último Partido",
  "teamDetailLastMatchEmpty": "Sin partidos previos disputados",
  "teamDetailNextMatchTitle": "Próximo Partido",
  "teamDetailNextMatchEmpty": "Sin próximos partidos agendados",
  "teamDetailOpponentLabel": "Rival",
  "teamDetailVenueLabel": "Sede / Cancha",
  "teamDetailDateLabel": "Fecha y hora",
  "teamDetailHomeConditionBadge": "Local",
  "teamDetailAwayConditionBadge": "Visitante",
  "teamDetailMatchesTabPlaceholderTitle": "Calendario del Equipo",
  "teamDetailMatchesTabPlaceholderMessage": "El historial completo y calendario de próximos partidos del equipo estará disponible en esta sección.",
  "teamDetailSquadTabPlaceholderTitle": "Plantilla Oficial",
  "teamDetailSquadTabPlaceholderMessage": "La nómina completa de jugadores con sus dorsales y posiciones tácticas estará disponible en esta sección."
}
```

---

## 3. Contratos de Navegación

1. **Desde `TeamsDirectoryScreen`**:
   - Tocar `Key('team_item_${team.id}')` selecciona el equipo en `teamsControllerProvider` y navega a `TeamDetailScreen(teamId: team.id)` con `RouteSettings(name: '/teams/${team.id}')`.
2. **Desde `MatchCenterCard`**:
   - Tocar `Key('match_card_home_team_${match.id}')` navega a `/teams/${match.homeTeamId}` si no es la ruta activa actual.
   - Tocar `Key('match_card_away_team_${match.id}')` navega a `/teams/${match.awayTeamId}` si no es la ruta activa actual.
   - Tocar el bloque central de marcador/hora mantiene el disparo de `onTap` de la tarjeta de partido.
3. **Ruta Declarativa en `AppRouter`**:
   - `/teams/:id` resuelve el parámetro `id` y construye `TeamDetailScreen(teamId: id)`.
