# Quickstart Validation Guide: HU 26.1 Referee Panel & Full Match Management

**Feature**: `059-referee-panel-match-management`
**Contracts**: [referee_panel_match_contract.md](contracts/referee_panel_match_contract.md)
**Data Model**: [data-model.md](data-model.md)

## Prerequisites

- Flutter SDK configurado en `/Volumes/DATA/Development/FlutterProjects/vifutbol`.
- Migración SQL `supabase/migrations/202611250004_match_report_referee_observations.sql` lista (y aplicada en `supabase-db` para pruebas contra nube).

## Automated Validation Commands

1. Regenerar localizaciones tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```
2. Ejecutar análisis estático sobre los archivos modificados y nuevos:
   ```bash
   flutter analyze lib/domain/entities/digital_match_report.dart \
     lib/domain/entities/digital_match_report_state.dart \
     lib/domain/services/referee_assigned_matches_service.dart \
     lib/application/use_cases/manage_digital_match_report_use_case.dart \
     lib/application/controllers/digital_match_report_controller.dart \
     lib/infrastructure/repositories/hybrid_match_reports_repository.dart \
     lib/presentation/panel/widgets/referee_panel_content.dart \
     lib/presentation/matches/digital_match_report_screen.dart \
     test/domain/services/referee_assigned_matches_service_test.dart \
     test/application/use_cases/manage_digital_match_report_use_case_test.dart \
     test/presentation/panel/referee_panel_content_test.dart \
     test/presentation/matches/digital_match_report_screen_test.dart
   ```
   **Resultado esperado**: `No issues found!`.
3. Ejecutar la suite de pruebas unitarias y de widget:
   ```bash
   flutter test test/domain/services/referee_assigned_matches_service_test.dart \
     test/application/use_cases/manage_digital_match_report_use_case_test.dart \
     test/presentation/panel/referee_panel_content_test.dart \
     test/presentation/matches/digital_match_report_screen_test.dart
   ```
   **Resultado esperado**: 100% de pruebas aprobadas.

## End-to-End Verification Scenarios

1. **Panel del Árbitro multi-torneo**:
   - Iniciar sesión como árbitro con `linkedRefereeId`, verificar carga de partidos asignados en varios torneos, nombres reales de equipos, torneo, jornada, hora Colombia, sede, estado en español, ordenamiento (`En juego` → `Programado` → `Finalizado`) y chips de filtro.
2. **Ciclo completo del partido**:
   - Tocar partido `Programado` → abrir `DigitalMatchReportScreen` → iniciar `Primer Tiempo` → registrar gol con asistencia, tarjeta amarilla/doble amarilla, sustitución, cambio a `Entretiempo` y `Segundo Tiempo`, guardar observaciones arbitrales → confirmar cierre oficial → verificar modo solo lectura y retorno al Panel con estado `Finalizado`.
3. **Propiedad y modo offline**:
   - Verificar que un árbitro distinto al asignado ve banner de solo lectura y no puede mutar el acta.
   - Verificar inicio, eventos, observaciones y cierre en modo offline con persistencia local y sincronización al reconectar.
