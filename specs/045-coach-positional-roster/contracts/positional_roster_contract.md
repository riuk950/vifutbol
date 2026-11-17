# UI & Provider Contracts: Plantilla Agrupada por Posición (HU 20.2)

**Feature**: `045-coach-positional-roster`

## 1. Reactive Data Provider

- `teamSquadRosterProvider(team.id)` (`lib/application/providers/teams_providers.dart`):
  - Retorna `TeamSquadRoster` actualizado reactivamente cada vez que cambia `teamsControllerProvider`.

## 2. UI Component Contract (`CoachPositionalRosterSection`)

Ubicación: `lib/presentation/panel/widgets/coach_positional_roster_section.dart` (renderizado dentro de `CoachPanelContent` cuando `coachTeams.isNotEmpty`).

### Keys y Elementos Requeridos
- Contenedor de sección: `Key('coach_positional_roster_section')`
- Alerta por falta de porteros (solo visible cuando `roster.goalkeepers.isEmpty`):
  - `Key('coach_no_goalkeeper_tactical_alert')`
- Bloques posicionales (siempre renderizados en orden `goalkeeper` -> `defender` -> `midfielder` -> `forward`):
  - `Key('coach_roster_group_goalkeeper')` -> encabezado `"Porteros (N)"`
  - `Key('coach_roster_group_defender')` -> encabezado `"Defensas (N)"`
  - `Key('coach_roster_group_midfielder')` -> encabezado `"Mediocampistas (N)"`
  - `Key('coach_roster_group_forward')` -> encabezado `"Delanteros (N)"`
- Estado vacío dentro de un bloque cuando su lista está vacía:
  - `Key('coach_roster_empty_<positionName>')` con texto `"Sin jugadores en esta posición"`
- Ítem de jugador:
  - `Key('coach_roster_player_<shirtNumber>_<playerId>')`
  - Muestra: badge numérico `#<shirtNumber>`, `fullName` (con `overflow: TextOverflow.ellipsis`), y `KickPulseBadge` con `"Elegible"` (`KickPulseBadgeVariant.dev`) o `"Inactivo / Sancionado"` (`KickPulseBadgeVariant.warning`).
