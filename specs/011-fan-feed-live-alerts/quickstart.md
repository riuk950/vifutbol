# Quickstart & Validation Guide: Feed de Noticias, Marcadores en Tiempo Real y Alertas (HU 9.1)

**Feature Branch**: `011-fan-feed-live-alerts`  
**Date**: 2026-11-05  
**Spec Reference**: [`specs/011-fan-feed-live-alerts/spec.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/spec.md)

---

## 1. Prerequisites & Environment Setup

- Flutter SDK ≥ 3.24.0 / Dart ≥ 3.5.0
- Localization files generated:
  ```bash
  flutter gen-l10n
  ```
- All dependencies resolved in `pubspec.yaml`.

---

## 2. Validation Scenarios

### Scenario 1: Marcadores en Vivo Reactivos con Insignia "EN VIVO"
1. **Acción**: Iniciar la app y situarse en la pestaña "Jornada".
2. **Condición**: Un partido cambia su estado a `MatchStatus.inProgress`.
3. **Resultado esperado**:
   - Aparece la tarjeta del partido con la insignia "EN VIVO" (`KickPulseColors.accentLive` `#EF4444`).
   - Los goles y el tiempo transcurrido se actualizan reactivamente sin requerir pull-to-refresh ni recarga manual.
   - Tipografía tabular (`tabular-nums`) para evitar oscilaciones de ancho de texto.
   - Al salir de la pestaña o pausar la app, el stream se cancela limpiamente (0 memory leaks).

### Scenario 2: Publicación y Consulta del Feed de Noticias
1. **Acción**: Iniciar sesión como `Organizador`, conmutar el control segmentado de la cabecera a "Noticias" y pulsar el botón "+ Nueva Noticia".
2. **Condición**: Publicar un boletín disciplinario con título, cuerpo y categoría `disciplinary`.
3. **Resultado esperado**:
   - La noticia se guarda y aparece inmediatamente en el feed con su etiqueta de categoría y marca de tiempo en español.
   - Cambiar a rol `Aficionado`: la noticia permanece visible y el botón de crear/eliminar desaparece.
   - Filtrar por categoría "Avisos Generales": la lista se filtra correctamente o muestra el estado vacío si no hay coincidencias.

### Scenario 3: Suscripción a Equipos Favoritos, Alertas y Enlace Profundo
1. **Acción**: Desde el feed de partidos o posiciones, tocar el icono de estrella/corazón de un equipo para marcarlo como favorito.
2. **Condición**: Se simula un recordatorio previo o un gol de ese equipo.
3. **Resultado esperado**:
   - El contador de la campana en el `AppBar` se incrementa con el badge de alertas no leídas.
   - Al tocar la campana, se abre la bandeja interna de alertas (`FanAlertsTraySheet`).
   - Al pulsar la alerta, se marca como leída (`isRead = true`) y navega directamente (*deep link*) al detalle de ese partido.
   - Si el usuario deniega las notificaciones push del sistema operativo, la bandeja interna sigue 100% operativa sin diálogos bloqueantes.

---

## 3. Automated Test Execution Commands

```bash
# 1. Regenerar localizaciones
flutter gen-l10n

# 2. Ejecutar pruebas unitarias del dominio y aplicación
flutter test test/unit/domain/tournament_news_item_test.dart
flutter test test/unit/domain/fan_favorites_and_alerts_test.dart
flutter test test/unit/application/tournament_news_use_cases_test.dart
flutter test test/unit/application/fan_favorites_and_alerts_use_cases_test.dart

# 3. Ejecutar pruebas de widgets e integración UI
flutter test test/widget/live_matches_feed_widget_test.dart
flutter test test/widget/tournament_news_feed_widget_test.dart
flutter test test/widget/fan_alerts_tray_widget_test.dart

# 4. Suite completa y análisis estático
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
```
