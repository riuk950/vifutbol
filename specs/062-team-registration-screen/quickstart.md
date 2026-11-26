# Guía de Validación Rápida (Quickstart): Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Funcionalidad**: `specs/062-team-registration-screen`  
**Referencias**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/062-team-registration-screen/spec.md) · [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/062-team-registration-screen/data-model.md) · [team-registration-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/062-team-registration-screen/contracts/team-registration-contracts.md)

## Prerrequisitos

1. Migración SQL `202611260002_teams_delegate_and_founded_date.sql` aplicada en `vifutboldev`.
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

2. **Pruebas unitarias y de widget de registro de equipo y ficha de detalle**:
   ```bash
   flutter test test/unit/team_registration_detailed_test.dart test/widget/create_team_screen_test.dart test/widget/team_info_tab_view_detailed_test.dart
   ```
   **Resultado esperado**: Todas las pruebas en verde (validación de delegado/fecha/colores distintos, auto-sugerencia de sigla, vista previa en vivo, `single-flight`, confirmación de cambios sin guardar, navegación desde Panel/Directorio y ficha de equipo con datos nuevos y equipos legados).

3. **Suite global**:
   ```bash
   flutter test
   ```
   **Resultado esperado**: 100% de pruebas pasando sin regresiones.

## Escenarios de Validación Manual End-to-End

1. **Navegación desde Panel y Directorio**: Iniciar sesión como Entrenador u Organizador, pulsar `Crear equipo` y confirmar navegación a la página dedicada `/teams/create` (no diálogo modal).
2. **Vista previa en vivo**: Escribir nombre (verificar auto-sugerencia de sigla), elegir colores primario y secundario distintos y observar la actualización inmediata del escudo/tarjeta superior.
3. **Validaciones y guardado**: Probar envío vacío/inválido (mensajes en español), completar delegado y fecha válida (≤ hoy), pulsar `Registrar equipo` (verificar indicador de carga y prevención de doble envío) y confirmar el regreso con mensaje de éxito y equipo listado.
4. **Ficha de detalle del equipo**: Abrir el equipo recién creado y verificar Delegado, Fecha de creación y colores distintivos en `TeamInfoTabView`.
