# Quickstart: Validación del Panel Administrativo Dinámico por Rol (HU 12.2)

**Feature**: `017-role-dynamic-panel`
**Date**: 2026-11-06

---

## Escenarios de Validación Rápida

### Escenario 1: Panel del Organizador
1. Cambiar el rol a `UserRole.organizer`.
2. Abrir el Navigation Drawer y pulsar sobre "Panel".
3. **Resultado esperado**:
   - AppBar muestra "Panel de Organización".
   - Se visualizan tarjetas métricas con torneos activos, partidos pendientes y torneos sin fixture.
   - Se exhiben botones para "Generar Fixture", "Programar Partido" y "Copia de Seguridad".

### Escenario 2: Panel del Entrenador
1. Cambiar el rol a `UserRole.coach`.
2. Navegar a `/panel`.
3. **Resultado esperado**:
   - AppBar muestra "Panel Técnico".
   - Se visualiza el resumen del club con jugadores habilitados y suspendidos.
   - Se ofrece el botón para gestionar la alineación del próximo partido.

### Escenario 3: Panel del Árbitro
1. Cambiar el rol a `UserRole.referee`.
2. Navegar a `/panel`.
3. **Resultado esperado**:
   - AppBar muestra "Panel Arbitral".
   - Se muestran los partidos asignados con el botón "Acta Digital" o el estado vacío correspondiente.

### Escenario 4: Ficha del Jugador
1. Cambiar el rol a `UserRole.player`.
2. Navegar a `/panel`.
3. **Resultado esperado**:
   - AppBar muestra "Ficha del Jugador".
   - Se visualiza la insignia de elegibilidad ("Habilitado" o "Sancionado").
   - Se muestra el bloque de estadísticas (goles, asistencias, tarjetas y partidos).

### Escenario 5: Restricción para Aficionados
1. Cambiar el rol a `UserRole.fan`.
2. Navegar directamente a `/panel`.
3. **Resultado esperado**:
   - Se despliega la vista restrictiva informativa.
   - Al pulsar "Volver a Partidos", la aplicación navega fluidamente a `/matches`.

---

## Comandos de Verificación Automatizada

```bash
# Pruebas de widgets dedicadas a la pantalla de Panel dinámico
flutter test test/presentation/panel/panel_screen_test.dart

# Pruebas de regresión del Drawer y Shell
flutter test test/presentation/app_drawer_widget_test.dart
flutter test test/presentation/app_shell_widget_test.dart

# Pruebas de responsividad (320x640 @ 130% text scaling)
flutter test test/presentation/directories_responsive_widget_test.dart

# Calidad de código y análisis estático
flutter analyze
dart format --output=none --set-exit-if-changed .
```
