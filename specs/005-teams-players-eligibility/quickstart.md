# Quickstart & Validation Guide: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Feature**: `005-teams-players-eligibility`  
**Date**: 2026-04-17

## 1. Prerequisites & Localization Generation

```bash
flutter gen-l10n
```

## 2. Static Analysis & Formatting Gate

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

**Expected Outcome**: `0` issues in `flutter analyze` and `0` unformatted files.

## 3. Automated Test Suite & Coverage Gate

```bash
flutter test --coverage
```

**Expected Outcome**:
- Pruebas unitarias de `TournamentTeam`, `RegisteredPlayer`, `LocalTeamsRepository`, `ManageTeamsEligibilityUseCase` y `TeamsController`, más widget tests de `StandingsTabView` y `TeamRosterDetailScreen` pasando al 100%.

## 4. End-to-End Validation Scenarios (`dev`)

1. **Escenario 1 — Registro de Equipo e Inscripción de Jugadores (`US1`)**:
   - En la pestaña `Posiciones`, con el campeonato `"Liga Clausura ViFutbol 2026"` (`Inscripciones Abiertas`) seleccionado y rol `Organizador` o `Entrenador`, presionar `"Inscribir Equipo"`.
   - Ingresar nombre `"Deportivo Sur"`, sigla `"DSU"`, elegir forma de escudo y colores, y guardar.
   - Abrir `"Deportivo Sur"`, presionar `"Inscribir Jugador"`, ingresar nombre, documento y dorsal con teclado numérico y verificar que el jugador queda vinculado a la plantilla.
2. **Escenario 2 — Bloqueo de Jugador Duplicado en el Mismo Torneo (`US2`)**:
   - En `"Real Sabana Club"`, intentar inscribir un jugador con el documento `"10100001"` (que ya pertenece a un jugador de `"Atlético Norte FC"` en el mismo campeonato).
   - Verificar que el sistema rechaza el registro y muestra: `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`.
3. **Escenario 3 — Bloqueo de Dorsal Duplicado en el Mismo Equipo (`US2`)**:
   - En `"Real Sabana Club"`, intentar inscribir un jugador con el dorsal `"10"` (ya asignado en ese equipo).
   - Verificar que se muestra el error: `"El número de camiseta 10 ya está en uso en este equipo."`.
4. **Escenario 4 — Validación de Cupo Mínimo y Habilitación por el Organizador (`US3`)**:
   - Como `Organizador`, abrir `"Real Sabana Club"` (`5 / 7` jugadores mínimos) y verificar que no permite habilitarse hasta completar `7` jugadores.
   - Inscribir `2` jugadores adicionales para llegar a `7`, presionar `"Habilitar Equipo"` y comprobar que el equipo y sus jugadores pasan a estado `"Habilitado"`.
