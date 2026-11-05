# Research: Navigation Drawer y Páginas de Directorio con Buscador

**Feature**: `014-navigation-drawer-directories`
**Date**: 2026-11-05

## Research Overview & Decisions

### Decision 1: Integración del Navigation Drawer en el Scaffold Principal

- **Context**: El menú lateral debe ser accesible universalmente por todos los roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`) desde cualquier sección de `AppShellScreen`.
- **Decision**: Configurar la propiedad `drawer: const AppNavigationDrawer()` en el `Scaffold` de `AppShellScreen`. Flutter gestiona automáticamente el icono hamburguesa (`Icons.menu`) en la posición `leading` del `AppBar` y el gesto nativo de deslizamiento lateral desde el borde (*edge swipe to open*).
- **Rationale**:
  - Evita construir botones personalizados o manejar controladores de animación manuales.
  - El Drawer estándar de Flutter (`NavigationDrawer` / `Drawer` de Material 3) se adapta de forma óptima a los tokens de diseño KickPulse (`KickPulseColors.surfaceBase`, `KickPulseColors.accentPrimary`, tipografía y bordes).
  - Al seleccionar una opción, se ejecuta `Navigator.of(context).pop()` antes de navegar a la ruta del directorio, garantizando que el Drawer esté completamente cerrado y que la nueva pantalla se apile con un botón de retroceso natural en su `AppBar`.
- **Alternatives Considered**:
  - *Custom Side Sheet*: Mayor complejidad de mantenimiento, no aprovecha el gesto nativo del sistema operativo ni la integración automática con el `Scaffold`.

---

### Decision 2: Algoritmo de Normalización y Búsqueda en Tiempo Real Insensible a Acentos (Diacritics-Insensitive)

- **Context**: El buscador superior debe filtrar en tiempo real de forma insensible a mayúsculas/minúsculas y acentos (ej. "alvarez" encuentra "Álvarez" y viceversa; "fútbol" encuentra "futbol").
- **Decision**: Crear una función utilitaria pura `normalizeSearchText(String input)` en `lib/application/utils/search_utils.dart` que convierte a minúsculas y reemplaza caracteres con tildes/marcas diacríticas mediante mapeo de caracteres acentuados en español:
  ```dart
  String normalizeSearchText(String input) {
    var text = input.trim().toLowerCase();
    const withAccents = 'áéíóúüñ';
    const withoutAccents = 'aeiouun';
    for (int i = 0; i < withAccents.length; i++) {
      text = text.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return text;
  }
  ```
  La búsqueda se realiza verificando `normalizedTarget.contains(normalizedQuery)`.
- **Rationale**:
  - Sin dependencias externas adicionales pesadas.
  - Rendimiento sub-milisegundo para listas locales de cientos de equipos, jugadores y torneos.
  - Idóneo para el español y nombres propios latinoamericanos comunes en fútbol aficionado y juvenil.
- **Alternatives Considered**:
  - *Paquete unorm / diacritic*: Añade dependencias de terceros innecesarias para un conjunto finito de caracteres diacríticos en español.
  - *RegExp*: Mayor sobrecarga computacional en filtrado iterativo cuadro a cuadro frente a sustitución de caracteres directa.

---

### Decision 3: Gestión de Estado y Controladores de los Directorios

- **Context**: Los directorios de Competiciones, Equipos y Jugadores necesitan gestionar:
  1. Consulta del catálogo base (reutilizando `tournamentsControllerProvider`, repositorios de equipos y jugadores).
  2. Término de búsqueda activo en tiempo real (`query`).
  3. Filtro de torneo seleccionado (`selectedTournamentId == null` para "Todos" o ID de torneo específico).
  4. Lista calculada de elementos filtrados.
- **Decision**: Implementar `StateNotifier` o `Notifier` en `flutter_riverpod` para cada directorio:
  - `CompetitionsDirectoryController` / `competitionsDirectoryControllerProvider`
  - `TeamsDirectoryController` / `teamsDirectoryControllerProvider`
  - `PlayersDirectoryController` / `playersDirectoryControllerProvider`
- **Rationale**:
  - Desacopla la lógica de filtrado y ordenamiento de los widgets visuales.
  - Facilita pruebas unitarias completas de búsqueda, borrado y filtrado por torneo sin necesidad de renderizar la interfaz.
  - Reacciona automáticamente a cambios en la base de datos local y permite actualizar en tiempo real si se crea una entidad desde el botón de acción rápida.
- **Alternatives Considered**:
  - *StatefulWidget local*: Menor reusabilidad y dificultad para probar el estado y los filtros de forma aislada.

---

### Decision 4: UX del Buscador y Manejo del Teclado Móvil

- **Context**: En dispositivos móviles (`320x640`), el teclado virtual puede cubrir los resultados y bloquear la experiencia de visualización.
- **Decision**:
  - El campo de búsqueda incluye un controlador `TextEditingController` con listener para actualizar el estado del controlador.
  - Se añade un `IconButton` con `Icons.clear` como `suffixIcon` visible solo cuando `query.isNotEmpty`.
  - La lista de resultados implementa `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, ocultando el teclado automáticamente al comenzar el desplazamiento.
  - Se garantiza que el campo de búsqueda tenga una altura táctil accesible (mínimo 44x44 px) con estilo KickPulse (`KickPulseColors.surfaceCard`, borde sutil y foco en `KickPulseColors.accentPrimary`).
- **Rationale**:
  - Cumplimiento estricto de `docs/MOBILE_GUIDELINES.md` (interacción, teclado y foco).
  - Experiencia fluida sin toques adicionales para ocultar el teclado.

---

### Decision 5: Acciones Rápidas Contextuales según Permisos del Rol

- **Context**: Usuarios con rol `Organizador` o permisos administrativos deben poder crear entidades directamente desde los directorios (decisión acordada en clarify).
- **Decision**:
  - Cada directorio consulta `activeRoleCapabilitiesProvider` o `activeUserRoleProvider`.
  - Si el usuario cuenta con la capacidad requerida (`manageTournaments`, `registerTeams`, `manageRoster`), se renderiza un `FloatingActionButton` o botón de acción en el `AppBar` con `Key` semántico (ej. `create_tournament_from_directory_button`, `create_team_from_directory_button`).
  - Al completar la creación, el controlador refresca automáticamente su lista de resultados.
- **Rationale**:
  - Mantiene la consistencia de permisos RBAC del sistema.
  - Ofrece accesos directos convenientes sin romper la segregación de roles.
