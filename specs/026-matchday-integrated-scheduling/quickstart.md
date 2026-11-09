# Quickstart & Validation Guide: Programación Integral de Partido en la Jornada (HU 15.3)

**Feature**: `026-matchday-integrated-scheduling`  
**Date**: 2026-11-09

---

## Prerequisites

1. Flutter SDK (`^3.11.0` / Dart `^3.11.0`) instalado y configurado.
2. Dependencias instaladas (`flutter pub get`) y archivos de localización generados (`flutter gen-l10n`).
3. Véase [data-model.md](./data-model.md) y [contracts/ui-matchday-scheduling-contracts.md](./contracts/ui-matchday-scheduling-contracts.md) para los contratos de widgets y casos de uso.

---

## End-to-End Validation Scenarios

### Scenario 1: Apertura del Formulario de Programación desde la Jornada (US1)
1. Iniciar la aplicación o montar `CompetitionDetailScreen` (`/competitions/:id`) con rol `UserRole.organizer` en un torneo en estado `openRegistration` o `inProgress` que tenga partidos generados.
2. En la pestaña **Partidos** (`CompetitionFixtureTabView`), tocar una tarjeta de partido en estado `pendingSchedule` o `scheduled` (`Key('fixture_match_item_${match.id}')`).
3. **Resultado esperado**: Se despliega directamente `ScheduleMatchDialog` mostrando los selectores de Fecha (`pick_match_date_field`), Hora (`pick_match_time_field`), Sede Deportiva (`select_venue_dropdown`), Cancha (`select_pitch_dropdown`) y Árbitro Oficial (`select_referee_dropdown`).
4. Cambiar al rol `UserRole.fan` (o tocar un partido en estado `completed`) y volver a tocar la tarjeta.
5. **Resultado esperado**: Se abre únicamente la hoja modal informativa de solo lectura sin controles de edición.

### Scenario 2: Asignación Completa de Logística y Sincronización Reactiva (US2)
1. En `ScheduleMatchDialog`, seleccionar una Sede Deportiva distinta y verificar que el desplegable de Cancha se actualiza con las canchas de dicha sede.
2. Seleccionar una fecha/hora válida dentro del campeonato, una cancha disponible y un árbitro activo, y pulsar **"Guardar Programación"** (`confirm_schedule_match_button`).
3. **Resultado esperado**:
   - El partido pasa a `MatchStatus.scheduled`.
   - En la lista de jornadas (`Key('fixture_match_logistics_${match.id}')`) se muestra la fecha, sede, cancha y árbitro asignados.
   - En la vista principal de **Partidos** (`MatchdayTabView`), al consultar la fecha asignada, el partido aparece automáticamente en el feed diario.

### Scenario 3: Prevención de Colisiones de Cancha y Árbitro (US3)
1. Intentar programar un segundo partido (del mismo o de otro torneo) en la misma cancha o con el mismo árbitro en un horario superpuesto.
2. Pulsar **"Guardar Programación"**.
3. **Resultado esperado**: El diálogo permanece abierto mostrando la alerta `Key('schedule_error_message')` con el motivo del conflicto y bloquea la persistencia hasta elegir otra hora, cancha o árbitro.

---

## Automated Verification Commands

```bash
# 1. Regenerar localizaciones en español
flutter gen-l10n

# 2. Ejecutar pruebas unitarias del caso de uso de programación y colisiones globales
flutter test test/unit/application/fixture_scheduling_use_case_test.dart

# 3. Ejecutar pruebas de widgets de la pestaña de jornadas y programación de partidos
flutter test test/presentation/tournaments/competition_fixture_widget_test.dart test/widget/matchday_fixture_widget_test.dart

# 4. Verificar análisis estático y formato (0 errores, 0 advertencias)
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```
