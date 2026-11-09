# Quickstart & Validation Guide: Pestaña de Calendario de Partidos del Equipo (HU 14.2)

**Feature**: `022-team-matches-schedule`  
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

### Pruebas Unitarias del Calendario y Resultado Semántico (`TeamMatchesSchedule`)

Verifica el filtrado exclusivo por equipo, el ordenamiento cronológico ascendente de próximos partidos (`inProgress` > `scheduled` > `pendingSchedule`), el ordenamiento descendente de resultados anteriores (`completed`) y el cálculo exacto de `TeamMatchOutcome` (`win`, `draw`, `loss`) tanto de local como de visitante:

```bash
flutter test test/presentation/teams/team_matches_schedule_test.dart
```

### Pruebas de Widgets de la Pestaña "Partidos" (`TeamDetailScreen` & `TeamMatchesTabView`)

Verifica la visualización de las secciones **"Próximos Partidos"** y **"Resultados Anteriores"**, los badges semánticos (**Victoria**, **Empate**, **Derrota**), la apertura del modal de detalle del partido al tocar un encuentro y los estados vacíos globales y parciales:

```bash
flutter test test/presentation/teams/team_detail_screen_test.dart
```

### Pruebas de Responsividad (`320x640 px` con `130%` de Escalado de Texto)

Verifica cero `RenderFlex` overflows en la pestaña "Partidos" bajo condiciones móviles compactas:

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

1. Abrir la aplicación y navegar al directorio de **Equipos** (`/teams`) o tocar un equipo desde cualquier tarjeta de partido.
2. En `TeamDetailScreen` (`/teams/:id`), tocar la segunda pestaña: **"Partidos"**.
3. Verificar la sección **"Próximos Partidos"**:
   - Los encuentros futuros aparecen ordenados de menor a mayor fecha.
   - Cada tarjeta muestra la franja superior con jornada, fecha, cancha y badge Local/Visitante sobre `MatchCenterCard`.
4. Verificar la sección **"Resultados Anteriores"**:
   - Los encuentros finalizados aparecen ordenados del más reciente al más antiguo con su marcador definitivo.
   - Cada tarjeta exhibe el badge semántico de **Victoria** (verde), **Empate** (amarillo/ámbar) o **Derrota** (rojo sutil) calculado desde la perspectiva del club actual.
5. Tocar el centro de cualquier partido y comprobar que se despliega el `ModalBottomSheet` con la jornada, los clubes, el marcador/resultado, la fecha/hora, la cancha y el árbitro.
6. Tocar el escudo o nombre del equipo rival en cualquier tarjeta y comprobar que navega al detalle del club rival.
