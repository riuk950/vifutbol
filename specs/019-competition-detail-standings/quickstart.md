# Quickstart & Verification Guide: Pestaña de Clasificación en Detalle de Competición (HU 13.2)

**Feature**: `019-competition-detail-standings`  
**Status**: Ready  
**Date**: 2026-11-06

---

## 1. Prerequisites

- Flutter SDK >= 3.29.0
- Localization files generated:
  ```bash
  flutter gen-l10n
  ```

---

## 2. Running Verification Tests

### 2.1 Tab View Integration & Subviews Switching
Verify that `CompetitionStandingsTabView` renders correct subviews according to tournament format (`league`, `knockoutCup`, `mixedGroupsAndKnockout`):
```bash
flutter test test/presentation/tournaments/competition_standings_tab_view_test.dart
```

### 2.2 Screen Integration & Tab Switching
Verify that switching from "Partidos" to "Clasificación" inside `CompetitionDetailScreen` retains state:
```bash
flutter test test/presentation/tournaments/competition_detail_screen_test.dart
```

### 2.3 Responsive Layout & Zero Overflows ($320 \times 640\text{ px}$ @ $130\%$)
Verify compact viewport rendering and horizontal scrolling without RenderFlex errors:
```bash
flutter test test/presentation/directories_responsive_widget_test.dart
```

### 2.4 Static Analysis & Code Quality
```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
```

---

## 3. Visual Scenarios

1. **Torneo Tipo Liga con Resultados**:
   - Acceder a `/competitions/:id`.
   - Pulsar pestaña "Clasificación".
   - Observar chips: `[Posiciones]` (activo) y `[Estadísticas]`.
   - Verificar tabla con columnas `#`, Equipo, `PJ`, `PG`, `PE`, `PP`, `GF`, `GC`, `DG`, `PTS`.
   - Pulsar `[Estadísticas]` $\to$ Se despliega `TournamentRankingsCard` con goleadores, tarjetas y vallas invictas.

2. **Torneo Tipo Copa (Eliminatoria Directa)**:
   - Acceder a `/competitions/:id`.
   - Pulsar pestaña "Clasificación".
   - Observar chips: `[Llaves]` (activo) y `[Estadísticas]`.
   - Verificar árbol visual interactivo de eliminatorias (`KnockoutBracketCard`).

3. **Torneo con Formato Mixto**:
   - Acceder a `/competitions/:id`.
   - Pulsar pestaña "Clasificación".
   - Observar chips: `[Posiciones]` (activo por defecto), `[Llaves]` y `[Estadísticas]`.
   - En `[Posiciones]`, alternar entre `Grupo A` y `Grupo B` mediante las pestañas de grupo de la tabla.
   - Alternar a `[Llaves]` para ver los cruces de playoffs.

4. **Torneo sin Partidos ni Estadísticas**:
   - Acceder a un torneo recién creado.
   - Pulsar "Clasificación" $\to$ Estado vacío `KickPulseStateView` amigable.
   - Pulsar `[Estadísticas]` $\to$ Estado vacío contextual ("Sin estadísticas registradas aún").
