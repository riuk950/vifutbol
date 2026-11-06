# Quickstart & Validation Guide: Feed Diario de Partidos

**Feature**: `015-matches-daily-feed`  
**Date**: 2026-11-06  
**Status**: Completed

Esta guía detalla los pasos de validación manual y automatizada para verificar el feed diario de partidos, las pestañas temporales y el selector de calendario.

---

## 1. Automated Validation Suites

Ejecución de pruebas unitarias y de widgets con cobertura sobre los nuevos componentes:

```bash
# 1. Pruebas de agrupamiento y controladores de estado
flutter test test/application/controllers/daily_matches_feed_controller_test.dart

# 2. Pruebas de widgets para la barra temporal y tarjetas Match Center
flutter test test/presentation/matches/widgets/daily_matches_tab_bar_test.dart
flutter test test/presentation/matches/widgets/match_center_card_test.dart

# 3. Pruebas de integración de la pantalla AppShell con selector de calendario
flutter test test/presentation/shell/tabs/matchday_daily_feed_view_test.dart
```

---

## 2. Manual Verification Scenarios

### Escenario 1: Apertura inicial y verificación de pestaña "Hoy"
1. Iniciar la aplicación en modo desarrollo o emulador/dispositivo.
2. Comprobar que en la barra superior aparece el icono de calendario junto a la campana de notificaciones.
3. Comprobar que la barra debajo del `AppBar` muestra tres pestañas: **Ayer**, **Hoy**, **Mañana**.
4. **Criterio de Aceptación**: La pestaña **Hoy** está seleccionada por defecto con el indicador verde de acento (`#10B981` / `#22C55E`).
5. Comprobar que solo se muestran los partidos cuya fecha programada sea la fecha actual del sistema.

### Escenario 2: Navegación entre Ayer y Mañana
1. Pulsar sobre la pestaña **Ayer**:
   - La pestaña "Ayer" pasa a estar activa.
   - La lista se actualiza mostrando las competiciones y partidos jugados el día anterior.
   - Los partidos finalizados exhiben su marcador final y la etiqueta `Final`.
2. Pulsar sobre la pestaña **Mañana**:
   - La pestaña "Mañana" pasa a estar activa.
   - La lista se actualiza mostrando la programación de partidos para el día siguiente con su hora prevista y sede.

### Escenario 3: Selección de fecha arbitraria mediante Calendario
1. En el `AppBar`, tocar el icono de calendario (`calendar_month`).
2. Se abre el diálogo del selector de fechas (`DatePicker`).
3. Seleccionar una fecha distinta a ayer, hoy y mañana (por ejemplo, dentro de 5 días o del mes pasado).
4. Confirmar la selección:
   - El diálogo se cierra.
   - El feed carga las competiciones y partidos correspondientes a esa fecha seleccionada.
   - Las tres pestañas (Ayer, Hoy, Mañana) se desmarcan y aparece un pill con la fecha personalizada (ej. `Sáb 15 nov`).
   - Al tocar cualquiera de las pestañas Ayer, Hoy o Mañana, el pill desaparece y se retorna al día correspondiente.

### Escenario 4: Aspecto visual Match Center (Stitch)
1. Observar una tarjeta de partido:
   - Extremo izquierdo: Escudo redondo del equipo local y nombre alineado a la derecha.
   - Centro: Contenedor elevado con la hora (ej. `18:30`) o marcador (`2 - 1`), y chip en vivo pulsante (`EN VIVO` en `#EF4444`) si el partido está en juego.
   - Extremo derecho: Escudo del visitante y nombre alineado a la izquierda.
2. Tocar sobre una tarjeta de partido:
   - Navega al acta o detalle del partido (`digital_match_report_screen.dart`).

### Escenario 5: Rol Organizador y Partidos Pendientes
1. Iniciar sesión con rol `organizer`.
2. Si existen partidos con estado `pendingSchedule`, verificar que en la parte superior del feed aparece el banner de alerta: `"X partidos pendientes de programar"`.
3. Tocar el banner: despliega el diálogo/lista para programar o generar fixture.
4. Iniciar sesión con rol `fan` o `player`: verificar que dicho banner no se muestra en absoluto.
