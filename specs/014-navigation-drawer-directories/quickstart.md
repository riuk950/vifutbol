# Quickstart & Validation Guide: Navigation Drawer y Páginas de Directorio con Buscador

**Feature**: `014-navigation-drawer-directories`
**Date**: 2026-11-05

Esta guía proporciona los pasos y comandos ejecutables para verificar la funcionalidad del Navigation Drawer y los directorios de búsqueda de principio a fin.

---

## 1. Validación de Localización (`l10n`)

Verificar que todas las claves en español para el Drawer y las tres pantallas de directorio se encuentren definidas en `lib/l10n/app_es.arb` y regeneradas:

```bash
flutter gen-l10n
```

Claves esperadas:
- `drawerTitle`: `"Menú Principal"`
- `drawerCompetitions`: `"Competiciones"`
- `drawerTeams`: `"Equipos"`
- `drawerPlayers`: `"Jugadores"`
- `drawerVenues`: `"Sedes"`
- `searchCompetitionsHint`: `"Buscar competiciones..."`
- `searchTeamsHint`: `"Buscar equipos..."`
- `searchPlayersHint`: `"Buscar jugadores..."`
- `filterAllTournaments`: `"Todos"`
- `noCompetitionsFound`: `"No se encontraron competiciones con ese criterio."`
- `noTeamsFound`: `"No se encontraron equipos con ese criterio."`
- `noPlayersFound`: `"No se encontraron jugadores con ese criterio."`

---

## 2. Pruebas Unitarias de Búsqueda y Normalización

Validar la función de búsqueda insensible a acentos y mayúsculas:

```bash
flutter test test/unit/application/search_utils_test.dart
```

Escenarios probados:
- Normalización de cadenas: `"Álvarez"` → `"alvarez"`, `"GÓMEZ"` → `"gomez"`.
- Coincidencia parcial: `"alv"` encuentra `"Álvarez"`, `"tig"` encuentra `"Tigres F.C."`.
- Espacios en blanco iniciales/finales y caracteres vacíos manejados de forma segura.

---

## 3. Pruebas Unitarias de Controladores de Directorio

Validar los controladores de estado con mocks y datos en memoria:

```bash
flutter test test/unit/application/directories_controllers_test.dart
```

Escenarios probados:
- `CompetitionsDirectoryController`: carga inicial, búsqueda reactiva, limpieza de término.
- `TeamsDirectoryController`: filtrado combinado por torneo ("Todos" vs torneo puntual) y texto.
- `PlayersDirectoryController`: filtrado combinado por torneo, nombre, dorsal, posición y equipo.

---

## 4. Pruebas de Widgets e Interacción

Validar la visualización del Drawer en todos los roles y la navegación a cada directorio:

```bash
flutter test test/presentation/app_drawer_widget_test.dart
flutter test test/presentation/directories_screens_widget_test.dart
```

Escenarios probados:
1. **Apertura de Drawer**:
   - Acceso con los 5 roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`).
   - Verificación de los 4 destinos visibles (`Competiciones`, `Equipos`, `Jugadores`, `Sedes`).
   - Cierre del drawer antes de navegar.
2. **Pantalla de Competiciones**:
   - Renderizado del buscador y lista de torneos.
   - Búsqueda en tiempo real ("juvenil", "copa") y botón de borrado (`X`).
   - Pulsación de tarjeta selecciona el torneo activo global y retorna al shell.
   - Botón crear visible solo para rol `Organizador`.
3. **Pantalla de Equipos**:
   - Selector horizontal de torneos con chip `"Todos"` seleccionado por defecto.
   - Búsqueda por nombre y abreviatura.
   - Apertura de detalle de plantilla al pulsar un equipo.
   - Botón crear equipo visible para roles autorizados.
4. **Pantalla de Jugadores**:
   - Búsqueda por nombre, dorsal o posición.
   - Apertura de ficha de rendimiento al pulsar un jugador.
   - Botón registrar jugador visible para roles autorizados.
5. **Responsividad y Accesibilidad**:
   - Viewport compacto (`320x640`) y escalado de texto al 130% sin desbordamientos (`RenderFlex overflow`).
   - Ocultamiento del teclado al desplazar la lista (`onDrag`).

---

## 5. Puertas de Calidad Globales

Ejecutar análisis estático, formato y suite completa de pruebas:

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
```
Resultados esperados:
- `flutter analyze`: **0 issues**
- `dart format`: **0 changed**
- `flutter test`: **100% de pruebas aprobadas** (cero regresiones)
