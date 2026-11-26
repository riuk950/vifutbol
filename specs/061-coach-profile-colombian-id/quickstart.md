# Guía de Validación Rápida (Quickstart): Perfil Completo del Entrenador (HU 27.1)

**Funcionalidad**: `specs/061-coach-profile-colombian-id`  
**Referencias**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/061-coach-profile-colombian-id/spec.md) · [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/061-coach-profile-colombian-id/data-model.md) · [coach-profile-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/061-coach-profile-colombian-id/contracts/coach-profile-contracts.md)

## Prerrequisitos

1. Migración SQL de `coach_profiles` y `complete_role_profile` aplicada en el entorno Supabase `vifutboldev`.
2. Localizaciones generadas tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```

## Comandos de Verificación Automatizada

1. **Análisis estático**:
   ```bash
   flutter analyze
   ```
   **Resultado esperado**: `No issues found!`.

2. **Pruebas unitarias y de widget del perfil de entrenador**:
   ```bash
   flutter test test/unit/coach_profile_completeness_test.dart test/widget/coach_personal_data_screen_test.dart test/widget/coach_personal_data_summary_screen_test.dart
   ```
   **Resultado esperado**: Todas las pruebas en verde (completitud de rol entrenador, validación de campos obligatorios y ≥ 18 años, autocompletado de escaneo dual, bloqueo sin fotos, prevención de doble envío, resumen con miniaturas y navegación a edición).

3. **Regresión de pestaña Perfil y suite global**:
   ```bash
   flutter test
   ```
   **Resultado esperado**: 100% de pruebas pasando sin regresiones.

## Escenarios de Validación Manual End-to-End

1. **Acceso desde Perfil (perfil incompleto)**:
   - Iniciar sesión con un usuario de rol `coach` con perfil incompleto.
   - En la pestaña `Perfil`, verificar badge `Perfil incompleto` y presionar `Completar perfil`.
   - Confirmar navegación a la pantalla dedicada del entrenador con secciones de cédula, ubicación en Colombia, captura frontal/posterior y datos técnicos (`Club` y `Nivel de licencia`).
2. **Escaneo dual y validación de edad/campos**:
   - Probar escaneo de cédula colombiana y verificar autocompletado de documento, nombres, apellidos, sexo, fecha de nacimiento y RH.
   - Probar una fecha de nacimiento menor a 18 años y verificar bloqueo con mensaje claro en español.
   - Intentar guardar omitiendo una foto de cédula o un campo obligatorio y verificar bloqueo con mensajes en español.
3. **Guardado atómico y pantalla resumen**:
   - Completar todos los campos (p. ej. club `"Independiente"`, licencia `"Sin licencia"`), capturar ambas caras de la cédula y pulsar `Guardar perfil`.
   - Verificar indicador de carga (sin doble envío), actualización del estado en `Perfil` a `Perfil completo`, y navegación a la pantalla resumen mostrando datos personales, datos técnicos y miniaturas en línea de ambas caras con toque para ampliar.
4. **Edición conservando fotografías**:
   - Desde la pantalla resumen, pulsar `Editar`, modificar un campo (p. ej. teléfono o club) sin recapturar las fotos, guardar y verificar que los cambios persisten conservando las dos fotos previas.
