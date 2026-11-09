# Quickstart: Validación de Pantalla de Detalle de Equipo con Pestañas y Resumen (HU 14.1)

**Feature**: `021-team-detail-summary`  
**Date**: 2026-11-09

---

## Escenarios de Validación Manual

### Escenario 1: Navegación al Detalle de Equipo desde el Directorio
1. Abrir el Navigation Drawer y seleccionar **"Equipos"**.
2. Tocar cualquier equipo de la lista (ej. *"Atlético Norte FC"*).
3. **Resultado esperado**:
   - Se abre `TeamDetailScreen` (`/teams/:id`).
   - El `AppBar` muestra el escudo vectorizado (`KickPulseTeamCrest`), el nombre del club, su código corto (`ATN`), el nombre de la competición y la insignia de elegibilidad.
   - Debajo del `AppBar` se muestran las 3 pestañas fijas: **"Información"**, **"Partidos"** y **"Plantilla"**, con **"Información"** seleccionada por defecto.

### Escenario 2: Navegación desde el Escudo/Nombre en Tarjetas de Partido
1. Ir a la vista de **"Partidos"** o al fixture de una competición.
2. Tocar sobre el nombre o escudo del equipo local o visitante en un `MatchCenterCard`.
3. **Resultado esperado**:
   - Se navega a la pantalla de detalle de dicho equipo (`/teams/:id`).
   - Al tocar el bloque central del marcador/horario en `MatchCenterCard`, sigue ejecutándose la acción de detalle del partido.

### Escenario 3: Resumen de Ficha del Club, Último y Próximo Partido
1. En la pestaña **"Información"** de un equipo con partidos jugados y programados:
2. **Resultado esperado**:
   - **Tarjeta de Ficha del Club**: Muestra nombre oficial, código corto, muestras de color primario y secundario con acento visual del club y torneo al que pertenece.
   - **Tarjeta de "Último Partido"**: Muestra el encuentro finalizado más reciente con rival, marcador final (`FT`), fecha y cancha/sede.
   - **Tarjeta de "Próximo Partido"**: Muestra el siguiente encuentro programado con rival, fecha, hora fijada y cancha/sede.

### Escenario 4: Estados Vacíos de Último y Próximo Partido
1. Consultar un equipo que aún no ha disputado partidos y/o no tiene próximos encuentros programados.
2. **Resultado esperado**:
   - En "Último Partido" se muestra *"Sin partidos previos disputados"*.
   - En "Próximo Partido" se muestra *"Sin próximos partidos agendados"*.

---

## Comandos de Verificación Automatizada

```bash
# Regenerar localización
flutter gen-l10n

# Pruebas unitarias del resumen determinista de partidos del equipo
flutter test test/presentation/teams/team_match_summary_test.dart

# Pruebas de widget de TeamDetailScreen y pestañas
flutter test test/presentation/teams/team_detail_screen_test.dart

# Pruebas de navegación en TeamsDirectoryScreen y MatchCenterCard
flutter test test/presentation/teams_directory_screen_test.dart
flutter test test/presentation/matches/widgets/match_center_card_test.dart

# Pruebas de responsividad (320x640 @ 130% text scaling)
flutter test test/presentation/directories_responsive_widget_test.dart

# Análisis estático sin errores ni advertencias
flutter analyze
```
