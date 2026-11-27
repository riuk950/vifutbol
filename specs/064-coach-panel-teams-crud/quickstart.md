# Quickstart Validation: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

## Prerequisitos

- Código en rama `064-coach-panel-teams-crud` (o rama de trabajo con los cambios de HU 27.4).
- Entorno Flutter configurado (`flutter analyze` y `flutter test` operativos).

## Validación Automatizada

1. Ejecutar análisis estático:
   ```bash
   flutter analyze
   ```
   **Esperado**: `No issues found!`.

2. Ejecutar pruebas unitarias y de widgets relacionadas:
   ```bash
   flutter test \
     test/application/providers/coach_teams_provider_test.dart \
     test/unit/application/manage_teams_eligibility_use_case_test.dart \
     test/unit/application/teams_controller_test.dart \
     test/widget/create_team_screen_test.dart \
     test/widget/coach_panel_teams_crud_test.dart
   ```
   **Esperado**: Todas las pruebas pasan (`0` fallos).

## Validación End-to-End en App

1. **Listado exclusivo**: Iniciar sesión como entrenador con 2+ equipos propios -> abrir `/panel` -> verificar que aparecen todos sus equipos con escudo circular y ninguno de otros entrenadores.
2. **Selección reactiva**: Tocar el segundo equipo -> verificar que métricas, próximo partido y plantilla cambian a los de ese equipo.
3. **Edición**: Pulsar **Editar** en una tarjeta -> verificar campos y escudo precargados (y torneo bloqueado si está `inProgress`/`finished`) -> modificar datos -> pulsar **Guardar cambios** -> verificar mensaje en español y tarjeta actualizada.
4. **Eliminación bloqueada vs permitida**:
   - Intentar eliminar un equipo con torneo `inProgress`/`finished` o con partidos -> verificar mensaje de bloqueo en español.
   - Pulsar **Eliminar** en un equipo autónomo o en `openRegistration` sin partidos -> **Cancelar** mantiene el equipo -> confirmar **Eliminar** remueve el equipo del panel y selecciona el siguiente (o muestra estado vacío si era el último).
