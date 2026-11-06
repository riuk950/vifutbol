# Contratos de Interfaz: Detalle de Competición y Fixture Completo

**Feature**: `018-competition-detail-fixture`
**Date**: 2026-11-06

---

## 1. Claves de Widgets (`Key`)

### 1.1 `CompetitionDetailScreen`
- **Key raíz**: `Key('competition_detail_screen')`
- **Botón de Retroceso**: `Key('competition_detail_back_button')`
- **Título en AppBar**: `Key('competition_detail_title')`
- **Categoría en AppBar**: `Key('competition_detail_category')`
- **Insignia de Estado del Torneo**: `Key('competition_detail_status_badge')`

### 1.2 Barra de Pestañas (`TabBar`)
- **Key de TabBar**: `Key('competition_detail_tab_bar')`
- **Pestaña "Partidos"**: `Key('competition_detail_tab_matches')`
- **Pestaña "Clasificación"**: `Key('competition_detail_tab_standings')`
- **Pestaña "Información"**: `Key('competition_detail_tab_info')`
- **Key de TabBarView**: `Key('competition_detail_tab_bar_view')`

### 1.3 Pestaña de Fixture ("Partidos")
- **Key del Contenedor**: `Key('competition_detail_fixture_content')`
- **Lista de Jornadas**: `Key('competition_detail_fixture_list')`
- **Encabezado por Jornada**: `Key('fixture_round_header_${roundNumber}')`
- **Tarjeta de Partido**: `Key('fixture_match_item_${match.id}')`
- **Estado Vacío de Partidos**: `Key('fixture_empty_matches_state')`

### 1.4 Pestaña de Clasificación
- **Key del Contenedor**: `Key('competition_detail_standings_content')`

### 1.5 Pestaña de Información
- **Key del Contenedor**: `Key('competition_detail_info_content')`

---

## 2. Claves de Internacionalización (`app_es.arb`)

```json
{
  "competitionDetailTabMatches": "Partidos",
  "competitionDetailTabStandings": "Clasificación",
  "competitionDetailTabInfo": "Información",
  "fixtureEmptyMatchesTitle": "Calendario en Preparación",
  "fixtureEmptyMatchesMessage": "Esta competición aún no tiene partidos programados en su calendario oficial.",
  "fixturePendingScheduleBadge": "Pendiente de programación",
  "fixtureRoundLabel": "Jornada {roundNumber}",
  "competitionInfoTitle": "Reglamento Oficial",
  "competitionInfoMessage": "El sistema oficial de puntuación, desempates y normas disciplinarias estará disponible próximamente."
}
```

---

## 3. Comportamientos de Navegación

1. **Entrada a la Pantalla**:
   - `CompetitionsDirectoryScreen` ejecuta `Navigator.of(context).pushNamed('/competitions/${tournament.id}')`.
   - Si se abre directamente vía ruta `/competitions/:id`, el router extrae el parámetro `id`.
2. **Retroceso**:
   - Pulsar `competition_detail_back_button` invoca `Navigator.of(context).pop()`.
3. **Pulsación en Tarjeta de Partido**:
   - Al tocar `fixture_match_item_${match.id}`, se abre la hoja modal inferior `MatchCenterCard` con los detalles completos del encuentro.
