# Quickstart & Verification Guide: Pestaña de Información y Reglas Oficiales (HU 13.3)

**Feature**: `020-competition-detail-rules`  
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

### 2.1 Tab View Integration & Official Rules Test
Verify that `CompetitionInfoTabView` renders scoring, parameters, squad limits, tiebreakers, dates, and venue card:
```bash
flutter test test/presentation/tournaments/competition_info_tab_view_test.dart
```

### 2.2 Screen Integration & 3-Tab Switching
Verify tab switching between "Partidos", "Clasificación" e "Información" inside `CompetitionDetailScreen`:
```bash
flutter test test/presentation/tournaments/competition_detail_screen_test.dart
```

### 2.3 Responsive Layout & Zero Overflows ($320 \times 640\text{ px}$ @ $130\%$)
Verify compact viewport rendering and scrolling without RenderFlex errors:
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

1. **Consulta Reglamentaria Deportiva (Cualquier Rol)**:
   - Acceder a `/competitions/:id`.
   - Pulsar pestaña "Información".
   - Verificar tarjetas de:
     - Encabezado con estado y fechas de vigencia.
     - Sistema de puntuación (Victoria, Empate, Derrota).
     - Criterios de desempate ordenados.
     - Parámetros de partido (duración de mitades).
     - Reglas de plantilla y disciplina (mín/máx jugadores, límite amarillas).
     - Sede principal asignada (nombre, dirección y canchas).
   - Constatar que la vista es de solo lectura (sin botones de gestión).

2. **Auditoría de Reglas Críticas (Rol Organizador)**:
   - Acceder con rol `UserRole.organizer` a un torneo que tenga registros en su auditoría (`auditTrail.isNotEmpty`).
   - Se muestra la sección de historial de auditoría al final del reglamento.
   - Acceder con rol `UserRole.fan` o `UserRole.player` $\to$ la sección de auditoría está ausente.
