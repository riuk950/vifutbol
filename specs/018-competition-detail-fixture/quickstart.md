# Quickstart: Validación del Detalle de Competición y Fixture Completo (HU 13.1)

**Feature**: `018-competition-detail-fixture`
**Date**: 2026-11-06

---

## Escenarios de Validación Manual

### Escenario 1: Navegación desde el Directorio de Competiciones
1. Abrir el Navigation Drawer y pulsar sobre "Competiciones".
2. Tocar sobre cualquier torneo con partidos (ej. "Liga Clausura 2026").
3. **Resultado esperado**:
   - Transición fluida a `/competitions/:id`.
   - El AppBar muestra el nombre del torneo, su categoría y el badge de estado.
   - La pestaña "Partidos" está activa por defecto.
   - Se muestra el botón de retroceso (`competition_detail_back_button`).

### Escenario 2: Exploración del Fixture por Jornadas
1. En la pestaña "Partidos", desplazarse verticalmente.
2. **Resultado esperado**:
   - Cada jornada presenta su encabezado descriptivo ("Jornada 1", "Jornada 2", etc.).
   - Se exhiben las tarjetas de partidos con sus equipos, horarios/sedes y marcadores.
   - Al tocar cualquier partido, se abre la hoja modal con el detalle del encuentro.

### Escenario 3: Navegación entre Pestañas
1. Tocar la pestaña "Clasificación".
2. **Resultado esperado**:
   - Se presenta la tabla de posiciones calculada para el torneo.
3. Tocar la pestaña "Información".
4. **Resultado esperado**:
   - Se presenta la tarjeta informativa de reglamento oficial.
5. Volver a "Partidos": se conserva la posición de desplazamiento.

### Escenario 4: Torneo Sin Fixture Generado (Estado Vacío)
1. Abrir un torneo nuevo en estado `openRegistration` sin partidos creados.
2. **Resultado esperado**:
   - En la pestaña "Partidos", se despliega el estado vacío informativo indicando que el calendario está en preparación.

---

## Comandos de Verificación Automatizada

```bash
# Pruebas de widget dedicadas
flutter test test/presentation/tournaments/competition_detail_screen_test.dart

# Pruebas de responsividad (320x640 @ 130% text scaling)
flutter test test/presentation/directories_responsive_widget_test.dart

# Calidad y análisis estático
flutter analyze
dart format --output=none --set-exit-if-changed .
```
