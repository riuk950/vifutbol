# Quickstart & Validation Guide: Creación de Campeonatos y Reglas Personalizadas (HU 4.1)

**Feature**: `004-tournaments-custom-rules`  
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

**Expected Outcome**: `0` issues found in `flutter analyze` and `0` formatting changes needed.

## 3. Automated Test Suite & Coverage Gate

```bash
flutter test --coverage
```

**Expected Outcome**:
- Todos los tests unitarios de dominio (`ChampionshipTournament`, `TournamentRulesConfig`, `ManageTournamentsUseCase`, máquina de estados e inmutabilidad auditada), infraestructura (`LocalTournamentsRepository` y borrador local) y widget tests (`StandingsTabView`, `TournamentFormScreen`, diálogos de borrador y auditoría) pasan al 100%.

## 4. End-to-End Manual Validation Scenarios (`dev`)

1. **Escenario 1 — Creación de Campeonato Formato Liga (`US1`)**:
   - Iniciar en entorno `dev` con rol `Organizador` y abrir la pestaña `Posiciones`.
   - Presionar `"Crear Campeonato"`, ingresar nombre `"Torneo Clausura 2026"`, categoría `"Libre"`, seleccionar formato `"Liga"` (`2` vueltas), configurar `3 / 1 / 0` puntos, suspensión a `3` amarillas, reordenar criterios de desempate y guardar.
   - Verificar que el campeonato aparece con estado `"Inscripciones Abiertas"` y muestra toda su normativa oficial.
2. **Escenario 2 — Creación de Copa Eliminatoria con Penales Directos (`US1`)**:
   - Abrir `"Crear Campeonato"`, seleccionar formato `"Copa Eliminatoria"`, elegir ronda inicial `"Octavos de Final"` y activar `"Desempate directo por penales al finalizar el tiempo reglamentario"`.
   - Guardar y verificar en la ficha de detalle la secuencia de llaves (`Octavos de Final` → `Cuartos de Final` → `Semifinal` → `Final`) con indicador de definición por penales.
3. **Escenario 3 — Inmutabilidad Auditada en Estado `"En Curso"` (`US2`)**:
   - Cambiar el estado de un campeonato a `"En Curso"` (o seleccionar `"Copa Relámpago Nocturna"`).
   - Abrir `"Editar Reglas"` y modificar los puntos por victoria de `3` a `2`.
   - Verificar que al intentar guardar se exige el diálogo de confirmación administrativa con motivo obligatorio, y que tras confirmar se registra la entrada en el historial de auditoría del campeonato.
4. **Escenario 4 — Borrador Local y Confirmación al Salir (`US3`)**:
   - Abrir `"Crear Campeonato"`, escribir un nombre parcial e intentar retroceder.
   - Verificar que aparece el diálogo `"¿Deseas descartar los cambios o guardar como borrador?"`.
   - Elegir `"Guardar borrador"` y volver a abrir `"Crear Campeonato"` para comprobar la restauración automática de los campos.
