# Quickstart & Validation Guide: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Feature**: `023-team-squad-roster`  
**Date**: 2026-11-09

---

## 1. Prerrequisitos

1. Tener el entorno de Flutter configurado (`Flutter 3.x` / `Dart 3.x`).
2. Regenerar los archivos de localización tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```

---

## 2. Ejecución de Pruebas Automatizadas

### Pruebas Unitarias de la Plantilla y Agrupación Táctica (`TeamSquadRoster`)

Verifica la resolución de `team.players`, la agrupación en los 4 bloques tácticos (`goalkeepers`, `defenders`, `midfielders`, `forwards`), el ordenamiento ascendente por `shirtNumber` y la generación de perfiles `PlayerPerformanceProfile` sincronizados con `isEligible`:

```bash
flutter test test/presentation/teams/team_squad_roster_test.dart
```

### Pruebas de Widgets de la Pestaña "Plantilla" (`TeamDetailScreen` & `TeamSquadTabView`)

Verifica la visualización de los 4 bloques verticales (**Porteros**, **Defensas**, **Centrocampistas**, **Delanteros**), el orden por dorsal, los badges de posición y de elegibilidad (**Habilitado** en verde / **Suspendido** en rojo), la apertura del modal de perfil de rendimiento al tocar un jugador y los estados vacíos globales y por posición:

```bash
flutter test test/presentation/teams/team_detail_screen_test.dart
```

### Pruebas de Responsividad (`320x640 px` con `130%` de Escalado de Texto)

Verifica cero `RenderFlex` overflows en las 3 pestañas de `TeamDetailScreen` ("Información", "Partidos" y "Plantilla") bajo condiciones móviles compactas:

```bash
flutter test test/presentation/directories_responsive_widget_test.dart
```

### Análisis Estático y Formato

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
```

---

## 3. Verificación Manual End-to-End

1. Abrir la aplicación y navegar al directorio de **Equipos** (`/teams`) o tocar el escudo/nombre de un equipo desde cualquier tarjeta de partido.
2. En `TeamDetailScreen` (`/teams/:id`), tocar la tercera pestaña: **"Plantilla"**.
3. Verificar los 4 bloques verticales por posición táctica:
   - **Porteros**, **Defensas**, **Centrocampistas** y **Delanteros** se muestran con sus encabezados y conteo de efectivos.
   - Dentro de cada bloque, los jugadores aparecen ordenados de menor a mayor número de dorsal (`#1`, `#4`, `#8`, etc.).
4. Verificar los datos de cada jugador:
   - Dorsal con tipografía tabular, nombre completo, badge de posición (*Portero*, *Defensa*, *Centrocampista*, *Delantero*) y badge de elegibilidad (**Habilitado** en verde o **Suspendido** en rojo).
5. Tocar cualquier tarjeta de jugador y comprobar que se despliega la hoja modal con `PlayerPerformanceProfileCard`, permitiendo consultar sus estadísticas y cambiar entre compañeros de plantilla.
