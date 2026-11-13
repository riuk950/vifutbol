# Quickstart & Validation Guide: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Feature**: `specs/039-players-directory-cloud-sync`  
**Status**: Ready for Validation  
**Date**: 2026-11-13  

---

## 1. Prerrequisitos de Ejecución

- Dispositivo o emulador Android disponible (`flutter devices`).
- Configuración de entorno `vifutboldev` en Supabase (Oracle Cloud self-hosted) o modo local offline en emulador.

---

## 2. Comandos de Verificación Automatizada

### Pruebas Unitarias del Controlador y Repositorio Híbrido
Verifica que `PlayersDirectoryController` ordene A-Z por `fullName`, ejecute búsqueda reactiva insensible a acentos/mayúsculas, cargue dinámicamente desde `TeamsRepository.loadAllPlayers()` y degrade a Hive sin conexión.

```bash
flutter test test/unit/application/players_directory_controller_test.dart
flutter test test/unit/infrastructure/sync/hybrid_teams_repository_players_test.dart
```

### Pruebas de Widgets de la Pantalla de Directorio
Verifica la ausencia de `ChoiceChip`s y de `Key('players_tournament_selector')`, la presencia de `Key('players_search_bar')`, el soporte de `RefreshIndicator` y la renderización de futbolistas.

```bash
flutter test test/presentation/players_directory_screen_test.dart
flutter test test/presentation/directories/players_directory_role_visibility_test.dart
```

### Análisis Estático y Formato
Garantiza cero advertencias y cumplimiento de estilo Dart.

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```

---

## 3. Escenarios de Validación Manual (E2E)

### Escenario 1: Remoción de Filter Chips y Barra de Búsqueda
1. Abrir la aplicación KickPulse en el emulador.
2. Navegar al menú lateral (Drawer) y seleccionar **"Jugadores"** (`PlayersDirectoryScreen`).
3. Comprobar que:
   - Ya no existe la barra horizontal de chips ("Todos", torneo A, torneo B).
   - El espacio superior superior muestra exclusivamente la barra de búsqueda reactiva.

### Escenario 2: Carga en Tiempo Real desde Supabase Cloud (`vifutboldev.players`)
1. Con conexión activa a internet, observar que la nómina de futbolistas se puebla automáticamente con los jugadores registrados en `vifutboldev.players`.
2. Escribir un texto en la barra de búsqueda (ej. parte del nombre, dorsal o posición).
3. Verificar filtrado inmediato en menos de 300 ms sin lag.

### Escenario 3: Resiliencia Offline y Pull-to-Refresh
1. Activar el Modo Avión en el emulador (`adb shell cmd connectivity airplane-mode enable` o desde la cortina de notificaciones).
2. Salir y reingresar a la pantalla de Jugadores.
3. Verificar que la lista de futbolistas se carga inmediatamente desde la caché local de Hive sin errores fatales.
4. Ejecutar el gesto de arrastrar hacia abajo para refrescar (Pull-to-Refresh):
   - Comprobar que la nómina existente se mantiene en pantalla.
   - Comprobar que se despliega un `SnackBar` informativo indicando la falta de conexión.
