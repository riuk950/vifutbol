# UI & Navigation Contracts: Navigation Drawer y Páginas de Directorio con Buscador

**Feature**: `014-navigation-drawer-directories`
**Date**: 2026-11-05

## 1. Rutas de Navegación del Router

| Ruta | Nombre del Manejador | Pantalla Destino | Parámetros | Comportamiento del AppBar |
|------|----------------------|------------------|------------|---------------------------|
| `/` | `shellHandler` | `AppShellScreen` | Ninguno | Título institucional, botón Drawer (leading), campana de alertas (actions). |
| `/competitions` | `competitionsDirectoryHandler` | `CompetitionsDirectoryScreen` | Ninguno | Botón Atrás (`leading: BackButton()`), Título "Competiciones", acción de creación si rol tiene permisos. |
| `/teams` | `teamsDirectoryHandler` | `TeamsDirectoryScreen` | Ninguno | Botón Atrás, Título "Equipos", acción de registro si rol tiene permisos. |
| `/players` | `playersDirectoryHandler` | `PlayersDirectoryScreen` | Ninguno | Botón Atrás, Título "Jugadores", acción de registro si rol tiene permisos. |
| `/venues` | `venuesHandler` | `VenuesDirectoryScreen` | Ninguno | Botón Atrás, Título "Sedes Deportivas", acción de agregar sede si rol es organizador. |

---

## 2. Contrato del Componente `AppNavigationDrawer`

### Ubicación
`lib/presentation/shell/widgets/app_navigation_drawer.dart`

### Propiedades y Keys de Prueba Semánticas

| Elemento Visual | `Key` de Localización en Pruebas | Tipo de Widget | Comportamiento |
|-----------------|---------------------------------|----------------|----------------|
| Drawer Raíz | `Key('app_navigation_drawer')` | `Drawer` / `NavigationDrawer` | Contenedor principal con tema Obsidian Pitch. |
| Encabezado | `Key('app_drawer_header')` | `DrawerHeader` / `Column` | Nombre de usuario, email, rol (`KickPulseBadge`) y logo de la app. |
| Ítem Competiciones | `Key('drawer_destination_competitions')` | `NavigationDrawerDestination` o `ListTile` | Cierra drawer (`pop`) y navega a `/competitions`. |
| Ítem Equipos | `Key('drawer_destination_teams')` | `NavigationDrawerDestination` o `ListTile` | Cierra drawer (`pop`) y navega a `/teams`. |
| Ítem Jugadores | `Key('drawer_destination_players')` | `NavigationDrawerDestination` o `ListTile` | Cierra drawer (`pop`) y navega a `/players`. |
| Ítem Sedes | `Key('drawer_destination_venues')` | `NavigationDrawerDestination` o `ListTile` | Cierra drawer (`pop`) y navega a `/venues`. |

---

## 3. Contrato del Buscador Superior (`KickPulseSearchBar`)

Componente reutilizable de búsqueda en tiempo real:

### Ubicación
`lib/presentation/design_system/widgets/kick_pulse_search_bar.dart`

### API Contract
```dart
class KickPulseSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const KickPulseSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
  });
}
```

### Comportamiento
- Muestra icono de búsqueda `Icons.search` a la izquierda.
- Altura mínima táctil de 44 px.
- Muestra `IconButton(icon: Icon(Icons.clear), onPressed: ...)` en el extremo derecho cuando el campo contiene texto (`query.isNotEmpty`).
- El botón de limpieza borra el texto del controlador, notifica con `onChanged('')` y ejecuta `onClear`.
- Se adhiere a los tokens de color KickPulse (`KickPulseColors.surfaceCard`, `KickPulseColors.accentPrimary` al enfocar).

---

## 4. Contratos de Interacción de las Pantallas de Directorio

### `CompetitionsDirectoryScreen`
- **Buscador**: `Key('competitions_search_bar')`
- **Lista de torneos**: `Key('competitions_directory_list')`
- **Tarjeta de torneo**: `Key('competition_item_${tournament.id}')`
- **Tap en torneo**: Ejecuta `ref.read(tournamentsControllerProvider.notifier).selectTournament(tournament.id)` y `Navigator.of(context).pop()`.
- **Botón crear** (solo organizador): `Key('create_tournament_from_directory_button')`
- **Estado vacío**: `Key('competitions_empty_state')`

### `TeamsDirectoryScreen`
- **Buscador**: `Key('teams_search_bar')`
- **Selector horizontal de torneos**: `Key('teams_tournament_selector')`
- **Chip Todos**: `Key('teams_tournament_chip_all')`
- **Chip Torneo**: `Key('teams_tournament_chip_${tournament.id}')`
- **Lista de equipos**: `Key('teams_directory_list')`
- **Tarjeta de equipo**: `Key('team_item_${team.id}')`
- **Tap en equipo**: Abre `showTeamDetailedStatsSheet` con la plantilla del equipo.
- **Botón crear** (roles autorizados): `Key('create_team_from_directory_button')`
- **Estado vacío**: `Key('teams_empty_state')`

### `PlayersDirectoryScreen`
- **Buscador**: `Key('players_search_bar')`
- **Selector horizontal de torneos**: `Key('players_tournament_selector')`
- **Chip Todos**: `Key('players_tournament_chip_all')`
- **Chip Torneo**: `Key('players_tournament_chip_${tournament.id}')`
- **Lista de jugadores**: `Key('players_directory_list')`
- **Fila/Tarjeta de jugador**: `Key('player_item_${player.id}')`
- **Tap en jugador**: Abre `showPlayerPerformanceProfileSheet` con la ficha de rendimiento.
- **Botón inscribir** (roles autorizados): `Key('register_player_from_directory_button')`
- **Estado vacío**: `Key('players_empty_state')`
