# Guía de Validación Rápida (Quickstart): Carga de Foto del Escudo del Equipo con Visualización Circular (HU 27.3)

**Funcionalidad**: `specs/063-team-crest-circular-photo`  
**Referencias**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/063-team-crest-circular-photo/spec.md) · [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/063-team-crest-circular-photo/data-model.md) · [team-crest-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/063-team-crest-circular-photo/contracts/team-crest-contracts.md)

## Prerrequisitos

1. Migración SQL `202611260003_team_crest_url_and_bucket.sql` aplicada en `vifutboldev`.
2. Localizaciones regeneradas tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```

## Comandos de Verificación Automatizada

1. **Análisis estático**:
   ```bash
   flutter analyze
   ```
   **Resultado esperado**: `No issues found!`.

2. **Pruebas unitarias y de widget de escudo circular y registro**:
   ```bash
   flutter test test/unit/team_crest_storage_test.dart test/widget/kick_pulse_team_crest_test.dart test/widget/create_team_screen_test.dart
   ```
   **Resultado esperado**: Todas las pruebas en verde (validación de tamaño ≤ 5 MB y formato JPEG/PNG/WebP, serialización `crestUrl`, renderizado circular de `KickPulseTeamCrest` con foto y fallback circular ante ausencia o error de imagen, selección/cambio/eliminación de escudo en `CreateTeamScreen`, denegación de permisos sin pérdida de datos y continuidad offline-first).

3. **Suite global**:
   ```bash
   flutter test
   ```
   **Resultado esperado**: 100% de pruebas pasando sin regresiones.

## Escenarios de Validación Manual End-to-End

1. **Subir, cambiar y quitar escudo en `CreateTeamScreen`**: Elegir imagen desde galería/cámara, comprobar vista previa circular con borde en colores distintivos, cambiar de colores y verificar actualización del borde, probar cambiar y quitar escudo.
2. **Visualización circular global**: Guardar el equipo con escudo y verificar renderizado circular en Directorio de equipos, Detalle del equipo, Tabla de posiciones y Tarjetas de partidos.
3. **Fallback circular**: Verificar que un equipo sin foto (o con URL inválida) muestra monograma circular con sus colores distintivos sin errores.
4. **Offline-first y permisos**: Probar denegación de permiso y registro sin conexión verificando preservación de datos y visualización local inmediata.
