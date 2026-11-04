# Quickstart & Validation Guide: Acta Digital del Árbitro (HU 7.1)

**Date**: 2026-11-04  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/spec.md)  
**Data Model**: [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/data-model.md)  
**Contract**: [digital-match-report-contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/contracts/digital-match-report-contract.md)

## 1. Prerequisites & Environment

- **Flutter SDK**: `3.41.2` (Dart `^3.11.0`)
- **Environment**: `AppEnvironment.development` (precarga torneo `tournament-seed-liga-clausura`, partido programado `match-seed-clausura-1` entre `Atlético Norte FC` y `Real Sabana Club`, y jugadores habilitados incluyendo a `Dávinson Sánchez` con dorsal `#5`).

## 2. Automated Verification Commands

Execute the quality gates from the repository root:

```bash
# 1. Regenerate localization files after updating lib/l10n/app_es.arb
flutter gen-l10n

# 2. Static analysis (must report 0 issues)
flutter analyze

# 3. Code formatting check
dart format --output=none --set-exit-if-changed lib test

# 4. Run unit and widget tests for HU 7.1
flutter test test/unit/domain/digital_match_report_entities_test.dart
flutter test test/unit/infrastructure/local_match_reports_repository_test.dart
flutter test test/unit/application/manage_digital_match_report_use_case_test.dart
flutter test test/unit/application/digital_match_report_controller_test.dart
flutter test test/widget/digital_match_report_widget_test.dart

# 5. Full test suite with coverage
flutter test --coverage
```

## 3. End-to-End Gherkin Validation Scenarios

### Scenario 1: Registro de gol con asistencia durante un partido en juego (Fase 1 Gherkin)
1. Iniciar sesión con rol `Árbitro` (u `Organizador`) y abrir la pestaña `"Jornada"`.
2. En la tarjeta del partido `Atlético Norte FC vs Real Sabana Club`, pulsar `"Acta Arbitral"`.
3. Pulsar `"Iniciar Partido"` para cambiar el estado a `"En Juego"` (`Primer Tiempo`).
4. Pulsar `"Registrar Gol"`, seleccionar `Atlético Norte FC`, minuto `34`, jugador anotador (`Radamel Falcao #9`) y jugador asistente (`James Rodríguez #10`), y confirmar.
5. **Expected Outcome**: El marcador en vivo se actualiza a `1 - 0` con tipografía tabular (`tabular-nums`) y el gol aparece en la línea de tiempo con señal semántica `"Accent Live"` (`#EF4444`).

### Scenario 2: Expulsión automática por doble tarjeta amarilla al jugador con dorsal "5" (Fase 1 Gherkin)
1. En el mismo partido `"En Juego"`, pulsar `"Tarjeta Amarilla"`, seleccionar al jugador con dorsal `"5"` (`Dávinson Sánchez`) en el minuto `25` y confirmar.
2. Pulsar nuevamente `"Tarjeta Amarilla"` para el jugador con dorsal `"5"` en el minuto `68` y confirmar.
3. **Expected Outcome**: El sistema registra automáticamente la segunda tarjeta amarilla seguida del evento de expulsión por tarjeta roja por acumulación (`secondYellowRedCard`) y bloquea al jugador con dorsal `"5"` impidiendo que pueda ser seleccionado para registrar nuevos goles, asistencias o sustituciones en ese encuentro.

### Scenario 3: Operación Offline-First y sincronización idempotente sin duplicados (Fase 2 Gherkin)
1. En la pantalla del Acta Digital, activar el modo sin conexión.
2. Verificar que se muestra el banner en español: `"Modo sin conexión: cambios guardados en el dispositivo"`.
3. Registrar un gol, una tarjeta amarilla y el cierre del primer tiempo (`"Descanso"`).
4. **Expected Outcome**: Todos los eventos se guardan localmente de inmediato sin bloquear la interfaz y el contador de cola pendiente refleja los eventos no sincronizados. Al restablecer la conexión, la cola se sincroniza automáticamente marcando todos los eventos como sincronizados sin duplicar ningún gol ni tarjeta.

### Scenario 4: Cierre definitivo e inmutable del acta oficial (Fase 3 Gherkin)
1. Pulsar `"Cerrar Acta Oficial"`, revisar el resumen consolidado de goles y tarjetas en el diálogo de confirmación y confirmar el cierre.
2. **Expected Outcome**: El partido cambia su estado a `"Finalizado"`, los controles de edición arbitral quedan bloqueados de forma inmutable y el marcador oficial se refleja en la tarjeta del partido en `"Jornada"`.
